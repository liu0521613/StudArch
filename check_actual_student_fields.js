import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function checkActualStudentFields() {
  try {
    console.log('=== 检查 student_profiles 表的实际字段 ===');
    
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(1);
    
    if (studentError) {
      console.error('查询 student_profiles 失败:', studentError);
      return;
    }
    
    if (!students || students.length === 0) {
      console.log('student_profiles 表中没有数据');
      return;
    }
    
    const student = students[0];
    const fields = Object.keys(student);
    console.log('student_profiles 实际字段:', fields);
    
    // 查找学号和姓名的字段
    const studentNumberField = fields.find(field => 
      field.toLowerCase().includes('number') || 
      field.toLowerCase().includes('student') ||
      field.toLowerCase().includes('id')
    );
    
    const nameField = fields.find(field => 
      field.toLowerCase().includes('name') ||
      field.toLowerCase().includes('full')
    );
    
    const classField = fields.find(field => 
      field.toLowerCase().includes('class')
    );
    
    console.log('\n关键字段映射:');
    console.log('学号字段:', studentNumberField || '未找到');
    console.log('姓名字段:', nameField || '未找到');
    console.log('班级字段:', classField || '未找到');
    
    // 显示所有字段和值
    console.log('\n=== 学生完整信息 ===');
    fields.forEach(field => {
      const value = student[field];
      console.log(`${field}: ${value}`);
    });
    
    // 检查是否有其他可以通过API访问的表可能包含毕业去向数据
    console.log('\n=== 检查其他可能的表 ===');
    
    // 检查所有我们能访问的表
    const tables = ['student_batch_operations', 'batch_imports', 'users', 'profiles'];
    
    for (const tableName of tables) {
      try {
        const { data, error, count } = await supabase
          .from(tableName)
          .select('*', { count: 'exact', head: true });
        
        if (error) {
          console.log(`❌ ${tableName}: ${error.message}`);
        } else {
          console.log(`✅ ${tableName}: ${count} 条记录`);
          
          if (count && count > 0) {
            const { data: sampleData, error: sampleError } = await supabase
              .from(tableName)
              .select('*')
              .limit(1);
            
            if (!sampleError && sampleData && sampleData.length > 0) {
              const sampleFields = Object.keys(sampleData[0]);
              const graduationFields = sampleFields.filter(field => 
                field.toLowerCase().includes('graduation') ||
                field.toLowerCase().includes('destination') ||
                field.toLowerCase().includes('employment')
              );
              
              if (graduationFields.length > 0) {
                console.log(`  🎯 ${tableName} 中发现毕业相关字段:`, graduationFields);
              }
            }
          }
        }
      } catch (err) {
        console.log(`❌ ${tableName}: 检查失败`);
      }
    }
    
  } catch (err) {
    console.error('检查失败:', err);
  }
}

checkActualStudentFields();