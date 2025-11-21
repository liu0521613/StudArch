-- 测试获取可导入学生函数
-- 运行此脚本来验证函数是否正常工作

-- 1. 首先运行 get_available_students_final.sql 创建函数

-- 2. 测试函数调用（返回表格格式）
SELECT * FROM get_available_students_for_import(
    '00000000-0000-0000-0000-000000000001'::UUID,  -- 测试教师ID
    '',  -- 关键词
    '',  -- 年级
    '',  -- 院系
    1,   -- 页码
    10   -- 每页数量
);

-- 3. 检查现有数据和导入状态
SELECT 
    u.id,
    u.full_name,
    u.user_number,
    u.email,
    CASE 
        WHEN EXISTS(SELECT 1 FROM teacher_students ts WHERE ts.teacher_id = '00000000-0000-0000-0000-000000000001' AND ts.student_id = u.id) 
        THEN '已导入'
        ELSE '可导入'
    END as import_status
FROM users u
WHERE u.role_id = '3' AND u.status = 'active'
ORDER BY u.created_at DESC
LIMIT 5;

-- 4. 检查teacher_students表
SELECT * FROM teacher_students WHERE teacher_id = '00000000-0000-0000-0000-000000000001';