-- 修复版本：先检查现有结构，再创建表
-- 在Supabase SQL Editor中执行此脚本

-- 1. 检查并删除可能存在的视图（如果存在）
DROP VIEW IF EXISTS user_details;

-- 2. 检查并删除可能存在的表（如果存在）
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- 3. 创建角色表
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

-- 4. 创建用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    user_number VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL REFERENCES roles(id),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_user_number UNIQUE(user_number)
);

-- 创建索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_user_number ON users(user_number);
CREATE INDEX idx_users_role_id ON users(role_id);

-- 5. 插入示例数据
INSERT INTO users (
    username, email, user_number, full_name, password_hash, role_id, status
) VALUES (
    'super_admin', 'admin@school.edu', 'ADMIN001', '超级管理员', 
    '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', -- 加密后的密码: admin123
    (SELECT id FROM roles WHERE role_name = 'super_admin'), 'active'
) ON CONFLICT (username) DO NOTHING;

-- 6. 创建用户详细信息视图
CREATE OR REPLACE VIEW user_details AS
SELECT 
    u.id, u.username, u.email, u.user_number, u.full_name, u.status,
    u.created_at, r.role_name, r.role_description
FROM users u
JOIN roles r ON u.role_id = r.id;

-- 7. 验证表创建成功
SELECT '表创建成功！' as message;
SELECT COUNT(*) as roles_count FROM roles;
SELECT COUNT(*) as users_count FROM users;