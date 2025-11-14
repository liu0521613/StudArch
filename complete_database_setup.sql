-- 完整数据库初始化脚本 - 一次性执行所有内容
-- 在Supabase SQL Editor中执行此脚本

-- ==================== 第一部分：基础表结构 ====================

-- 1. 删除可能存在的视图和表
DROP VIEW IF EXISTS user_details CASCADE;
DROP VIEW IF EXISTS student_complete_info CASCADE;
DROP TABLE IF EXISTS student_batch_operations CASCADE;
DROP TABLE IF EXISTS profile_edit_logs CASCADE;
DROP TABLE IF EXISTS student_profiles CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS system_settings CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- 2. 创建角色表
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_description TEXT,
    permissions JSONB DEFAULT '[]',
    is_system_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 创建用户表（包含完整字段）
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    user_number VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL REFERENCES roles(id),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    phone VARCHAR(20),
    department VARCHAR(100),
    grade VARCHAR(20),
    class_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_user_number UNIQUE(user_number)
);

-- 创建索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_user_number ON users(user_number);
CREATE INDEX idx_users_role_id ON users(role_id);

-- ==================== 第二部分：个人信息相关表 ====================

-- 1. 系统设置表
CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    setting_description TEXT,
    is_editable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 班级信息表
CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_name VARCHAR(100) NOT NULL UNIQUE,
    class_code VARCHAR(50) UNIQUE,
    grade VARCHAR(20) NOT NULL,
    department VARCHAR(100),
    head_teacher_id UUID REFERENCES users(id),
    student_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 学生个人信息扩展表
CREATE TABLE student_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    birth_date DATE,
    id_card VARCHAR(20),
    nationality VARCHAR(50),
    political_status VARCHAR(20),
    phone VARCHAR(20),
    emergency_contact VARCHAR(50),
    emergency_phone VARCHAR(20),
    home_address TEXT,
    admission_date DATE,
    graduation_date DATE,
    student_type VARCHAR(20),
    class_id UUID REFERENCES classes(id),
    class_name VARCHAR(100),
    profile_status VARCHAR(20) DEFAULT 'incomplete' CHECK (profile_status IN ('incomplete', 'pending', 'approved', 'rejected')),
    edit_count INTEGER DEFAULT 0,
    last_edit_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_student_user UNIQUE(user_id)
);

-- 4. 学生个人信息修改记录表
CREATE TABLE profile_edit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_profile_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    changed_fields JSONB NOT NULL,
    old_values JSONB,
    new_values JSONB,
    edit_reason TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==================== 第三部分：插入基础数据 ====================

-- 1. 插入系统角色
INSERT INTO roles (id, role_name, role_description, permissions, is_system_default) VALUES
('1', 'super_admin', '超级管理员', '{"manage_users": true, "manage_roles": true, "manage_system": true}', true),
('2', 'teacher', '教师', '{"manage_students": true, "review_profiles": true}', true),
('3', 'student', '学生', '{"view_profile": true, "edit_profile": true}', true)
ON CONFLICT (role_name) DO NOTHING;

-- 2. 插入系统设置
INSERT INTO system_settings (setting_key, setting_value, setting_description) VALUES
('student_profile_edit_enabled', 'true', '学生个人信息维护功能开关'),
('student_profile_mandatory_fields', '["full_name", "id_card", "phone", "emergency_contact", "class_name"]', '学生必填信息字段'),
('max_profile_edit_count', '3', '学生个人信息最大修改次数')
ON CONFLICT (setting_key) DO NOTHING;

-- 3. 插入测试用户数据
INSERT INTO users (id, username, email, user_number, full_name, password_hash, role_id, status, phone, department, grade, class_name) VALUES
-- 学生用户
('100001', 'student_2021001', 'student_2021001@example.com', '2021001', '李小明', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '3', 'active', '13800138000', '计算机学院', '2021级', '计算机科学与技术1班'),
('100002', 'student_2021002', 'student_2021002@example.com', '2021002', '王小红', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '3', 'active', '13800138001', '计算机学院', '2021级', '计算机科学与技术1班'),
('100003', 'student_2021003', 'student_2021003@example.com', '2021003', '张伟', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '3', 'active', '13800138002', '软件学院', '2021级', '软件工程1班'),
-- 教师用户
('200001', 'teacher_zhang', 'teacher_zhang@example.com', 'T001', '张老师', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '2', 'active', '13800138003', '计算机学院', NULL, NULL),
('200002', 'teacher_wang', 'teacher_wang@example.com', 'T002', '王老师', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '2', 'active', '13800138004', '软件学院', NULL, NULL),
-- 管理员用户
('300001', 'admin', 'admin@example.com', 'A001', '系统管理员', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '1', 'active', '13800138005', NULL, NULL, NULL)
ON CONFLICT (username) DO NOTHING;

