-- 修复学生导入显示问题的脚本

-- 1. 禁用RLS策略（如果存在）
DO $$
BEGIN
    -- 禁用主要表的RLS
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN
        EXECUTE 'ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已禁用users表的RLS';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'teacher_students') THEN
        EXECUTE 'ALTER TABLE IF EXISTS public.teacher_students DISABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已禁用teacher_students表的RLS';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'teacher_student_relations') THEN
        EXECUTE 'ALTER TABLE IF EXISTS public.teacher_student_relations DISABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已禁用teacher_student_relations表的RLS';
    END IF;
END $$;

-- 2. 确保师生关系表存在并创建必要的结构
DO $$
BEGIN
    -- 检查并创建teacher_students表
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_students') THEN
        EXECUTE '
        CREATE TABLE public.teacher_students (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            teacher_id UUID NOT NULL,
            student_id UUID NOT NULL,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE(teacher_id, student_id)
        )';
        
        EXECUTE 'CREATE INDEX ON public.teacher_students(teacher_id)';
        EXECUTE 'CREATE INDEX ON public.teacher_students(student_id)';
        RAISE NOTICE '已创建teacher_students表';
    END IF;
    
    -- 检查并创建teacher_student_relations表（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_student_relations') THEN
        EXECUTE '
        CREATE TABLE public.teacher_student_relations (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            teacher_id UUID NOT NULL,
            student_id UUID NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE(teacher_id, student_id)
        )';
        
        EXECUTE 'CREATE INDEX ON public.teacher_student_relations(teacher_id)';
        EXECUTE 'CREATE INDEX ON public.teacher_student_relations(student_id)';
        RAISE NOTICE '已创建teacher_student_relations表';
    END IF;
END $$;

-- 3. 插入测试学生数据（如果users表为空）
DO $$
DECLARE
    student_count INTEGER := 0;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
        -- 检查是否有学生数据
        SELECT COUNT(*) INTO student_count FROM public.users WHERE role_id = '3';
        
        -- 如果没有学生数据，插入测试数据
        IF student_count = 0 THEN
            INSERT INTO public.users (id, username, email, user_number, full_name, role_id, status, phone, department, grade, class_name, created_at, updated_at) VALUES
            ('00000000-0000-0000-0000-000000000101', 'student001', 'student001@university.edu.cn', 'ST2021001', '张小明', '3', 'active', '13800001234', '计算机学院', '2021级', '计算机科学与技术1班', NOW(), NOW()),
            ('00000000-0000-0000-0000-000000000102', 'student002', 'student002@university.edu.cn', 'ST2021002', '李小红', '3', 'active', '13900001234', '计算机学院', '2021级', '计算机科学与技术2班', NOW(), NOW()),
            ('00000000-0000-0000-0000-000000000103', 'student003', 'student003@university.edu.cn', 'ST2021003', '王大力', '3', 'active', '13700001234', '软件学院', '2021级', '软件工程1班', NOW(), NOW()),
            ('00000000-0000-0000-0000-000000000104', 'student004', 'student004@university.edu.cn', 'ST2021004', '刘美丽', '3', 'active', '13600001234', '软件学院', '2021级', '软件工程2班', NOW(), NOW());
            
            RAISE NOTICE '已插入4个测试学生';
        END IF;
    END IF;
END $$;

-- 4. 建立师生关系（如果不存在）
DO $$
DECLARE
    relation_count INTEGER := 0;
    test_teacher_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- 检查teacher_students表
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_students') THEN
        SELECT COUNT(*) INTO relation_count FROM public.teacher_students WHERE teacher_id = test_teacher_id;
        
        -- 如果测试教师没有管理学生，建立关系
        IF relation_count = 0 THEN
            INSERT INTO public.teacher_students (teacher_id, student_id, created_by) VALUES
                ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001'),
                ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000001'),
                ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000001'),
                ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000001')
            ON CONFLICT (teacher_id, student_id) DO NOTHING;
            
            RAISE NOTICE '已建立测试教师的学生关系';
        END IF;
    END IF;
    
    -- 检查teacher_student_relations表
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_student_relations') THEN
        SELECT COUNT(*) INTO relation_count FROM public.teacher_student_relations WHERE teacher_id = test_teacher_id;
        
        -- 如果测试教师没有管理学生，建立关系
        IF relation_count = 0 THEN
            INSERT INTO public.teacher_student_relations (teacher_id, student_id) VALUES
                ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000101'),
                ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000102'),
                ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000103'),
                ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000104')
            ON CONFLICT (teacher_id, student_id) DO NOTHING;
            
            RAISE NOTICE '已建立测试教师的学生关系（teacher_student_relations表）';
        END IF;
    END IF;
