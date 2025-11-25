-- 创建奖惩信息相关的数据库表结构

-- 1. 创建奖惩信息表
CREATE TABLE IF NOT EXISTS reward_punishments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('reward', 'punishment')),
    name TEXT NOT NULL,
    level TEXT NOT NULL CHECK (level IN ('class', 'department', 'school', 'province', 'country')),
    category TEXT,
    description TEXT NOT NULL,
    date DATE NOT NULL,
    created_by TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_by TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    review_notes TEXT
);

-- 2. 创建奖惩附件表（可选）
CREATE TABLE IF NOT EXISTS reward_punishment_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reward_punishment_id UUID NOT NULL REFERENCES reward_punishments(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size NUMERIC,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_reward_punishments_student_id ON reward_punishments(student_id);
CREATE INDEX IF NOT EXISTS idx_reward_punishments_type ON reward_punishments(type);
CREATE INDEX IF NOT EXISTS idx_reward_punishments_level ON reward_punishments(level);
CREATE INDEX IF NOT EXISTS idx_reward_punishments_status ON reward_punishments(status);
CREATE INDEX IF NOT EXISTS idx_reward_punishments_date ON reward_punishments(date DESC);

-- 4. 创建更新时间戳的触发器
DROP TRIGGER IF EXISTS update_reward_punishments_updated_at ON reward_punishments;
CREATE TRIGGER update_reward_punishments_updated_at 
    BEFORE UPDATE ON reward_punishments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. 禁用RLS策略（如果启用了RLS）
ALTER TABLE reward_punishments DISABLE ROW LEVEL SECURITY;
ALTER TABLE reward_punishment_attachments DISABLE ROW LEVEL SECURITY;

-- 6. 插入一些示例数据（如果表为空）
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM reward_punishments LIMIT 1) THEN
        -- 获取现有学生的ID
        DECLARE
            student_uuid UUID;
        BEGIN
            SELECT id INTO student_uuid FROM student_profiles LIMIT 1;
            
            IF student_uuid IS NOT NULL THEN
                -- 插入示例奖励记录
                INSERT INTO reward_punishments (
                    student_id, type, name, level, category, description, date, created_by, status
                ) VALUES 
                (
                    student_uuid, 
                    'reward', 
                    '校级奖学金', 
                    'school', 
                    '奖学金', 
                    '获得2021-2022学年校级一等奖学金，学习成绩优秀，综合素质突出', 
                    '2022-10-15', 
                    'teacher001',
                    'approved'
                ),
                (
                    student_uuid, 
                    'reward', 
                    '优秀学生干部', 
                    'school', 
                    '荣誉', 
                    '担任班级团支书期间，工作认真负责，被评为2022年度优秀学生干部', 
                    '2023-03-20', 
                    'teacher001',
                    'approved'
                ),
                (
                    student_uuid, 
                    'punishment', 
                    '迟到警告', 
                    'class', 
                    '纪律处分', 
                    '因多次上课迟到，给予口头警告处分', 
                    '2022-12-05', 
                    'teacher001',
                    'approved'
                );
                
                RAISE NOTICE '已创建3条示例奖惩记录';
            ELSE
                RAISE NOTICE '未找到学生记录，跳过奖惩示例数据插入';
            END IF;
        END;
    END IF;
END $$;

-- 7. 验证表创建和数据插入
SELECT 'reward_punishments 表记录数: ' || COUNT(*) as count FROM reward_punishments;
SELECT 'reward_punishment_attachments 表记录数: ' || COUNT(*) as count FROM reward_punishment_attachments;

-- 8. 创建奖惩统计函数
CREATE OR REPLACE FUNCTION get_reward_punishment_stats(student_uuid UUID)
RETURNS TABLE (
    total_rewards INTEGER,
    total_punishments INTEGER,
    recent_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) FILTER (WHERE type = 'reward')::INTEGER as total_rewards,
        COUNT(*) FILTER (WHERE type = 'punishment')::INTEGER as total_punishments,
        COUNT(*) FILTER (WHERE date >= CURRENT_DATE - INTERVAL '1 year')::INTEGER as recent_count
    FROM reward_punishments 
    WHERE student_id = student_uuid;
END;
$$ LANGUAGE plpgsql;

COMMIT;