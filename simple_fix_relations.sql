-- 简化版本：使用现有数据库中的实际数据创建关联

-- 1. 首先查看现有的学生用户
SELECT 
    'Found existing students:' as info,
    id,
    username,
    full_name,
    user_number,
    email
FROM users 
WHERE role_id = '3' 
AND status = 'active'
LIMIT 5;

-- 2. 查看现有的教师用户
SELECT 
    'Found existing teachers:' as info,
    id,
    username,
    full_name,
    user_number,
    email
FROM users 
WHERE role_id = '2' 
AND status = 'active'
LIMIT 3;

-- 3. 使用现有的第一个教师和学生创建关联
INSERT INTO teacher_students (teacher_id, student_id, created_by)
SELECT 
    t.id as teacher_id,
    s.id as student_id,
    t.id as created_by
FROM users t, users s
WHERE t.role_id = '2' 
AND s.role_id = '3'
AND s.status = 'active'
AND t.status = 'active'
LIMIT 5
ON CONFLICT (teacher_id, student_id) DO NOTHING;

-- 4. 验证创建的关联
SELECT 
    'Created teacher-student relationships:' as info,
    ts.teacher_id,
    teacher.username as teacher_name,
    ts.student_id,
    student.username as student_name,
    student.full_name as student_full_name,
    ts.created_at
FROM teacher_students ts
JOIN users teacher ON ts.teacher_id = teacher.id
JOIN users student ON ts.student_id = student.id
WHERE ts.teacher_id = (SELECT id FROM users WHERE role_id = '2' LIMIT 1)
LIMIT 5;

-- 5. 检查teacher_students表状态
SELECT 
    'teacher_students table status:' as info,
    COUNT(*) as total_relations
FROM teacher_students;