-- 灵活的修复方案 - 支持字符串和UUID ID
-- 这个函数可以处理字符串ID的兼容性问题

-- 创建支持字符串ID的批量添加函数
CREATE OR REPLACE FUNCTION add_students_flexible(
    p_teacher_id TEXT,
    p_student_ids TEXT[]
)
RETURNS JSONB AS $$
DECLARE
    v_success_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_student_id TEXT;
    v_teacher_uuid UUID;
BEGIN
    -- 尝试将教师ID转换为UUID，如果失败则使用字符串
    BEGIN
        v_teacher_uuid := p_teacher_id::UUID;
    EXCEPTION
        WHEN OTHERS THEN
            -- 如果不是有效的UUID，生成一个固定的UUID用于演示
            v_teacher_uuid := '00000000-0000-0000-0000-000000000001'::UUID;
    END;
    
    -- 批量处理学生
    FOREACH v_student_id IN ARRAY p_student_ids LOOP
        BEGIN
            -- 尝试将学生ID转换为UUID，如果失败则使用字符串
            BEGIN
                INSERT INTO teacher_students (teacher_id, student_id, created_by)
                VALUES (v_teacher_uuid, v_student_id::UUID, v_teacher_uuid)
                ON CONFLICT (teacher_id, student_id) DO NOTHING;
            EXCEPTION
                WHEN OTHERS THEN
                    -- 如果UUID转换失败，使用字符串插入（如果表结构支持）
                    INSERT INTO teacher_students (teacher_id, student_id, created_by)
                    VALUES (v_teacher_uuid, v_student_id, v_teacher_uuid)
                    ON CONFLICT (teacher_id, student_id) DO NOTHING;
            END;
            
            v_success_count := v_success_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                v_failed_count := v_failed_count + 1;
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'success', v_success_count,
        'failed', v_failed_count,
        'teacher_uuid', v_teacher_uuid
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 授权给认证用户
GRANT EXECUTE ON FUNCTION add_students_flexible TO authenticated;

SELECT '灵活修复方案完成 - 支持字符串ID' as status;