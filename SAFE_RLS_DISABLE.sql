-- 安全的RLS禁用脚本
-- 只对实际存在的表进行操作，避免错误

-- 步骤1: 检查并禁用所有表的RLS（如果存在）
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' AND rowsecurity = true
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE public.%I DISABLE ROW LEVEL SECURITY', r.tablename);
            RAISE NOTICE '已禁用表 % 的RLS', r.tablename;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '禁用表 % 的RLS时出错: %', r.tablename, SQLERRM;
        END;
    END LOOP;
END $$;

-- 步骤2: 删除所有存在的策略
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
            RAISE NOTICE '已删除策略: %', r.policyname;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '删除策略 % 时出错: %', r.policyname, SQLERRM;
        END;
    END LOOP;
END $$;

-- 步骤3: 尝试对常见表执行禁用（如果表存在）
DO $$
BEGIN
    -- 用户相关表
    BEGIN
        ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 users 表';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠ users 表处理失败: %', SQLERRM;
    END;
    
    BEGIN
        ALTER TABLE IF EXISTS public.user_profiles DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 user_profiles 表';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠ user_profiles 表不存在或处理失败: %', SQLERRM;
    END;
    
    -- 学生相关表
    BEGIN
        ALTER TABLE IF EXISTS public.students DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 students 表';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠ students 表处理失败: %', SQLERRM;
    END;
    
    BEGIN
        ALTER TABLE IF EXISTS public.student_profiles DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 student_profiles 表';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠ student_profiles 表不存在或处理失败: %', SQLERRM;
    END;
    
    -- 教师相关表
    BEGIN
        ALTER TABLE IF EXISTS public.teachers DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 teachers 表';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠ teachers 表处理失败: %', SQLERRM;
    END;
    
    BEGIN
        ALTER TABLE IF EXISTS public.teacher_profiles DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 teacher_profiles 表';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠ teacher_profiles 表不存在或处理失败: %', SQLERRM;
    END;
    
    -- 关系表
    BEGIN
        ALTER TABLE IF EXISTS public.teacher_student_relations DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 teacher_student_relations 表';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠ teacher_student_relations 表不存在或处理失败: %', SQLERRM;
    END;
    
END $$;

-- 步骤4: 删除常见策略（如果存在）
DO $$
BEGIN
    -- 用户表策略
    BEGIN
        DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
    EXCEPTION WHEN OTHERS THEN END;
    
    BEGIN
        DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
    EXCEPTION WHEN OTHERS THEN END;
    
    -- 用户档案表策略
    BEGIN
        DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.user_profiles;
    EXCEPTION WHEN OTHERS THEN END;
    
    -- 学生表策略
    BEGIN
        DROP POLICY IF EXISTS "Students can view own data" ON public.students;
    EXCEPTION WHEN OTHERS THEN END;
    
    BEGIN
        DROP POLICY IF EXISTS "Teachers can view students" ON public.students;
    EXCEPTION WHEN OTHERS THEN END;
    
    BEGIN
        DROP POLICY IF EXISTS "Teachers can update students" ON public.students;
    EXCEPTION WHEN OTHERS THEN END;
    
    -- 教师表策略
    BEGIN
        DROP POLICY IF EXISTS "Teachers can view own data" ON public.teachers;
    EXCEPTION WHEN OTHERS THEN END;
    
    BEGIN
        DROP POLICY IF EXISTS "Teachers can update own data" ON public.teachers;
    EXCEPTION WHEN OTHERS THEN END;
    
END $$;

-- 步骤5: 验证结果
SELECT 
    '=== RLS状态检查 ===' as section,
    '' as info

UNION ALL

SELECT 
    '启用RLS的表数量' as section,
    COUNT(*)::text as info
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true

UNION ALL

SELECT 
    '剩余策略数量' as section,
    COUNT(*)::text as info
FROM pg_policies 
WHERE schemaname = 'public'

UNION ALL

SELECT 
    '=== 当前存在的表 ===' as section,
    '' as info

UNION ALL

SELECT 
    tablename as section,
    CASE WHEN rowsecurity THEN 'RLS已启用' ELSE 'RLS已禁用' END as info
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 完成提示
SELECT 
    'RLS禁用操作完成！' as result,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true) = 0 
        THEN '✅ 所有表的RLS都已禁用'
        ELSE '⚠️ 部分表的RLS仍启用'
    END as status;