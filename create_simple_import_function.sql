-- 创建简化的导入函数，避免复杂的外键约束

-- 1. 删除现有的导入函数（如果存在）
DROP FUNCTION IF EXISTS simple_import_graduation_data(TEXT, TEXT, TEXT, TEXT, NUMERIC, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- 2. 创建简化的导入函数
CREATE OR REPLACE FUNCTION simple_import_graduation_data(
    p_student_number TEXT,
    p_destination_type TEXT,
    p_company_name TEXT DEFAULT NULL,
    p_position TEXT DEFAULT NULL,
    p_salary NUMERIC DEFAULT NULL,
    p_work_location TEXT DEFAULT NULL,
    p_school_name TEXT DEFAULT NULL,
    p_major TEXT DEFAULT NULL,
    p_degree TEXT DEFAULT NULL,
    p_abroad_country TEXT DEFAULT NULL,
    p_startup_name TEXT DEFAULT NULL,
    p_startup_role TEXT DEFAULT NULL,
    p_other_description TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    student_record RECORD;
    existing_record RECORD;
    new_record_id UUID;
BEGIN
    -- 查找学生记录
    SELECT id, full_name INTO student_record 
    FROM student_profiles 
    WHERE student_number = p_student_number
    LIMIT 1;
    
    IF NOT FOUND THEN
        RETURN 'ERROR: 找不到学号为 ' || COALESCE(p_student_number, 'NULL') || ' 的学生，请先导入学生数据';
    END IF;
    
    -- 验证去向类型
    IF p_destination_type NOT IN ('employment', 'furtherstudy', 'abroad', 'entrepreneurship', 'unemployed', 'other') THEN
        RETURN 'ERROR: 无效的去向类型: ' || COALESCE(p_destination_type, 'NULL') || '，请使用: employment, furtherstudy, abroad, entrepreneurship, unemployed, other';
    END IF;
    
    -- 检查是否已存在毕业去向记录
    SELECT id INTO existing_record
    FROM graduation_destinations 
    WHERE student_id = student_record.id;
    
    IF existing_record IS NOT NULL THEN
        -- 更新现有记录
        UPDATE graduation_destinations SET
            destination_type = p_destination_type,
            company_name = p_company_name,
            position = p_position,
            salary = p_salary,
            work_location = p_work_location,
            school_name = p_school_name,
            major = p_major,
            degree = p_degree,
            abroad_country = p_abroad_country,
            startup_name = p_startup_name,
            startup_role = p_startup_role,
            other_description = p_other_description,
            status = 'pending',
            updated_at = NOW()
        WHERE id = existing_record.id;
        
        RETURN 'SUCCESS: 更新学生 ' || p_student_number || ' (' || student_record.full_name || ') 的毕业去向成功';
    ELSE
        -- 创建新记录
        INSERT INTO graduation_destinations (
            student_id,
            destination_type,
            company_name,
            position,
            salary,
            work_location,
            school_name,
            major,
            degree,
            abroad_country,
            startup_name,
            startup_role,
            other_description,
            status,
            submit_time,
            created_at,
            updated_at
        ) VALUES (
            student_record.id,
            p_destination_type,
            p_company_name,
            p_position,
            p_salary,
            p_work_location,
            p_school_name,
            p_major,
            p_degree,
            p_abroad_country,
            p_startup_name,
            p_startup_role,
            p_other_description,
            'pending',
            NOW(),
            NOW(),
            NOW()
        ) RETURNING id INTO new_record_id;
        
        RETURN 'SUCCESS: 导入学生 ' || p_student_number || ' (' || student_record.full_name || ') 的毕业去向成功';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 3. 创建批次导入函数
CREATE OR REPLACE FUNCTION create_import_batch(
    p_batch_name TEXT,
    p_imported_by TEXT DEFAULT NULL,
    p_total_records INTEGER DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
    new_batch_id UUID;
BEGIN
    INSERT INTO graduation_import_batches (
        batch_name,
        imported_by,
        total_records,
        status,
        created_at,
        updated_at
    ) VALUES (
        p_batch_name,
        p_imported_by,
        p_total_records,
        'processing',
        NOW(),
        NOW()
    ) RETURNING id INTO new_batch_id;
    
    RETURN new_batch_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '创建批次失败: %', SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 4. 创建记录导入失败函数
CREATE OR REPLACE FUNCTION record_import_failure(
    p_batch_id UUID,
    p_row_number INTEGER,
    p_student_number TEXT,
    p_error_message TEXT,
    p_raw_data JSONB DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO graduation_import_failures (
        batch_id,
        row_number,
        student_number,
        error_message,
        raw_data,
        created_at
    ) VALUES (
        p_batch_id,
        p_row_number,
        p_student_number,
        p_error_message,
        p_raw_data,
        NOW()
    );
    
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '记录失败信息时出错: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- 5. 创建更新批次状态函数
CREATE OR REPLACE FUNCTION update_batch_status(
    p_batch_id UUID,
    p_success_count INTEGER DEFAULT NULL,
    p_failure_count INTEGER DEFAULT NULL,
    p_status TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE graduation_import_batches SET
        success_count = COALESCE(p_success_count, success_count),
        failure_count = COALESCE(p_failure_count, failure_count),
        status = COALESCE(p_status, status),
        updated_at = NOW()
    WHERE id = p_batch_id;
    
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '更新批次状态失败: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- 6. 测试函数
SELECT '测试导入函数...' as test_status;

-- 测试学生数据
SELECT student_number, full_name FROM student_profiles LIMIT 3;

-- 测试导入函数
SELECT simple_import_graduation_data(
    '2021001',
    'employment',
    '腾讯科技有限公司',
    '软件工程师',
    15000,
    '深圳市南山区'
) as test_result;

-- 验证结果
SELECT 'graduation_destinations 表记录数: ' || COUNT(*) as count FROM graduation_destinations;

COMMIT;