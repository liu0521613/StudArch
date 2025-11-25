-- 简化版 get_available_students_for_import 函数
-- 解决所有歧义和语法问题

DROP FUNCTION IF EXISTS get_available_students_for_import CASCADE;

CREATE OR REPLACE FUNCTION get_available_students_for_import(
    p_teacher_id UUID,
    p_keyword TEXT DEFAULT '',
    p_grade TEXT DEFAULT '',
    p_department TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE(
    students JSON,
    total_count BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    offset_count INTEGER;
    student_list JSON;
    total_records BIGINT;
BEGIN
    offset_count := (p_page - 1) * p_limit;
    
    -- 获取总数
    SELECT COUNT(*) INTO total_records
    FROM users u
    INNER JOIN roles r ON u.role_id = r.id
    LEFT JOIN teacher_students ts ON u.id = ts.student_id AND ts.teacher_id = p_teacher_id
    WHERE u.role_id = 3  -- 学生角色
    AND u.status = 'active'
    AND (ts.student_id IS NULL OR ts.teacher_id != p_teacher_id)  -- 尚未被该教师管理
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR 
         u.user_number ILIKE '%' || p_keyword || '%' OR
         u.email ILIKE '%' || p_keyword || '%')
    AND (p_grade = '' OR u.grade ILIKE '%' || p_grade || '%')
    AND (p_department = '' OR u.department ILIKE '%' || p_department || '%');
    
    -- 获取学生列表
    SELECT json_agg(
        json_build_object(
            'id', u.id,
            'username', u.username,
            'email', u.email,
            'user_number', u.user_number,
            'full_name', u.full_name,
            'role_id', u.role_id::TEXT,
            'status', u.status,
            'phone', u.phone,
            'department', u.department,
            'grade', u.grade,
            'class_name', u.class_name,
            'created_at', u.created_at,
            'updated_at', u.updated_at,
            'role', json_build_object(
                'id', r.id::TEXT,
                'role_name', r.role_name,
                'role_description', r.role_description,
                'permissions', r.permissions,
                'is_system_default', r.is_system_default,
                'created_at', r.created_at,
                'updated_at', r.updated_at
            )
        )
    ) INTO student_list
    FROM users u
    INNER JOIN roles r ON u.role_id = r.id
    LEFT JOIN teacher_students ts ON u.id = ts.student_id AND ts.teacher_id = p_teacher_id
    WHERE u.role_id = 3  -- 学生角色
    AND u.status = 'active'
    AND (ts.student_id IS NULL OR ts.teacher_id != p_teacher_id)  -- 尚未被该教师管理
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR 
         u.user_number ILIKE '%' || p_keyword || '%' OR
         u.email ILIKE '%' || p_keyword || '%')
    AND (p_grade = '' OR u.grade ILIKE '%' || p_grade || '%')
    AND (p_department = '' OR u.department ILIKE '%' || p_department || '%')
    ORDER BY u.created_at DESC
    LIMIT p_limit
    OFFSET offset_count;
    
    -- 返回结果
    RETURN QUERY SELECT student_list, total_records;
END;
$$;

-- 设置权限
GRANT EXECUTE ON FUNCTION get_available_students_for_import TO authenticated;

-- 测试函数
SELECT '修复完成，测试函数结果' as info;
SELECT * FROM get_available_students_for_import(
    '00000000-0000-0000-0000-000000000001', 
    '', 
    '', 
    '', 
    1, 
    20
);

COMMIT;