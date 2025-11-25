-- 完全清理所有相关函数和视图
-- 在不确定数据库状态时使用

-- 删除视图
DROP VIEW IF EXISTS teacher_student_stats CASCADE;

-- 删除所有函数（不指定参数，删除所有重载版本）
DROP FUNCTION IF EXISTS get_teacher_students CASCADE;
DROP FUNCTION IF EXISTS get_teacher_students_v2 CASCADE;
DROP FUNCTION IF EXISTS get_available_students_for_import CASCADE;
DROP FUNCTION IF EXISTS batch_add_students_to_teacher CASCADE;
DROP FUNCTION IF EXISTS remove_student_from_teacher CASCADE;
DROP FUNCTION IF EXISTS get_teacher_student_stats CASCADE;

-- 显示清理结果
DO $$
BEGIN
    RAISE NOTICE '所有相关函数和视图已清理完成';
    RAISE NOTICE '现在可以重新执行 fix_function_conflicts.sql';
END $$;