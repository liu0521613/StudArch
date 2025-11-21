-- 简化的毕业去向数据导入存储过程
CREATE OR REPLACE FUNCTION simple_import_graduation_data(
    p_student_number TEXT,
    p_destination_type TEXT,
    p_company_name TEXT DEFAULT NULL,
    p_position TEXT DEFAULT NULL,
    p_salary NUMERIC DEFAULT NULL,
    p_work_location TEXT DEFAULT NULL,
    p_school_name TEXT DEFAULT NULL,
    p_major TEXT DEFAULT NULL,
    p_degree TEXT DEFAULT NULL,
    p_abroad_country TEXT DEFAULT NULL,
    p_startup_name TEXT DEFAULT NULL,
    p_startup_role TEXT DEFAULT NULL,
    p_other_description TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    student_record RECORD;
    existing_record RECORD;
    new_record_id UUID;
BEGIN
    -- 验证去向类型
    IF p_destination_type NOT IN ('employment', 'furtherstudy', 'abroad', 'entrepreneurship', 'unemployed', 'other') THEN
        RETURN 'ERROR: 无效的去向类型: ' || COALESCE(p_destination_type, 'NULL');
    END IF;
    
    -- 查找学生记录
    SELECT id INTO student_record 
    FROM student_profiles 
    WHERE student_number = p_student_number;
    
    IF student_record IS NULL THEN
        RETURN 'ERROR: 找不到学号为 ' || COALESCE(p_student_number, 'NULL') || ' 的学生';
    END IF;
    
    -- 检查是否已存在毕业去向记录
    SELECT id INTO existing_record
    FROM graduation_destinations 
    WHERE student_id = student_record.id;
    
    IF existing_record IS NOT NULL THEN
        -- 更新现有记录
        UPDATE graduation_destinations SET
            destination_type = p_destination_type,
            company_name = p_company_name,
            position = p_position,
            salary = p_salary,
            work_location = p_work_location,
            school_name = p_school_name,
            major = p_major,
            degree = p_degree,
            abroad_country = p_abroad_country,
            startup_name = p_startup_name,
            startup_role = p_startup_role,
            other_description = p_other_description,
            status = 'pending',
            updated_at = NOW()
        WHERE id = existing_record.id;
        
        RETURN 'SUCCESS: 更新学生 ' || p_student_number || ' 的毕业去向成功';
    ELSE
        -- 创建新记录
        INSERT INTO graduation_destinations (
            student_id,
            destination_type,
            company_name,
            position,
            salary,
            work_location,
            school_name,
            major,
            degree,
            abroad_country,
            startup_name,
            startup_role,
            other_description,
            status,
            submit_time,
            created_at,
            updated_at
        ) VALUES (
            student_record.id,
            p_destination_type,
            p_company_name,
            p_position,
            p_salary,
            p_work_location,
            p_school_name,
            p_major,
            p_degree,
            p_abroad_country,
            p_startup_name,
            p_startup_role,
            p_other_description,
            'pending',
            NOW(),
            NOW(),
            NOW()
        ) RETURNING id INTO new_record_id;
        
        RETURN 'SUCCESS: 导入学生 ' || p_student_number || ' 的毕业去向成功';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 删除现有表并重新创建（以移除外键约束）
DROP TABLE IF EXISTS graduation_import_batches CASCADE;
DROP TABLE IF EXISTS graduation_import_failures CASCADE;

-- 创建导入批次表（无外键约束）
CREATE TABLE graduation_import_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_name TEXT NOT NULL,
    filename TEXT,
    total_count INTEGER NOT NULL DEFAULT 0,
    success_count INTEGER NOT NULL DEFAULT 0,
    failed_count INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
    error_details JSONB DEFAULT '[]',
    imported_by TEXT, -- 纯文本类型，无外键约束
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建导入失败记录表
CREATE TABLE graduation_import_failures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES graduation_import_batches(id) ON DELETE CASCADE,
    row_number INTEGER NOT NULL,
    student_id UUID REFERENCES student_profiles(id),
    error_message TEXT NOT NULL,
    original_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建导入失败记录表（如果不存在）
CREATE TABLE IF NOT EXISTS graduation_import_failures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES graduation_import_batches(id) ON DELETE CASCADE,
    row_number INTEGER NOT NULL,
    student_id UUID REFERENCES student_profiles(id),
    error_message TEXT NOT NULL,
    original_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_graduation_import_batches_imported_by ON graduation_import_batches(imported_by);
CREATE INDEX IF NOT EXISTS idx_graduation_import_failures_batch_id ON graduation_import_failures(batch_id);

-- 插入测试数据（可选）
DO $$
BEGIN
    -- 检查是否有学生数据，如果没有则插入一些测试数据
    IF NOT EXISTS (SELECT 1 FROM student_profiles LIMIT 1) THEN
        INSERT INTO student_profiles (student_number, full_name, class_name, created_at, updated_at) VALUES
        ('2021001', '张三', '计算机科学与技术1班', NOW(), NOW()),
        ('2021002', '李四', '计算机科学与技术1班', NOW(), NOW()),
        ('2021003', '王五', '软件工程1班', NOW(), NOW()),
        ('2021004', '赵六', '软件工程1班', NOW(), NOW()),
        ('2021005', '钱七', '计算机科学与技术2班', NOW(), NOW());
    END IF;
END $$;