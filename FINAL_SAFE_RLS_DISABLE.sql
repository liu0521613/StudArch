-- 最终安全RLS禁用脚本
-- 修复语法错误，确保在所有PostgreSQL版本中正常工作

-- 步骤1: 禁用所有表的RLS
DO $$
DECLARE
    table_record RECORD;
BEGIN
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' AND rowsecurity = true
    LOOP
        BEGIN
            EXECUTE 'ALTER TABLE public.' || quote_ident(table_record.tablename) || ' DISABLE ROW LEVEL SECURITY';
            RAISE NOTICE '已禁用表 % 的RLS', table_record.tablename;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '禁用表 % 的RLS时出错: %', table_record.tablename, SQLERRM;
        END;
    END LOOP;
END $$;

-- 步骤2: 删除所有策略
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE 'DROP POLICY ' || quote_ident(policy_record.policyname) || ' ON ' || quote_ident(policy_record.schemaname) || '.' || quote_ident(policy_record.tablename);
            RAISE NOTICE '已删除策略: %', policy_record.policyname;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '删除策略 % 时出错: %', policy_record.policyname, SQLERRM;
        END;
    END LOOP;
END $$;

-- 步骤3: 对常见表单独处理（确保覆盖）
DO $$
BEGIN
    -- 处理用户表
    PERFORM 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users';
    IF FOUND THEN
        ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 users 表';
    END IF;
    
    -- 处理学生表
    PERFORM 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'students';
    IF FOUND THEN
        ALTER TABLE public.students DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 students 表';
    END IF;
    
    -- 处理教师表
    PERFORM 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'teachers';
    IF FOUND THEN
        ALTER TABLE public.teachers DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 teachers 表';
    END IF;
    
    -- 处理学生档案表
    PERFORM 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'student_profiles';
    IF FOUND THEN
        ALTER TABLE public.student_profiles DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 student_profiles 表';
    END IF;
    
    -- 处理教师档案表
    PERFORM 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'teacher_profiles';
    IF FOUND THEN
        ALTER TABLE public.teacher_profiles DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 teacher_profiles 表';
    END IF;
    
    -- 处理师生关系表
    PERFORM 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'teacher_student_relations';
    IF FOUND THEN
        ALTER TABLE public.teacher_student_relations DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✓ 已处理 teacher_student_relations 表';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '处理表时出现错误: %', SQLERRM;
END $$;

-- 步骤4: 验证结果
-- 检查启用RLS的表数量
SELECT '启用RLS的表数量' as info, COUNT(*) as count
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

-- 检查剩余策略数量
SELECT '剩余策略数量' as info, COUNT(*) as count
FROM pg_policies 
WHERE schemaname = 'public';

-- 显示所有表及其RLS状态
SELECT '表名' as info, tablename as details, 
       CASE WHEN rowsecurity THEN 'RLS已启用' ELSE 'RLS已禁用' END as status
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 最终结果
SELECT 'RLS禁用操作完成！' as result,
       CASE 
           WHEN (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true) = 0 
           THEN '✅ 所有表的RLS都已禁用'
           ELSE '⚠️ 仍有部分表的RLS启用'
       END as status;