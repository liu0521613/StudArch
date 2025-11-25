import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function checkBatchData() {
  try {
    console.log('=== 检查导入批次数据 ===');
    
    // 查询导入批次
    const { data: batches, error: batchError } = await supabase
      .from('graduation_import_batches')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);
    
    if (batchError) {
      console.error('查询批次失败:', batchError);
    } else {
      console.log('导入批次记录:', batches?.length || 0, '条');
      if (batches && batches.length > 0) {
        batches.forEach((batch, index) => {
          console.log(`批次 ${index + 1}:`, {
            id: batch.id,
            batch_name: batch.batch_name,
            total_records: batch.total_records,
            success_count: batch.success_count,
            failure_count: batch.failure_count,
            status: batch.status,
            created_at: batch.created_at
          });
        });
      }
    }
    
    // 查询毕业去向数据
    console.log('\n=== 检查毕业去向数据 ===');
    const { data: destinations, error: destError } = await supabase
      .from('graduation_destinations')
      .select('*')
      .limit(5);
    
    if (destError) {
      console.error('查询去向失败:', destError);
    } else {
      console.log('毕业去向记录:', destinations?.length || 0, '条');
      if (destinations && destinations.length > 0) {
        destinations.forEach((dest, index) => {
          console.log(`去向 ${index + 1}:`, {
            id: dest.id,
            student_id: dest.student_id,
            destination_type: dest.destination_type,
            status: dest.status,
            batch_import_id: dest.batch_import_id
          });
        });
      }
    }
    
    // 查询学生数据
    console.log('\n=== 检查学生数据 ===');
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('id, student_number, full_name, class_name')
      .limit(5);
    
    if (studentError) {
      console.error('查询学生失败:', studentError);
    } else {
      console.log('学生记录:', students?.length || 0, '条');
      if (students && students.length > 0) {
        students.forEach((student, index) => {
          console.log(`学生 ${index + 1}:`, student);
        });
      }
    }
    
  } catch (err) {
    console.error('检查失败:', err);
  }
}

checkBatchData();