-- 修复外键约束问题的最终脚本
-- 执行顺序：1. 先移除约束 2. 修改字段类型 3. 重新创建表（如果需要）

-- 步骤1: 移除外键约束
DO $$
BEGIN
    -- 检查并移除外键约束
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'graduation_import_batches_imported_by_fkey' 
        AND table_name = 'graduation_import_batches'
    ) THEN
        ALTER TABLE graduation_import_batches 
        DROP CONSTRAINT graduation_import_batches_imported_by_fkey;
        RAISE NOTICE '外键约束已移除';
    END IF;
    
    -- 将字段改为TEXT类型以支持NULL值
    ALTER TABLE graduation_import_batches 
    ALTER COLUMN imported_by TYPE TEXT USING imported_by::TEXT;
    
    RAISE NOTICE 'imported_by字段已改为TEXT类型';
END $$;

-- 步骤2: 测试插入
DO $$
BEGIN
    -- 测试插入不带用户ID的批次记录
    INSERT INTO graduation_import_batches (
        batch_name,
        filename,
        total_count,
        success_count,
        failed_count,
        status,
        imported_by,
        created_at,
        updated_at
    ) VALUES (
        '约束修复测试',
        'test.xlsx',
        1,
        0,
        0,
        'processing',
        NULL, -- 使用NULL避免外键约束
        NOW(),
        NOW()
    );
    
    RAISE NOTICE '测试插入成功';
    
    -- 删除测试记录
    DELETE FROM graduation_import_batches WHERE batch_name = '约束修复测试';
    
    RAISE NOTICE '测试记录已清理';
END $$;

-- 步骤3: 验证表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'graduation_import_batches' 
    AND column_name = 'imported_by';

-- 步骤4: 检查约束状态
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'graduation_import_batches';

COMMIT;