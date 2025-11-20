-- 删除所有 RLS 策略的脚本
-- 此脚本将删除所有表上的行级安全策略

-- 1. 首先查看当前所有启用了 RLS 的表
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE rowsecurity = true 
    AND schemaname = 'public';

-- 2. 查看所有存在的 RLS 策略
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public';

-- 3. 禁用所有表的 RLS
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teachers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.enrollments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.student_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.classes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.grades DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.schedules DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.subjects DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.semesters DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.departments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.permissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_student_relations DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_classes DISABLE ROW LEVEL SECURITY;

-- 4. 删除所有 RLS 策略
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
DROP POLICY IF EXISTS "Courses are viewable by everyone" ON public.courses;
DROP POLICY IF EXISTS "Teachers can manage own courses" ON public.courses;
DROP POLICY IF EXISTS "Students can view enrolled courses" ON public.courses;
DROP POLICY IF EXISTS "Enrollments are viewable by related users" ON public.enrollments;
DROP POLICY IF EXISTS "Students can manage own enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Teachers can manage course enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Student profiles are viewable by everyone" ON public.student_profiles;
DROP POLICY IF EXISTS "Students can update own profile" ON public.student_profiles;
DROP POLICY IF EXISTS "Teachers can view student profiles" ON public.student_profiles;
DROP POLICY IF EXISTS "Teacher profiles are viewable by everyone" ON public.teacher_profiles;
DROP POLICY IF EXISTS "Teachers can update own profile" ON public.teacher_profiles;
DROP POLICY IF EXISTS "Classes are viewable by everyone" ON public.classes;
DROP POLICY IF EXISTS "Teachers can manage own classes" ON public.classes;
DROP POLICY IF EXISTS "Students can view enrolled classes" ON public.classes;
DROP POLICY IF EXISTS "Assignments are viewable by related users" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can manage own assignments" ON public.assignments;
DROP POLICY IF EXISTS "Submissions are viewable by related users" ON public.submissions;
DROP POLICY IF EXISTS "Students can manage own submissions" ON public.submissions;
DROP POLICY IF EXISTS "Teachers can grade submissions" ON public.submissions;
DROP POLICY IF EXISTS "Grades are viewable by related users" ON public.grades;
DROP POLICY IF EXISTS "Students can view own grades" ON public.grades;
DROP POLICY IF EXISTS "Teachers can manage course grades" ON public.grades;
DROP POLICY IF EXISTS "Attendance records are viewable by related users" ON public.attendance;
DROP POLICY IF EXISTS "Teachers can manage own class attendance" ON public.attendance;
DROP POLICY IF EXISTS "Students can view own attendance" ON public.attendance;
DROP POLICY IF EXISTS "Notifications are viewable by recipient" ON public.notifications;
DROP POLICY IF EXISTS "Users can manage own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Messages are viewable by participants" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
DROP POLICY IF EXISTS "Documents are viewable by authorized users" ON public.documents;
DROP POLICY IF EXISTS "Users can manage own documents" ON public.documents;
DROP POLICY IF EXISTS "Schedules are viewable by related users" ON public.schedules;
DROP POLICY IF EXISTS "Teachers can manage own schedules" ON public.schedules;
DROP POLICY IF EXISTS "Students can view own schedules" ON public.schedules;
DROP POLICY IF EXISTS "Subjects are viewable by everyone" ON public.subjects;
DROP POLICY IF EXISTS "Teachers can manage subjects" ON public.subjects;
DROP POLICY IF EXISTS "Semesters are viewable by everyone" ON public.semesters;
DROP POLICY IF EXISTS "Admins can manage semesters" ON public.semesters;
DROP POLICY IF EXISTS "Departments are viewable by everyone" ON public.departments;
DROP POLICY IF EXISTS "Admins can manage departments" ON public.departments;
DROP POLICY IF EXISTS "Roles are viewable by authenticated users" ON public.roles;
DROP POLICY IF EXISTS "Admins can manage roles" ON public.roles;
DROP POLICY IF EXISTS "Permissions are viewable by authenticated users" ON public.permissions;
DROP POLICY IF EXISTS "Admins can manage permissions" ON public.permissions;
DROP POLICY IF EXISTS "User roles are viewable by authenticated users" ON public.user_roles;
DROP POLICY IF EXISTS "Users can view own roles" ON public.user_roles;
DROP POLICY IF EXISTS "Admins can manage user roles" ON public.user_roles;
DROP POLICY IF EXISTS "Teacher student relations are viewable by related users" ON public.teacher_student_relations;
DROP POLICY IF EXISTS "Teachers can manage own student relations" ON public.teacher_student_relations;
DROP POLICY IF EXISTS "Teacher classes are viewable by related users" ON public.teacher_classes;
DROP POLICY IF EXISTS "Teachers can manage own classes" ON public.teacher_classes;
DROP POLICY IF EXISTS "Students can view teacher classes" ON public.teacher_classes;

-- 5. 通用清理：删除任何剩余的策略
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                     r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- 6. 通用禁用RLS：确保所有表都禁用了RLS
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' AND rowsecurity = true
    LOOP
        EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY', r.tablename);
    END LOOP;
END $$;

-- 7. 验证结果
SELECT 
    'Tables with RLS enabled after cleanup:' as status,
    COUNT(*) as count
FROM pg_tables 
WHERE rowsecurity = true 
    AND schemaname = 'public';

SELECT 
    'Policies remaining after cleanup:' as status,
    COUNT(*) as count
FROM pg_policies 
WHERE schemaname = 'public';

-- 完成提示
SELECT 'All RLS policies have been successfully removed!' as result;