import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function checkTables() {
  try {
    console.log('=== 检查 graduation_destinations 表 ===');
    
    const { data, error, count } = await supabase
      .from('graduation_destinations')
      .select('*', { count: 'exact' });
    
    if (error) {
      console.error('查询 graduation_destinations 失败:', error);
      return;
    }
    
    console.log('graduation_destinations 表中有', count, '条记录');
    if (count > 0) {
      console.log('前3条记录:');
      data.slice(0, 3).forEach((record, index) => {
        console.log(`${index + 1}:`, {
          id: record.id,
          student_id: record.student_id,
          destination_type: record.destination_type,
          status: record.status,
          submit_time: record.submit_time
        });
      });
    }
    
    console.log('\n=== 检查 student_profiles 表 ===');
    const { data: students, error: studentError, count: studentCount } = await supabase
      .from('student_profiles')
      .select('id, student_number, full_name, class_name', { count: 'exact' });
    
    if (studentError) {
      console.error('查询 student_profiles 失败:', studentError);
    } else {
      console.log('student_profiles 表中有', studentCount, '条记录');
      if (studentCount > 0) {
        console.log('前3条学生记录:');
        students.slice(0, 3).forEach((student, index) => {
          console.log(`${index + 1}:`, student);
        });
      }
    }
    
    // 检查关联关系
    if (count > 0 && studentCount > 0) {
      console.log('\n=== 检查关联查询 ===');
      const { data: joinedData, error: joinError } = await supabase
        .from('graduation_destinations')
        .select(`
          *,
          student!inner (
            student_number,
            full_name,
            class_name
          )
        `)
        .limit(3);
      
      if (joinError) {
        console.error('关联查询失败:', joinError);
      } else {
        console.log('关联查询结果:');
        joinedData.forEach((record, index) => {
          console.log(`${index + 1}:`, {
            id: record.id,
            student_number: record.student?.student_number,
            full_name: record.student?.full_name,
            class_name: record.student?.class_name,
            destination_type: record.destination_type,
            status: record.status
          });
        });
      }
    }
    
  } catch (err) {
    console.error('检查失败:', err);
  }
}

checkTables();