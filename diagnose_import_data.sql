-- 诊断批量导入数据问题
-- 检查数据库中的学生数据和权限

-- 1. 检查users表中的学生数量
SELECT 
    'users表学生总数' as 检查项,
    COUNT(*) as 数量
FROM users 
WHERE role_id = 3 AND status = 'active';

-- 2. 检查角色表
SELECT 
    '角色表信息' as 检查项,
    id,
    role_name,
    role_description
FROM roles 
ORDER BY id;

-- 3. 检查是否有任何用户
SELECT 
    'users表总用户数' as 检查项,
    COUNT(*) as 数量
FROM users;

-- 4. 检查teacher_students表（教师学生关联）
SELECT 
    'teacher_students关联数' as 检查项,
    COUNT(*) as 数量
FROM teacher_students;

-- 5. 检查当前教师ID和其学生
SELECT 
    '当前教师管理的学生数' as 检查项,
    COUNT(*) as 数量
FROM teacher_students 
WHERE teacher_id = '00000000-0000-0000-0000-000000000001';

-- 6. 显示几个示例学生数据（如果有的话）
SELECT 
    '示例学生数据' as 检查项,
    id,
    username,
    user_number,
    full_name,
    role_id,
    status,
    department,
    grade,
    class_name
FROM users 
WHERE role_id = 3 
LIMIT 5;

-- 7. 测试get_available_students_for_import函数（应该返回可导入的学生）
SELECT * FROM get_available_students_for_import(
    '00000000-0000-0000-0000-000000000001', 
    '', 
    '', 
    '', 
    1, 
    20
);

-- 8. 检查是否有权限问题
SELECT 
    '权限检查' as 检查项,
    has_function_privilege('get_available_students_for_import', 'execute') as 函数权限;