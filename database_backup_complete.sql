-- ==========================================
-- 完整数据库备份包 - 超级管理平台
-- 适用于 Supabase 项目
-- 创建时间: 2025-11-17
-- ==========================================

-- ==================== 注意事项 ====================
-- 1. 请在 Supabase SQL Editor 中按顺序执行此脚本
-- 2. 确保已启用数据库扩展：uuid-ossp, pgcrypto
-- 3. 执行前请备份现有数据（如果有）

-- ==================== 第一部分：数据库初始化 ====================

-- 1. 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. 删除可能存在的视图和表（按依赖关系顺序）
DROP VIEW IF EXISTS student_complete_info CASCADE;
DROP VIEW IF EXISTS user_details CASCADE;
DROP TABLE IF EXISTS student_batch_operations CASCADE;
DROP TABLE IF EXISTS profile_edit_logs CASCADE;
DROP TABLE IF EXISTS student_profiles CASCADE;
DROP TABLE IF EXISTS import_failures CASCADE;
DROP TABLE IF EXISTS batch_imports CASCADE;
DROP TABLE IF EXISTS login_logs CASCADE;
DROP TABLE IF EXISTS password_resets CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS system_settings CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- ==================== 第二部分：创建核心表结构 ====================

-- 1. 角色表
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_description TEXT,
    permissions JSONB DEFAULT '[]',
    is_system_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 用户表
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
    last_login TIMESTAMP WITH TIME ZONE,
    password_changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_user_number UNIQUE(user_number)
);

-- 3. 系统设置表
CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    setting_description TEXT,
    is_editable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 班级信息表
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

-- 5. 学生个人信息表
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

-- 6. 个人信息修改记录表
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

-- 7. 批量导入记录表
CREATE TABLE batch_imports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    import_type VARCHAR(50) NOT NULL CHECK (import_type IN ('teachers', 'students', 'classes')),
    filename VARCHAR(255) NOT NULL,
    total_records INTEGER NOT NULL,
    success_count INTEGER DEFAULT 0,
    failed_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    error_log TEXT,
    imported_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 8. 导入失败记录表
CREATE TABLE import_failures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_import_id UUID NOT NULL REFERENCES batch_imports(id) ON DELETE CASCADE,
    row_data JSONB NOT NULL,
    error_message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. 登录日志表
CREATE TABLE login_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    login_method VARCHAR(20) DEFAULT 'password' CHECK (login_method IN ('password', 'sso', 'token')),
    ip_address INET,
    user_agent TEXT,
    login_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    success BOOLEAN DEFAULT TRUE,
    failure_reason TEXT
);

-- 10. 密码重置记录表
CREATE TABLE password_resets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reset_token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE,
    ip_address INET,
    user_agent TEXT
);

-- 11. 批量操作记录表
CREATE TABLE student_batch_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operation_type VARCHAR(50) NOT NULL CHECK (operation_type IN ('grade_upload', 'class_change', 'status_update')),
    description TEXT NOT NULL,
    operation_data JSONB NOT NULL,
    affected_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failed_count INTEGER DEFAULT 0,
    operated_by UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    error_log TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- ==================== 第三部分：创建索引 ====================

-- 用户表索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_user_number ON users(user_number);
CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_status ON users(status);

-- 学生个人信息表索引
CREATE INDEX idx_student_profiles_user_id ON student_profiles(user_id);
CREATE INDEX idx_student_profiles_class_id ON student_profiles(class_id);
CREATE INDEX idx_student_profiles_status ON student_profiles(profile_status);

-- 班级表索引
CREATE INDEX idx_classes_grade ON classes(grade);
CREATE INDEX idx_classes_department ON classes(department);

-- 修改记录表索引
CREATE INDEX idx_profile_edit_logs_profile_id ON profile_edit_logs(student_profile_id);

-- 批量导入相关索引
CREATE INDEX idx_batch_imports_import_type ON batch_imports(import_type);
CREATE INDEX idx_batch_imports_imported_by ON batch_imports(imported_by);
CREATE INDEX idx_batch_imports_status ON batch_imports(status);
CREATE INDEX idx_import_failures_batch_import_id ON import_failures(batch_import_id);

