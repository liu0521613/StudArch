-- 修复RLS权限问题 - 在Supabase SQL Editor中执行此脚本

-- 1. 临时禁用RLS以便应用可以访问数据（推荐用于开发环境）
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE roles DISABLE ROW LEVEL SECURITY;

-- 2. 或者，创建允许匿名访问的策略（生产环境推荐）
-- 为roles表创建允许读取的策略
CREATE POLICY "允许匿名读取角色" ON roles
    FOR SELECT USING (true);

-- 为users表创建允许读取的策略  
CREATE POLICY "允许匿名读取用户" ON users
    FOR SELECT USING (true);

-- 为users表创建允许插入的策略
CREATE POLICY "允许匿名创建用户" ON users
    FOR INSERT WITH CHECK (true);

-- 为users表创建允许更新的策略
CREATE POLICY "允许匿名更新用户" ON users
    FOR UPDATE USING (true);

-- 为users表创建允许删除的策略
CREATE POLICY "允许匿名删除用户" ON users
    FOR DELETE USING (true);

-- 3. 验证策略是否生效
SELECT tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'roles');

-- 4. 测试数据访问
SELECT '测试角色表访问:' as test, COUNT(*) as count FROM roles;
SELECT '测试用户表访问:' as test, COUNT(*) as count FROM users;

-- 5. 重新启用RLS（如果使用策略方案）
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

-- 选择方案1（禁用RLS）或方案2（创建策略），不要同时使用两者