-- 首先检查数据库中实际存在的表
-- 这个脚本不会修改任何数据，只是查看当前状态

-- 查看所有public schema中的表
SELECT 
    'public schema中的所有表' as info,
    tablename as table_name,
    tableowner as owner
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 查看哪些表启用了RLS
SELECT 
    '启用RLS的表' as info,
    tablename as table_name
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true
ORDER BY tablename;

-- 查看所有存在的RLS策略
SELECT 
    '现有RLS策略' as info,
    tablename as table_name,
    policyname as policy_name,
    permissive as policy_type,
    cmd as command_type
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;