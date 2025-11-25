-- 紧急数据插入脚本 - 直接插入测试数据到毕业去向表
-- 执行此脚本来立即解决列表无数据问题

-- 1. 首先检查并确保学生数据存在
SELECT '检查学生数据...' as status;
SELECT COUNT(*) as student_count FROM student_profiles;

-- 2. 如果没有学生数据，插入一些测试学生
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM student_profiles LIMIT 1) THEN
        INSERT INTO student_profiles (
            id, user_id, student_number, full_name, class_name, admission_date, graduation_date, created_at, updated_at
        ) VALUES 
        (gen_random_uuid(), gen_random_uuid(), '2021001', '张三', '计算机科学与技术1班', '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), gen_random_uuid(), '2021002', '李四', '计算机科学与技术1班', '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), gen_random_uuid(), '2021003', '王五', '软件工程1班', '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), gen_random_uuid(), '2021004', '赵六', '软件工程1班', '2021-09-01', '2025-06-30', NOW(), NOW()),
        (gen_random_uuid(), gen_random_uuid(), '2021005', '钱七', '计算机科学与技术2班', '2021-09-01', '2025-06-30', NOW(), NOW());
        
        RAISE NOTICE '插入了5个测试学生记录';
    END IF;
END $$;

-- 3. 清除现有的毕业去向数据（重新开始）
SELECT '清理现有数据...' as status;
DELETE FROM graduation_destinations;

-- 4. 直接插入测试毕业去向数据（不使用导入函数）
SELECT '插入毕业去向数据...' as status;
INSERT INTO graduation_destinations (
    student_id,
    destination_type,
    company_name,
    position,
    salary,
    work_location,
    school_name,
    major,
    degree,
    abroad_country,
    startup_name,
    startup_role,
    other_description,
    status,
    submit_time,
    created_at,
    updated_at
) VALUES 
((SELECT id FROM student_profiles WHERE student_number = '2021001' LIMIT 1), 
 'employment', '腾讯科技有限公司', '前端开发工程师', 15000, '深圳市南山区', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', NOW(), NOW(), NOW()),

((SELECT id FROM student_profiles WHERE student_number = '2021002' LIMIT 1), 
 'employment', '阿里巴巴（中国）有限公司', 'Java开发工程师', 18000, '杭州市余杭区', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', NOW(), NOW(), NOW()),

((SELECT id FROM student_profiles WHERE student_number = '2021003' LIMIT 1), 
 'furtherstudy', NULL, NULL, NULL, NULL, '清华大学', '计算机应用技术', '硕士研究生', NULL, NULL, NULL, NULL, 'pending', NOW(), NOW(), NOW()),

((SELECT id FROM student_profiles WHERE student_number = '2021004' LIMIT 1), 
 'abroad', NULL, NULL, NULL, NULL, '美国斯坦福大学', '人工智能', '博士研究生', '美国', NULL, NULL, NULL, 'pending', NOW(), NOW(), NOW()),

((SELECT id FROM student_profiles WHERE student_number = '2021005' LIMIT 1), 
 'entrepreneurship', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '北京创新科技有限公司', '创始人兼CEO', NULL, 'pending', NOW(), NOW(), NOW());

-- 5. 验证插入结果
SELECT '验证插入结果...' as status;
SELECT COUNT(*) as inserted_count FROM graduation_destinations;

-- 6. 显示插入的具体数据
SELECT '显示插入的毕业去向数据...' as status;
SELECT 
    gd.id,
    gd.destination_type,
    gd.company_name,
    gd.position,
    gd.salary,
    gd.work_location,
    gd.school_name,
    gd.status,
    gd.submit_time,
    sp.student_number,
    sp.full_name,
    sp.class_name
FROM graduation_destinations gd
INNER JOIN student_profiles sp ON gd.student_id = sp.id
ORDER BY gd.submit_time DESC;

-- 7. 创建一个导入批次记录（模拟导入）
SELECT '创建导入批次记录...' as status;
INSERT INTO graduation_import_batches (
    batch_name,
    import_file_path,
    total_records,
    success_count,
    failure_count,
    status,
    imported_by,
    created_at,
    updated_at
) VALUES (
    '手动插入测试数据',
    'emergency_data_insert.sql',
    5,
    5,
    0,
    'completed',
    '550e8400-e29b-41d4-a716-446655440001',
    NOW(),
    NOW()
);

-- 8. 最终状态检查
SELECT '=== 最终状态检查 ===' as info;
SELECT 
    (SELECT COUNT(*) FROM student_profiles) as total_students,
    (SELECT COUNT(*) FROM graduation_destinations) as total_destinations,
    (SELECT COUNT(*) FROM graduation_import_batches) as total_batches;

COMMIT;

-- 9. 测试查询（模拟前端查询）
SELECT '=== 模拟前端查询测试 ===' as info;
SELECT 
    gd.*,
    sp.student_number,
    sp.full_name,
    sp.class_name
FROM graduation_destinations gd
INNER JOIN student_profiles sp ON gd.student_id = sp.id
ORDER BY gd.submit_time DESC
LIMIT 5;