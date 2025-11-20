-- 最小化RLS禁用脚本
-- 使用最基本的语法，避免所有可能的错误

-- 第一步：查看当前状态
SELECT '开始RLS禁用操作' as status;

-- 第二步：简单的策略删除（如果存在）
DROP POLICY IF EXISTS "enable_all" ON public.auth.users;
DROP POLICY IF EXISTS "users_can_insert" ON public.auth.users;
DROP POLICY IF EXISTS "users_can_update" ON public.auth.users;
DROP POLICY IF EXISTS "users_can_delete" ON public.auth.users;

-- 第三步：尝试禁用常见表的RLS
ALTER TABLE IF EXISTS public.auth.users DISABLE ROW LEVEL SECURITY;

-- 第四步：检查结果
SELECT '操作完成，检查结果:' as status;

SELECT 
    'auth.users RLS状态' as table_info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'auth' AND tablename = 'users' AND rowsecurity = true
        ) THEN '仍启用'
        ELSE '已禁用'
    END as rls_status;

SELECT 
    '剩余RLS策略数' as policy_info,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public')::text as count;

SELECT 'RLS禁用脚本执行完成!' as result;