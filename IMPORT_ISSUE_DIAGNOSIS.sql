-- 学生导入显示问题全面诊断脚本

-- 1. 检查所有相关表是否存在
SELECT '=== 表结构检查 ===' as section;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN 'users表存在'
        ELSE 'users表不存在'
    END as table_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_students') THEN 'teacher_students表存在'
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_student_relations') THEN 'teacher_student_relations表存在'
        ELSE '师生关系表不存在'
    END as table_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'roles') THEN 'roles表存在'
        ELSE 'roles表不存在'
    END as table_status;

-- 2. 检查用户数据
SELECT '=== 用户数据检查 ===' as section;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
        EXECUTE 'SELECT ''用户总数'' as data_type, COUNT(*)::text as count FROM public.users';
        
        EXECUTE 'SELECT ''学生用户数'' as data_type, COUNT(*)::text as count FROM public.users WHERE role_id = ''3''';
        
        EXECUTE 'SELECT ''活跃学生数'' as data_type, COUNT(*)::text as count FROM public.users WHERE role_id = ''3'' AND status = ''active''';
        
        -- 显示最近创建的学生
        EXECUTE 'SELECT ''最近学生（前5）'' as data_type, user_number || '' - '' || full_name as details FROM public.users WHERE role_id = ''3'' ORDER BY created_at DESC LIMIT 5';
    ELSE
        RAISE NOTICE 'users表不存在，无法检查用户数据';
    END IF;
END $$;

-- 3. 检查师生关系数据
SELECT '=== 师生关系检查 ===' as section;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_students') THEN
        EXECUTE 'SELECT ''师生关系总数'' as data_type, COUNT(*)::text as count FROM public.teacher_students';
        
        -- 按教师分组统计
        EXECUTE 'SELECT ''教师学生关系详情'' as data_type, teacher_id || '' 管理 '' || COUNT(*)::text || '' 个学生'' as details FROM public.teacher_students GROUP BY teacher_id';
    ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_student_relations') THEN
        EXECUTE 'SELECT ''师生关系总数'' as data_type, COUNT(*)::text as count FROM public.teacher_student_relations';
        
        -- 按教师分组统计
        EXECUTE 'SELECT ''教师学生关系详情'' as data_type, teacher_id || '' 管理 '' || COUNT(*)::text || '' 个学生'' as details FROM public.teacher_student_relations GROUP BY teacher_id';
    ELSE
        RAISE NOTICE '师生关系表不存在';
    END IF;
END $$;

-- 4. 检查RLS策略状态
SELECT '=== RLS策略检查 ===' as section;

SELECT 
    '启用RLS的表' as info_type,
    tablename as table_name,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('users', 'teacher_students', 'teacher_student_relations')
ORDER BY tablename;

SELECT 
    'RLS策略数量' as info_type,
    COUNT(*)::text as policy_count
FROM pg_policies 
WHERE schemaname = 'public';

-- 5. 检查特定教师的学生
SELECT '=== 特定教师学生检查 ===' as section;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_students') THEN
        EXECUTE 'SELECT ''测试教师管理的学生数'' as data_type, COUNT(*)::text as count FROM public.teacher_students WHERE teacher_id = ''00000000-0000-0000-0000-000000000001''';
        
        EXECUTE 'SELECT ''测试教师管理的学生详情'' as data_type, student_id FROM public.teacher_students WHERE teacher_id = ''00000000-0000-0000-0000-000000000001'' LIMIT 5';
    ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_student_relations') THEN
        EXECUTE 'SELECT ''测试教师管理的学生数'' as data_type, COUNT(*)::text as count FROM public.teacher_student_relations WHERE teacher_id = ''00000000-0000-0000-0000-000000000001''';
        
        EXECUTE 'SELECT ''测试教师管理的学生详情'' as data_type, student_id FROM public.teacher_student_relations WHERE teacher_id = ''00000000-0000-0000-0000-000000000001'' LIMIT 5';
    ELSE
        RAISE NOTICE '师生关系表不存在';
    END IF;
END $$;

-- 6. 临时修复：创建测试数据（如果需要）
SELECT '=== 建议的修复方案 ===' as section;

SELECT 
    'Action' as fix_type,
    '1. 如果没有学生数据：运行demo学生数据插入脚本' as suggestion;

SELECT 
    'Action' as fix_type,
    '2. 如果师生关系表为空：建立师生关系' as suggestion;

SELECT 
    'Action' as fix_type,
    '3. 如果RLS启用：禁用RLS策略' as suggestion;

SELECT 
    'Action' as fix_type,
    '4. 检查前端逻辑：确保正确的教师ID' as suggestion;