-- 登录日志索引
CREATE INDEX idx_login_logs_user_id ON login_logs(user_id);
CREATE INDEX idx_login_logs_login_time ON login_logs(login_time);
CREATE INDEX idx_login_logs_success ON login_logs(success);

-- 密码重置索引
CREATE INDEX idx_password_resets_user_id ON password_resets(user_id);
CREATE INDEX idx_password_resets_reset_token ON password_resets(reset_token);
CREATE INDEX idx_password_resets_expires_at ON password_resets(expires_at);

-- ==================== 第四部分：插入基础数据 ====================

-- 1. 插入系统角色
INSERT INTO roles (id, role_name, role_description, permissions, is_system_default) VALUES
(1, 'super_admin', '超级管理员', '{"manage_users": true, "manage_roles": true, "manage_system": true}', true),
(2, 'teacher', '教师', '{"manage_students": true, "review_profiles": true}', true),
(3, 'student', '学生', '{"view_profile": true, "edit_profile": true}', true)
ON CONFLICT (role_name) DO NOTHING;

-- 2. 插入系统设置
INSERT INTO system_settings (setting_key, setting_value, setting_description) VALUES
('student_profile_edit_enabled', 'true', '学生个人信息维护功能开关'),
('student_profile_mandatory_fields', '["full_name", "id_card", "phone", "emergency_contact", "class_name"]', '学生必填信息字段'),
('max_profile_edit_count', '3', '学生个人信息最大修改次数'),
('profile_auto_approve', 'false', '是否自动审核通过个人信息')
ON CONFLICT (setting_key) DO NOTHING;

