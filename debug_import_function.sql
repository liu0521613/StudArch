-- 带详细错误处理的导入函数
-- 用于诊断具体错误原因

CREATE OR REPLACE FUNCTION import_training_program_courses(
    p_courses JSONB,
    p_program_code TEXT DEFAULT 'CS_2021',
    p_batch_name TEXT DEFAULT NULL,
    p_imported_by UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    batch_uuid UUID;
    program_uuid UUID;
    v_success INTEGER := 0;
    v_failed INTEGER := 0;
    course_record JSONB;
    course_uuid UUID;
    error_message TEXT;
    row_number INTEGER := 1;
    result JSONB;
    total_courses INTEGER;
    success_message TEXT;
    debug_info JSONB;
    course_number_val TEXT;
    course_name_val TEXT;
    course_nature_val TEXT;
BEGIN
    -- 获取或创建培养方案
    SELECT id INTO program_uuid 
    FROM training_programs 
    WHERE program_code = p_program_code;
    
    IF program_uuid IS NULL THEN
        INSERT INTO training_programs (
            program_name, 
            program_code, 
            major, 
            department, 
            total_credits,
            created_at,
            updated_at
        ) VALUES (
            '默认培养方案',
            p_program_code,
            '默认专业',
            '默认院系',
            0,
            NOW(),
            NOW()
        ) RETURNING id INTO program_uuid;
    END IF;
    
    -- 计算课程数量
    SELECT COUNT(*) INTO total_courses 
    FROM jsonb_array_elements(p_courses);
    
    -- 创建导入批次
    INSERT INTO training_program_import_batches (
        program_id,
        batch_name,
        imported_by,
        total_records,
        status,
        import_date,
        created_at
    ) VALUES (
        program_uuid,
        COALESCE(p_batch_name, '导入批次_' || to_char(NOW(), 'YYYY-MM-DD HH24:MI:SS')),
        p_imported_by,
        total_courses,
        'processing',
        NOW(),
        NOW()
    ) RETURNING id INTO batch_uuid;
    
    -- 处理每个课程
    FOR course_record IN SELECT * FROM jsonb_array_elements(p_courses)
    LOOP
        BEGIN
            -- 提取字段值用于调试
            course_number_val := course_record->>'course_number';
            course_name_val := course_record->>'course_name';
            course_nature_val := course_record->>'course_nature';
            
            -- 构建调试信息
            debug_info := jsonb_build_object(
                'row_number', row_number,
                'course_number', course_number_val,
                'course_name', course_name_val,
                'course_nature', course_nature_val,
                'credits', course_record->>'credits'
            );
            
            -- 插入课程（简化字段，只插入必需的）
            INSERT INTO training_program_courses (
                program_id,
                course_number,
                course_name,
                credits,
                course_nature,
                sequence_order,
                created_at,
                updated_at
            ) VALUES (
                program_uuid,
                course_number_val,
                course_name_val,
                COALESCE((course_record->>'credits')::NUMERIC, 0),
                course_nature_val,
                row_number,
                NOW(),
                NOW()
            ) RETURNING id INTO course_uuid;
            
            v_success := v_success + 1;
            
        EXCEPTION WHEN OTHERS THEN
            error_message := SQLERRM;
            v_failed := v_failed + 1;
            
            -- 记录详细错误信息
            UPDATE training_program_import_batches 
            SET error_details = COALESCE(error_details, '[]'::jsonb) || 
                   jsonb_build_object(
                       'row', row_number, 
                       'error', error_message,
                       'debug_info', debug_info
                   )
            WHERE id = batch_uuid;
        END;
        
        row_number := row_number + 1;
    END LOOP;
    
    -- 更新批次状态
    UPDATE training_program_import_batches 
    SET 
        success_count = v_success,
        failure_count = v_failed,
        status = CASE WHEN v_failed = 0 THEN 'completed' ELSE 'failed' END,
        completed_at = NOW()
    WHERE id = batch_uuid;
    
    -- 更新培养方案总学分
    UPDATE training_programs 
    SET total_credits = (
        SELECT COALESCE(SUM(credits), 0) 
        FROM training_program_courses 
        WHERE program_id = program_uuid AND status = 'active'
    ),
    updated_at = NOW()
    WHERE id = program_uuid;
    
    -- 构建成功消息
    success_message := '成功导入 ' || v_success::TEXT || ' 门课程，失败 ' || v_failed::TEXT || ' 门';
    
    -- 返回结果
    result := jsonb_build_object(
        'success', v_success > 0,
        'message', success_message,
        'batch_id', batch_uuid,
        'program_id', program_uuid,
        'success_count', v_success,
        'failure_count', v_failed,
        'total_count', v_success + v_failed,
        'debug', '使用调试版本，检查 error_details 字段获取详细错误信息'
    );
    
    RETURN result;
    
END;
$$ LANGUAGE plpgsql;

COMMIT;