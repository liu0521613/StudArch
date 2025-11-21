-- 修复教师学生显示问题的SQL脚本 - v3（最终版本）
-- 请在Supabase SQL编辑器中执行

-- 1. 清理现有函数和策略
DROP FUNCTION IF EXISTS get_teacher_students(uuid,text,integer,integer) CASCADE;
DROP FUNCTION IF EXISTS get_authorized_students(text,text,text,integer,integer) CASCADE;
DROP FUNCTION IF EXISTS batch_add_students_to_teacher(uuid,uuid[]) CASCADE;
DROP FUNCTION IF EXISTS remove_student_from_teacher(uuid,uuid) CASCADE;

-- 2. 确保 teacher_students 表存在
CREATE TABLE IF NOT EXISTS teacher_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE(teacher_id, student_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_teacher_students_teacher_id ON teacher_students(teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_students_student_id ON teacher_students(student_id);

-- 3. 重置RLS策略
ALTER TABLE teacher_students DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for all authenticated users" ON teacher_students;
DROP POLICY IF EXISTS "Enable insert access for all authenticated users" ON teacher_students;
DROP POLICY IF EXISTS "Enable update access for all authenticated users" ON teacher_students;
DROP POLICY IF EXISTS "Enable delete access for all authenticated users" ON teacher_students;

ALTER TABLE teacher_students ENABLE ROW LEVEL SECURITY;

-- 创建简化的RLS策略
CREATE POLICY "Enable read access for all authenticated users" ON teacher_students
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert access for all authenticated users" ON teacher_students
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update access for all authenticated users" ON teacher_students
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete access for all authenticated users" ON teacher_students
    FOR DELETE USING (auth.role() = 'authenticated');

-- 4. 创建获取教师学生列表的函数
CREATE OR REPLACE FUNCTION get_teacher_students(
    p_teacher_id UUID,
    p_keyword TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    students JSONB,
    total_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    WITH total_count_cte AS (
        SELECT COUNT(*) as cnt
        FROM teacher_students ts
        INNER JOIN users u ON ts.student_id = u.id
        INNER JOIN roles r ON u.role_id = r.id
        WHERE ts.teacher_id = p_teacher_id
        AND r.role_name = 'student'
        AND (p_keyword = '' OR 
             u.full_name ILIKE '%' || p_keyword || '%' OR
             u.user_number ILIKE '%' || p_keyword || '%' OR
             u.email ILIKE '%' || p_keyword || '%')
    ),
    students_data AS (
        SELECT jsonb_build_object(
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
            'role', jsonb_build_object(
                'id', r.id,
                'role_name', r.role_name,
                'role_description', r.role_description
            ),
            'associated_at', ts.created_at
        ) as student_json
        FROM teacher_students ts
        INNER JOIN users u ON ts.student_id = u.id
        INNER JOIN roles r ON u.role_id = r.id
        WHERE ts.teacher_id = p_teacher_id
        AND r.role_name = 'student'
        AND (p_keyword = '' OR 
             u.full_name ILIKE '%' || p_keyword || '%' OR
             u.user_number ILIKE '%' || p_keyword || '%' OR
             u.email ILIKE '%' || p_keyword || '%')
        ORDER BY ts.created_at DESC
        LIMIT p_limit OFFSET ((p_page - 1) * p_limit)
    ),
    aggregated_data AS (
        SELECT 
            jsonb_agg(student_json) as students_json
        FROM students_data
    )
    SELECT 
        COALESCE(ad.students_json, '[]'::jsonb) as students,
        COALESCE(t.cnt, 0::bigint) as total_count
    FROM total_count_cte t
    CROSS JOIN aggregated_data ad;
    
END;
$$;

-- 5. 创建获取授权学生的函数
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
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    WITH total_count_cte AS (
        SELECT COUNT(*) as cnt
        FROM users u
        INNER JOIN roles r ON u.role_id = r.id
        WHERE r.role_name = 'student'
        AND u.status = 'active'
        AND (p_keyword = '' OR 
             u.full_name ILIKE '%' || p_keyword || '%' OR
             u.user_number ILIKE '%' || p_keyword || '%' OR
             u.email ILIKE '%' || p_keyword || '%')
        AND (p_grade = '' OR u.grade = p_grade)
        AND (p_department = '' OR u.department = p_department)
    ),
    students_data AS (
        SELECT jsonb_build_object(
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
            'role', jsonb_build_object(
                'id', r.id,
                'role_name', r.role_name,
                'role_description', r.role_description
            )
        ) as student_json
        FROM users u
        INNER JOIN roles r ON u.role_id = r.id
        WHERE r.role_name = 'student'
        AND u.status = 'active'
        AND (p_keyword = '' OR 
             u.full_name ILIKE '%' || p_keyword || '%' OR
             u.user_number ILIKE '%' || p_keyword || '%' OR
             u.email ILIKE '%' || p_keyword || '%')
        AND (p_grade = '' OR u.grade = p_grade)
        AND (p_department = '' OR u.department = p_department)
        ORDER BY u.created_at DESC
        LIMIT p_limit OFFSET ((p_page - 1) * p_limit)
    ),
    aggregated_data AS (
        SELECT 
            jsonb_agg(student_json) as students_json
        FROM students_data
    )
    SELECT 
        COALESCE(t.cnt, 0::bigint) as total_count,
        COALESCE(ad.students_json, '[]'::jsonb) as students
    FROM total_count_cte t
    CROSS JOIN aggregated_data ad;
    
END;
$$;

-- 6. 创建批量添加学生的函数
CREATE OR REPLACE FUNCTION batch_add_students_to_teacher(
    p_teacher_id UUID,
    p_student_ids UUID[]
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_success_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_processed_count INTEGER := 0;
BEGIN
    -- 验证教师是否存在
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_teacher_id) THEN
        RETURN jsonb_build_object(
            'success', 0,
            'failed', 0,
            'error', '无效的教师ID'
        );
    END IF;

    -- 使用高效的批量插入
    INSERT INTO teacher_students (teacher_id, student_id, created_by)
    SELECT p_teacher_id, unnest(p_student_ids), p_teacher_id
    ON CONFLICT (teacher_id, student_id) DO NOTHING;
    
    -- 获取影响的行数
    GET DIAGNOSTICS v_processed_count = ROW_COUNT;
    v_success_count = v_processed_count;
    v_failed_count = array_length(p_student_ids, 1) - v_processed_count;

    RETURN jsonb_build_object(
        'success', v_success_count,
        'failed', v_failed_count
    );
END;
$$;

-- 7. 创建移除学生关联的函数
CREATE OR REPLACE FUNCTION remove_student_from_teacher(
    p_teacher_id UUID,
    p_student_id UUID
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    DELETE FROM teacher_students 
    WHERE teacher_id = p_teacher_id 
    AND student_id = p_student_id;
    
    RETURN FOUND;
END;
$$;

-- 8. 授权执行权限
GRANT EXECUTE ON FUNCTION get_teacher_students TO authenticated;
GRANT EXECUTE ON FUNCTION get_authorized_students TO authenticated;
GRANT EXECUTE ON FUNCTION batch_add_students_to_teacher TO authenticated;
GRANT EXECUTE ON FUNCTION remove_student_from_teacher TO authenticated;

-- 9. 验证和测试
DO $$
DECLARE
    v_teacher_count INTEGER;
    v_student_count INTEGER;
    v_relation_count INTEGER;
BEGIN
    -- 统计数据
    SELECT COUNT(*) INTO v_teacher_count FROM users u WHERE u.role_id = '2';
    SELECT COUNT(*) INTO v_student_count FROM users u WHERE u.role_id = '3' AND u.status = 'active';
    SELECT COUNT(*) INTO v_relation_count FROM teacher_students;
    
    RAISE NOTICE '=== 验证结果 ===';
    RAISE NOTICE '教师数量: %', v_teacher_count;
    RAISE NOTICE '活跃学生数量: %', v_student_count;
    RAISE NOTICE '师生关联数量: %', v_relation_count;
    
    IF v_student_count = 0 THEN
        RAISE NOTICE '⚠️  没有找到学生数据，可能需要先创建一些学生用户';
    ELSIF v_teacher_count = 0 THEN
        RAISE NOTICE '⚠️  没有找到教师数据，可能需要先创建一些教师用户';
    ELSE
        RAISE NOTICE '✅ 数据库结构和函数修复完成！';
    END IF;
END
$$;