-- 学生个人信息维护功能 - 数据库表结构和SQL脚本
-- 为Supabase手动执行

-- ==================== 系统设置表（用于控制个人信息维护功能开关） ====================
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    setting_description TEXT,
    is_editable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 插入系统设置
INSERT INTO system_settings (setting_key, setting_value, setting_description) VALUES
('student_profile_edit_enabled', 'true', '学生个人信息维护功能开关'),
('student_profile_mandatory_fields', '["full_name", "id_card", "phone", "emergency_contact", "class_name"]', '学生必填信息字段'),
('max_profile_edit_count', '3', '学生个人信息最大修改次数')
ON CONFLICT (setting_key) DO NOTHING;

-- ==================== 班级信息表 ====================
CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_name VARCHAR(100) NOT NULL UNIQUE, -- 班级名称
    class_code VARCHAR(50) UNIQUE, -- 班级代码
    grade VARCHAR(20) NOT NULL, -- 年级
    department VARCHAR(100), -- 院系
    head_teacher_id UUID REFERENCES users(id), -- 班主任
    student_count INTEGER DEFAULT 0, -- 学生人数
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==================== 学生个人信息扩展表 ====================
CREATE TABLE IF NOT EXISTS student_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 基本信息
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')), -- 性别
    birth_date DATE, -- 出生日期
    id_card VARCHAR(20), -- 身份证号
    nationality VARCHAR(50), -- 民族
    political_status VARCHAR(20), -- 政治面貌
    
    -- 联系信息
    phone VARCHAR(20), -- 手机号
    emergency_contact VARCHAR(50), -- 紧急联系人
    emergency_phone VARCHAR(20), -- 紧急联系电话
    home_address TEXT, -- 家庭地址
    
    -- 学业信息
    admission_date DATE, -- 入学日期
    graduation_date DATE, -- 毕业日期
    student_type VARCHAR(20), -- 学生类型（全日制、非全日制等）
    
    -- 班级信息
    class_id UUID REFERENCES classes(id), -- 班级ID
    class_name VARCHAR(100), -- 班级名称（冗余存储，便于查询）
    
    -- 状态信息
    profile_status VARCHAR(20) DEFAULT 'incomplete' CHECK (profile_status IN ('incomplete', 'pending', 'approved', 'rejected')),
    edit_count INTEGER DEFAULT 0, -- 修改次数
    last_edit_at TIMESTAMP WITH TIME ZONE, -- 最后修改时间
    
    -- 审核信息
    reviewed_by UUID REFERENCES users(id), -- 审核人
    reviewed_at TIMESTAMP WITH TIME ZONE, -- 审核时间
    review_notes TEXT, -- 审核意见
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_student_user UNIQUE(user_id)
);

