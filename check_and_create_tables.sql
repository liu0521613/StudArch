-- 检查并创建所需的表结构

-- 1. 检查现有表
SELECT 
    tablename,
    schemaname 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'student_profiles', 'graduation_destinations', 'graduation_import_batches', 'graduation_import_failures')
ORDER BY tablename;

-- 2. 创建 users 表（如果不存在）
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'teacher', 'student', 'user')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 创建 student_profiles 表（如果不存在）
CREATE TABLE IF NOT EXISTS student_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    student_number TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    class_name TEXT,
    admission_date DATE,
    graduation_date DATE,
    phone TEXT,
    email TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'graduated', 'suspended', 'withdrawn')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 创建 graduation_destinations 表（无外键约束版本）
CREATE TABLE IF NOT EXISTS graduation_destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL, -- 移除外键约束，改为应用层验证
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
    approved_by TEXT, -- 改为TEXT类型
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- 审核字段
    reviewer_notes TEXT,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 移除唯一约束，允许重复记录（应用层处理）
    -- CONSTRAINT unique_student_destination UNIQUE (student_id)
);

-- 5. 创建导入批次表
CREATE TABLE IF NOT EXISTS graduation_import_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_name TEXT NOT NULL,
    imported_by TEXT, -- 改为TEXT类型以避免外键约束
    total_records INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
    import_file_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. 创建导入失败记录表
CREATE TABLE IF NOT EXISTS graduation_import_failures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID REFERENCES graduation_import_batches(id) ON DELETE CASCADE,
    row_number INTEGER,
    student_number TEXT,
    error_message TEXT,
    raw_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. 创建更新时间戳的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 8. 为各表创建更新时间戳的触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_student_profiles_updated_at ON student_profiles;
CREATE TRIGGER update_student_profiles_updated_at 
    BEFORE UPDATE ON student_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_graduation_destinations_updated_at ON graduation_destinations;
CREATE TRIGGER update_graduation_destinations_updated_at 
    BEFORE UPDATE ON graduation_destinations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_graduation_import_batches_updated_at ON graduation_import_batches;
CREATE TRIGGER update_graduation_import_batches_updated_at 
    BEFORE UPDATE ON graduation_import_batches 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. 禁用所有RLS策略
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE student_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_destinations DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_import_batches DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_import_failures DISABLE ROW LEVEL SECURITY;

-- 10. 插入测试数据（如果学生表为空）
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM student_profiles LIMIT 1) THEN
        INSERT INTO student_profiles (
            id, user_id, student_number, full_name, class_name, 
            admission_date, graduation_date, created_at, updated_at
        ) VALUES 
        (gen_random_uuid(), gen_random_uuid(), '2021001', '张三', '计算机科学与技术1班', 
         '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), gen_random_uuid(), '2021002', '李四', '计算机科学与技术1班', 
         '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), gen_random_uuid(), '2021003', '王五', '软件工程1班', 
         '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), gen_random_uuid(), '2021004', '赵六', '软件工程1班', 
         '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), gen_random_uuid(), '2021005', '钱七', '计算机科学与技术2班', 
         '2021-09-01', '2025-06-30', NOW(), NOW());
        
        RAISE NOTICE '已创建5个测试学生记录';
    END IF;
END $$;

-- 11. 验证表和数据
SELECT 'users 表记录数: ' || COUNT(*) as count FROM users;
SELECT 'student_profiles 表记录数: ' || COUNT(*) as count FROM student_profiles;
SELECT 'graduation_destinations 表记录数: ' || COUNT(*) as count FROM graduation_destinations;
SELECT 'graduation_import_batches 表记录数: ' || COUNT(*) as count FROM graduation_import_batches;

COMMIT;