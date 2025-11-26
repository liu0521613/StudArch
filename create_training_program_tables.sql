-- 培养方案数据库表设计
-- 用于存储和管理培养方案课程信息

-- 1. 培养方案主表
CREATE TABLE IF NOT EXISTS training_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_name TEXT NOT NULL,                   -- 培养方案名称
    program_code TEXT UNIQUE NOT NULL,             -- 培养方案代码
    major TEXT NOT NULL,                           -- 专业
    department TEXT,                               -- 院系
    total_credits NUMERIC DEFAULT 0,               -- 总学分
    duration_years INTEGER DEFAULT 4,             -- 学制年限
    description TEXT,                               -- 培养方案描述
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'deprecated')),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 培养方案课程表
CREATE TABLE IF NOT EXISTS training_program_courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID NOT NULL REFERENCES training_programs(id) ON DELETE CASCADE,
    course_number TEXT NOT NULL,                   -- 课程号
    course_name TEXT NOT NULL,                      -- 课程名称
    credits NUMERIC NOT NULL CHECK (credits > 0),  -- 学分
    recommended_grade TEXT,                         -- 建议修读年级
    semester TEXT,                                  -- 学期
    exam_method TEXT,                               -- 考试方式
    course_nature TEXT,                             -- 课程性质
    course_type TEXT DEFAULT 'required',           -- 课程类型：必修/选修
    prerequisites TEXT[],                           -- 先修课程
    course_category TEXT,                           -- 课程分类
    teaching_hours INTEGER,                         -- 学时
    theory_hours INTEGER,                           -- 理论学时
    practice_hours INTEGER,                         -- 实践学时
    weekly_hours NUMERIC,                           -- 周学时
    course_description TEXT,                        -- 课程描述
    remarks TEXT,                                   -- 备注
    sequence_order INTEGER DEFAULT 0,              -- 排序顺序
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 确保同一培养方案内课程号唯一
    UNIQUE(program_id, course_number)
);

-- 3. 培养方案导入批次表
CREATE TABLE IF NOT EXISTS training_program_import_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_name TEXT NOT NULL,                       -- 批次名称
    program_id UUID REFERENCES training_programs(id) ON DELETE SET NULL,
    imported_by UUID REFERENCES users(id) ON DELETE SET NULL,
    file_name TEXT,                                 -- 原始文件名
    total_records INTEGER DEFAULT 0,                -- 总记录数
    success_count INTEGER DEFAULT 0,                -- 成功数量
    failure_count INTEGER DEFAULT 0,                -- 失败数量
    status TEXT DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed', 'cancelled')),
    error_summary JSONB,                            -- 错误汇总
    import_settings JSONB,                          -- 导入设置
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 培养方案导入失败记录表
CREATE TABLE IF NOT EXISTS training_program_import_failures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES training_program_import_batches(id) ON DELETE CASCADE,
    row_number INTEGER,                             -- 行号
    course_number TEXT,                              -- 课程号
    course_name TEXT,                                -- 课程名称
    error_message TEXT NOT NULL,                    -- 错误信息
    raw_data JSONB,                                 -- 原始数据
    validation_errors JSONB,                        -- 验证错误详情
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 培养方案与学生关联表（用于学生端显示）
CREATE TABLE IF NOT EXISTS student_training_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    program_id UUID NOT NULL REFERENCES training_programs(id) ON DELETE CASCADE,
    enrollment_date DATE,                           -- 分配日期
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'changed', 'suspended')),
    notes TEXT,                                     -- 备注
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 确保学生与培养方案唯一关联
    UNIQUE(student_id, program_id)
);

-- 6. 学生课程修读状态表（用于跟踪学生的课程修读情况）
CREATE TABLE IF NOT EXISTS student_course_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES training_program_courses(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'failed', 'exempted')),
    grade NUMERIC CHECK (grade >= 0 AND grade <= 100), -- 成绩
    grade_point NUMERIC CHECK (grade_point >= 0 AND grade_point <= 4), -- 绩点
    semester_completed TEXT,                         -- 完成学期
    academic_year TEXT,                             -- 学年
    teacher TEXT,                                   -- 授课教师
    notes TEXT,                                     -- 备注
    completed_at TIMESTAMP WITH TIME ZONE,         -- 完成时间
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 确保学生与课程的唯一记录
    UNIQUE(student_id, course_id)
);