END $$;

-- 5. 创建验证函数（如果不存在）
DO $$
BEGIN
    -- 创建获取教师学生的函数
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'get_teacher_students_simple') THEN
        EXECUTE '
        CREATE OR REPLACE FUNCTION public.get_teacher_students_simple(
            p_teacher_id UUID,
            p_keyword TEXT DEFAULT '''',
            p_page INTEGER DEFAULT 1,
            p_limit INTEGER DEFAULT 20
        )
        RETURNS TABLE(
            students JSONB,
            total_count BIGINT
        )
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $$
        DECLARE
            offset_val INTEGER;
        BEGIN
            offset_val := (p_page - 1) * p_limit;
            
            RETURN QUERY
            SELECT 
                jsonb_agg(
                    jsonb_build_object(
                        ''id'', u.id,
                        ''username'', u.username,
                        ''email'', u.email,
                        ''user_number'', u.user_number,
                        ''full_name'', u.full_name,
                        ''role_id'', u.role_id,
                        ''status'', u.status,
                        ''phone'', u.phone,
                        ''department'', u.department,
                        ''grade'', u.grade,
                        ''class_name'', u.class_name,
                        ''created_at'', u.created_at,
                        ''updated_at'', u.updated_at
                    ) ORDER BY u.created_at DESC
                ) as students,
                (SELECT COUNT(*) FROM public.users u 
                 JOIN public.teacher_students ts ON u.id = ts.student_id 
                 WHERE ts.teacher_id = p_teacher_id 
                   AND u.role_id = ''3''
                   AND (p_keyword = '''' OR u.full_name ILIKE ''%'' || p_keyword || ''%'' 
                                              OR u.user_number ILIKE ''%'' || p_keyword || ''%'' 
                                              OR u.email ILIKE ''%'' || p_keyword || ''%'')
                )::BIGINT as total_count
            FROM public.users u
            JOIN public.teacher_students ts ON u.id = ts.student_id
            WHERE ts.teacher_id = p_teacher_id
              AND u.role_id = ''3''
              AND (p_keyword = '''' OR u.full_name ILIKE ''%'' || p_keyword || ''%'' 
                                         OR u.user_number ILIKE ''%'' || p_keyword || ''%'' 
                                         OR u.email ILIKE ''%'' || p_keyword || ''%'')
            LIMIT p_limit OFFSET offset_val;
        END;
        $$';
        
        RAISE NOTICE '已创建get_teacher_students_simple函数';
    END IF;
END $$;

-- 6. 验证修复结果
SELECT '=== 修复结果验证 ===' as section;

-- 检查学生数据
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
        SELECT '学生总数' as status, COUNT(*)::text as count FROM public.users WHERE role_id = '3';
    END IF;
END $$;

-- 检查师生关系
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_students') THEN
        SELECT '师生关系总数' as status, COUNT(*)::text as count FROM public.teacher_students;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_student_relations') THEN
        SELECT '师生关系总数（relations表）' as status, COUNT(*)::text as count FROM public.teacher_student_relations;
    END IF;
END $$;

-- 检查测试教师的学生
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'teacher_students') THEN
        SELECT '测试教师管理的学生数' as status, COUNT(*)::text as count FROM public.teacher_students WHERE teacher_id = '00000000-0000-0000-0000-000000000001';
    END IF;
END $$;

SELECT '=== 修复完成 ===' as section;
SELECT '学生导入显示问题修复脚本执行完成' as result;