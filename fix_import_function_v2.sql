-- 修复 get_available_students_for_import 函数 - 解决 role_id 歧义问题

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
BEGIN
    offset_count := (p_page - 1) * p_limit;
    
    RETURN QUERY
    WITH available_students AS (
        SELECT 
            u.id,
            u.username,
            u.email,
            u.user_number,
            u.full_name,
            u.status,
            u.phone,
            u.department,
            u.grade,
            u.class_name,
            u.created_at,
            u.updated_at,
            r.id as role_id_col,
            r.role_name,
            r.role_description,
            r.permissions,
            r.is_system_default,
            r.created_at as role_created_at,
            r.updated_at as role_updated_at,
            COUNT(*) OVER () as total_count
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
        OFFSET offset_count
    )
    SELECT 
        json_agg(
            json_build_object(
                'id', id,
                'username', username,
                'email', email,
                'user_number', user_number,
                'full_name', full_name,
                'role_id', u.role_id::TEXT,
                'status', status,
                'phone', phone,
                'department', department,
                'grade', grade,
                'class_name', class_name,
                'created_at', created_at,
                'updated_at', updated_at,
                'role', json_build_object(
                    'id', role_id_col::TEXT,
                    'role_name', role_name,
                    'role_description', role_description,
                    'permissions', permissions,
                    'is_system_default', is_system_default,
                    'created_at', role_created_at,
                    'updated_at', role_updated_at
                )
            )
        ) as students,
        MAX(total_count) as total_count
    FROM available_students
    GROUP BY total_count;
END;
$$;

-- 设置权限
GRANT EXECUTE ON FUNCTION get_available_students_for_import TO authenticated;

-- 测试函数
SELECT '测试函数结果' as info;
SELECT * FROM get_available_students_for_import(
    '00000000-0000-0000-0000-000000000001', 
    '', 
    '', 
    '', 
    1, 
    20
);

COMMIT;