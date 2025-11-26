-- 修复 training_program_import_batches 表结构
-- 添加缺失的字段

-- 添加 import_date 字段
ALTER TABLE training_program_import_batches 
ADD COLUMN IF NOT EXISTS import_date TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 添加 error_details 字段
ALTER TABLE training_program_import_batches 
ADD COLUMN IF NOT EXISTS error_details JSONB DEFAULT '[]'::jsonb;

-- 添加 completed_at 字段
ALTER TABLE training_program_import_batches 
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- 更新现有记录的import_date（如果为空）
UPDATE training_program_import_batches 
SET import_date = created_at 
WHERE import_date IS NULL;

COMMIT;