-- 创建索引提高查询性能
CREATE INDEX IF NOT EXISTS idx_training_program_courses_program_id ON training_program_courses(program_id);
CREATE INDEX IF NOT EXISTS idx_training_program_courses_course_number ON training_program_courses(course_number);
CREATE INDEX IF NOT EXISTS idx_student_training_programs_student_id ON student_training_programs(student_id);
CREATE INDEX IF NOT EXISTS idx_student_training_programs_program_id ON student_training_programs(program_id);
CREATE INDEX IF NOT EXISTS idx_student_course_progress_student_id ON student_course_progress(student_id);
CREATE INDEX IF NOT EXISTS idx_student_course_progress_course_id ON student_course_progress(course_id);
CREATE INDEX IF NOT EXISTS idx_training_program_import_batches_status ON training_program_import_batches(status);

-- 创建更新时间戳的触发器函数（如果不存在）
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为各表创建更新时间戳的触发器
DROP TRIGGER IF EXISTS update_training_programs_updated_at ON training_programs;
CREATE TRIGGER update_training_programs_updated_at 
    BEFORE UPDATE ON training_programs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_training_program_courses_updated_at ON training_program_courses;
CREATE TRIGGER update_training_program_courses_updated_at 
    BEFORE UPDATE ON training_program_courses 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_training_program_import_batches_updated_at ON training_program_import_batches;
CREATE TRIGGER update_training_program_import_batches_updated_at 
    BEFORE UPDATE ON training_program_import_batches 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_student_training_programs_updated_at ON student_training_programs;
CREATE TRIGGER update_student_training_programs_updated_at 
    BEFORE UPDATE ON student_training_programs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_student_course_progress_updated_at ON student_course_progress;
CREATE TRIGGER update_student_course_progress_updated_at 
    BEFORE UPDATE ON student_course_progress 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入默认的培养方案数据（用于测试）
DO $$
BEGIN
    -- 创建默认的培养方案
    INSERT INTO training_programs (
        program_name, 
        program_code, 
        major, 
        department, 
        total_credits,
        duration_years,
        description,
        created_at,
        updated_at
    ) VALUES (
        '计算机科学与技术培养方案（2021版）',
        'CS_2021',
        '计算机科学与技术',
        '计算机学院',
        160,
        4,
        '计算机科学与技术专业本科培养方案，包含专业基础课程、专业核心课程和专业选修课程。',
        NOW(),
        NOW()
    ) ON CONFLICT (program_code) DO NOTHING;
    
    -- 记录插入的方案ID
    DECLARE
        program_uuid UUID;
    BEGIN
        SELECT id INTO program_uuid FROM training_programs WHERE program_code = 'CS_2021';
        
        IF program_uuid IS NOT NULL THEN
            RAISE NOTICE '已创建默认培养方案，ID: %', program_uuid;
        END IF;
    END;
END $$;

-- 验证表创建结果
SELECT 
    'training_programs 表记录数: ' || COUNT(*) as count 
FROM training_programs
UNION ALL
SELECT 
    'training_program_courses 表记录数: ' || COUNT(*) as count 
FROM training_program_courses
UNION ALL
SELECT 
    'student_training_programs 表记录数: ' || COUNT(*) as count 
FROM student_training_programs
UNION ALL
SELECT 
    'student_course_progress 表记录数: ' || COUNT(*) as count 
FROM student_course_progress;

-- 禁用RLS策略以确保API正常访问
ALTER TABLE training_programs DISABLE ROW LEVEL SECURITY;
ALTER TABLE training_program_courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE training_program_import_batches DISABLE ROW LEVEL SECURITY;
ALTER TABLE training_program_import_failures DISABLE ROW LEVEL SECURITY;
ALTER TABLE student_training_programs DISABLE ROW LEVEL SECURITY;
ALTER TABLE student_course_progress DISABLE ROW LEVEL SECURITY;

COMMIT;