-- ==================== 学生个人信息修改记录表 ====================
CREATE TABLE IF NOT EXISTS profile_edit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_profile_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    
    -- 修改内容
    changed_fields JSONB NOT NULL, -- 修改的字段和值
    old_values JSONB, -- 旧值
    new_values JSONB, -- 新值
    
    -- 修改信息
    edit_reason TEXT, -- 修改原因
    ip_address INET, -- IP地址
    user_agent TEXT, -- 用户代理
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==================== 学生批量操作记录表 ====================
CREATE TABLE IF NOT EXISTS student_batch_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operation_type VARCHAR(50) NOT NULL CHECK (operation_type IN ('grade_upload', 'class_change', 'status_update')),
    description TEXT NOT NULL,
    
    -- 操作数据
    operation_data JSONB NOT NULL, -- 操作的具体数据
    affected_count INTEGER DEFAULT 0, -- 受影响的学生数
    success_count INTEGER DEFAULT 0, -- 成功操作数
    failed_count INTEGER DEFAULT 0, -- 失败操作数
    
    -- 操作者信息
    operated_by UUID NOT NULL REFERENCES users(id),
    
    -- 状态信息
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    error_log TEXT, -- 错误日志
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- ==================== 创建索引 ====================
CREATE INDEX IF NOT EXISTS idx_student_profiles_user_id ON student_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_class_id ON student_profiles(class_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_status ON student_profiles(profile_status);
CREATE INDEX IF NOT EXISTS idx_classes_grade ON classes(grade);
CREATE INDEX IF NOT EXISTS idx_classes_department ON classes(department);
CREATE INDEX IF NOT EXISTS idx_profile_edit_logs_profile_id ON profile_edit_logs(student_profile_id);

-- ==================== 触发器函数 ====================
-- 更新学生班级信息时同步更新class_name
CREATE OR REPLACE FUNCTION sync_student_class_name()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.class_id IS NOT NULL THEN
        SELECT class_name INTO NEW.class_name FROM classes WHERE id = NEW.class_id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER sync_student_class_name_trigger 
    BEFORE INSERT OR UPDATE ON student_profiles
    FOR EACH ROW EXECUTE FUNCTION sync_student_class_name();

-- 更新班级学生人数
CREATE OR REPLACE FUNCTION update_class_student_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.class_id IS DISTINCT FROM NEW.class_id) THEN
        -- 更新新班级学生数
        IF NEW.class_id IS NOT NULL THEN
            UPDATE classes 
            SET student_count = (
                SELECT COUNT(*) FROM student_profiles 
                WHERE class_id = NEW.class_id AND profile_status != 'rejected'
            )
            WHERE id = NEW.class_id;
        END IF;
        
        -- 更新旧班级学生数
        IF TG_OP = 'UPDATE' AND OLD.class_id IS NOT NULL AND OLD.class_id != NEW.class_id THEN
            UPDATE classes 
            SET student_count = (
                SELECT COUNT(*) FROM student_profiles 
                WHERE class_id = OLD.class_id AND profile_status != 'rejected'
            )
            WHERE id = OLD.class_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_class_student_count_trigger 
    AFTER INSERT OR UPDATE OR DELETE ON student_profiles
    FOR EACH ROW EXECUTE FUNCTION update_class_student_count();

-- ==================== 视图：学生完整信息视图 ====================
CREATE OR REPLACE VIEW student_complete_info AS
SELECT 
    u.id as user_id,
    u.username,
    u.email,
    u.user_number,
    u.full_name,
    u.status as user_status,
    u.phone as user_phone,
    u.department,
    u.grade,
    u.class_name as user_class_name,
    
    sp.id as profile_id,
    sp.gender,
    sp.birth_date,
    sp.id_card,
    sp.nationality,
    sp.political_status,
    sp.phone as profile_phone,
    sp.emergency_contact,
    sp.emergency_phone,
    sp.home_address,
    sp.admission_date,
    sp.graduation_date,
    sp.student_type,
    sp.class_id,
    sp.class_name as profile_class_name,
    sp.profile_status,
    sp.edit_count,
    sp.last_edit_at,
    sp.reviewed_by,
    sp.reviewed_at,
    sp.review_notes,
    
    c.class_code,
    c.head_teacher_id,
    c.student_count,
    c.status as class_status,
    
    CASE 
        WHEN sp.profile_status = 'approved' THEN '已完善'
        WHEN sp.profile_status = 'pending' THEN '待审核'
        WHEN sp.profile_status = 'rejected' THEN '需修改'
        ELSE '未完善'
    END as profile_status_text
    
FROM users u
LEFT JOIN student_profiles sp ON u.id = sp.user_id
LEFT JOIN classes c ON sp.class_id = c.id
WHERE u.role_id = (SELECT id FROM roles WHERE role_name = 'student');

