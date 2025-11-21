-- 超安全修复脚本 - 避免所有冲突
-- 只修复核心问题，不重建现有表

-- 1. 确保用户表存在（不重建，只检查）
DO $$
BEGIN
    -- 检查 users 表是否存在，如果不存在则创建
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'users') THEN
        CREATE TABLE users (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email TEXT UNIQUE NOT NULL,
            full_name TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- 插入测试用户
        INSERT INTO users (id, email, full_name) 
        VALUES ('550e8400-e29b-41d4-a716-446655440001', 'teacher@example.com', '测试教师');
        
        RAISE NOTICE '创建了 users 表';
    END IF;
END $$;

-- 2. 确保学生档案表存在并有数据
DO $$
BEGIN
    -- 如果表不存在则创建
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'student_profiles') THEN
        CREATE TABLE student_profiles (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID,
            student_number TEXT UNIQUE NOT NULL,
            full_name TEXT NOT NULL,
            class_name TEXT,
            admission_date DATE,
            graduation_date DATE,
            phone TEXT,
            email TEXT,
            status TEXT DEFAULT 'active',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE '创建了 student_profiles 表';
    END IF;
    
    -- 插入测试学生数据（如果表为空）
    IF (SELECT COUNT(*) FROM student_profiles) = 0 THEN
        INSERT INTO student_profiles (
            id, student_number, full_name, class_name, 
            admission_date, graduation_date, created_at, updated_at
        ) VALUES 
        (gen_random_uuid(), '2021001', '张三', '计算机科学与技术1班', 
         '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), '2021002', '李四', '计算机科学与技术1班', 
         '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), '2021003', '王五', '软件工程1班', 
         '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), '2021004', '赵六', '软件工程1班', 
         '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), '2021005', '钱七', '计算机科学与技术2班', 
         '2021-09-01', '2025-06-30', NOW(), NOW());
        
        RAISE NOTICE '插入了测试学生数据';
    END IF;
END $$;

-- 3. 确保毕业去向表存在
DO $$
BEGIN
    -- 如果表不存在则创建
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'graduation_destinations') THEN
        CREATE TABLE graduation_destinations (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            student_id UUID NOT NULL,
            destination_type TEXT NOT NULL,
            company_name TEXT,
            position TEXT,
            salary NUMERIC,
            work_location TEXT,
            school_name TEXT,
            major TEXT,
            degree TEXT,
            abroad_country TEXT,
            startup_name TEXT,
            startup_role TEXT,
            other_description TEXT,
            status TEXT DEFAULT 'pending',
            submit_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            approved_by TEXT,
            approved_at TIMESTAMP WITH TIME ZONE,
            approval_notes TEXT,
            reviewer_notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE '创建了 graduation_destinations 表';
    END IF;
END $$;

-- 4. 确保导入批次表存在
DO $$
BEGIN
    -- 如果表不存在则创建
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'graduation_import_batches') THEN
        CREATE TABLE graduation_import_batches (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            batch_name TEXT NOT NULL,
            imported_by TEXT,
            total_records INTEGER DEFAULT 0,
            success_count INTEGER DEFAULT 0,
            failure_count INTEGER DEFAULT 0,
            status TEXT DEFAULT 'processing',
            import_file_path TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE '创建了 graduation_import_batches 表';
    END IF;
END $$;

-- 5. 确保导入失败记录表存在
DO $$
BEGIN
    -- 如果表不存在则创建
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'graduation_import_failures') THEN
        CREATE TABLE graduation_import_failures (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            batch_id UUID REFERENCES graduation_import_batches(id) ON DELETE CASCADE,
            row_number INTEGER,
            student_number TEXT,
            error_message TEXT,
            raw_data JSONB,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE '创建了 graduation_import_failures 表';
    END IF;
END $$;

-- 6. 创建或更新时间戳触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 7. 为需要的表创建触发器（只创建不存在的）
DO $$
BEGIN
    -- 为 users 表创建触发器
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_updated_at') THEN
        CREATE TRIGGER update_users_updated_at 
            BEFORE UPDATE ON users 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE '创建了 users 表触发器';
    END IF;
    
    -- 为 student_profiles 表创建触发器
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_student_profiles_updated_at') THEN
        CREATE TRIGGER update_student_profiles_updated_at 
            BEFORE UPDATE ON student_profiles 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE '创建了 student_profiles 表触发器';
    END IF;
    
    -- 为 graduation_destinations 表创建触发器
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_graduation_destinations_updated_at') THEN
        CREATE TRIGGER update_graduation_destinations_updated_at 
            BEFORE UPDATE ON graduation_destinations 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE '创建了 graduation_destinations 表触发器';
    END IF;
    
    -- 为 graduation_import_batches 表创建触发器
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_graduation_import_batches_updated_at') THEN
        CREATE TRIGGER update_graduation_import_batches_updated_at 
            BEFORE UPDATE ON graduation_import_batches 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE '创建了 graduation_import_batches 表触发器';
    END IF;
END $$;

-- 8. 禁用 RLS 策略
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE student_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_destinations DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_import_batches DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_import_failures DISABLE ROW LEVEL SECURITY;

-- 9. 创建简化的导入函数
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

-- 10. 创建批次函数
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

-- 11. 验证修复结果
SELECT '=== 验证结果 ===' as status;
SELECT 'users 表记录数: ' || COUNT(*) as count FROM users;
SELECT 'student_profiles 表记录数: ' || COUNT(*) as count FROM student_profiles;
SELECT 'graduation_destinations 表记录数: ' || COUNT(*) as count FROM graduation_destinations;
SELECT 'graduation_import_batches 表记录数: ' || COUNT(*) as count FROM graduation_import_batches;

-- 测试导入函数
SELECT '=== 测试导入函数 ===' as test_status;
SELECT simple_import_graduation_data(
    '2021001',
    'employment',
    '腾讯科技有限公司',
    '软件工程师',
    15000,
    '深圳市南山区'
) as test_result;

-- 最终验证
SELECT '=== 最终验证 ===' as final_status;
SELECT COUNT(*) as graduation_destination_count FROM graduation_destinations;

COMMIT;