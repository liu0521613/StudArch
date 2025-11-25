-- 最基础版本的 get_available_students_for_import 函数
-- 避免所有可能的复杂性和歧义

-- 完全删除函数
DROP FUNCTION IF EXISTS get_available_students_for_import CASCADE;

-- 创建最简化版本
CREATE OR REPLACE FUNCTION get_available_students_for_import(
    p_teacher_id UUID,
    p_keyword TEXT DEFAULT '',
    p_grade TEXT DEFAULT '',
    p_department TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 50
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    result_json JSON;
    total_count BIGINT;
    offset_count INTEGER;
BEGIN
    offset_count := (p_page - 1) * p_limit;
    
    -- 计算总数
    SELECT COUNT(*)::BIGINT INTO total_count
    FROM users u
    WHERE u.role_id = 3
    AND u.status = 'active'
    AND NOT EXISTS (
        SELECT 1 FROM teacher_students ts 
        WHERE ts.student_id = u.id AND ts.teacher_id = p_teacher_id
    )
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR 
         u.user_number ILIKE '%' || p_keyword || '%' OR
         u.email ILIKE '%' || p_keyword || '%')
    AND (p_grade = '' OR u.grade ILIKE '%' || p_grade || '%')
    AND (p_department = '' OR u.department ILIKE '%' || p_department || '%');
    
    -- 构建结果JSON
    SELECT json_build_object(
        'students', (
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
                        'id', '3',
                        'role_name', 'student',
                        'role_description', '学生',
                        'permissions', '[]',
                        'is_system_default', true,
                        'created_at', NOW(),
                        'updated_at', NOW()
                    )
                )
            )
            FROM users u
            WHERE u.role_id = 3
            AND u.status = 'active'
            AND NOT EXISTS (
                SELECT 1 FROM teacher_students ts 
                WHERE ts.student_id = u.id AND ts.teacher_id = p_teacher_id
            )
            AND (p_keyword = '' OR 
                 u.full_name ILIKE '%' || p_keyword || '%' OR 
                 u.user_number ILIKE '%' || p_keyword || '%' OR
                 u.email ILIKE '%' || p_keyword || '%')
            AND (p_grade = '' OR u.grade ILIKE '%' || p_grade || '%')
            AND (p_department = '' OR u.department ILIKE '%' || p_department || '%')
            ORDER BY u.created_at DESC
            LIMIT p_limit
            OFFSET offset_count
        ),
        'total_count', total_count
    ) INTO result_json;
    
    RETURN result_json;
END;
$$;

-- 设置权限
GRANT EXECUTE ON FUNCTION get_available_students_for_import TO authenticated;

-- 测试函数
SELECT '基础版本测试结果：' as info;
SELECT get_available_students_for_import(
    '00000000-0000-0000-0000-000000000001', 
    '', 
    '', 
    '', 
    1, 
    20
);

COMMIT;