-- 3. 插入测试用户数据（使用固定的UUID便于测试）
INSERT INTO users (id, username, email, user_number, full_name, password_hash, role_id, status, phone, department, grade, class_name) VALUES
-- 学生用户
('11111111-1111-1111-1111-111111111111', 'student_2021001', 'student_2021001@example.com', '2021001', '李小明', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', 3, 'active', '13800138000', '计算机学院', '2021级', '计算机科学与技术1班'),
('11111111-1111-1111-1111-111111111112', 'student_2021002', 'student_2021002@example.com', '2021002', '王小红', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', 3, 'active', '13800138001', '计算机学院', '2021级', '计算机科学与技术1班'),
('11111111-1111-1111-1111-111111111113', 'student_2021003', 'student_2021003@example.com', '2021003', '张伟', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', 3, 'active', '13800138002', '软件学院', '2021级', '软件工程1班'),
-- 教师用户
('11111111-1111-1111-1111-111111111121', 'teacher_zhang', 'teacher_zhang@example.com', 'T001', '张老师', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', 2, 'active', '13800138003', '计算机学院', NULL, NULL),
('11111111-1111-1111-1111-111111111122', 'teacher_wang', 'teacher_wang@example.com', 'T002', '王老师', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', 2, 'active', '13800138004', '软件学院', NULL, NULL),
-- 管理员用户
('11111111-1111-1111-1111-111111111131', 'admin', 'admin@example.com', 'A001', '系统管理员', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', 1, 'active', '13800138005', NULL, NULL, NULL)
ON CONFLICT (username) DO NOTHING;

-- 4. 插入班级数据
INSERT INTO classes (id, class_name, class_code, grade, department, head_teacher_id) VALUES
('11111111-1111-1111-1111-111111111141', '计算机科学与技术1班', 'CS202101', '2021级', '计算机学院', '11111111-1111-1111-1111-111111111121'),
('11111111-1111-1111-1111-111111111142', '计算机科学与技术2班', 'CS202102', '2021级', '计算机学院', NULL),
('11111111-1111-1111-1111-111111111143', '软件工程1班', 'SE202101', '2021级', '软件学院', '11111111-1111-1111-1111-111111111122')
ON CONFLICT (class_name) DO NOTHING;

-- ==================== 第五部分：创建触发器函数 ====================

-- 1. 自动更新时间戳的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为用户表添加更新触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 为角色表添加更新触发器
CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 为批量导入表添加更新触发器
CREATE TRIGGER update_batch_imports_updated_at BEFORE UPDATE ON batch_imports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. 同步学生班级信息触发器
CREATE OR REPLACE FUNCTION sync_student_class_name()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.class_id IS NOT NULL THEN
        SELECT class_name INTO NEW.class_name FROM classes WHERE id = NEW.class_id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER sync_student_class_name_trigger 
    BEFORE INSERT OR UPDATE ON student_profiles
    FOR EACH ROW EXECUTE FUNCTION sync_student_class_name();

-- 3. 更新班级学生人数触发器
CREATE OR REPLACE FUNCTION update_class_student_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.class_id IS DISTINCT FROM NEW.class_id) THEN
        -- 更新新班级学生数
        IF NEW.class_id IS NOT NULL THEN
            UPDATE classes 
            SET student_count = (
                SELECT COUNT(*) FROM student_profiles 
                WHERE class_id = NEW.class_id AND profile_status != 'rejected'
            )
            WHERE id = NEW.class_id;
        END IF;
        
        -- 更新旧班级学生数
        IF TG_OP = 'UPDATE' AND OLD.class_id IS NOT NULL AND OLD.class_id != NEW.class_id THEN
            UPDATE classes 
            SET student_count = (
                SELECT COUNT(*) FROM student_profiles 
                WHERE class_id = OLD.class_id AND profile_status != 'rejected'
            )
            WHERE id = OLD.class_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_class_student_count_trigger 
    AFTER INSERT OR UPDATE OR DELETE ON student_profiles
    FOR EACH ROW EXECUTE FUNCTION update_class_student_count();

-- ==================== 第六部分：创建视图 ====================

-- 1. 用户详细信息视图
CREATE OR REPLACE VIEW user_details AS
SELECT 
    u.id, u.username, u.email, u.user_number, u.full_name, u.status,
    u.phone, u.department, u.grade, u.class_name,
    u.created_at, r.role_name, r.role_description
FROM users u
JOIN roles r ON u.role_id = r.id;

-- 2. 学生完整信息视图
CREATE OR REPLACE VIEW student_complete_info AS
SELECT 
    u.id as user_id,
    u.username,
    u.email,
    u.user_number,
    u.full_name,
    u.status as user_status,
    u.phone as user_phone,
    u.department,
    u.grade,
    u.class_name as user_class_name,
    
    sp.id as profile_id,
    sp.gender,
    sp.birth_date,
    sp.id_card,
    sp.nationality,
    sp.political_status,
    sp.phone as profile_phone,
    sp.emergency_contact,
    sp.emergency_phone,
    sp.home_address,
    sp.admission_date,
    sp.graduation_date,
    sp.student_type,
    sp.class_id,
    sp.class_name as profile_class_name,
    sp.profile_status,
    sp.edit_count,
    sp.last_edit_at,
    sp.reviewed_by,
    sp.reviewed_at,
    sp.review_notes,
    
    c.class_code,
    c.head_teacher_id,
    c.student_count,
    c.status as class_status,
    
    CASE 
        WHEN sp.profile_status = 'approved' THEN '已完善'
        WHEN sp.profile_status = 'pending' THEN '待审核'
        WHEN sp.profile_status = 'rejected' THEN '需修改'
        ELSE '未完善'
    END as profile_status_text
FROM users u
LEFT JOIN student_profiles sp ON u.id = sp.user_id
LEFT JOIN classes c ON sp.class_id = c.id
WHERE u.role_id = 3;

-- ==================== 第七部分：创建存储过程 ====================

-- 1. 学生初始化个人信息函数
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

-- 2. 提交学生个人信息函数
CREATE OR REPLACE FUNCTION submit_student_profile(
    p_profile_id UUID,
    p_profile_data JSONB,
    p_edit_reason TEXT DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE plpgsql AS $$
DECLARE
    v_profile_record RECORD;
    v_mandatory_fields JSONB;
    v_missing_fields TEXT[];
    v_field TEXT;
    v_max_edit_count INTEGER;
    v_is_enabled BOOLEAN;
BEGIN
    -- 检查功能是否启用
    SELECT setting_value::BOOLEAN INTO v_is_enabled 
    FROM system_settings 
    WHERE setting_key = 'student_profile_edit_enabled';
    
    IF NOT v_is_enabled THEN
        RAISE EXCEPTION '学生个人信息维护功能已禁用';
    END IF;
    
    -- 获取必填字段
    SELECT setting_value::JSONB INTO v_mandatory_fields 
    FROM system_settings 
    WHERE setting_key = 'student_profile_mandatory_fields';
    
    -- 获取最大修改次数
    SELECT setting_value::INTEGER INTO v_max_edit_count 
    FROM system_settings 
    WHERE setting_key = 'max_profile_edit_count';
    
    -- 检查修改次数限制
    SELECT * INTO v_profile_record FROM student_profiles WHERE id = p_profile_id;
    
    IF v_profile_record.edit_count >= v_max_edit_count AND v_profile_record.profile_status != 'incomplete' THEN
        RAISE EXCEPTION '已达到最大修改次数限制 (%)', v_max_edit_count;
    END IF;
    
    -- 检查必填字段
    v_missing_fields := ARRAY[]::TEXT[];
    
    FOREACH v_field IN ARRAY ARRAY(SELECT jsonb_array_elements_text(v_mandatory_fields))
    LOOP
        IF p_profile_data->>v_field IS NULL OR p_profile_data->>v_field = '' THEN
            v_missing_fields := array_append(v_missing_fields, v_field);
        END IF;
    END LOOP;
    
    IF array_length(v_missing_fields, 1) > 0 THEN
        RAISE EXCEPTION '缺少必填字段: %', array_to_string(v_missing_fields, ', ');
    END IF;
    
    -- 更新学生个人信息
    UPDATE student_profiles 
    SET 
        gender = p_profile_data->>'gender',
        birth_date = (p_profile_data->>'birth_date')::DATE,
        id_card = p_profile_data->>'id_card',
        nationality = p_profile_data->>'nationality',
        political_status = p_profile_data->>'political_status',
        phone = p_profile_data->>'phone',
        emergency_contact = p_profile_data->>'emergency_contact',
        emergency_phone = p_profile_data->>'emergency_phone',
        home_address = p_profile_data->>'home_address',
        admission_date = (p_profile_data->>'admission_date')::DATE,
        graduation_date = (p_profile_data->>'graduation_date')::DATE,
        student_type = p_profile_data->>'student_type',
        profile_status = 'pending',
        edit_count = edit_count + 1,
        last_edit_at = NOW(),
        updated_at = NOW()
    WHERE id = p_profile_id;
    
    -- 记录修改日志
    INSERT INTO profile_edit_logs (
        student_profile_id,
        user_id,
        changed_fields,
        old_values,
        new_values,
        edit_reason
    ) VALUES (
        p_profile_id,
        v_profile_record.user_id,
        p_profile_data,
        to_jsonb(v_profile_record),
        p_profile_data,
        p_edit_reason
    );
    
    RETURN TRUE;
END;
$$;

-- 3. 审核学生个人信息函数
CREATE OR REPLACE FUNCTION review_student_profile(
    p_profile_id UUID,
    p_review_result VARCHAR,
    p_reviewed_by UUID,
    p_review_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE student_profiles 
    SET 
        profile_status = p_review_result,
        reviewed_by = p_reviewed_by,
        reviewed_at = NOW(),
        review_notes = p_review_notes,
        updated_at = NOW()
    WHERE id = p_profile_id;
    
    RETURN TRUE;
END;
$$;

-- ==================== 第八部分：初始化学生数据 ====================

-- 为每个学生初始化个人信息
DO $$
DECLARE
    v_student_id UUID;
    v_profile_id UUID;
    v_student_record RECORD;
    v_class_id UUID;
    v_profile_data JSONB;
BEGIN
    FOR v_student_record IN 
        SELECT u.id, u.username, u.full_name, u.class_name 
        FROM users u 
        WHERE u.role_id = 3
    LOOP
        -- 获取班级ID
        SELECT id INTO v_class_id FROM classes WHERE class_name = v_student_record.class_name;
        
        -- 初始化学生个人信息
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
                class_id = v_class_id,
                profile_status = 'approved',
                edit_count = 1,
                last_edit_at = NOW(),
                reviewed_by = '11111111-1111-1111-1111-111111111131',
                reviewed_at = NOW(),
                review_notes = '测试数据，审核通过',
                updated_at = NOW()
            WHERE id = v_profile_id;
        END IF;
    END LOOP;
END $$;

-- ==================== 第九部分：启用行级安全策略 ====================

-- 启用行级安全
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_edit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_batch_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE batch_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_failures ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_resets ENABLE ROW LEVEL SECURITY;

-- 1. 超级管理员可访问所有用户数据
CREATE POLICY "超级管理员可访问所有用户" ON users
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id = 1
    ));

-- 2. 教师只能查看学生用户
CREATE POLICY "教师可查看学生" ON users
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id = 2
    ) AND role_id = 3);

-- 3. 用户只能查看自己的信息
CREATE POLICY "用户可查看自己" ON users
    FOR SELECT USING (id = auth.uid());

-- 4. 系统设置策略：只有超级管理员可修改
CREATE POLICY "系统设置管理策略" ON system_settings
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id = 1
    ));

-- 5. 学生个人信息策略：学生只能查看和修改自己的信息
CREATE POLICY "学生个人信息策略" ON student_profiles
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "学生个人信息更新策略" ON student_profiles
    FOR UPDATE USING (user_id = auth.uid());

-- 6. 教师和管理员可以查看所有学生信息
CREATE POLICY "教师查看学生信息策略" ON student_profiles
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id IN (1, 2)
    ));

