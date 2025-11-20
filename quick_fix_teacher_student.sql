-- 快速修复教师学生管理功能
-- 这个脚本会创建必要的表和函数

-- 1. 彻底删除所有可能存在的冲突函数（包括所有重载版本）
DO $$
BEGIN
    -- 删除 get_authorized_students 的所有重载版本
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_authorized_students') THEN
        DROP FUNCTION get_authorized_students CASCADE;
    END IF;
    
    -- 删除 get_teacher_students 的所有重载版本
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_teacher_students') THEN
        DROP FUNCTION get_teacher_students CASCADE;
    END IF;
    
    -- 删除 batch_add_students_to_teacher 的所有重载版本
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'batch_add_students_to_teacher') THEN
        DROP FUNCTION batch_add_students_to_teacher CASCADE;
    END IF;
END $$;

-- 2. 创建教师-学生关联表（如果不存在）
CREATE TABLE IF NOT EXISTS teacher_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE(teacher_id, student_id)
);

-- 3. 创建索引
CREATE INDEX IF NOT EXISTS idx_teacher_students_teacher_id ON teacher_students(teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_students_student_id ON teacher_students(student_id);

-- 4. 启用RLS
ALTER TABLE teacher_students ENABLE ROW LEVEL SECURITY;

-- 5. 创建简化的批量添加函数
CREATE OR REPLACE FUNCTION batch_add_students_to_teacher(
    p_teacher_id TEXT,
    p_student_ids TEXT[]
)
RETURNS JSONB AS $$
DECLARE
    v_success_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_student_id TEXT;
BEGIN
    -- 简化版本：不验证权限，直接插入
    FOREACH v_student_id IN ARRAY p_student_ids LOOP
        BEGIN
            INSERT INTO teacher_students (teacher_id, student_id, created_by)
            VALUES (p_teacher_id::UUID, v_student_id::UUID, p_teacher_id::UUID)
            ON CONFLICT (teacher_id, student_id) DO NOTHING;
            
            v_success_count := v_success_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                v_failed_count := v_failed_count + 1;
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'success', v_success_count,
        'failed', v_failed_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. 创建获取教师学生的函数
CREATE OR REPLACE FUNCTION get_teacher_students(
    p_teacher_id TEXT,
    p_keyword TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    students JSONB,
    total_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH filtered_students AS (
        SELECT u.*,
               jsonb_build_object(
                   'id', u.id,
                   'username', u.username,
                   'email', u.email,
                   'user_number', u.user_number,
                   'full_name', u.full_name,
                   'role_id', u.role_id,
                   'status', u.status,
                   'phone', u.phone,
                   'department', u.department,
                   'grade', u.grade,
                   'class_name', u.class_name,
                   'created_at', u.created_at,
                   'updated_at', u.updated_at
               ) as student_data
        FROM users u
        JOIN teacher_students ts ON u.id = ts.student_id
        WHERE ts.teacher_id = p_teacher_id::UUID
        AND u.role_id = '3'
        AND (p_keyword = '' OR 
             u.full_name ILIKE '%' || p_keyword || '%' OR 
             u.user_number ILIKE '%' || p_keyword || '%')
    )
    SELECT 
        jsonb_agg(student_data) as students,
        COUNT(*) as total_count
    FROM filtered_students
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. 创建获取已授权学生的函数
CREATE OR REPLACE FUNCTION get_authorized_students(
    p_keyword TEXT DEFAULT '',
    p_grade TEXT DEFAULT '',
    p_department TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    students JSONB,
    total_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH authorized_students AS (
        SELECT u.*,
               jsonb_build_object(
                   'id', u.id,
                   'username', u.username,
                   'email', u.email,
                   'user_number', u.user_number,
                   'full_name', u.full_name,
                   'role_id', u.role_id,
                   'status', u.status,
                   'phone', u.phone,
                   'department', u.department,
                   'grade', u.grade,
                   'class_name', u.class_name,
                   'created_at', u.created_at,
                   'updated_at', u.updated_at,
                   'role', jsonb_build_object(
                       'id', r.id,
                       'role_name', r.role_name,
                       'role_description', r.role_description,
                       'permissions', r.permissions,
                       'is_system_default', r.is_system_default,
                       'created_at', r.created_at,
                       'updated_at', r.updated_at
                   )
               ) as student_data
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE u.role_id = '3'
        AND u.status = 'active'
        AND (p_keyword = '' OR 
             u.full_name ILIKE '%' || p_keyword || '%' OR 
             u.user_number ILIKE '%' || p_keyword || '%' OR
             u.email ILIKE '%' || p_keyword || '%')
        AND (p_grade = '' OR u.grade = p_grade)
        AND (p_department = '' OR u.department = p_department)
    )
    SELECT 
        jsonb_agg(student_data) as students,
        COUNT(*) as total_count
    FROM authorized_students
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. 授权给认证用户
GRANT EXECUTE ON FUNCTION batch_add_students_to_teacher TO authenticated;
GRANT EXECUTE ON FUNCTION get_teacher_students TO authenticated;
GRANT EXECUTE ON FUNCTION get_authorized_students TO authenticated;

SELECT '教师学生管理功能修复完成' as status;