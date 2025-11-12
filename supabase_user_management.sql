-- 超级管理平台用户管理系统数据库设计
-- 此SQL脚本用于在Supabase中手动创建用户管理相关表结构

-- ==================== 角色表（系统预定义角色） ====================
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE, -- 角色名称: super_admin, teacher, student
    role_description TEXT, -- 角色描述
    permissions JSONB DEFAULT '[]', -- 权限配置JSON
    is_system_default BOOLEAN DEFAULT FALSE, -- 是否为系统默认角色
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 插入系统预定义角色
INSERT INTO roles (role_name, role_description, permissions, is_system_default) VALUES
('super_admin', '超级管理员', '["user_management", "system_settings", "all_access"]', TRUE),
('teacher', '教师', '["student_management", "course_management", "grade_management"]', TRUE),
('student', '学生', '["view_own_profile", "submit_assignments", "view_courses"]', TRUE)
ON CONFLICT (role_name) DO NOTHING;

-- ==================== 用户表 ====================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE, -- 用户名
    email VARCHAR(255) UNIQUE, -- 邮箱
    user_number VARCHAR(50) NOT NULL, -- 学号/工号
    full_name VARCHAR(100) NOT NULL, -- 真实姓名
    password_hash VARCHAR(255) NOT NULL, -- 密码哈希
    role_id INTEGER NOT NULL REFERENCES roles(id), -- 角色ID
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')), -- 用户状态
    
    -- 扩展信息
    phone VARCHAR(20), -- 手机号
    department VARCHAR(100), -- 部门/院系
    grade VARCHAR(20), -- 年级（学生使用）
    class_name VARCHAR(50), -- 班级名称
    
    -- 时间戳
    last_login TIMESTAMP WITH TIME ZONE, -- 最后登录时间
    password_changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 密码最后修改时间
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 索引
    CONSTRAINT unique_user_number UNIQUE(user_number)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_user_number ON users(user_number);
CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- ==================== 批量导入记录表 ====================
CREATE TABLE IF NOT EXISTS batch_imports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    import_type VARCHAR(50) NOT NULL CHECK (import_type IN ('teachers', 'students')), -- 导入类型
    filename VARCHAR(255) NOT NULL, -- 文件名
    total_records INTEGER NOT NULL, -- 总记录数
    success_count INTEGER DEFAULT 0, -- 成功导入数
    failed_count INTEGER DEFAULT 0, -- 失败导入数
    
    -- 导入状态
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    error_log TEXT, -- 错误日志
    
    -- 操作信息
    imported_by UUID, -- 导入操作人（用户ID）
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- ==================== 导入失败记录表 ====================
CREATE TABLE IF NOT EXISTS import_failures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_import_id UUID NOT NULL REFERENCES batch_imports(id) ON DELETE CASCADE,
    row_data JSONB NOT NULL, -- 原始行数据
    error_message TEXT NOT NULL, -- 错误信息
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==================== 登录日志表 ====================
CREATE TABLE IF NOT EXISTS login_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    login_method VARCHAR(20) DEFAULT 'password' CHECK (login_method IN ('password', 'sso', 'token')),
    ip_address INET, -- 登录IP地址
    user_agent TEXT, -- 用户代理信息
    login_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    success BOOLEAN DEFAULT TRUE -- 登录是否成功
);

-- 创建登录日志索引
CREATE INDEX IF NOT EXISTS idx_login_logs_user_id ON login_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_login_logs_login_time ON login_logs(login_time);

-- ==================== 密码重置记录表 ====================
CREATE TABLE IF NOT EXISTS password_resets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reset_token VARCHAR(255) NOT NULL UNIQUE, -- 重置令牌
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL, -- 令牌过期时间
    used BOOLEAN DEFAULT FALSE, -- 是否已使用
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE
);

-- ==================== 触发器函数：自动更新时间戳 ====================
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

-- ==================== 视图：用户详细信息视图 ====================
CREATE OR REPLACE VIEW user_details AS
SELECT 
    u.id,
    u.username,
    u.email,
    u.user_number,
    u.full_name,
    u.status,
    u.phone,
    u.department,
    u.grade,
    u.class_name,
    u.last_login,
    u.created_at,
    r.role_name,
    r.role_description,
    r.permissions
FROM users u
JOIN roles r ON u.role_id = r.id;

-- ==================== 安全策略（Row Level Security） ====================
-- 启用行级安全策略
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE batch_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_logs ENABLE ROW LEVEL SECURITY;

-- 创建策略：超级管理员可以访问所有用户数据
CREATE POLICY "超级管理员可访问所有用户" ON users
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id = (SELECT id FROM roles WHERE role_name = 'super_admin')
    ));

-- 创建策略：教师只能查看学生用户
CREATE POLICY "教师可查看学生" ON users
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id = (SELECT id FROM roles WHERE role_name = 'teacher')
    ) AND role_id = (SELECT id FROM roles WHERE role_name = 'student'));

-- 创建策略：用户只能查看自己的信息
CREATE POLICY "用户可查看自己" ON users
    FOR SELECT USING (id = auth.uid());

