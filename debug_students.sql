-- 调试学生数据 - 检查数据库中的实际学生数据

-- 1. 检查所有用户表中的数据
SELECT 
    'users_table' as table_name,
    COUNT(*) as total_users,
    COUNT(CASE WHEN role_id = '3' THEN 1 END) as students,
    COUNT(CASE WHEN role_id = '3' AND status = 'active' THEN 1 END) as active_students
FROM users;

-- 2. 显示前10个学生用户
SELECT 
    id,
    username,
    user_number,
    full_name,
    email,
    role_id,
    status
FROM users 
WHERE role_id = '3'
LIMIT 10;

-- 3. 检查teacher_students表
SELECT 
    'teacher_students_table' as table_name,
    COUNT(*) as total_relations
FROM teacher_students;

-- 4. 检查当前教师的学生关系
SELECT 
    teacher_id,
    student_id,
    created_at
FROM teacher_students 
WHERE teacher_id = '00000000-0000-0000-0000-000000000001'
LIMIT 5;

-- 5. 检查是否存在特定的演示学生ID
SELECT 
    id,
    full_name,
    user_number,
    status
FROM users 
WHERE id IN (
    '00000000-0000-0000-0000-000000000101',
    '00000000-0000-0000-0000-000000000102'
);

-- 6. 测试插入一个简单的关系
SELECT 
    'test_insert' as operation,
    '尝试插入测试关系' as description;

-- 7. 检查roles表
SELECT * FROM roles WHERE role_name = 'student';