-- 最终简化版本：避免所有错误
-- 使用最简单直接的方式

-- 先删除所有旧版本函数
DROP FUNCTION IF EXISTS import_training_program_courses(JSONB, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS import_training_program_courses(JSONB, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS get_training_program_courses(UUID);

-- 创建简化版本的导入函数
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
            INSERT INTO training_program_courses (
                program_id,
                course_number,
                course_name,
                credits,
                recommended_grade,
                semester,
                exam_method,
                course_nature,
                sequence_order,
                created_at,
                updated_at
            ) VALUES (
                program_uuid,
                course_record->>'course_number',
                course_record->>'course_name',
                COALESCE((course_record->>'credits')::NUMERIC, 0),
                course_record->>'recommended_grade',
                course_record->>'semester',
                course_record->>'exam_method',
                course_record->>'course_nature',
                row_number,
                NOW(),
                NOW()
            ) RETURNING id INTO course_uuid;
            
            v_success := v_success + 1;
            
        EXCEPTION WHEN OTHERS THEN
            error_message := SQLERRM;
            v_failed := v_failed + 1;
            
            UPDATE training_program_import_batches 
            SET error_details = COALESCE(error_details, '[]'::jsonb) || 
                   jsonb_build_object('row', row_number, 'error', error_message)
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
    
    -- 构建成功消息（避免格式化错误）
    success_message := '成功导入 ' || v_success::TEXT || ' 门课程，失败 ' || v_failed::TEXT || ' 门';
    
    -- 返回结果
    result := jsonb_build_object(
        'success', v_success > 0,
        'message', success_message,
        'batch_id', batch_uuid,
        'program_id', program_uuid,
        'success_count', v_success,
        'failure_count', v_failed,
        'total_count', v_success + v_failed
    );
    
    RETURN result;
    
END;
$$ LANGUAGE plpgsql;

-- 创建获取培养方案课程的函数
CREATE OR REPLACE FUNCTION get_training_program_courses(p_program_id UUID)
RETURNS SETOF JSONB AS $$
BEGIN
    RETURN QUERY
    SELECT jsonb_build_object(
        'id', tpc.id,
        'course_number', tpc.course_number,
        'course_name', tpc.course_name,
        'credits', tpc.credits,
        'recommended_grade', tpc.recommended_grade,
        'semester', tpc.semester,
        'exam_method', tpc.exam_method,
        'course_nature', tpc.course_nature,
        'course_type', tpc.course_type,
        'sequence_order', tpc.sequence_order
    )
    FROM training_program_courses tpc
    WHERE tpc.program_id = p_program_id AND tpc.status = 'active'
    ORDER BY tpc.sequence_order, tpc.course_number;
END;
$$ LANGUAGE plpgsql;

COMMIT;