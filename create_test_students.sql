-- 创建测试学生数据
-- 如果数据库中没有学生，执行这个脚本

-- 确保角色存在
INSERT INTO roles (id, role_name, role_description, permissions, is_system_default) VALUES
(1, 'admin', '管理员', '[]', true),
(2, 'teacher', '教师', '[]', true),
(3, 'student', '学生', '[]', true)
ON CONFLICT (id) DO NOTHING;

-- 创建测试学生数据
INSERT INTO users (
    id, username, email, user_number, full_name, 
    password_hash, role_id, status, phone, 
    department, grade, class_name, created_at, updated_at
) VALUES
-- 计算机学院学生
('00000000-0000-0000-0000-0000000101', 'student001', 'student001@university.edu.cn', 'ST2021001', '张小明', 'hashed_password', 3, 'active', '13800001234', '计算机学院', '2021级', '计算机科学与技术1班', NOW(), NOW()),
('00000000-0000-0000-0000-0000000102', 'student002', 'student002@university.edu.cn', 'ST2021002', '李小红', 'hashed_password', 3, 'active', '13800001235', '计算机学院', '2021级', '计算机科学与技术1班', NOW(), NOW()),
('00000000-0000-0000-0000-0000000103', 'student003', 'student003@university.edu.cn', 'ST2021003', '王小强', 'hashed_password', 3, 'active', '13800001236', '计算机学院', '2021级', '计算机科学与技术2班', NOW(), NOW()),
('00000000-0000-0000-0000-0000000104', 'student004', 'student004@university.edu.cn', 'ST2021004', '赵小芳', 'hashed_password', 3, 'active', '13800001237', '计算机学院', '2021级', '计算机科学与技术2班', NOW(), NOW()),

-- 软件工程专业学生
('00000000-0000-0000-0000-0000000105', 'student005', 'student005@university.edu.cn', 'ST2021005', '刘小军', 'hashed_password', 3, 'active', '13800001238', '计算机学院', '2021级', '软件工程1班', NOW(), NOW()),
('00000000-0000-0000-0000-0000000106', 'student006', 'student006@university.edu.cn', 'ST2021006', '陈小静', 'hashed_password', 3, 'active', '13800001239', '计算机学院', '2021级', '软件工程1班', NOW(), NOW()),
('00000000-0000-0000-0000-0000000107', 'student007', 'student007@university.edu.cn', 'ST2021007', '杨小华', 'hashed_password', 3, 'active', '13800001240', '计算机学院', '2021级', '软件工程2班', NOW(), NOW()),
('00000000-0000-0000-0000-0000000108', 'student008', 'student008@university.edu.cn', 'ST2021008', '黄小美', 'hashed_password', 3, 'active', '13800001241', '计算机学院', '2021级', '软件工程2班', NOW(), NOW()),

-- 2022级学生
('00000000-0000-0000-0000-0000000109', 'student009', 'student009@university.edu.cn', 'ST2022001', '周小伟', 'hashed_password', 3, 'active', '13800001242', '计算机学院', '2022级', '计算机科学与技术1班', NOW(), NOW()),
('00000000-0000-0000-0000-0000000110', 'student010', 'student010@university.edu.cn', 'ST2022002', '吴小丽', 'hashed_password', 3, 'active', '13800001243', '计算机学院', '2022级', '计算机科学与技术1班', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 创建测试教师（如果不存在）
INSERT INTO users (
    id, username, email, user_number, full_name, 
    password_hash, role_id, status, phone, 
    department, created_at, updated_at
) VALUES
('00000000-0000-0000-0000-000000000001', 'teacher001', 'teacher001@university.edu.cn', 'TC2021001', '张老师', 'hashed_password', 2, 'active', '13900001234', '计算机学院', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 创建超级管理员
INSERT INTO users (
    id, username, email, user_number, full_name, 
    password_hash, role_id, status, phone, 
    department, created_at, updated_at
) VALUES
('00000000-0000-0000-0000-000000000000', 'admin', 'admin@university.edu.cn', 'ADMIN001', '系统管理员', 'hashed_password', 1, 'active', '13900000000', '系统管理', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 提交事务
COMMIT;

-- 验证插入结果
SELECT 
    '创建后学生总数' as 结果,
    COUNT(*) as 数量
FROM users 
WHERE role_id = 3;

SELECT 
    '创建后用户总数' as 结果,
    COUNT(*) as 数量
FROM users;