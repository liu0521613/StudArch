-- 修复教师学生列表 - 创建一些实际的关联关系

-- 1. 创建教师-学生关联关系（模拟已导入的学生）
INSERT INTO teacher_students (teacher_id, student_id, created_by)
SELECT 
    '00000000-0000-0000-0000-000000001'::UUID as teacher_id,
    u.id as student_id,
    '00000000-0000-0000-0000-000000001'::UUID as created_by
FROM users u
WHERE u.role_id = '3' 
AND u.status = 'active'
AND (u.username LIKE '%001%' OR u.username LIKE '%002%' OR u.username LIKE '%003%')
LIMIT 5
ON CONFLICT (teacher_id, student_id) DO NOTHING;

-- 2. 验证插入的关联关系
SELECT 
    'Teacher-Student relationships created:' as info,
    ts.teacher_id,
    u.username,
    u.full_name,
    u.user_number,
    ts.created_at
FROM teacher_students ts
JOIN users u ON ts.student_id = u.id
WHERE ts.teacher_id = '00000000-0000-0000-0000-000000001'::UUID
AND u.role_id = '3'
ORDER BY ts.created_at DESC;

-- 3. 显示当前教师的学生数量
SELECT 
    'Total students for this teacher:' as info,
    COUNT(*) as student_count
FROM teacher_students 
WHERE teacher_id = '00000000-0000-0000-0000-000000001'::UUID;

-- 4. 测试获取教师学生的函数
SELECT * FROM get_teacher_students_v2(
    '00000000-0000-0000-0000-000000001',
    '',
    1,
    20
);