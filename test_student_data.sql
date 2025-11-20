-- 创建测试学生数据用于批量导入功能测试
-- 确保必要的表和函数存在后运行此脚本

-- 插入测试学生数据（如果不存在）
INSERT INTO users (id, username, email, user_number, full_name, password_hash, role_id, status, phone, department, grade, class_name, created_at, updated_at)
SELECT 
    gen_random_uuid()::text,
    'test_student_' || seq || '@example.com',
    '2021' || LPAD(seq::text, 3, '0'),
    '测试学生' || seq,
    '$2b$12$LQv3c1yqBWVHxkd0L', -- 模拟密码哈希
    (SELECT id FROM roles WHERE role_name = 'student' LIMIT 1),
    'active',
    '138' || (seq + 1000) || '****' || RIGHT(seq::text, 4),
    CASE 
        WHEN seq <= 5 THEN '计算机学院'
        WHEN seq <= 10 THEN '软件学院'
        ELSE '信息工程学院'
    END,
    '2021级',
    CASE 
        WHEN seq <= 3 THEN '计算机科学与技术' || (seq % 3 + 1) || '班'
        WHEN seq <= 6 THEN '软件工程' || (seq % 3 + 1) || '班'
        ELSE '信息工程' || (seq % 3 + 1) || '班'
    END,
    NOW(),
    NOW()
FROM generate_series(1, 15) AS seq
WHERE NOT EXISTS (
    SELECT 1 FROM users 
    WHERE user_number = '2021' || LPAD(seq::text, 3, '0')
);

-- 插入一个测试教师（如果不存在）
INSERT INTO users (id, username, email, user_number, full_name, password_hash, role_id, status, phone, department, grade, class_name, created_at, updated_at)
SELECT 
    gen_random_uuid()::text,
    'teacher_test',
    'teacher@example.com',
    'T001',
    '测试教师',
    '$2b$12$LQv3c1yqBWVHxkd0L', -- 模拟密码哈希
    (SELECT id FROM roles WHERE role_name = 'teacher' LIMIT 1),
    'active',
    '13900001111',
    '计算机学院',
    '教师',
    '计算机学院',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM users 
    WHERE user_number = 'T001'
);

-- 插入一些教师学生关联关系
INSERT INTO teacher_students (teacher_id, student_id, created_by)
SELECT 
    t.id,
    s.id,
    t.id
FROM users t, users s
JOIN roles rt ON t.role_id = rt.id
JOIN roles rs ON s.role_id = rs.id
WHERE t.user_number = 'T001'
AND rs.role_name = 'student'
AND s.user_number IN ('2021001', '2021002', '2021003')
ON CONFLICT (teacher_id, student_id) DO NOTHING;

-- 显示创建的数据
SELECT 
    '已创建学生数据' as message,
    COUNT(*) FILTER (WHERE role_id = (SELECT id FROM roles WHERE role_name = 'student')) as student_count,
    COUNT(*) FILTER (WHERE role_id = (SELECT id FROM roles WHERE role_name = 'teacher')) as teacher_count
FROM users
WHERE user_number LIKE '2021%' OR user_number = 'T001';

-- 显示教师学生关联数据
SELECT 
    '已创建教师学生关联' as message,
    COUNT(*) as association_count
FROM teacher_students
WHERE teacher_id = (SELECT id FROM users WHERE user_number = 'T001');