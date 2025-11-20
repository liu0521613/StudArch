-- 插入演示学生数据
-- 确保演示用的学生在数据库中存在

-- 1. 首先检查student角色是否存在
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM roles WHERE role_name = 'student' AND id = '3') THEN
        INSERT INTO roles (id, role_name, role_description, is_system_default, created_at, updated_at)
        VALUES ('3', 'student', '学生', true, NOW(), NOW());
    END IF;
END $$;

-- 2. 插入演示学生数据（如果不存在）
INSERT INTO users (
    id, username, email, user_number, full_name, role_id, status, 
    phone, department, grade, class_name, created_at, updated_at,
    password_hash
) VALUES 
    ('00000000-0000-0000-0000-000000000101', 'student001', 'student001@university.edu.cn', '2021001', '张小明', '3', 'active', '138****1234', '计算机学院', '2021级', '计算机科学与技术1班', '2021-09-01', NOW(), 'demo123'),
    ('00000000-0000-0000-0000-000000000102', 'student002', 'student002@university.edu.cn', '2021002', '李小红', '3', 'active', '139****5678', '计算机学院', '2021级', '计算机科学与技术2班', '2021-09-01', NOW(), 'demo123'),
    ('00000000-0000-0000-0000-000000000103', 'student003', 'student003@university.edu.cn', '2021003', '王大力', '3', 'active', '137****9012', '软件学院', '2021级', '软件工程1班', '2021-09-01', NOW(), 'demo123'),
    ('00000000-0000-0000-0000-000000000104', 'student004', 'student004@university.edu.cn', '2021004', '刘美丽', '3', 'active', '136****3456', '软件学院', '2021级', '软件工程2班', '2021-09-01', NOW(), 'demo123'),
    ('00000000-0000-0000-0000-000000000105', 'student005', 'student005@university.edu.cn', '2021005', '陈志强', '3', 'active', '135****7890', '信息工程学院', '2022级', '信息工程1班', '2022-09-01', NOW(), 'demo123')
ON CONFLICT (id) DO NOTHING;

-- 3. 插入更多演示学生
INSERT INTO users (
    id, username, email, user_number, full_name, role_id, status, 
    phone, department, grade, class_name, created_at, updated_at,
    password_hash
) VALUES 
    ('00000000-0000-0000-0000-000000000106', 'student006', 'student006@university.edu.cn', '2021006', '赵文静', '3', 'active', '138****2345', '信息工程学院', '2022级', '信息工程2班', '2022-09-01', NOW(), 'demo123'),
    ('00000000-0000-0000-0000-000000000107', 'student007', 'student007@university.edu.cn', '2021007', '孙建华', '3', 'active', '139****6789', '计算机学院', '2020级', '计算机科学与技术3班', '2020-09-01', NOW(), 'demo123'),
    ('00000000-0000-0000-0000-000000000108', 'student008', 'student008@university.edu.cn', '2021008', '周雅婷', '3', 'active', '136****0123', '计算机学院', '2020级', '计算机科学与技术4班', '2020-09-01', NOW(), 'demo123'),
    ('00000000-0000-0000-0000-000000000109', 'student009', 'student009@university.edu.cn', '2021009', '吴志华', '3', 'active', '137****4567', '软件学院', '2022级', '软件工程3班', '2022-09-01', NOW(), 'demo123'),
    ('00000000-0000-0000-0000-000000000110', 'student010', 'student010@university.edu.cn', '2021010', '郑晓雯', '3', 'active', '135****8901', '信息工程学院', '2021级', '信息工程3班', '2021-09-01', NOW(), 'demo123')
ON CONFLICT (id) DO NOTHING;

-- 4. 创建一个演示教师（如果不存在）
INSERT INTO users (
    id, username, email, user_number, full_name, role_id, status, 
    phone, department, created_at, updated_at,
    password_hash
) VALUES 
    ('00000000-0000-0000-0000-000000000001', 'teacher001', 'teacher001@university.edu.cn', 'T2021001', '张老师', '2', 'active', '138****9999', '计算机学院', NOW(), NOW(), 'demo123')
ON CONFLICT (id) DO NOTHING;

-- 5. 确保teacher角色存在
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM roles WHERE role_name = 'teacher' AND id = '2') THEN
        INSERT INTO roles (id, role_name, role_description, is_system_default, created_at, updated_at)
        VALUES ('2', 'teacher', '教师', true, NOW(), NOW());
    END IF;
END $$;

-- 6. 显示插入结果
SELECT 
    'Demo students and teacher inserted successfully' as status,
    COUNT(*) as total_students
FROM users 
WHERE role_id IN ('2', '3');

SELECT 
    'Available demo students:' as info,
    id,
    full_name,
    user_number,
    email
FROM users 
WHERE role_id = '3' 
AND status = 'active'
ORDER BY user_number;