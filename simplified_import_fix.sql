-- 简化的导入函数修复 - 解决导入不工作问题
-- 如果原来的导入函数有问题，使用这个简化版本

-- 删除可能有问题的导入函数
DROP FUNCTION IF EXISTS simple_import_graduation_data(TEXT, TEXT, TEXT, TEXT, NUMERIC, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- 重新创建简化的导入函数
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
    -- 强制查找学生记录（使用更严格的查询）
    BEGIN
        SELECT id, full_name INTO student_record 
        FROM student_profiles 
        WHERE student_number = p_student_number
        LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
        RETURN 'ERROR: 查询学生数据时出错: ' || SQLERRM;
    END;
    
    -- 检查是否找到学生
    IF student_record.id IS NULL THEN
        RETURN 'ERROR: 找不到学号为 ' || COALESCE(p_student_number, 'NULL') || ' 的学生';
    END IF;
    
    -- 验证去向类型
    IF p_destination_type NOT IN ('employment', 'furtherstudy', 'abroad', 'entrepreneurship', 'unemployed', 'other') THEN
        RETURN 'ERROR: 无效的去向类型: ' || COALESCE(p_destination_type, 'NULL');
    END IF;
    
    -- 检查是否已存在记录
    BEGIN
        SELECT id INTO existing_record
        FROM graduation_destinations 
        WHERE student_id = student_record.id
        LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
        RETURN 'ERROR: 查询现有记录时出错: ' || SQLERRM;
    END;
    
    -- 插入或更新记录
    BEGIN
        IF existing_record.id IS NOT NULL THEN
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
            );
            
            RETURN 'SUCCESS: 导入学生 ' || p_student_number || ' (' || student_record.full_name || ') 的毕业去向成功';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RETURN 'ERROR: 插入数据时出错: ' || SQLERRM;
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: 函数执行出错: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 测试函数
SELECT '=== 测试导入函数 ===' as test_info;
SELECT simple_import_graduation_data('2021001', 'employment', '测试公司', '测试职位', 10000) as test_result;

-- 验证插入
SELECT COUNT(*) as total_after_test FROM graduation_destinations;

COMMIT;