-- 检查导入数据的SQL脚本
-- 在Supabase SQL Editor中执行此脚本来诊断数据问题

-- 1. 检查毕业去向表中的数据
SELECT '=== 毕业去向表数据检查 ===' as info;
SELECT COUNT(*) as total_destinations FROM graduation_destinations;

-- 2. 显示具体的毕业去向记录（应该能看到导入的数据）
SELECT '=== 具体毕业去向记录 ===' as info;
SELECT 
    gd.id,
    gd.destination_type,
    gd.company_name,
    gd.position,
    gd.status,
    gd.submit_time,
    sp.student_number,
    sp.full_name,
    sp.class_name
FROM graduation_destinations gd
INNER JOIN student_profiles sp ON gd.student_id = sp.id
ORDER BY gd.created_at DESC
LIMIT 10;

-- 3. 检查学生档案表是否有数据
SELECT '=== 学生档案表数据检查 ===' as info;
SELECT COUNT(*) as total_students FROM student_profiles;
SELECT student_number, full_name, class_name FROM student_profiles LIMIT 5;

-- 4. 检查导入批次记录
SELECT '=== 导入批次记录检查 ===' as info;
SELECT 
    id,
    batch_name,
    total_records,
    success_count,
    failure_count,
    status,
    import_file_path,
    created_at
FROM graduation_import_batches
ORDER BY created_at DESC
LIMIT 5;

-- 5. 检查导入失败记录（如果有的话）
SELECT '=== 导入失败记录检查 ===' as info;
SELECT 
    row_number,
    student_number,
    error_message,
    created_at
FROM graduation_import_failures
ORDER BY created_at DESC
LIMIT 5;

-- 6. 检查表结构是否正确
SELECT '=== 表结构检查 ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'graduation_destinations'
ORDER BY ordinal_position;

-- 7. 测试查询（模拟前端查询）
SELECT '=== 模拟前端查询测试 ===' as info;
SELECT 
    gd.*,
    sp.student_number,
    sp.full_name,
    sp.class_name
FROM graduation_destinations gd
INNER JOIN student_profiles sp ON gd.student_id = sp.id
LIMIT 3;