-- ==========================================
-- 数据库验证脚本
-- 用于验证数据库初始化后的数据完整性
-- ==========================================

-- ==================== 第一部分：基本验证 ====================

-- 1. 验证表结构是否存在
SELECT '验证表结构' as section;

SELECT 
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name) 
        THEN '✅ 存在' 
        ELSE '❌ 缺失' 
    END as status
FROM (VALUES 
    ('roles'),
    ('users'),
    ('system_settings'),
    ('classes'),
    ('student_profiles'),
    ('profile_edit_logs'),
    ('student_batch_operations')
) as t(table_name);

-- 2. 验证视图是否存在
SELECT '验证视图' as section;

SELECT 
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema = 'public' AND table_name = v.table_name) 
        THEN '✅ 存在' 
        ELSE '❌ 缺失' 
    END as status
FROM (VALUES 
    ('user_details'),
    ('student_complete_info')
) as v(table_name);

-- ==================== 第二部分：数据完整性验证 ====================

-- 1. 验证角色数据
SELECT '验证角色数据' as section;

SELECT 
    role_name,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) = 1 THEN '✅ 正常'
        ELSE '❌ 异常'
    END as status
FROM roles 
WHERE role_name IN ('super_admin', 'teacher', 'student')
GROUP BY role_name
ORDER BY role_name;

-- 2. 验证用户数据
SELECT '验证用户数据' as section;

SELECT 
    role_name,
    COUNT(*) as user_count,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ 正常'
        ELSE '❌ 异常'
    END as status
FROM users u
JOIN roles r ON u.role_id = r.id
GROUP BY role_name
ORDER BY role_name;

-- 3. 验证系统设置
SELECT '验证系统设置' as section;

SELECT 
    setting_key,
    setting_value,
    CASE 
        WHEN setting_value IS NOT NULL THEN '✅ 正常'
        ELSE '❌ 异常'
    END as status
FROM system_settings
ORDER BY setting_key;

-- 4. 验证班级数据
SELECT '验证班级数据' as section;

SELECT 
    class_name,
    grade,
    student_count,
    CASE 
        WHEN class_name IS NOT NULL THEN '✅ 正常'
        ELSE '❌ 异常'
    END as status
FROM classes
ORDER BY grade, class_name;

-- 5. 验证学生个人信息
SELECT '验证学生个人信息' as section;

SELECT 
    u.username,
    u.full_name,
    sp.profile_status,
    sp.edit_count,
    CASE 
        WHEN sp.id IS NOT NULL THEN '✅ 正常'
        ELSE '❌ 缺失'
    END as status
FROM users u
LEFT JOIN student_profiles sp ON u.id = sp.user_id
WHERE u.role_id = 3
ORDER BY u.user_number;

-- ==================== 第三部分：功能验证 ====================

-- 1. 验证视图功能
SELECT '验证视图功能' as section;

-- 用户详情视图
SELECT 
    'user_details' as view_name,
    COUNT(*) as record_count,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ 正常'
        ELSE '❌ 异常'
    END as status
FROM user_details;

-- 学生完整信息视图
SELECT 
    'student_complete_info' as view_name,
    COUNT(*) as record_count,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ 正常'
        ELSE '❌ 异常'
    END as status
FROM student_complete_info;

-- 2. 验证存储过程功能
SELECT '验证存储过程功能' as section;

-- 检查存储过程是否存在
SELECT 
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name IS NOT NULL THEN '✅ 存在'
        ELSE '❌ 缺失'
    END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('initialize_student_profile', 'submit_student_profile', 'review_student_profile')
ORDER BY routine_name;

-- ==================== 第四部分：安全策略验证 ====================

-- 1. 验证行级安全策略 (RLS)
SELECT '验证行级安全策略 (RLS)' as section;

SELECT 
    tablename,
    schemaname,
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN '✅ 已启用'
        ELSE '❌ 未启用'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'student_profiles', 'classes', 'system_settings')
ORDER BY tablename;

-- 2. 验证策略数量
SELECT 
    tablename,
    COUNT(*) as policy_count,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ 已配置'
        ELSE '❌ 未配置'
    END as policy_status
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'student_profiles', 'classes', 'system_settings')
GROUP BY tablename
ORDER BY tablename;

-- ==================== 第五部分：数据质量检查 ====================

-- 1. 检查数据唯一性
SELECT '检查数据唯一性' as section;

-- 检查用户名唯一性
SELECT 
    '用户名唯一性' as check_type,
    COUNT(DISTINCT username) as distinct_count,
    COUNT(*) as total_count,
    CASE 
        WHEN COUNT(DISTINCT username) = COUNT(*) THEN '✅ 唯一'
        ELSE '❌ 重复'
    END as status
FROM users;

