-- 教师学生管理相关表结构
-- 创建教师-学生关联表
CREATE TABLE IF NOT EXISTS teacher_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE(teacher_id, student_id)
);

-- 创建索引提高查询性能
CREATE INDEX IF NOT EXISTS idx_teacher_students_teacher_id ON teacher_students(teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_students_student_id ON teacher_students(student_id);

-- 启用RLS (行级安全策略)
ALTER TABLE teacher_students ENABLE ROW LEVEL SECURITY;

-- 策略：教师只能查看自己的学生关联记录
CREATE POLICY "Teachers can view their own student associations"
    ON teacher_students FOR SELECT
    USING (
        auth.uid() = teacher_id OR
        (EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role_id = (SELECT id FROM roles WHERE role_name = 'super_admin')
        ))
    );

-- 策略：教师只能管理自己的学生关联记录
CREATE POLICY "Teachers can manage their own student associations"
    ON teacher_students FOR ALL
    USING (
        auth.uid() = teacher_id OR
        (EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role_id = (SELECT id FROM roles WHERE role_name = 'super_admin')
        ))
    );

-- 创建函数：获取教师管理的所有学生
CREATE OR REPLACE FUNCTION get_teacher_students(
    p_teacher_id UUID,
    p_keyword TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    students JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', u.id,
            'username', u.username,
            'email', u.email,
            'user_number', u.user_number,
            'full_name', u.full_name,
            'phone', u.phone,
            'department', u.department,
            'grade', u.grade,
            'class_name', u.class_name,
            'status', u.status,
            'role', r,
            'associated_at', ts.created_at
        )
    ) FILTER (WHERE u.id IS NOT NULL)
    FROM teacher_students ts
    JOIN users u ON ts.student_id = u.id
    JOIN roles r ON u.role_id = r.id
    WHERE ts.teacher_id = p_teacher_id
    AND r.role_name = 'student'
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR
         u.user_number ILIKE '%' || p_keyword || '%' OR
         u.email ILIKE '%' || p_keyword || '%')
    ORDER BY ts.created_at DESC
    LIMIT p_limit OFFSET ((p_page - 1) * p_limit);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建函数：获取所有已授权学生（供教师选择导入）
CREATE OR REPLACE FUNCTION get_authorized_students(
    p_keyword TEXT DEFAULT '',
    p_grade TEXT DEFAULT '',
    p_department TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    total_count BIGINT,
    students JSONB
) AS $$
DECLARE
    v_total_count BIGINT;
    v_students JSONB;
BEGIN
    -- 计算总数
    SELECT COUNT(*) INTO v_total_count
    FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE r.role_name = 'student'
    AND u.status = 'active'
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR
         u.user_number ILIKE '%' || p_keyword || '%' OR
         u.email ILIKE '%' || p_keyword || '%')
    AND (p_grade = '' OR u.grade = p_grade)
    AND (p_department = '' OR u.department = p_department);

    -- 获取分页数据
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', u.id,
            'username', u.username,
            'email', u.email,
            'user_number', u.user_number,
            'full_name', u.full_name,
            'phone', u.phone,
            'department', u.department,
            'grade', u.grade,
            'class_name', u.class_name,
            'status', u.status,
            'role', r
        )
    ) FILTER (WHERE u.id IS NOT NULL) INTO v_students
    FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE r.role_name = 'student'
    AND u.status = 'active'
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR
         u.user_number ILIKE '%' || p_keyword || '%' OR
         u.email ILIKE '%' || p_keyword || '%')
    AND (p_grade = '' OR u.grade = p_grade)
    AND (p_department = '' OR u.department = p_department)
    ORDER BY u.created_at DESC
    LIMIT p_limit OFFSET ((p_page - 1) * p_limit);

    RETURN QUERY SELECT v_total_count, v_students;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建函数：批量添加学生到教师管理列表
CREATE OR REPLACE FUNCTION batch_add_students_to_teacher(
    p_teacher_id UUID,
    p_student_ids UUID[]
)
RETURNS JSONB AS $$
DECLARE
    v_success_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_error_messages TEXT[];
    v_student_id UUID;
BEGIN
    -- 验证教师权限
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = p_teacher_id 
        AND role_id = (SELECT id FROM roles WHERE role_name = 'teacher')
    ) THEN
        RETURN jsonb_build_object(
            'success', 0,
            'failed', 0,
            'error', '无效的教师ID或权限不足'
        );
    END IF;

    -- 批量插入学生关联
    FOREACH v_student_id IN ARRAY p_student_ids LOOP
        BEGIN
            -- 验证学生是否存在且状态正常
            IF EXISTS (
                SELECT 1 FROM users u
                JOIN roles r ON u.role_id = r.id
                WHERE u.id = v_student_id 
                AND r.role_name = 'student'
                AND u.status = 'active'
            ) THEN
                -- 插入关联记录（忽略重复）
                INSERT INTO teacher_students (teacher_id, student_id, created_by)
                VALUES (p_teacher_id, v_student_id, p_teacher_id)
                ON CONFLICT (teacher_id, student_id) DO NOTHING;
                
                v_success_count := v_success_count + 1;
            ELSE
                v_failed_count := v_failed_count + 1;
                v_error_messages := array_append(v_error_messages, 
                    format('学生ID %s 不存在或状态异常', v_student_id));
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                v_failed_count := v_failed_count + 1;
                v_error_messages := array_append(v_error_messages, 
                    format('学生ID %s 添加失败: %s', v_student_id, SQLERRM));
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'success', v_success_count,
        'failed', v_failed_count,
        'errors', v_error_messages
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建函数：移除教师-学生关联
CREATE OR REPLACE FUNCTION remove_student_from_teacher(
    p_teacher_id UUID,
    p_student_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM teacher_students 
    WHERE teacher_id = p_teacher_id 
    AND student_id = p_student_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建视图：教师学生统计
CREATE OR REPLACE VIEW teacher_student_stats AS
SELECT 
    t.id as teacher_id,
    t.full_name as teacher_name,
    COUNT(ts.student_id) as student_count,
    MAX(ts.created_at) as last_add_date
FROM users t
LEFT JOIN teacher_students ts ON t.id = ts.teacher_id
JOIN roles r ON t.role_id = r.id
WHERE r.role_name = 'teacher'
GROUP BY t.id, t.full_name;

-- 授权必要的权限
GRANT SELECT, INSERT, UPDATE, DELETE ON teacher_students TO authenticated;
GRANT EXECUTE ON FUNCTION get_teacher_students TO authenticated;
GRANT EXECUTE ON FUNCTION get_authorized_students TO authenticated;
GRANT EXECUTE ON FUNCTION batch_add_students_to_teacher TO authenticated;
GRANT EXECUTE ON FUNCTION remove_student_from_teacher TO authenticated;
GRANT SELECT ON teacher_student_stats TO authenticated;

-- 插入一些测试数据（仅用于演示）
INSERT INTO teacher_students (teacher_id, student_id, created_by)
SELECT 
    t.id,
    s.id,
    t.id
FROM users t, users s
JOIN roles r ON s.role_id = r.id
WHERE t.role_id = (SELECT id FROM roles WHERE role_name = 'teacher')
AND r.role_name = 'student'
AND t.user_number = 'T001' -- 假设有一个教师用户
LIMIT 5
ON CONFLICT (teacher_id, student_id) DO NOTHING;