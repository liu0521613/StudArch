import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function checkGraduationData() {
  try {
    console.log('=== 检查所有毕业去向相关表的数据 ===');
    
    const tables = [
      'graduation_destinations',
      'graduation_destination', 
      'student_graduation_destinations',
      'student_graduation_destination',
      'student_batch_operations',
      'batch_imports',
      'graduation_import_batches'
    ];
    
    for (const tableName of tables) {
      console.log(`\n--- 检查表 ${tableName} ---`);
      
      try {
        const { data, error } = await supabase
          .from(tableName)
          .select('*')
          .limit(5);
        
        if (error) {
          console.log(`❌ 查询失败: ${error.message}`);
        } else {
          console.log(`✅ 表存在，记录数: ${data?.length || 0}`);
          
          if (data && data.length > 0) {
            console.log('字段:', Object.keys(data[0]));
            console.log('数据示例:');
            data.forEach((record, index) => {
              console.log(`  记录 ${index + 1}:`, record);
            });
          }
        }
      } catch (err) {
        console.log(`❌ 检查失败: ${err.message}`);
      }
    }
    
    console.log('\n=== 检查 student_profiles 表字段（用于关联查询） ===');
    
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(1);
    
    if (studentError) {
      console.error('查询学生表失败:', studentError);
    } else {
      console.log('student_profiles 字段:', students && students.length > 0 ? Object.keys(students[0]) : '无数据');
      if (students && students.length > 0) {
        console.log('学生数据示例:', students[0]);
      }
    }
    
    console.log('\n=== 检查是否有导入批次记录 ===');
    
    const { data: batches, error: batchError } = await supabase
      .from('graduation_import_batches')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(3);
    
    if (batchError) {
      console.log('查询导入批次失败:', batchError.message);
    } else {
      console.log('导入批次记录:', batches?.length || 0, '条');
      if (batches && batches.length > 0) {
        batches.forEach((batch, index) => {
          console.log(`批次 ${index + 1}:`, {
            id: batch.id,
            batch_name: batch.batch_name,
            total_records: batch.total_records,
            success_count: batch.success_count,
            status: batch.status
          });
        });
      }
    }
    
  } catch (err) {
    console.error('检查失败:', err);
  }
}

checkGraduationData();