-- 检查现有数据并解决冲突

-- 1. 查看现有的学生用户
SELECT 
    'Existing students' as info,
    id,
    username,
    user_number,
    full_name,
    email,
    role_id,
    status
FROM users 
WHERE role_id = '3'
ORDER BY user_number;

-- 2. 查看现有的学号
SELECT 
    'Existing user numbers' as info,
    user_number,
    COUNT(*) as count
FROM users 
WHERE role_id = '3'
GROUP BY user_number
HAVING COUNT(*) > 1;

-- 3. 查看现有的教师
SELECT 
    'Existing teachers' as info,
    id,
    username,
    user_number,
    full_name,
    role_id,
    status
FROM users 
WHERE role_id = '2'
ORDER BY user_number;