-- 7. 批量导入表策略
CREATE POLICY "批量导入管理员策略" ON batch_imports
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id IN (1, 2)
    ));

-- 8. 导入失败记录策略
CREATE POLICY "导入失败记录策略" ON import_failures
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id IN (1, 2)
    ));

-- 9. 登录日志策略
CREATE POLICY "登录日志个人策略" ON login_logs
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "登录日志管理员策略" ON login_logs
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id IN (1, 2)
    ));

-- 10. 密码重置策略
CREATE POLICY "密码重置个人策略" ON password_resets
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY "密码重置管理员策略" ON password_resets
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id = 1
    ));

-- ==================== 第十部分：验证和结果 ====================

-- 验证数据库初始化结果
SELECT '数据库初始化完成！' as message;
SELECT '角色数量：' || COUNT(*) as roles_count FROM roles;
SELECT '用户数量：' || COUNT(*) as users_count FROM users;
SELECT '班级数量：' || COUNT(*) as classes_count FROM classes;
SELECT '批量导入表创建成功' as batch_imports_status FROM batch_imports LIMIT 1;
SELECT '导入失败记录表创建成功' as import_failures_status FROM import_failures LIMIT 1;
SELECT '登录日志表创建成功' as login_logs_status FROM login_logs LIMIT 1;
SELECT '密码重置表创建成功' as password_resets_status FROM password_resets LIMIT 1;
SELECT '学生个人信息数量：' || COUNT(*) as student_profiles_count FROM student_profiles;

-- 显示测试登录信息
SELECT 
    '测试登录信息：' as info,
    username,
    '密码：123456' as password_hint,
    full_name,
    role_name
FROM users u
JOIN roles r ON u.role_id = r.id
WHERE u.username IN ('student_2021001', 'teacher_zhang', 'admin');

-- 查看学生信息统计
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
WHERE u.role_id = 3
ORDER BY u.user_number;