-- 安全的学生导入问题修复脚本
-- 只对确实存在的表进行操作

-- 1. 禁用users表的RLS（如果表存在且启用RLS）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users' AND rowsecurity = true) THEN
        EXECUTE 'ALTER TABLE public.users DISABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已禁用users表的RLS';
    END IF;
END $$;

-- 2. 禁用teacher_students表的RLS（如果表存在且启用RLS）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'teacher_students' AND rowsecurity = true) THEN
        EXECUTE 'ALTER TABLE public.teacher_students DISABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已禁用teacher_students表的RLS';
    END IF;
END $$;

-- 3. 禁用teacher_student_relations表的RLS（如果表存在且启用RLS）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'teacher_student_relations' AND rowsecurity = true) THEN
        EXECUTE 'ALTER TABLE public.teacher_student_relations DISABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已禁用teacher_student_relations表的RLS';
    END IF;
END $$;

-- 4. 创建teacher_students表（如果不存在）
CREATE TABLE IF NOT EXISTS public.teacher_students (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    teacher_id UUID NOT NULL,
    student_id UUID NOT NULL,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(teacher_id, student_id)
);

-- 5. 创建teacher_student_relations表（如果不存在）
CREATE TABLE IF NOT EXISTS public.teacher_student_relations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    teacher_id UUID NOT NULL,
    student_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(teacher_id, student_id)
);

-- 6. 插入测试学生数据到users表（如果表存在）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
        -- 插入学生1
        INSERT INTO public.users (id, username, email, user_number, full_name, role_id, status, phone, department, grade, class_name, created_at, updated_at)
        SELECT '00000000-0000-0000-0000-000000000101', 'student001', 'student001@university.edu.cn', 'ST2021001', '张小明', '3', 'active', '13800001234', '计算机学院', '2021级', '计算机科学与技术1班', NOW(), NOW()
        WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE id = '00000000-0000-0000-0000-000000000101');
        
        -- 插入学生2
        INSERT INTO public.users (id, username, email, user_number, full_name, role_id, status, phone, department, grade, class_name, created_at, updated_at)
        SELECT '00000000-0000-0000-0000-000000000102', 'student002', 'student002@university.edu.cn', 'ST2021002', '李小红', '3', 'active', '13900001234', '计算机学院', '2021级', '计算机科学与技术2班', NOW(), NOW()
        WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE id = '00000000-0000-0000-0000-000000000102');
        
        -- 插入学生3
        INSERT INTO public.users (id, username, email, user_number, full_name, role_id, status, phone, department, grade, class_name, created_at, updated_at)
        SELECT '00000000-0000-0000-0000-000000000103', 'student003', 'student003@university.edu.cn', 'ST2021003', '王大力', '3', 'active', '13700001234', '软件学院', '2021级', '软件工程1班', NOW(), NOW()
        WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE id = '00000000-0000-0000-0000-000000000103');
        
        -- 插入学生4
        INSERT INTO public.users (id, username, email, user_number, full_name, role_id, status, phone, department, grade, class_name, created_at, updated_at)
        SELECT '00000000-0000-0000-0000-000000000104', 'student004', 'student004@university.edu.cn', 'ST2021004', '刘美丽', '3', 'active', '13600001234', '软件学院', '2021级', '软件工程2班', NOW(), NOW()
        WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE id = '00000000-0000-0000-0000-000000000104');
        
        RAISE NOTICE '学生数据插入完成';
    END IF;
END $$;