-- ==================== 存储过程：学生初始化个人信息 ====================
CREATE OR REPLACE FUNCTION initialize_student_profile(
    p_user_id UUID
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_profile_id UUID;
    v_user_record RECORD;
    v_max_edit_count INTEGER;
BEGIN
    -- 获取系统设置
    SELECT setting_value::INTEGER INTO v_max_edit_count 
    FROM system_settings 
    WHERE setting_key = 'max_profile_edit_count';
    
    -- 获取用户信息
    SELECT * INTO v_user_record FROM users WHERE id = p_user_id;
    
    -- 创建学生个人信息记录
    INSERT INTO student_profiles (
        user_id,
        class_name,
        profile_status,
        edit_count
    ) VALUES (
        p_user_id,
        v_user_record.class_name,
        'incomplete',
        0
    )
    RETURNING id INTO v_profile_id;
    
    RETURN v_profile_id;
END;
$$;

-- ==================== 存储过程：提交学生个人信息 ====================
CREATE OR REPLACE FUNCTION submit_student_profile(
    p_profile_id UUID,
    p_profile_data JSONB,
    p_edit_reason TEXT DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_profile_record RECORD;
    v_mandatory_fields JSONB;
    v_missing_fields TEXT[];
    v_field TEXT;
    v_max_edit_count INTEGER;
    v_is_enabled BOOLEAN;
BEGIN
    -- 检查功能是否启用
    SELECT setting_value::BOOLEAN INTO v_is_enabled 
    FROM system_settings 
    WHERE setting_key = 'student_profile_edit_enabled';
    
    IF NOT v_is_enabled THEN
        RAISE EXCEPTION '学生个人信息维护功能已禁用';
    END IF;
    
    -- 获取必填字段
    SELECT setting_value::JSONB INTO v_mandatory_fields 
    FROM system_settings 
    WHERE setting_key = 'student_profile_mandatory_fields';
    
    -- 获取最大修改次数
    SELECT setting_value::INTEGER INTO v_max_edit_count 
    FROM system_settings 
    WHERE setting_key = 'max_profile_edit_count';
    
    -- 检查修改次数限制
    SELECT * INTO v_profile_record FROM student_profiles WHERE id = p_profile_id;
    
    IF v_profile_record.edit_count >= v_max_edit_count AND v_profile_record.profile_status != 'incomplete' THEN
        RAISE EXCEPTION '已达到最大修改次数限制 (%)', v_max_edit_count;
    END IF;
    
    -- 检查必填字段
    v_missing_fields := ARRAY[]::TEXT[];
    
    FOREACH v_field IN ARRAY ARRAY(SELECT jsonb_array_elements_text(v_mandatory_fields))
    LOOP
        IF p_profile_data->>v_field IS NULL OR p_profile_data->>v_field = '' THEN
            v_missing_fields := array_append(v_missing_fields, v_field);
        END IF;
    END LOOP;
    
    IF array_length(v_missing_fields, 1) > 0 THEN
        RAISE EXCEPTION '缺少必填字段: %', array_to_string(v_missing_fields, ', ');
    END IF;
    
    -- 更新学生个人信息
    UPDATE student_profiles 
    SET 
        gender = p_profile_data->>'gender',
        birth_date = (p_profile_data->>'birth_date')::DATE,
        id_card = p_profile_data->>'id_card',
        nationality = p_profile_data->>'nationality',
        political_status = p_profile_data->>'political_status',
        phone = p_profile_data->>'phone',
        emergency_contact = p_profile_data->>'emergency_contact',
        emergency_phone = p_profile_data->>'emergency_phone',
        home_address = p_profile_data->>'home_address',
        admission_date = (p_profile_data->>'admission_date')::DATE,
        graduation_date = (p_profile_data->>'graduation_date')::DATE,
        student_type = p_profile_data->>'student_type',
        profile_status = 'pending',
        edit_count = edit_count + 1,
        last_edit_at = NOW(),
        updated_at = NOW()
    WHERE id = p_profile_id;
    
    -- 记录修改日志
    INSERT INTO profile_edit_logs (
        student_profile_id,
        user_id,
        changed_fields,
        old_values,
        new_values,
        edit_reason
    ) VALUES (
        p_profile_id,
        v_profile_record.user_id,
        p_profile_data,
        to_jsonb(v_profile_record),
        p_profile_data,
        p_edit_reason
    );
    
    RETURN TRUE;
END;
$$;

-- ==================== 存储过程：审核学生个人信息 ====================
CREATE OR REPLACE FUNCTION review_student_profile(
    p_profile_id UUID,
    p_review_result VARCHAR, -- 'approved' or 'rejected'
    p_reviewed_by UUID,
    p_review_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE student_profiles 
    SET 
        profile_status = p_review_result,
        reviewed_by = p_reviewed_by,
        reviewed_at = NOW(),
        review_notes = p_review_notes,
        updated_at = NOW()
    WHERE id = p_profile_id;
    
    RETURN TRUE;
END;
$$;

-- ==================== 插入示例数据 ====================
-- 插入示例班级
INSERT INTO classes (class_name, class_code, grade, department) VALUES
('计算机科学与技术1班', 'CS202101', '2021级', '计算机学院'),
('计算机科学与技术2班', 'CS202102', '2021级', '计算机学院'),
('软件工程1班', 'SE202101', '2021级', '软件学院')
ON CONFLICT (class_name) DO NOTHING;

-- 更新学生示例数据的班级信息
UPDATE users 
SET class_name = '计算机科学与技术1班'
WHERE username = 'student_2021001';

-- 初始化学生个人信息
DO $$
DECLARE
    v_student_id UUID;
    v_profile_id UUID;
    v_student_full_name TEXT;
    v_student_class_name TEXT;
    v_profile_data JSONB;
BEGIN
    SELECT id, full_name, class_name INTO v_student_id, v_student_full_name, v_student_class_name 
    FROM users WHERE username = 'student_2021001';
    
    IF v_student_id IS NOT NULL THEN
        SELECT initialize_student_profile(v_student_id) INTO v_profile_id;
        
        -- 构建JSON数据（使用jsonb_build_object避免格式问题）
        v_profile_data := jsonb_build_object(
            'full_name', v_student_full_name,
            'class_name', v_student_class_name,
            'gender', 'male',
            'birth_date', '2000-01-01',
            'id_card', '11010120000101001X',
            'nationality', '汉族',
            'political_status', '团员',
            'phone', '13800138000',
            'emergency_contact', '父亲',
            'emergency_phone', '13800138001',
            'home_address', '北京市海淀区',
            'admission_date', '2021-09-01',
            'graduation_date', '2025-06-30',
            'student_type', '全日制'
        );
        
        -- 提交示例个人信息（包含必填字段）
        PERFORM submit_student_profile(
            v_profile_id,
            v_profile_data,
            '首次提交个人信息'
        );
        
        -- 审核通过
        PERFORM review_student_profile(v_profile_id, 'approved', 
            (SELECT id FROM users WHERE username = 'teacher_zhang'), '信息完整，审核通过');
    END IF;
END $$;

-- ==================== 启用行级安全策略 ====================
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_edit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_batch_operations ENABLE ROW LEVEL SECURITY;

-- 系统设置策略：只有超级管理员可修改
CREATE POLICY "系统设置管理策略" ON system_settings
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id = (SELECT id FROM roles WHERE role_name = 'super_admin')
    ));

-- 班级策略：教师和管理员可管理
CREATE POLICY "班级管理策略" ON classes
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id IN (
            SELECT id FROM roles WHERE role_name IN ('super_admin', 'teacher')
        )
    ));

-- 学生个人信息策略：学生只能查看和修改自己的信息
CREATE POLICY "学生个人信息策略" ON student_profiles
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "学生个人信息更新策略" ON student_profiles
    FOR UPDATE USING (user_id = auth.uid());

-- 教师和管理员可以查看所有学生信息
CREATE POLICY "教师查看学生信息策略" ON student_profiles
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role_id IN (
            SELECT id FROM roles WHERE role_name IN ('super_admin', 'teacher')
        )
    ));

-- ==================== 查询示例 ====================
-- 查看所有学生完整信息
-- SELECT * FROM student_complete_info;

-- 查看待审核的学生信息
-- SELECT * FROM student_complete_info WHERE profile_status = 'pending';

-- 查看班级学生统计
-- SELECT class_name, grade, student_count FROM classes ORDER BY grade, class_name;

-- 查看学生个人信息修改记录
-- SELECT * FROM profile_edit_logs ORDER BY created_at DESC;