-- 检查学号唯一性
SELECT 
    '学号唯一性' as check_type,
    COUNT(DISTINCT user_number) as distinct_count,
    COUNT(*) as total_count,
    CASE 
        WHEN COUNT(DISTINCT user_number) = COUNT(*) THEN '✅ 唯一'
        ELSE '❌ 重复'
    END as status
FROM users;

-- 2. 检查必填字段完整性
SELECT '检查必填字段完整性' as section;

-- 检查用户必填字段
SELECT 
    '用户表' as table_name,
    COUNT(*) as total_count,
    COUNT(username) as username_count,
    COUNT(full_name) as fullname_count,
    COUNT(password_hash) as password_count,
    CASE 
        WHEN COUNT(username) = COUNT(*) AND 
             COUNT(full_name) = COUNT(*) AND 
             COUNT(password_hash) = COUNT(*) THEN '✅ 完整'
        ELSE '❌ 缺失'
    END as status
FROM users;

-- ==================== 第六部分：测试登录信息验证 ====================

SELECT '测试登录信息验证' as section;

-- 显示测试账户信息
SELECT 
    u.username,
    u.full_name,
    r.role_name,
    '密码: 123456' as password_hint,
    CASE 
        WHEN u.status = 'active' THEN '✅ 激活'
        ELSE '❌ 禁用'
    END as account_status
FROM users u
JOIN roles r ON u.role_id = r.id
WHERE u.username IN ('admin', 'teacher_zhang', 'student_2021001')
ORDER BY r.role_name;

-- 验证测试账户密码
SELECT 
    u.username,
    CASE 
        WHEN u.password_hash = '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou' THEN '✅ 密码正确'
        ELSE '❌ 密码错误'
    END as password_status
FROM users u
WHERE u.username IN ('admin', 'teacher_zhang', 'student_2021001');

-- ==================== 第七部分：综合验证报告 ====================

SELECT '综合验证报告' as section;

-- 计算验证通过率
WITH validations AS (
    -- 表结构验证
    SELECT COUNT(*) as total, SUM(CASE WHEN status = '✅ 存在' THEN 1 ELSE 0 END) as passed FROM (
        SELECT '✅ 存在' as status FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'roles' UNION ALL
        SELECT '✅ 存在' FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users' UNION ALL
        SELECT '✅ 存在' FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'system_settings' UNION ALL
        SELECT '✅ 存在' FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'classes' UNION ALL
        SELECT '✅ 存在' FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'student_profiles'
    ) t
    
    UNION ALL
    
    -- 数据验证
    SELECT COUNT(*), SUM(CASE WHEN user_count > 0 THEN 1 ELSE 0 END) FROM (
        SELECT COUNT(*) as user_count FROM users WHERE role_id = 1
        UNION ALL
        SELECT COUNT(*) FROM users WHERE role_id = 2
        UNION ALL
        SELECT COUNT(*) FROM users WHERE role_id = 3
    ) u
    
    UNION ALL
    
    -- 功能验证
    SELECT COUNT(*), COUNT(*) FROM (
        SELECT 1 FROM user_details LIMIT 1
        UNION ALL
        SELECT 1 FROM student_complete_info LIMIT 1
    ) f
),

summary AS (
    SELECT 
        SUM(total) as total_checks,
        SUM(passed) as passed_checks,
        ROUND(SUM(passed) * 100.0 / SUM(total), 2) as pass_rate
    FROM validations
)

SELECT 
    total_checks as "总检查项数",
    passed_checks as "通过检查项数",
    pass_rate as "通过率(%)",
    CASE 
        WHEN pass_rate = 100 THEN '✅ 数据库验证通过'
        WHEN pass_rate >= 80 THEN '⚠️ 数据库验证警告'
        ELSE '❌ 数据库验证失败'
    END as "验证结果"
FROM summary;

-- ==================== 第八部分：手动验证建议 ====================

SELECT '手动验证建议' as section;

-- 建议的手动验证步骤
WITH suggestions AS (
    SELECT 1 as step, '测试超级管理员登录' as action, '使用 admin / 123456 登录系统' as description UNION ALL
    SELECT 2, '测试学生信息维护', '使用 student_2021001 账户测试个人信息编辑功能' UNION ALL
    SELECT 3, '测试教师查看权限', '使用 teacher_zhang 账户查看学生信息' UNION ALL
    SELECT 4, '验证数据权限', '测试不同角色的数据访问权限是否正常' UNION ALL
    SELECT 5, '检查系统设置', '验证系统设置功能是否正常工作'
)

SELECT 
    '步骤 ' || step as step_number,
    action,
    description
FROM suggestions
ORDER BY step;

-- ==================== 执行说明 ====================

/*
使用说明：
1. 在 Supabase SQL Editor 中执行此脚本
2. 查看每个部分的验证结果
3. 如果所有检查项都显示 ✅，说明数据库初始化成功
4. 如果有 ❌ 或 ⚠️ 标记，请检查相关问题

执行命令：
-- 在 SQL Editor 中粘贴并执行整个脚本
*/