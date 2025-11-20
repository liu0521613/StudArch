-- 简化版学生导入问题修复脚本
-- 避免复杂PL/pgSQL语法，使用简单SQL语句

-- 1. 禁用所有RLS策略
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_students DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_student_relations DISABLE ROW LEVEL SECURITY;

-- 2. 删除所有RLS策略（只删除存在的表的策略）
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own user profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own user profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own user profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Students can view own data" ON public.students;
DROP POLICY IF EXISTS "Teachers can view students" ON public.students;
DROP POLICY IF EXISTS "Teachers can update students" ON public.students;
DROP POLICY IF EXISTS "Students can insert own data" ON public.students;
DROP POLICY IF EXISTS "Teachers can view own data" ON public.teachers;
DROP POLICY IF EXISTS "Teachers can update own data" ON public.teachers;
DROP POLICY IF EXISTS "Teachers can insert own data" ON public.teachers;
DROP POLICY IF EXISTS "Student profiles are viewable by everyone" ON public.student_profiles;
DROP POLICY IF EXISTS "Students can update own profile" ON public.student_profiles;
DROP POLICY IF EXISTS "Teachers can view student profiles" ON public.student_profiles;
DROP POLICY IF EXISTS "Teacher profiles are viewable by everyone" ON public.teacher_profiles;
DROP POLICY IF EXISTS "Teachers can update own profile" ON public.teacher_profiles;
DROP POLICY IF EXISTS "Teacher student relations are viewable by related users" ON public.teacher_student_relations;
DROP POLICY IF EXISTS "Teachers can manage own student relations" ON public.teacher_student_relations;

-- 3. 创建teacher_students表（如果不存在）
CREATE TABLE IF NOT EXISTS public.teacher_students (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    teacher_id UUID NOT NULL,
    student_id UUID NOT NULL,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(teacher_id, student_id)
);

-- 4. 创建teacher_student_relations表（如果不存在）
CREATE TABLE IF NOT EXISTS public.teacher_student_relations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    teacher_id UUID NOT NULL,
    student_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(teacher_id, student_id)
);

-- 5. 插入测试学生数据（如果不存在）
INSERT INTO public.users (id, username, email, user_number, full_name, role_id, status, phone, department, grade, class_name, created_at, updated_at)
SELECT '00000000-0000-0000-0000-000000000101', 'student001', 'student001@university.edu.cn', 'ST2021001', '张小明', '3', 'active', '13800001234', '计算机学院', '2021级', '计算机科学与技术1班', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE id = '00000000-0000-0000-0000-000000000101');

INSERT INTO public.users (id, username, email, user_number, full_name, role_id, status, phone, department, grade, class_name, created_at, updated_at)
SELECT '00000000-0000-0000-0000-000000000102', 'student002', 'student002@university.edu.cn', 'ST2021002', '李小红', '3', 'active', '13900001234', '计算机学院', '2021级', '计算机科学与技术2班', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE id = '00000000-0000-0000-0000-000000000102');

INSERT INTO public.users (id, username, email, user_number, full_name, role_id, status, phone, department, grade, class_name, created_at, updated_at)
SELECT '00000000-0000-0000-0000-000000000103', 'student003', 'student003@university.edu.cn', 'ST2021003', '王大力', '3', 'active', '13700001234', '软件学院', '2021级', '软件工程1班', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE id = '00000000-0000-0000-0000-000000000103');

INSERT INTO public.users (id, username, email, user_number, full_name, role_id, status, phone, department, grade, class_name, created_at, updated_at)
SELECT '00000000-0000-0000-0000-000000000104', 'student004', 'student004@university.edu.cn', 'ST2021004', '刘美丽', '3', 'active', '13600001234', '软件学院', '2021级', '软件工程2班', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE id = '00000000-0000-0000-0000-000000000104');

-- 6. 建立师生关系（如果不存在）
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

-- 7. 同样在teacher_student_relations表中建立关系（如果表存在）
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

-- 8. 验证修复结果
SELECT '=== 修复结果验证 ===' as section;

-- 检查学生数据
SELECT '学生总数' as status, COUNT(*)::text as count 
FROM public.users 
WHERE role_id = '3';

-- 检查师生关系
SELECT '师生关系总数（teacher_students表）' as status, COUNT(*)::text as count 
FROM public.teacher_students;

SELECT '师生关系总数（relations表）' as status, COUNT(*)::text as count 
FROM public.teacher_student_relations;

-- 检查测试教师管理的学生
SELECT '测试教师管理的学生数' as status, COUNT(*)::text as count 
FROM public.teacher_students 
WHERE teacher_id = '00000000-0000-0000-0000-000000000001';

-- 检查RLS状态
SELECT '启用RLS的表数量' as status, COUNT(*)::text as count 
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

SELECT '剩余策略数量' as status, COUNT(*)::text as count 
FROM pg_policies 
WHERE schemaname = 'public';

SELECT '=== 修复完成 ===' as section;
SELECT '学生导入问题修复脚本执行完成！' as result;