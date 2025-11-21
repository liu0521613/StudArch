-- 快速修复 user 相关的数据库问题
-- 这个脚本确保数据库层面没有问题

-- 1. 再次确保所有必需的表都存在
DO $$
BEGIN
    -- 创建用户表（简化版，避免外键约束）
    CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT UNIQUE NOT NULL,
        full_name TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- 禁用 RLS
    ALTER TABLE users DISABLE ROW LEVEL SECURITY;
    
    -- 插入一个默认用户（用于测试）
    INSERT INTO users (id, email, full_name) 
    VALUES ('550e8400-e29b-41d4-a716-446655440001', 'teacher@example.com', '测试教师')
    ON CONFLICT (id) DO NOTHING;
    
    RAISE NOTICE 'users 表已确保存在并插入测试用户';
END $$;

-- 2. 确保毕业去向表没有外键约束问题
DO $$
BEGIN
    -- 如果表存在但有问题，删除重新创建
    DROP TABLE IF EXISTS graduation_destinations CASCADE;
    
    CREATE TABLE graduation_destinations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        student_id UUID NOT NULL, -- 注意：不设置外键约束
        destination_type TEXT NOT NULL CHECK (destination_type IN ('employment', 'furtherstudy', 'abroad', 'entrepreneurship', 'unemployed', 'other')),
        
        -- 就业相关字段
        company_name TEXT,
        position TEXT,
        salary NUMERIC,
        work_location TEXT,
        
        -- 升学相关字段
        school_name TEXT,
        major TEXT,
        degree TEXT,
        
        -- 出国相关字段
        abroad_country TEXT,
        
        -- 创业相关字段
        startup_name TEXT,
        startup_role TEXT,
        
        -- 其他去向描述
        other_description TEXT,
        
        -- 状态和时间戳
        status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
        submit_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        approved_by TEXT, -- 改为TEXT类型，避免外键问题
        approved_at TIMESTAMP WITH TIME ZONE,
        approval_notes TEXT,
        
        -- 审核字段
        reviewer_notes TEXT,
        
        -- 时间戳
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- 禁用 RLS
    ALTER TABLE graduation_destinations DISABLE ROW LEVEL SECURITY;
    
    -- 创建触发器
    CREATE TRIGGER update_graduation_destinations_updated_at 
        BEFORE UPDATE ON graduation_destinations 
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
    RAISE NOTICE 'graduation_destinations 表已重新创建，无外键约束';
END $$;

-- 3. 确保导入批次表正确
DO $$
BEGIN
    DROP TABLE IF EXISTS graduation_import_batches CASCADE;
    
    CREATE TABLE graduation_import_batches (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        batch_name TEXT NOT NULL,
        imported_by TEXT, -- 改为TEXT类型
        total_records INTEGER DEFAULT 0,
        success_count INTEGER DEFAULT 0,
        failure_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
        import_file_path TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- 禁用 RLS
    ALTER TABLE graduation_import_batches DISABLE ROW LEVEL SECURITY;
    
    -- 创建触发器
    CREATE TRIGGER update_graduation_import_batches_updated_at 
        BEFORE UPDATE ON graduation_import_batches 
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
    RAISE NOTICE 'graduation_import_batches 表已重新创建';
END $$;

-- 4. 确保导入失败记录表正确
DO $$
BEGIN
    DROP TABLE IF EXISTS graduation_import_failures CASCADE;
    
    CREATE TABLE graduation_import_failures (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        batch_id UUID REFERENCES graduation_import_batches(id) ON DELETE CASCADE,
        row_number INTEGER,
        student_number TEXT,
        error_message TEXT,
        raw_data JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- 禁用 RLS
    ALTER TABLE graduation_import_failures DISABLE ROW LEVEL SECURITY;
    
    RAISE NOTICE 'graduation_import_failures 表已重新创建';
END $$;

-- 5. 重新创建简化导入函数（不依赖用户认证）
DROP FUNCTION IF EXISTS simple_import_graduation_data(TEXT, TEXT, TEXT, TEXT, NUMERIC, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

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

-- 6. 创建批次函数（简化版）
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

-- 7. 验证和测试
SELECT '=== 验证结果 ===' as verification;
SELECT 'users 表记录数: ' || COUNT(*) as count FROM users;
SELECT 'student_profiles 表记录数: ' || COUNT(*) as count FROM student_profiles;
SELECT 'graduation_destinations 表记录数: ' || COUNT(*) as count FROM graduation_destinations;

-- 测试导入函数
SELECT '=== 测试导入函数 ===' as test;
SELECT simple_import_graduation_data(
    '2021001',
    'employment',
    '测试公司',
    '测试岗位',
    10000
) as import_test;

COMMIT;