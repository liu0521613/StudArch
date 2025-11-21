-- 获取可导入学生列表（排除已导入的学生）
-- 简化版本，避免复杂的CTE嵌套问题

CREATE OR REPLACE FUNCTION get_available_students_for_import(
    p_teacher_id UUID,
    p_keyword TEXT DEFAULT '',
    p_grade TEXT DEFAULT '',
    p_department TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 50
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_offset INTEGER := (p_page - 1) * p_limit;
    v_result JSONB;
BEGIN
    -- 使用更简单的查询方式
    SELECT jsonb_build_object(
        'students', jsonb_agg(
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
                'created_at', u.created_at,
                'updated_at', u.updated_at,
                'role', jsonb_build_object(
                    'id', u.role_id,
                    'role_name', u.role_name,
                    'role_description', u.role_description,
                    'is_system_default', u.is_system_default,
                    'created_at', r.created_at,
                    'updated_at', r.updated_at
                )
            )
        ),
        'total_count', COUNT(*) OVER()
    ) INTO v_result
    FROM (
        SELECT 
            u.id,
            u.username,
            u.email,
            u.user_number,
            u.full_name,
            u.phone,
            u.department,
            u.grade,
            u.class_name,
            u.status,
            u.created_at,
            u.updated_at,
            u.role_id,
            r.role_name,
            r.role_description,
            r.is_system_default,
            r.created_at,
            r.updated_at
        FROM users u
        LEFT JOIN roles r ON u.role_id = r.id
        WHERE u.role_id = '3'  -- 学生角色
          AND u.status = 'active'
          AND NOT EXISTS (
              SELECT 1 FROM teacher_students ts 
              WHERE ts.teacher_id = p_teacher_id 
                AND ts.student_id = u.id
          )
          AND (
              p_keyword = '' OR 
              LOWER(u.full_name) LIKE LOWER('%' || p_keyword || '%') OR
              LOWER(u.user_number) LIKE LOWER('%' || p_keyword || '%') OR
              LOWER(u.email) LIKE LOWER('%' || p_keyword || '%')
          )
          AND (p_grade = '' OR u.grade = p_grade)
          AND (p_department = '' OR u.department = p_department)
        ORDER BY u.created_at DESC
        LIMIT p_limit OFFSET v_offset
    ) u;
    
    RETURN COALESCE(v_result, jsonb_build_object('students', jsonb_build_array(), 'total_count', 0));
END;
$$;

-- 添加注释
COMMENT ON FUNCTION get_available_students_for_import IS '获取可导入学生列表，排除已导入的学生';

-- 授权执行权限给 authenticated 用户
GRANT EXECUTE ON FUNCTION get_available_students_for_import TO authenticated;
GRANT EXECUTE ON FUNCTION get_available_students_for_import TO anon;

-- 注意：函数不需要RLS，ROW LEVEL SECURITY只对表有效