-- 修复版本：测试数据初始化（修复password_hash遗漏问题）
-- 在Supabase SQL Editor中执行此脚本

-- 1. 先检查现有表结构，如果需要扩展users表
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS department VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS grade VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS class_name VARCHAR(100);

-- 2. 插入角色数据（如果不存在）
INSERT INTO roles (id, role_name, role_description, permissions, is_system_default) VALUES
('1', 'super_admin', '超级管理员', '{"manage_users": true, "manage_roles": true, "manage_system": true}', true),
('2', 'teacher', '教师', '{"manage_students": true, "review_profiles": true}', true),
('3', 'student', '学生', '{"view_profile": true, "edit_profile": true}', true)
ON CONFLICT (role_name) DO NOTHING;

-- 3. 插入测试用户数据（包含必填的password_hash字段）
INSERT INTO users (id, username, email, user_number, full_name, password_hash, role_id, status, phone, department, grade, class_name) VALUES
-- 学生用户（使用UUID格式）
('11111111-1111-1111-1111-111111111111', 'student_2021001', 'student_2021001@example.com', '2021001', '李小明', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '3', 'active', '13800138000', '计算机学院', '2021级', '计算机科学与技术1班'),
('11111111-1111-1111-1111-111111111112', 'student_2021002', 'student_2021002@example.com', '2021002', '王小红', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '3', 'active', '13800138001', '计算机学院', '2021级', '计算机科学与技术1班'),
('11111111-1111-1111-1111-111111111113', 'student_2021003', 'student_2021003@example.com', '2021003', '张伟', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '3', 'active', '13800138002', '软件学院', '2021级', '软件工程1班'),
-- 教师用户（使用UUID格式）
('11111111-1111-1111-1111-111111111121', 'teacher_zhang', 'teacher_zhang@example.com', 'T001', '张老师', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '2', 'active', '13800138003', '计算机学院', NULL, NULL),
('11111111-1111-1111-1111-111111111122', 'teacher_wang', 'teacher_wang@example.com', 'T002', '王老师', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '2', 'active', '13800138004', '软件学院', NULL, NULL),
-- 管理员用户（使用UUID格式）
('11111111-1111-1111-1111-111111111131', 'admin', 'admin@example.com', 'A001', '系统管理员', '$2a$10$rOz8R7lTQyX3c8k8V7M8Ou', '1', 'active', '13800138005', NULL, NULL, NULL)
ON CONFLICT (username) DO NOTHING;

-- 4. 插入班级数据（使用UUID格式）
INSERT INTO classes (id, class_name, class_code, grade, department, head_teacher_id) VALUES
('11111111-1111-1111-1111-111111111141', '计算机科学与技术1班', 'CS202101', '2021级', '计算机学院', '11111111-1111-1111-1111-111111111121'),
('11111111-1111-1111-1111-111111111142', '计算机科学与技术2班', 'CS202102', '2021级', '计算机学院', NULL),
('11111111-1111-1111-1111-111111111143', '软件工程1班', 'SE202101', '2021级', '软件学院', '11111111-1111-1111-1111-111111111122')
ON CONFLICT (class_name) DO NOTHING;

-- 5. 创建系统设置（如果不存在）
INSERT INTO system_settings (setting_key, setting_value, setting_description, is_editable) VALUES
('max_profile_edit_count', '3', '学生个人信息最大修改次数', true),
('profile_auto_approve', 'false', '是否自动审核通过个人信息', true)
ON CONFLICT (setting_key) DO NOTHING;

-- 6. 初始化学生个人信息
DO $$
DECLARE
    v_student_id UUID;
    v_profile_id UUID;
    v_student_record RECORD;
    v_max_edit_count INTEGER;
BEGIN
    -- 获取系统设置
    SELECT setting_value::INTEGER INTO v_max_edit_count 
    FROM system_settings 
    WHERE setting_key = 'max_profile_edit_count';
    
    -- 为每个学生初始化个人信息
    FOR v_student_record IN 
        SELECT u.id, u.username, u.full_name, u.class_name 
        FROM users u 
        WHERE u.role_id = '3'
    LOOP
        -- 检查是否已有个人信息
        SELECT id INTO v_profile_id FROM student_profiles WHERE user_id = v_student_record.id;
        
        IF v_profile_id IS NULL THEN
            -- 初始化学生个人信息
            INSERT INTO student_profiles (user_id, profile_data, profile_status, edit_count, max_edit_count)
            VALUES (v_student_record.id, '{}', 'draft', 0, COALESCE(v_max_edit_count, 3))
            RETURNING id INTO v_profile_id;
            
            RAISE NOTICE '已为学生 % 初始化个人信息', v_student_record.full_name;
        ELSE
            RAISE NOTICE '学生 % 已有个人信息，跳过初始化', v_student_record.full_name;
        END IF;
    END LOOP;
END $$;

-- 7. 为测试学生李小明创建完整的个人信息数据
DO $$
DECLARE
    v_profile_id UUID;
    v_profile_data JSONB;
    v_student_record RECORD;
BEGIN
    -- 获取李小明的用户信息和班级信息
    SELECT u.id, u.full_name, u.class_name, c.id as class_id
    INTO v_student_record
    FROM users u
    LEFT JOIN classes c ON u.class_name = c.class_name
    WHERE u.username = 'student_2021001';
    
    IF v_student_record.id IS NOT NULL THEN
        -- 获取个人信息ID
        SELECT id INTO v_profile_id FROM student_profiles WHERE user_id = v_student_record.id;
        
        IF v_profile_id IS NULL THEN
            -- 初始化个人信息
            INSERT INTO student_profiles (user_id, profile_data, profile_status, edit_count, max_edit_count)
            VALUES (v_student_record.id, '{}', 'draft', 0, 3)
            RETURNING id INTO v_profile_id;
        END IF;
        
        -- 构建完整的个人信息数据
        v_profile_data := jsonb_build_object(
            'gender', 'male',
            'birth_date', '2000-01-01',
            'id_card', '11010120000101001X',
            'nationality', '汉族',
            'political_status', '团员',
            'phone', '13800138000',
            'emergency_contact', '李建国',
            'emergency_phone', '13800138000',
            'home_address', '北京市朝阳区建国路100号',
            'admission_date', '2021-09-01',
            'graduation_date', '2025-06-30',
            'student_type', '全日制',
            'class_name', v_student_record.class_name,
            'class_id', v_student_record.class_id
        );
        
        -- 更新个人信息（手动提交）
        UPDATE student_profiles 
        SET 
            profile_data = v_profile_data,
            profile_status = 'approved',
            edit_count = 1,
            last_edit_time = NOW(),
            reviewer_id = '11111111-1111-1111-1111-111111111131',
            review_time = NOW(),
            review_comment = '测试数据，审核通过'
        WHERE id = v_profile_id;
        
        RAISE NOTICE '已为李小明创建完整的个人信息';
    ELSE
        RAISE NOTICE '未找到李小明的用户记录';
    END IF;
END $$;

-- 8. 验证数据
SELECT 
    u.username, 
    u.full_name, 
    u.department, 
    u.grade, 
    u.class_name,
    sp.profile_status,
    sp.edit_count
FROM users u
LEFT JOIN student_profiles sp ON u.id = sp.user_id
WHERE u.role_id = '3'
ORDER BY u.user_number;

-- 9. 提供登录信息提示
SELECT 
    '测试登录信息：' as info,
    username,
    '密码：123456' as password_hint,
    full_name,
    role_name
FROM users u
JOIN roles r ON u.role_id = r.id
WHERE u.username IN ('student_2021001', 'teacher_zhang', 'admin');