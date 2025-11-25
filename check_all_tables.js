import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function checkAllTables() {
  try {
    console.log('=== 检查所有表 ===');
    
    // 尝试查询可能相关的表
    const tables = [
      'graduation_destinations',
      'graduation_destination',
      'student_graduation_destinations',
      'student_graduation_destination',
      'graduation_import_batches',
      'student_profiles',
      'students'
    ];
    
    for (const tableName of tables) {
      try {
        const { data, error, count } = await supabase
          .from(tableName)
          .select('*', { count: 'exact', head: true });
        
        if (error) {
          console.log(`❌ 表 ${tableName} 不存在或无权限访问`);
        } else {
          console.log(`✅ 表 ${tableName} 存在，有 ${count} 条记录`);
        }
      } catch (err) {
        console.log(`❌ 表 ${tableName} 检查失败:`, err.message);
      }
    }
    
    // 查询导入批次表
    console.log('\n=== 检查导入批次相关表 ===');
    const batchTables = [
      'graduation_import_batches',
      'graduation_import_failures',
      'import_batches',
      'batch_imports'
    ];
    
    for (const tableName of batchTables) {
      try {
        const { data, error, count } = await supabase
          .from(tableName)
          .select('*', { count: 'exact', head: true });
        
        if (error) {
          console.log(`❌ 批次表 ${tableName} 不存在`);
        } else {
          console.log(`✅ 批次表 ${tableName} 存在，有 ${count} 条记录`);
        }
      } catch (err) {
        console.log(`❌ 批次表 ${tableName} 检查失败:`, err.message);
      }
    }
    
  } catch (err) {
    console.error('检查失败:', err);
  }
}

checkAllTables();