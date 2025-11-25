import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function checkStudentData() {
  try {
    console.log('=== 检查 student_profiles 表的完整数据 ===');
    
    const { data: students, error } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(5);

    if (error) {
      console.error('查询失败:', error);
      return;
    }

    if (!students || students.length === 0) {
      console.log('没有学生数据');
      return;
    }

    console.log('找到', students.length, '个学生记录\n');

    students.forEach((student, index) => {
      console.log(`=== 学生 ${index + 1} ===`);
      console.log('所有字段和值:');
      
      // 找出有值的字段
      Object.entries(student).forEach(([key, value]) => {
        if (value !== null && value !== undefined && value !== '') {
          console.log(`  ${key}: ${value}`);
        }
      });
      
      console.log('');
    });

    // 尝试查找可能有姓名和学号的字段
    console.log('=== 查找可能的学号和姓名字段 ===');
    if (students.length > 0) {
      const allFields = new Set();
      students.forEach(student => {
        Object.keys(student).forEach(field => allFields.add(field));
      });

      const fields = Array.from(allFields);
      
      const possibleIdFields = fields.filter(field => 
        field.toLowerCase().includes('id') || 
        field.toLowerCase().includes('number') ||
        field.toLowerCase().includes('student')
      );
      
      const possibleNameFields = fields.filter(field => 
        field.toLowerCase().includes('name') ||
        field.toLowerCase().includes('full')
      );
      
      const possibleClassFields = fields.filter(field => 
        field.toLowerCase().includes('class')
      );

      console.log('可能的学号字段:', possibleIdFields);
      console.log('可能的姓名字段:', possibleNameFields);
      console.log('可能的班级字段:', possibleClassFields);

      // 检查第一个学生的这些字段值
      const firstStudent = students[0];
      console.log('\n第一个学生的关键字段值:');
      possibleIdFields.forEach(field => {
        console.log(`  ${field}: ${firstStudent[field]}`);
      });
      possibleNameFields.forEach(field => {
        console.log(`  ${field}: ${firstStudent[field]}`);
      });
      possibleClassFields.forEach(field => {
        console.log(`  ${field}: ${firstStudent[field]}`);
      });
    }
    
  } catch (err) {
    console.error('检查失败:', err);
  }
}

checkStudentData();