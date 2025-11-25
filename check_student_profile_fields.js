import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function checkStudentProfileFields() {
  try {
    console.log('=== 详细检查 student_profiles 表所有字段 ===');
    
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(5);
    
    if (studentError) {
      console.error('查询失败:', studentError);
      return;
    }
    
    if (!students || students.length === 0) {
      console.log('没有学生数据');
      return;
    }
    
    // 获取所有字段
    const allFields = new Set();
    students.forEach(student => {
      Object.keys(student).forEach(field => allFields.add(field));
    });
    
    const fields = Array.from(allFields);
    console.log('所有字段:', fields);
    
    // 查找可能的毕业去向相关字段
    const possibleGraduationFields = fields.filter(field => {
      const lowerField = field.toLowerCase();
      return lowerField.includes('graduation') ||
             lowerField.includes('destination') ||
             lowerField.includes('employment') ||
             lowerField.includes('company') ||
             lowerField.includes('job') ||
             lowerField.includes('career') ||
             lowerField.includes('work') ||
             lowerField.includes('salary') ||
             lowerField.includes('position') ||
             lowerField.includes('major') ||
             lowerField.includes('school') ||
             lowerField.includes('abroad') ||
             lowerField.includes('startup');
    });
    
    console.log('\n可能的毕业去向相关字段:', possibleGraduationFields);
    
    // 显示每个学生这些字段的值
    console.log('\n=== 学生毕业去向信息 ===');
    students.forEach((student, index) => {
      console.log(`\n学生 ${index + 1} (${student.student_number || '无学号'}):`);
      
      // 基本信息
      console.log(`  姓名: ${student.full_name || '无'}`);
      console.log(`  班级: ${student.class_name || '无'}`);
      console.log(`  学号: ${student.student_number || '无'}`);
      
      // 毕业相关字段
      possibleGraduationFields.forEach(field => {
        const value = student[field];
        if (value !== null && value !== undefined && value !== '') {
          console.log(`  ${field}: ${value}`);
        }
      });
    });
    
    // 如果没有找到毕业去向字段，尝试直接查找特定的导入批次数据
    if (possibleGraduationFields.length === 0) {
      console.log('\n=== 检查可能的毕业去向数据 ===');
      console.log('尝试检查最近是否有人通过批量操作插入了数据...');
      
      // 检查 student_batch_operations 表
      const { data: operations, error: opError } = await supabase
        .from('student_batch_operations')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(5);
      
      if (opError) {
        console.log('批量操作表查询失败:', opError.message);
      } else {
        console.log('批量操作记录:', operations?.length || 0, '条');
        if (operations && operations.length > 0) {
          operations.forEach((op, index) => {
            console.log(`操作 ${index + 1}:`, {
              operation_type: op.operation_type,
              status: op.status,
              created_at: op.created_at
            });
          });
        }
      }
    }
    
  } catch (err) {
    console.error('检查失败:', err);
  }
}

checkStudentProfileFields();