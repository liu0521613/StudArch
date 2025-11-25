-- 创建毕业去向表
CREATE TABLE IF NOT EXISTS graduation_destinations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
    destination_type TEXT NOT NULL CHECK (destination_type IN ('employment', 'furtherstudy', 'abroad', 'entrepreneurship', 'unemployed', 'other')),
    company_name TEXT,
    position TEXT,
    salary DECIMAL(10,2),
    work_location TEXT,
    school_name TEXT,
    major TEXT,
    degree TEXT,
    abroad_country TEXT,
    startup_name TEXT,
    startup_role TEXT,
    other_description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    review_comment TEXT,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    proof_files TEXT[] DEFAULT '{}',
    submit_time TIMESTAMPTZ DEFAULT NOW(),
    batch_import_id UUID REFERENCES graduation_import_batches(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建导入批次表
CREATE TABLE IF NOT EXISTS graduation_import_batches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    batch_name TEXT NOT NULL,
    import_file_path TEXT,
    total_records INTEGER NOT NULL DEFAULT 0,
    success_count INTEGER NOT NULL DEFAULT 0,
    failure_count INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
    error_details JSONB DEFAULT '[]',
    imported_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建导入失败记录表
CREATE TABLE IF NOT EXISTS graduation_import_failures (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    batch_id UUID NOT NULL REFERENCES graduation_import_batches(id) ON DELETE CASCADE,
    row_number INTEGER NOT NULL,
    student_number TEXT,
    error_message TEXT NOT NULL,
    raw_data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_graduation_destinations_student_id ON graduation_destinations(student_id);
CREATE INDEX IF NOT EXISTS idx_graduation_destinations_status ON graduation_destinations(status);
CREATE INDEX IF NOT EXISTS idx_graduation_destinations_destination_type ON graduation_destinations(destination_type);
CREATE INDEX IF NOT EXISTS idx_graduation_destinations_submit_time ON graduation_destinations(submit_time);
CREATE INDEX IF NOT EXISTS idx_graduation_import_batches_imported_by ON graduation_import_batches(imported_by);

-- 禁用 RLS（行级安全策略）
ALTER TABLE graduation_destinations DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_import_batches DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_import_failures DISABLE ROW LEVEL SECURITY;

-- 插入示例数据（基于之前成功导入的数据）
INSERT INTO graduation_destinations (student_id, destination_type, company_name, position, salary, work_location, status, submit_time) VALUES
((SELECT id FROM student_profiles WHERE student_number = '2021001' LIMIT 1), 'employment', '阿里巴巴（中国）有限公司', '前端开发工程师', 15000.00, '杭州', 'pending', NOW()),
((SELECT id FROM student_profiles WHERE student_number = '2021002' LIMIT 1), 'furtherstudy', NULL, NULL, NULL, NULL, 'pending', NOW()),
((SELECT id FROM student_profiles WHERE student_number = '2021003' LIMIT 1), 'abroad', NULL, NULL, NULL, NULL, 'pending', NOW()),
((SELECT id FROM student_profiles WHERE student_number = '2021004' LIMIT 1), 'entrepreneurship', NULL, NULL, NULL, NULL, 'pending', NOW()),
((SELECT id FROM student_profiles WHERE student_number = '2021005' LIMIT 1), 'other', NULL, NULL, NULL, NULL, 'pending', NOW());

-- 更新升学记录的学校信息
UPDATE graduation_destinations SET school_name = '清华大学', major = '计算机应用技术', degree = '硕士研究生' 
WHERE destination_type = 'furtherstudy' AND student_id = (SELECT id FROM student_profiles WHERE student_number = '2021002' LIMIT 1);

-- 更新出国记录的学校信息
UPDATE graduation_destinations SET school_name = '美国斯坦福大学', major = '人工智能', degree = '博士研究生', abroad_country = '美国' 
WHERE destination_type = 'abroad' AND student_id = (SELECT id FROM student_profiles WHERE student_number = '2021003' LIMIT 1);

-- 更新创业记录
UPDATE graduation_destinations SET startup_name = '北京创新科技有限公司', startup_role = '创始人兼CEO' 
WHERE destination_type = 'entrepreneurship' AND student_id = (SELECT id FROM student_profiles WHERE student_number = '2021004' LIMIT 1);

-- 更新其他记录描述
UPDATE graduation_destinations SET other_description = '自由职业' 
WHERE destination_type = 'other' AND student_id = (SELECT id FROM student_profiles WHERE student_number = '2021005' LIMIT 1);

-- 创建一个导入批次记录
INSERT INTO graduation_import_batches (batch_name, import_file_path, total_records, success_count, failure_count, status, imported_by) VALUES
('毕业去向导入_' || NOW(), 'test_graduation_import.xlsx', 5, 5, 0, 'completed', (SELECT id FROM users LIMIT 1));

-- 授予必要的权限
GRANT ALL ON graduation_destinations TO anon;
GRANT ALL ON graduation_import_batches TO anon;
GRANT ALL ON graduation_import_failures TO anon;
GRANT ALL ON graduation_destinations TO authenticated;
GRANT ALL ON graduation_import_batches TO authenticated;
GRANT ALL ON graduation_import_failures TO authenticated;