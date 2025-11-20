-- 简单清理RLS脚本 - 修复语法错误
-- 分步执行，避免复杂语法问题

-- 步骤1: 禁用已知表的RLS（忽略表不存在错误）
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teachers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.student_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_student_relations DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.classes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.enrollments DISABLE ROW LEVEL SECURITY;

-- 步骤2: 删除常见策略
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Students can view own data" ON public.students;
DROP POLICY IF EXISTS "Teachers can view students" ON public.students;
DROP POLICY IF EXISTS "Teachers can update students" ON public.students;
DROP POLICY IF EXISTS "Teachers can view own data" ON public.teachers;
DROP POLICY IF EXISTS "Teachers can update own data" ON public.teachers;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.user_profiles;
DROP POLICY IF EXISTS "Student profiles are viewable by everyone" ON public.student_profiles;
DROP POLICY IF EXISTS "Students can update own profile" ON public.student_profiles;
DROP POLICY IF EXISTS "Teachers can view student profiles" ON public.student_profiles;
DROP POLICY IF EXISTS "Teacher profiles are viewable by everyone" ON public.teacher_profiles;
DROP POLICY IF EXISTS "Teachers can update own profile" ON public.teacher_profiles;
DROP POLICY IF EXISTS "Teacher student relations are viewable by related users" ON public.teacher_student_relations;
DROP POLICY IF EXISTS "Teachers can manage own student relations" ON public.teacher_student_relations;

-- 步骤3: 检查结果
SELECT 
    'RLS Status Check' as check_type,
    COUNT(*)::text as count
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

SELECT 
    'Policies Remaining' as check_type,
    COUNT(*)::text as count
FROM pg_policies 
WHERE schemaname = 'public';

SELECT 'RLS disable operation completed!' as result;