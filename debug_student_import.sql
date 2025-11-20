-- 检查学生导入问题的诊断脚本

-- 1. 检查所有表的存在情况
SELECT '=== 检查表存在情况 ===' as section;

SELECT 
    'Table Check' as info_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'students') THEN 'students表存在'
        ELSE 'students表不存在'
    END as status;

SELECT 
    'Table Check' as info_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'student_profiles') THEN 'student_profiles表存在'
        ELSE 'student_profiles表不存在'
    END as status;

SELECT 
    'Table Check' as info_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_student_relations') THEN 'teacher_student_relations表存在'
        ELSE 'teacher_student_relations表不存在'
    END as status;

-- 2. 检查学生数据
SELECT '=== 检查学生数据 ===' as section;

-- 检查students表数据
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'students') THEN
        RAISE NOTICE '=== students表数据 ===';
        EXECUTE 'SELECT COUNT(*) as student_count FROM public.students';
        EXECUTE 'SELECT ''Students Table Count'' as info, COUNT(*)::text as count FROM public.students';
        
        -- 显示最近插入的几条学生数据
        EXECUTE 'SELECT ''Recent Students'' as info, id, name, email, created_at FROM public.students ORDER BY created_at DESC LIMIT 5';
    ELSE
        RAISE NOTICE 'students表不存在';
    END IF;
END $$;

-- 检查student_profiles表数据
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'student_profiles') THEN
        RAISE NOTICE '=== student_profiles表数据 ===';
        EXECUTE 'SELECT COUNT(*) as profile_count FROM public.student_profiles';
        EXECUTE 'SELECT ''Student Profiles Count'' as info, COUNT(*)::text as count FROM public.student_profiles';
    ELSE
        RAISE NOTICE 'student_profiles表不存在';
    END IF;
END $$;

-- 3. 检查RLS策略
SELECT '=== 检查RLS策略 ===' as section;

SELECT 
    'RLS Policies' as info_type,
    COUNT(*)::text as count
FROM pg_policies 
WHERE schemaname = 'public';

SELECT 
    'Table RLS Status' as info_type,
    tablename as table_name,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('students', 'student_profiles', 'teacher_student_relations')
ORDER BY tablename;

-- 4. 检查师生关系
SELECT '=== 检查师生关系 ===' as section;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_student_relations') THEN
        EXECUTE 'SELECT COUNT(*) as relation_count FROM public.teacher_student_relations';
        EXECUTE 'SELECT ''Teacher-Student Relations'' as info, COUNT(*)::text as count FROM public.teacher_student_relations';
    ELSE
        RAISE NOTICE 'teacher_student_relations表不存在';
    END IF;
END $$;

-- 5. 检查当前用户信息
SELECT '=== 检查当前用户 ===' as section;

SELECT 
    'Current User' as info_type,
    current_user as user_name,
    session_user as session_user_name;

-- 6. 提供修复建议
SELECT '=== 修复建议 ===' as section;

SELECT 
    'Action' as action_type,
    '1. 如果学生表为空：检查批量导入函数是否正确执行' as suggestion;

SELECT 
    'Action' as action_type,
    '2. 如果有数据但前端不显示：检查RLS策略或前端获取逻辑' as suggestion;

SELECT 
    'Action' as action_type,
    '3. 如果师生关系表为空：需要建立师生关联关系' as suggestion;