-- 7. 建立师生关系
DO $$
BEGIN
    -- 在teacher_students表中建立关系（如果表存在）
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_students') THEN
        INSERT INTO public.teacher_students (teacher_id, student_id, created_by)
        SELECT '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001'
        WHERE NOT EXISTS (SELECT 1 FROM public.teacher_students WHERE teacher_id = '00000000-0000-0000-0000-000000000001' AND student_id = '00000000-0000-0000-0000-000000000101');
        
        INSERT INTO public.teacher_students (teacher_id, student_id, created_by)
        SELECT '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000001'
        WHERE NOT EXISTS (SELECT 1 FROM public.teacher_students WHERE teacher_id = '00000000-0000-0000-0000-000000000001' AND student_id = '00000000-0000-0000-0000-000000000102');
        
        INSERT INTO public.teacher_students (teacher_id, student_id, created_by)
        SELECT '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000001'
        WHERE NOT EXISTS (SELECT 1 FROM public.teacher_students WHERE teacher_id = '00000000-0000-0000-0000-000000000001' AND student_id = '00000000-0000-0000-0000-000000000103');
        
        INSERT INTO public.teacher_students (teacher_id, student_id, created_by)
        SELECT '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000001'
        WHERE NOT EXISTS (SELECT 1 FROM public.teacher_students WHERE teacher_id = '00000000-0000-0000-0000-000000000001' AND student_id = '00000000-0000-0000-0000-000000000104');
        
        RAISE NOTICE 'teacher_students表师生关系建立完成';
    END IF;
    
    -- 在teacher_student_relations表中建立关系（如果表存在）
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_student_relations') THEN
        INSERT INTO public.teacher_student_relations (teacher_id, student_id)
        SELECT '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000101'
        WHERE NOT EXISTS (SELECT 1 FROM public.teacher_student_relations WHERE teacher_id = '00000000-0000-0000-0000-000000000001' AND student_id = '00000000-0000-0000-0000-000000000101');
        
        INSERT INTO public.teacher_student_relations (teacher_id, student_id)
        SELECT '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000102'
        WHERE NOT EXISTS (SELECT 1 FROM public.teacher_student_relations WHERE teacher_id = '00000000-0000-0000-0000-000000000001' AND student_id = '00000000-0000-0000-0000-000000000102');
        
        INSERT INTO public.teacher_student_relations (teacher_id, student_id)
        SELECT '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000103'
        WHERE NOT EXISTS (SELECT 1 FROM public.teacher_student_relations WHERE teacher_id = '00000000-0000-0000-0000-000000000001' AND student_id = '00000000-0000-0000-0000-000000000103');
        
        INSERT INTO public.teacher_student_relations (teacher_id, student_id)
        SELECT '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000104'
        WHERE NOT EXISTS (SELECT 1 FROM public.teacher_student_relations WHERE teacher_id = '00000000-0000-0000-0000-000000000001' AND student_id = '00000000-0000-0000-0000-000000000104');
        
        RAISE NOTICE 'teacher_student_relations表师生关系建立完成';
    END IF;
END $$;

-- 8. 验证修复结果
SELECT '=== 修复结果验证 ===' as section;

-- 检查users表是否存在及其中的学生数据
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
        SELECT 'users表学生总数' as status, COUNT(*)::text as count 
        FROM public.users 
        WHERE role_id = '3';
    ELSE
        SELECT 'users表状态' as status, '表不存在' as count;
    END IF;
END $$;

-- 检查teacher_students表
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_students') THEN
        SELECT 'teacher_students表关系总数' as status, COUNT(*)::text as count 
        FROM public.teacher_students;
        
        SELECT '测试教师管理的学生数' as status, COUNT(*)::text as count 
        FROM public.teacher_students 
        WHERE teacher_id = '00000000-0000-0000-0000-000000000001';
    ELSE
        SELECT 'teacher_students表状态' as status, '表不存在' as count;
    END IF;
END $$;

-- 检查teacher_student_relations表
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_student_relations') THEN
        SELECT 'teacher_student_relations表关系总数' as status, COUNT(*)::text as count 
        FROM public.teacher_student_relations;
    ELSE
        SELECT 'teacher_student_relations表状态' as status, '表不存在' as count;
    END IF;
END $$;

-- 检查RLS状态
SELECT '启用RLS的表数量' as status, COUNT(*)::text as count 
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

SELECT '=== 修复完成 ===' as section;
SELECT '安全导入修复脚本执行完成！' as result;