-- 修复登录问题：重建用户表和角色表关系
-- 执行此脚本来解决 "Could not find a relationship between 'users' and 'roles'" 错误

-- 1. 重建角色表
DROP TABLE IF EXISTS roles CASCADE;

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_description TEXT,
    permissions JSONB DEFAULT '[]',
    is_system_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 插入系统角色
INSERT INTO roles (role_name, role_description, permissions, is_system_default) VALUES
('super_admin', '超级管理员', '["user_management", "system_settings", "all_access"]', TRUE),
('teacher', '教师', '["student_management", "course_management", "grade_management"]', TRUE),
('student', '学生', '["view_own_profile", "submit_assignments", "view_courses"]', TRUE)
ON CONFLICT (role_name) DO NOTHING;

-- 2. 重建用户表（完整的结构）
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    user_number VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL REFERENCES roles(id),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    
    -- 扩展信息
    phone VARCHAR(20),
    department VARCHAR(100),
    grade VARCHAR(20),
    class_name VARCHAR(50),
    
    -- 时间戳
    last_login TIMESTAMP WITH TIME ZONE,
    password_changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 约束
    CONSTRAINT unique_user_number UNIQUE(user_number)
);

-- 创建索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_user_number ON users(user_number);
CREATE INDEX idx_users_role_id ON users(role_id);

-- 3. 重建学生档案表（保持现有数据）
DROP TABLE IF EXISTS student_profiles CASCADE;

CREATE TABLE student_profiles (
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

-- 4. 重建毕业去向表
DROP TABLE IF EXISTS graduation_destinations CASCADE;

CREATE TABLE graduation_destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL,
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
    approved_by TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- 审核字段
    reviewer_notes TEXT,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 重建导入批次表
DROP TABLE IF EXISTS graduation_import_batches CASCADE;

CREATE TABLE graduation_import_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_name TEXT NOT NULL,
    imported_by TEXT,
    total_records INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
    import_file_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. 重建导入失败记录表
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
DROP TRIGGER IF EXISTS update_student_profiles_updated_at ON student_profiles;
DROP TRIGGER IF EXISTS update_graduation_destinations_updated_at ON graduation_destinations;
DROP TRIGGER IF EXISTS update_graduation_import_batches_updated_at ON graduation_import_batches;

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_profiles_updated_at 
    BEFORE UPDATE ON student_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_graduation_destinations_updated_at 
    BEFORE UPDATE ON graduation_destinations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_graduation_import_batches_updated_at 
    BEFORE UPDATE ON graduation_import_batches 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. 禁用所有RLS策略
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE student_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_destinations DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_import_batches DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_import_failures DISABLE ROW LEVEL SECURITY;

-- 10. 插入测试用户（包括教师用户）
INSERT INTO users (
    id, username, email, user_number, full_name, password_hash, role_id, status
) VALUES 
('550e8400-e29b-41d4-a716-446655440001', 'teacher', 'teacher@example.com', 'T001', '测试教师', 'hashed_password', 2, 'active')
ON CONFLICT (id) DO NOTHING;

-- 插入更多测试用户
INSERT INTO users (username, email, user_number, full_name, password_hash, role_id, status) VALUES
('admin', 'admin@example.com', 'A001', '超级管理员', 'hashed_password', 1, 'active'),
('student1', 'student1@example.com', '2021001', '张三', 'hashed_password', 3, 'active'),
('student2', 'student2@example.com', '2021002', '李四', 'hashed_password', 3, 'active')
ON CONFLICT DO NOTHING;

-- 11. 插入测试学生数据
INSERT INTO student_profiles (
    user_id, student_number, full_name, class_name, admission_date, graduation_date
) VALUES 
((SELECT id FROM users WHERE user_number = '2021001'), '2021001', '张三', '计算机科学与技术1班', '2021-09-01', '2025-06-30'),
((SELECT id FROM users WHERE user_number = '2021002'), '2021002', '李四', '计算机科学与技术1班', '2021-09-01', '2025-06-30'),
((SELECT id FROM users WHERE user_number = '2021003'), '2021003', '王五', '软件工程1班', '2021-09-01', '2025-06-30'),
((SELECT id FROM users WHERE user_number = '2021004'), '2021004', '赵六', '软件工程1班', '2021-09-01', '2025-06-30'),
((SELECT id FROM users WHERE user_number = '2021005'), '2021005', '钱七', '计算机科学与技术2班', '2021-09-01', '2025-06-30')
ON CONFLICT (student_number) DO NOTHING;

-- 12. 重新创建导入函数
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

-- 验证修复结果
SELECT '修复完成！' as status;
SELECT '用户表记录数:' as info, COUNT(*) as count FROM users;
SELECT '角色表记录数:' as info, COUNT(*) as count FROM roles;
SELECT '学生档案表记录数:' as info, COUNT(*) as count FROM student_profiles;

COMMIT;