-- 清理函数冲突
-- 删除旧版本函数，只保留新版本

-- 删除旧版本的函数（TEXT 参数版本）
DROP FUNCTION IF EXISTS import_training_program_courses(
    p_courses JSONB,
    p_program_code TEXT,
    p_batch_name TEXT,
    p_imported_by TEXT
);

-- 删除新版本的函数（UUID 参数版本），以便重新创建
DROP FUNCTION IF EXISTS import_training_program_courses(
    p_courses JSONB,
    p_program_code TEXT,
    p_batch_name TEXT,
    p_imported_by UUID
);

COMMIT;