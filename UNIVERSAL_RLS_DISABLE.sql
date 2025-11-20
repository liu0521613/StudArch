-- 通用RLS禁用脚本
-- 不依赖任何特定的表名，适用于任何数据库

-- 步骤1: 通用禁用所有表的RLS
DO $$
DECLARE
    tbl_name text;
BEGIN
    FOR tbl_name IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' AND rowsecurity = true
    LOOP
        BEGIN
            EXECUTE 'ALTER TABLE public.' || quote_ident(tbl_name) || ' DISABLE ROW LEVEL SECURITY';
            RAISE NOTICE '已禁用表 % 的RLS', tbl_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '禁用表 % 时出错: %', tbl_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- 步骤2: 删除所有策略
DO $$
DECLARE
    policy_name text;
    table_name text;
    schema_name text;
BEGIN
    FOR schema_name, table_name, policy_name IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE 'DROP POLICY ' || quote_ident(policy_name) || ' ON ' || quote_ident(schema_name) || '.' || quote_ident(table_name);
            RAISE NOTICE '已删除策略: %', policy_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '删除策略 % 时出错: %', policy_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- 步骤3: 再次确认禁用（双重保险）
DO $$
DECLARE
    tbl_name text;
BEGIN
    FOR tbl_name IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE 'ALTER TABLE IF EXISTS public.' || quote_ident(tbl_name) || ' DISABLE ROW LEVEL SECURITY';
        EXCEPTION WHEN OTHERS THEN
            NULL; -- 忽略错误，继续执行
        END;
    END LOOP;
END $$;

-- 验证结果
SELECT '=== RLS禁用结果 ===' as section;

SELECT 
    '剩余启用RLS的表' as status,
    COUNT(*)::text as count
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

SELECT 
    '剩余RLS策略' as status,
    COUNT(*)::text as count
FROM pg_policies 
WHERE schemaname = 'public';

SELECT 
    '=== 执行完成 ===' as section;