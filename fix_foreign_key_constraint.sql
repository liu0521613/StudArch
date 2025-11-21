-- 快速修复外键约束问题
-- 移除 graduation_import_batches 表的外键约束

-- 1. 移除外键约束
ALTER TABLE graduation_import_batches 
DROP CONSTRAINT IF EXISTS graduation_import_batches_imported_by_fkey;

-- 2. 将 imported_by 列改为 TEXT 类型（如果还不是）
ALTER TABLE graduation_import_batches 
ALTER COLUMN imported_by TYPE TEXT USING imported_by::TEXT;

-- 3. 插入一个模拟用户记录到 auth.users 表（可选方案）
-- 注意：这需要管理员权限，如果不行就用上面的方案
DO $$
BEGIN
    -- 检查是否存在模拟用户，不存在则创建
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = '550e8400-e29b-41d4-a716-446655440001') THEN
        -- 尝试插入模拟用户（可能会因权限失败）
        BEGIN
            INSERT INTO auth.users (
                id,
                aud,
                role,
                email,
                created_at,
                updated_at
            ) VALUES (
                '550e8400-e29b-41d4-a716-446655440001',
                'authenticated',
                'authenticated',
                'mock-user@local.dev',
                NOW(),
                NOW()
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '无法创建模拟用户: %', SQLERRM;
        END;
    END IF;
END $$;

-- 4. 验证修复结果
\d+ graduation_import_batches;

-- 5. 测试插入
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
    '测试批次',
    'test.xlsx',
    1,
    0,
    0,
    'processing',
    '550e8400-e29b-41d4-a716-446655440001',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- 查看结果
SELECT * FROM graduation_import_batches ORDER BY created_at DESC LIMIT 1;

-- 清理测试数据
DELETE FROM graduation_import_batches WHERE batch_name = '测试批次';

COMMIT;