-- ==================== 插入示例数据 ====================
-- 插入示例超级管理员（密码：admin123，请在生产环境中修改）
INSERT INTO users (
    username, 
    email, 
    user_number, 
    full_name, 
    password_hash, 
    role_id, 
    status
) VALUES (
    'super_admin',
    'admin@school.edu',
    'ADMIN001',
    '超级管理员',
    crypt('admin123', gen_salt('bf')), -- 使用bcrypt加密密码
    (SELECT id FROM roles WHERE role_name = 'super_admin'),
    'active'
) ON CONFLICT (username) DO NOTHING;

-- 插入示例教师
INSERT INTO users (
    username, 
    email, 
    user_number, 
    full_name, 
    password_hash, 
    role_id, 
    status, 
    department
) VALUES (
    'teacher_zhang',
    'zhang@school.edu',
    'T2024001',
    '张老师',
    crypt('teacher123', gen_salt('bf')),
    (SELECT id FROM roles WHERE role_name = 'teacher'),
    'active',
    '计算机学院'
) ON CONFLICT (username) DO NOTHING;

-- 插入示例学生
INSERT INTO users (
    username, 
    email, 
    user_number, 
    full_name, 
    password_hash, 
    role_id, 
    status, 
    department, 
    grade, 
    class_name
) VALUES (
    'student_2021001',
    '2021001@student.school.edu',
    '2021001',
    '李小明',
    crypt('student123', gen_salt('bf')),
    (SELECT id FROM roles WHERE role_name = 'student'),
    'active',
    '计算机学院',
    '2021级',
    '计算机科学与技术1班'
) ON CONFLICT (username) DO NOTHING;

-- ==================== 存储过程：批量导入用户 ====================
CREATE OR REPLACE FUNCTION batch_import_users(
    p_import_type VARCHAR,
    p_filename VARCHAR,
    p_imported_by UUID,
    p_user_data JSONB
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_id UUID;
    v_total_count INTEGER;
    v_success_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_user_record JSONB;
    v_error_message TEXT;
BEGIN
    -- 创建导入记录
    INSERT INTO batch_imports (import_type, filename, total_records, imported_by, status)
    VALUES (p_import_type, p_filename, jsonb_array_length(p_user_data), p_imported_by, 'processing')
    RETURNING id INTO v_batch_id;
    
    -- 处理每一条用户数据
    FOR v_user_record IN SELECT * FROM jsonb_array_elements(p_user_data)
    LOOP
        BEGIN
            -- 插入用户数据
            INSERT INTO users (
                username,
                email,
                user_number,
                full_name,
                password_hash,
                role_id,
                status,
                department,
                grade,
                class_name
            ) VALUES (
                (v_user_record->>'username'),
                (v_user_record->>'email'),
                (v_user_record->>'user_number'),
                (v_user_record->>'full_name'),
                crypt('default123', gen_salt('bf')), -- 默认密码
                CASE 
                    WHEN p_import_type = 'teachers' THEN (SELECT id FROM roles WHERE role_name = 'teacher')
                    WHEN p_import_type = 'students' THEN (SELECT id FROM roles WHERE role_name = 'student')
                END,
                'active',
                (v_user_record->>'department'),
                (v_user_record->>'grade'),
                (v_user_record->>'class_name')
            );
            
            v_success_count := v_success_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                v_failed_count := v_failed_count + 1;
                v_error_message := SQLERRM;
                
                -- 记录失败信息
                INSERT INTO import_failures (batch_import_id, row_data, error_message)
                VALUES (v_batch_id, v_user_record, v_error_message);
        END;
    END LOOP;
    
    -- 更新导入记录状态
    UPDATE batch_imports 
    SET 
        success_count = v_success_count,
        failed_count = v_failed_count,
        status = CASE WHEN v_failed_count = 0 THEN 'completed' ELSE 'completed' END,
        completed_at = NOW()
    WHERE id = v_batch_id;
    
    RETURN v_batch_id;
END;
$$;

-- ==================== 存储过程：重置用户密码 ====================
CREATE OR REPLACE FUNCTION reset_user_password(
    p_user_id UUID,
    p_reset_by UUID
) RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_password VARCHAR := substring(md5(random()::text) from 1 for 8); -- 生成8位随机密码
BEGIN
    -- 更新用户密码
    UPDATE users 
    SET 
        password_hash = crypt(v_new_password, gen_salt('bf')),
        password_changed_at = NOW()
    WHERE id = p_user_id;
    
    -- 记录密码重置
    INSERT INTO password_resets (user_id, reset_token, expires_at, used)
    VALUES (p_user_id, md5(random()::text), NOW() + INTERVAL '1 hour', TRUE);
    
    RETURN v_new_password;
END;
$$;

-- ==================== 查询示例 ====================
-- 查询所有用户详细信息
-- SELECT * FROM user_details;

-- 查询批量导入记录
-- SELECT * FROM batch_imports ORDER BY created_at DESC;

-- 查询特定导入的失败记录
-- SELECT * FROM import_failures WHERE batch_import_id = 'your-batch-id';

-- 查询用户登录日志
-- SELECT * FROM login_logs WHERE user_id = 'your-user-id' ORDER BY login_time DESC;

-- 注释：在生产环境中，请确保：
-- 1. 修改默认密码
-- 2. 配置适当的SSL证书
-- 3. 定期备份数据库
-- 4. 监控数据库性能
-- 5. 配置适当的防火墙规则