-- 4. 插入班级数据
INSERT INTO classes (id, class_name, class_code, grade, department, head_teacher_id) VALUES
('400001', '计算机科学与技术1班', 'CS202101', '2021级', '计算机学院', '200001'),
('400002', '计算机科学与技术2班', 'CS202102', '2021级', '计算机学院', NULL),
('400003', '软件工程1班', 'SE202101', '2021级', '软件学院', '200002')
ON CONFLICT (class_name) DO NOTHING;

-- ==================== 第四部分：创建视图和函数 ====================

-- 1. 创建用户详细信息视图
CREATE OR REPLACE VIEW user_details AS
SELECT 
    u.id, u.username, u.email, u.user_number, u.full_name, u.status,
    u.phone, u.department, u.grade, u.class_name,
    u.created_at, r.role_name, r.role_description
FROM users u
JOIN roles r ON u.role_id = r.id;

-- 2. 创建学生初始化个人信息函数
CREATE OR REPLACE FUNCTION initialize_student_profile(p_user_id UUID) RETURNS UUID
LANGUAGE plpgsql AS $$
DECLARE
    v_profile_id UUID;
    v_user_record RECORD;
BEGIN
    SELECT * INTO v_user_record FROM users WHERE id = p_user_id;
    
    INSERT INTO student_profiles (user_id, class_name, profile_status, edit_count) VALUES
    (p_user_id, v_user_record.class_name, 'incomplete', 0)
    RETURNING id INTO v_profile_id;
    
    RETURN v_profile_id;
END;
$$;

-- ==================== 第五部分：初始化学生个人信息 ====================

-- 为每个学生初始化个人信息
DO $$
DECLARE
    v_student_id UUID;
    v_profile_id UUID;
    v_student_record RECORD;
    v_profile_data JSONB;
BEGIN
    FOR v_student_record IN 
        SELECT u.id, u.username, u.full_name, u.class_name 
        FROM users u 
        WHERE u.role_id = '3'
    LOOP
        SELECT initialize_student_profile(v_student_record.id) INTO v_profile_id;
        
        -- 为李小明创建完整个人信息
        IF v_student_record.username = 'student_2021001' THEN
            v_profile_data := jsonb_build_object(
                'gender', 'male',
                'birth_date', '2000-01-01',
                'id_card', '11010120000101001X',
                'nationality', '汉族',
                'political_status', '团员',
                'phone', '13800138000',
                'emergency_contact', '李建国',
                'emergency_phone', '13800138000',
                'home_address', '北京市朝阳区建国路100号',
                'admission_date', '2021-09-01',
                'graduation_date', '2025-06-30',
                'student_type', '全日制',
                'class_name', v_student_record.class_name
            );
            
            -- 更新李小明的个人信息
            UPDATE student_profiles SET
                gender = v_profile_data->>'gender',
                birth_date = (v_profile_data->>'birth_date')::DATE,
                id_card = v_profile_data->>'id_card',
                nationality = v_profile_data->>'nationality',
                political_status = v_profile_data->>'political_status',
                phone = v_profile_data->>'phone',
                emergency_contact = v_profile_data->>'emergency_contact',
                emergency_phone = v_profile_data->>'emergency_phone',
                home_address = v_profile_data->>'home_address',
                admission_date = (v_profile_data->>'admission_date')::DATE,
                graduation_date = (v_profile_data->>'graduation_date')::DATE,
                student_type = v_profile_data->>'student_type',
                profile_status = 'approved',
                edit_count = 1,
                last_edit_at = NOW(),
                reviewed_by = '300001',
                reviewed_at = NOW(),
                review_notes = '测试数据，审核通过'
            WHERE id = v_profile_id;
        END IF;
    END LOOP;
END $$;

-- ==================== 第六部分：验证和结果 ====================

SELECT '数据库初始化完成！' as message;
SELECT COUNT(*) as roles_count FROM roles;
SELECT COUNT(*) as users_count FROM users;
SELECT COUNT(*) as student_profiles_count FROM student_profiles;

-- 查看学生信息
SELECT 
    u.username, 
    u.full_name, 
    u.department, 
    u.grade, 
    u.class_name,
    sp.profile_status,
    sp.edit_count
FROM users u
LEFT JOIN student_profiles sp ON u.id = sp.user_id
WHERE u.role_id = '3'
ORDER BY u.user_number;

-- 测试登录信息
SELECT 
    '测试登录信息：' as info,
    username,
    '密码：123456' as password_hint,
    full_name,
    role_name
FROM users u
JOIN roles r ON u.role_id = r.id
WHERE u.username IN ('student_2021001', 'teacher_zhang', 'admin');