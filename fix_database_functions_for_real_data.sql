-- 根据真实数据库结构修复批量导入功能
-- 这个文件包含了所有必要的数据库函数

-- 1. 获取教师管理的学生列表函数
CREATE OR REPLACE FUNCTION get_teacher_students_v2(
    p_teacher_id UUID,
    p_keyword TEXT DEFAULT '',
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 20
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
    SELECT 
        json_agg(
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
        ) as students,
        (SELECT COUNT(*) FROM teacher_students ts 
         WHERE ts.teacher_id = p_teacher_id) as total_count
    FROM users u
    INNER JOIN teacher_students ts ON u.id = ts.student_id
    INNER JOIN roles r ON u.role_id = r.id
    WHERE ts.teacher_id = p_teacher_id
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR 
         u.user_number ILIKE '%' || p_keyword || '%' OR
         u.email ILIKE '%' || p_keyword || '%')
    GROUP BY ts.teacher_id
    LIMIT p_limit
    OFFSET offset_count;
END;
$$;

-- 2. 获取可导入的学生列表函数
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
    SELECT 
        json_agg(
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
        ) as students,
        COUNT(*) OVER () as total_count
    FROM users u
    INNER JOIN roles r ON u.role_id = r.id
    LEFT JOIN teacher_students ts ON u.id = ts.student_id AND ts.teacher_id = p_teacher_id
    WHERE u.role_id = 3  -- 学生角色
    AND u.status = 'active'
    AND ts.student_id IS NULL  -- 尚未被该教师管理
    AND (p_keyword = '' OR 
         u.full_name ILIKE '%' || p_keyword || '%' OR 
         u.user_number ILIKE '%' || p_keyword || '%' OR
         u.email ILIKE '%' || p_keyword || '%')
    AND (p_grade = '' OR u.grade ILIKE '%' || p_grade || '%')
    AND (p_department = '' OR u.department ILIKE '%' || p_department || '%')
    GROUP BY u.id, r.id
    ORDER BY u.created_at DESC
    LIMIT p_limit
    OFFSET offset_count;
END;
$$;

-- 3. 批量添加学生到教师管理列表函数
CREATE OR REPLACE FUNCTION batch_add_students_to_teacher(
    p_teacher_id UUID,
    p_student_ids TEXT[]
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    success_count INTEGER := 0;
    failed_count INTEGER := 0;
    error_message TEXT;
    student_id UUID;
    existing_count INTEGER;
BEGIN
    -- 验证教师是否存在
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_teacher_id AND role_id = 2) THEN
        RETURN json_build_object('success', 0, 'failed', 0, 'error', '无效的教师ID');
    END IF;
    
    -- 处理每个学生ID
    FOREACH student_id IN ARRAY p_student_ids LOOP
        BEGIN
            -- 检查学生是否存在且为学生角色
            IF NOT EXISTS (SELECT 1 FROM users WHERE id = student_id AND role_id = 3) THEN
                failed_count := failed_count + 1;
                CONTINUE;
            END IF;
            
            -- 检查是否已经存在关联
            SELECT COUNT(*) INTO existing_count
            FROM teacher_students 
            WHERE teacher_id = p_teacher_id AND student_id = student_id;
            
            IF existing_count > 0 THEN
                -- 已存在，算作成功（重复导入）
                success_count := success_count + 1;
                CONTINUE;
            END IF;
            
            -- 插入新的关联记录
            INSERT INTO teacher_students (teacher_id, student_id, created_at, created_by)
            VALUES (p_teacher_id, student_id, NOW(), p_teacher_id);
            
            success_count := success_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                failed_count := failed_count + 1;
                IF error_message IS NULL THEN
                    error_message := SQLERRM;
                END IF;
        END;
    END LOOP;
    
    -- 构建返回结果
    IF failed_count > 0 THEN
        error_message := COALESCE(error_message, '部分导入失败');
    END IF;
    
    RETURN json_build_object(
        'success', success_count,
        'failed', failed_count,
        'error', error_message
    );
END;
$$;

-- 4. 移除学生从教师管理列表函数
CREATE OR REPLACE FUNCTION remove_student_from_teacher(
    p_teacher_id UUID,
    p_student_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM teacher_students 
    WHERE teacher_id = p_teacher_id AND student_id = p_student_id;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count > 0;
END;
$$;

-- 5. 获取教师学生统计信息函数
CREATE OR REPLACE FUNCTION get_teacher_student_stats(p_teacher_id UUID)
RETURNS TABLE(
    teacher_id UUID,
    student_count BIGINT,
    last_add_date TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p_teacher_id,
        COUNT(*) as student_count,
        MAX(ts.created_at) as last_add_date
    FROM teacher_students ts
    WHERE ts.teacher_id = p_teacher_id
    GROUP BY ts.teacher_id;
END;
$$;

-- 6. 创建或更新视图以便于查询统计信息
CREATE OR REPLACE VIEW teacher_student_stats AS
SELECT 
    ts.teacher_id,
    COUNT(*) as student_count,
    MAX(ts.created_at) as last_add_date
FROM teacher_students ts
GROUP BY ts.teacher_id;

-- 7. 权限设置（如果需要）
-- GRANT EXECUTE ON FUNCTION get_teacher_students_v2 TO authenticated;
-- GRANT EXECUTE ON FUNCTION get_available_students_for_import TO authenticated;
-- GRANT EXECUTE ON FUNCTION batch_add_students_to_teacher TO authenticated;
-- GRANT EXECUTE ON FUNCTION remove_student_from_teacher TO authenticated;
-- GRANT EXECUTE ON FUNCTION get_teacher_student_stats TO authenticated;

-- 8. 测试查询（可选）
-- SELECT * FROM get_teacher_students_v2('your-teacher-id', '', 1, 20);
-- SELECT * FROM get_available_students_for_import('your-teacher-id', '', '', '', 1, 50);

COMMIT;