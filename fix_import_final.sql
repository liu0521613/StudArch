-- 最终修复版 get_available_students_for_import 函数
-- 完全避免歧义问题

-- 首先完全删除函数
DROP FUNCTION IF EXISTS get_available_students_for_import CASCADE;

-- 重新创建简化版本
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
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT json_agg(
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
        ) FROM (
            SELECT u.*, r.*
            FROM users u
            INNER JOIN roles r ON u.role_id = r.id
            LEFT JOIN teacher_students ts ON u.id = ts.student_id AND ts.teacher_id = p_teacher_id
            WHERE u.role_id = 3
            AND u.status = 'active'
            AND (ts.student_id IS NULL OR ts.teacher_id != p_teacher_id)
            AND (p_keyword = '' OR 
                 u.full_name ILIKE '%' || p_keyword || '%' OR 
                 u.user_number ILIKE '%' || p_keyword || '%' OR
                 u.email ILIKE '%' || p_keyword || '%')
            AND (p_grade = '' OR u.grade ILIKE '%' || p_grade || '%')
            AND (p_department = '' OR u.department ILIKE '%' || p_department || '%')
            ORDER BY u.created_at DESC
            LIMIT p_limit
            OFFSET (p_page - 1) * p_limit
        ) u
        INNER JOIN roles r ON u.role_id = r.id) as students,
        (SELECT COUNT(*)::BIGINT
         FROM users u
         INNER JOIN roles r ON u.role_id = r.id
         LEFT JOIN teacher_students ts ON u.id = ts.student_id AND ts.teacher_id = p_teacher_id
         WHERE u.role_id = 3
         AND u.status = 'active'
         AND (ts.student_id IS NULL OR ts.teacher_id != p_teacher_id)
         AND (p_keyword = '' OR 
              u.full_name ILIKE '%' || p_keyword || '%' OR 
              u.user_number ILIKE '%' || p_keyword || '%' OR
              u.email ILIKE '%' || p_keyword || '%')
         AND (p_grade = '' OR u.grade ILIKE '%' || p_grade || '%')
         AND (p_department = '' OR u.department ILIKE '%' || p_department || '%')) as total_count;
END;
$$;

-- 设置权限
GRANT EXECUTE ON FUNCTION get_available_students_for_import TO authenticated;

-- 立即测试
SELECT '最终版本测试结果：' as info;
SELECT * FROM get_available_students_for_import(
    '00000000-0000-0000-0000-000000000001', 
    '', 
    '', 
    '', 
    1, 
    20
);

COMMIT;