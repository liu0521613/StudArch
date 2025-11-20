-- 修复SQL聚合函数错误
-- 创建修正后的教师学生管理函数

-- 1. 删除有问题的函数
DROP FUNCTION IF EXISTS get_teacher_students_v2 CASCADE;

-- 2. 创建修正后的获取教师学生函数
CREATE OR REPLACE FUNCTION get_teacher_students_v2(
    p_teacher_id TEXT,
    p_keyword TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    students JSONB,
    total_count BIGINT
) AS $$
DECLARE
    v_offset INTEGER := (p_page - 1) * p_limit;
    v_filtered_students JSONB;
    v_total_count BIGINT;
BEGIN
    -- 获取过滤后的学生数据
    SELECT jsonb_agg(
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
        )
    ) INTO v_filtered_students
    FROM users u
    JOIN teacher_students ts ON u.id = ts.student_id
    WHERE ts.teacher_id = p_teacher_id::UUID
    AND u.role_id = '3'
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR 
         u.user_number ILIKE '%' || p_keyword || '%')
    ORDER BY u.created_at DESC
    LIMIT p_limit OFFSET v_offset;
    
    -- 获取总数
    SELECT COUNT(*) INTO v_total_count
    FROM users u
    JOIN teacher_students ts ON u.id = ts.student_id
    WHERE ts.teacher_id = p_teacher_id::UUID
    AND u.role_id = '3'
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR 
         u.user_number ILIKE '%' || p_keyword || '%');
    
    -- 返回结果
    RETURN QUERY 
    SELECT v_filtered_students as students, v_total_count as total_count;
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. 删除有问题的get_authorized_students函数
DROP FUNCTION IF EXISTS get_all_available_students_v2 CASCADE;

-- 4. 创建修正后的获取已授权学生函数
CREATE OR REPLACE FUNCTION get_all_available_students_v2(
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
DECLARE
    v_offset INTEGER := (p_page - 1) * p_limit;
    v_authorized_students JSONB;
    v_total_count BIGINT;
BEGIN
    -- 获取过滤后的已授权学生数据
    SELECT jsonb_agg(
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
        )
    ) INTO v_authorized_students
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
    ORDER BY u.created_at DESC
    LIMIT p_limit OFFSET v_offset;
    
    -- 获取总数
    SELECT COUNT(*) INTO v_total_count
    FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE u.role_id = '3'
    AND u.status = 'active'
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR 
         u.user_number ILIKE '%' || p_keyword || '%' OR
         u.email ILIKE '%' || p_keyword || '%')
    AND (p_grade = '' OR u.grade = p_grade)
    AND (p_department = '' OR u.department = p_department);
    
    -- 返回结果
    RETURN QUERY 
    SELECT v_authorized_students as students, v_total_count as total_count;
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 重新授权
GRANT EXECUTE ON FUNCTION get_teacher_students_v2 TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_available_students_v2 TO authenticated;

SELECT 'SQL聚合函数错误修复完成' as status;