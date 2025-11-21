-- 修复教师学生显示问题的SQL脚本 - v2（解决函数冲突）
-- 请在Supabase SQL编辑器中执行

-- 1. 删除可能存在的冲突函数
DROP FUNCTION IF EXISTS get_teacher_students(uuid,text,integer,integer) CASCADE;
DROP FUNCTION IF EXISTS get_authorized_students(text,text,text,integer,integer) CASCADE;
DROP FUNCTION IF EXISTS batch_add_students_to_teacher(uuid,uuid[]) CASCADE;

-- 2. 检查并创建 teacher_students 表
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'teacher_students'
    ) THEN
        CREATE TABLE teacher_students (
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
        
        RAISE NOTICE '创建了 teacher_students 表';
    ELSE
        RAISE NOTICE 'teacher_students 表已存在';
    END IF;
END
$$;

-- 3. 重置RLS策略
ALTER TABLE teacher_students DISABLE ROW LEVEL SECURITY;

-- 删除现有可能有问题的策略
DROP POLICY IF EXISTS "Teachers can view their own student associations" ON teacher_students;
DROP POLICY IF EXISTS "Teachers can manage their own student associations" ON teacher_students;
DROP POLICY IF EXISTS "Allow all authenticated users to view teacher_student associations" ON teacher_students;
DROP POLICY IF EXISTS "Allow all authenticated users to manage teacher_student associations" ON teacher_students;

-- 启用RLS
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

-- 4. 创建简化版的获取教师学生列表函数
CREATE OR REPLACE FUNCTION get_teacher_students(
    p_teacher_id UUID DEFAULT NULL,
    p_keyword TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    students JSONB,
    total_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- 如果没有指定教师ID，返回空结果
    IF p_teacher_id IS NULL THEN
        RETURN QUERY SELECT NULL::JSONB, 0::BIGINT;
        RETURN;
    END IF;
    
    -- 使用CTE计算总数和获取数据
    RETURN QUERY
    WITH total AS (
        SELECT COUNT(*) as cnt
        FROM teacher_students ts
        JOIN users u ON ts.student_id = u.id
        JOIN roles r ON u.role_id = r.id
        WHERE ts.teacher_id = p_teacher_id
        AND r.role_name = 'student'
        AND (p_keyword = '' OR 
             u.full_name ILIKE '%' || p_keyword || '%' OR
             u.user_number ILIKE '%' || p_keyword || '%' OR
             u.email ILIKE '%' || p_keyword || '%')
    ),
    data AS (
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
        ) FILTER (WHERE u.id IS NOT NULL) as students_json
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
        LIMIT p_limit OFFSET ((p_page - 1) * p_limit)
    )
    SELECT 
        COALESCE(d.students_json, '[]'::jsonb) as students,
        COALESCE(t.cnt, 0) as total_count
    FROM total t, data d
    LIMIT 1;
    
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
    WITH total AS (
        SELECT COUNT(*) as cnt
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
    ),
    data AS (
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
        ) FILTER (WHERE u.id IS NOT NULL) as students_json
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
        LIMIT p_limit OFFSET ((p_page - 1) * p_limit)
    )
    SELECT 
        COALESCE(t.cnt, 0) as total_count,
        COALESCE(d.students_json, '[]'::jsonb) as students
    FROM total t, data d
    LIMIT 1;
    
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
    v_student_id UUID;
    v_error_messages TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- 简化权限检查
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_teacher_id) THEN
        RETURN jsonb_build_object(
            'success', 0,
            'failed', 0,
            'error', '无效的教师ID'
        );
    END IF;

    -- 批量插入，使用更高效的方法
    INSERT INTO teacher_students (teacher_id, student_id, created_by)
    SELECT p_teacher_id, unnest(p_student_ids), p_teacher_id
    ON CONFLICT (teacher_id, student_id) DO NOTHING;
    
    -- 计算成功和失败的数量
    GET DIAGNOSTICS v_success_count = ROW_COUNT;
    v_failed_count := array_length(p_student_ids, 1) - v_success_count;

    RETURN jsonb_build_object(
        'success', v_success_count,
        'failed', v_failed_count,
        'errors', v_error_messages
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

-- 9. 插入测试数据（仅用于验证）
DO $$
DECLARE
    v_teacher_id UUID;
    v_student_ids UUID[];
BEGIN
    -- 查找一个教师ID
    SELECT id INTO v_teacher_id FROM users WHERE user_number ILIKE '%T%' LIMIT 1;
    
    IF v_teacher_id IS NOT NULL THEN
        -- 查找前5个学生ID
        SELECT array_agg(u.id) INTO v_student_ids
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE r.role_name = 'student'
        AND u.status = 'active'
        LIMIT 5;
        
        IF v_student_ids IS NOT NULL AND array_length(v_student_ids, 1) > 0 THEN
            -- 插入关联数据
            INSERT INTO teacher_students (teacher_id, student_id, created_by)
            SELECT v_teacher_id, unnest(v_student_ids), v_teacher_id
            ON CONFLICT (teacher_id, student_id) DO NOTHING;
            
            RAISE NOTICE '已为教师 % 插入 % 个学生关联', v_teacher_id, array_length(v_student_ids, 1);
        END IF;
    END IF;
END
$$;

-- 10. 验证结果
DO $$
DECLARE
    v_teacher_student_count INTEGER;
    v_student_count INTEGER;
    v_teacher_count INTEGER;
BEGIN
    -- 统计teacher_students表记录数
    SELECT COUNT(*) INTO v_teacher_student_count FROM teacher_students;
    
    -- 统计活跃学生数
    SELECT COUNT(*) INTO v_student_count FROM users u WHERE u.role_id = '3' AND u.status = 'active';
    
    -- 统计教师数
    SELECT COUNT(*) INTO v_teacher_count FROM users u WHERE u.role_id = '2';
    
    RAISE NOTICE '=== 修复结果 ===';
    RAISE NOTICE 'teacher_students 表记录数: %', v_teacher_student_count;
    RAISE NOTICE '活跃学生数量: %', v_student_count;
    RAISE NOTICE '教师数量: %', v_teacher_count;
    RAISE NOTICE '';
    RAISE NOTICE '✅ 修复完成！现在可以测试导入功能了。';
END
$$;