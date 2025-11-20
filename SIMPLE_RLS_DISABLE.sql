-- 简单RLS禁用脚本
-- 直接在Supabase SQL编辑器中执行此文件

-- 步骤1: 禁用主要表的RLS
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teachers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.student_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_student_relations DISABLE ROW LEVEL SECURITY;

-- 步骤2: 删除所有相关策略
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own user profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own user profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Students can view own data" ON public.students;
DROP POLICY IF EXISTS "Teachers can view students" ON public.students;
DROP POLICY IF EXISTS "Teachers can update students" ON public.students;
DROP POLICY IF EXISTS "Teachers can view own data" ON public.teachers;
DROP POLICY IF EXISTS "Teachers can update own data" ON public.teachers;
DROP POLICY IF EXISTS "Student profiles are viewable by everyone" ON public.student_profiles;
DROP POLICY IF EXISTS "Students can update own profile" ON public.student_profiles;
DROP POLICY IF EXISTS "Teachers can view student profiles" ON public.student_profiles;
DROP POLICY IF EXISTS "Teacher profiles are viewable by everyone" ON public.teacher_profiles;
DROP POLICY IF EXISTS "Teachers can update own profile" ON public.teacher_profiles;
DROP POLICY IF EXISTS "Teacher student relations are viewable by related users" ON public.teacher_student_relations;
DROP POLICY IF EXISTS "Teachers can manage own student relations" ON public.teacher_student_relations;

-- 步骤3: 验证结果
SELECT 
    'RLS Status After Disable' as status,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('users', 'user_profiles', 'students', 'teachers', 'student_profiles', 'teacher_profiles', 'teacher_student_relations')
ORDER BY tablename;

SELECT 
    'Remaining Policies' as status,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public';

-- 完成提示
SELECT 'All RLS policies have been disabled!' as result;