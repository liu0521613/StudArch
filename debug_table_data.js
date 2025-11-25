import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function debugTableData() {
  try {
    console.log('=== 检查 graduation_destinations 表结构和数据 ===');
    
    // 查询所有数据
    const { data: destinations, error: destError } = await supabase
      .from('graduation_destinations')
      .select('*');
    
    if (destError) {
      console.error('查询 graduation_destinations 失败:', destError);
    } else {
      console.log('graduation_destinations 记录数:', destinations?.length || 0);
      if (destinations && destinations.length > 0) {
        console.log('表字段:', Object.keys(destinations[0]));
        console.log('前2条记录:');
        destinations.slice(0, 2).forEach((record, index) => {
          console.log(`记录 ${index + 1}:`, {
            id: record.id,
            student_id: record.student_id,
            destination_type: record.destination_type,
            status: record.status,
            submit_time: record.submit_time,
            company_name: record.company_name,
            school_name: record.school_name
          });
        });
      }
    }
    
    console.log('\n=== 检查 student_profiles 表 ===');
    
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(5);
    
    if (studentError) {
      console.error('查询 student_profiles 失败:', studentError);
    } else {
      console.log('student_profiles 记录数:', students?.length || 0);
      if (students && students.length > 0) {
        console.log('学生表字段:', Object.keys(students[0]));
        console.log('前2条学生记录:');
        students.slice(0, 2).forEach((student, index) => {
          console.log(`学生 ${index + 1}:`, {
            id: student.id,
            student_number: student.student_number,
            full_name: student.full_name,
            class_name: student.class_name
          });
        });
      }
    }
    
    console.log('\n=== 测试关联查询（前端代码使用的查询） ===');
    
    // 这是前端代码使用的查询
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
      console.log('可能的问题:');
      console.log('1. student_profiles 表的字段名不是 student_number, full_name, class_name');
      console.log('2. 外键关系 student_id -> student_profiles.id 不正确');
      console.log('3. RLS策略阻止了查询');
    } else {
      console.log('✅ 关联查询成功');
      console.log('关联查询结果:', joinedData?.length || 0, '条');
      if (joinedData && joinedData.length > 0) {
        joinedData.forEach((record, index) => {
          console.log(`关联记录 ${index + 1}:`, {
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
    console.error('调试失败:', err);
  }
}

debugTableData();