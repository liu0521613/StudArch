import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function checkApiTables() {
  try {
    console.log('=== 检查可以通过 API 访问的表 ===');
    
    // 只检查我们知道可以通过 API 访问的表
    const accessibleTables = [
      'student_profiles',
      'student_batch_operations', 
      'batch_imports',
      'users',
      'profiles'
    ];
    
    for (const tableName of accessibleTables) {
      console.log(`\n--- 检查表 ${tableName} ---`);
      
      try {
        const { data, error, count } = await supabase
          .from(tableName)
          .select('*', { count: 'exact', head: true });
        
        if (error) {
          console.log(`❌ API 访问失败: ${error.message}`);
        } else {
          console.log(`✅ API 可访问，记录数: ${count}`);
          
          // 如果有数据，查看字段结构
          if (count && count > 0) {
            const { data: sampleData, error: dataError } = await supabase
              .from(tableName)
              .select('*')
              .limit(1);
            
            if (!dataError && sampleData && sampleData.length > 0) {
              console.log('字段:', Object.keys(sampleData[0]));
              
              // 检查是否有毕业相关字段
              const fields = Object.keys(sampleData[0]);
              const graduationFields = fields.filter(field => 
                field.includes('graduation') || 
                field.includes('destination') ||
                field.includes('employment') ||
                field.includes('company')
              );
              
              if (graduationFields.length > 0) {
                console.log('🎯 发现毕业相关字段:', graduationFields);
                console.log('完整记录:', sampleData[0]);
              }
            }
          }
        }
      } catch (err) {
        console.log(`❌ 检查失败: ${err.message}`);
      }
    }
    
    console.log('\n=== 重点检查 student_profiles 表的毕业相关数据 ===');
    
    // student_profiles 可能包含了毕业去向信息
    const { data: studentsWithGraduation, error: studentGradError } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(5);
    
    if (studentGradError) {
      console.error('查询学生毕业信息失败:', studentGradError);
    } else {
      console.log('学生记录数:', studentsWithGraduation?.length || 0);
      
      if (studentsWithGraduation && studentsWithGraduation.length > 0) {
        console.log('student_profiles 完整字段:');
        console.log(Object.keys(studentsWithGraduation[0]));
        
        // 查找所有可能的毕业去向字段
        const allFields = new Set();
        studentsWithGraduation.forEach(student => {
          Object.keys(student).forEach(field => allFields.add(field));
        });
        
        const graduationFields = Array.from(allFields).filter(field => 
          field.toLowerCase().includes('graduation') ||
          field.toLowerCase().includes('destination') ||
          field.toLowerCase().includes('employment') ||
          field.toLowerCase().includes('company') ||
          field.toLowerCase().includes('job') ||
          field.toLowerCase().includes('career')
        );
        
        if (graduationFields.length > 0) {
          console.log('\n🎯 发现可能的毕业去向字段:', graduationFields);
          studentsWithGraduation.forEach((student, index) => {
            console.log(`\n学生 ${index + 1} 的毕业信息:`);
            graduationFields.forEach(field => {
              if (student[field] !== null && student[field] !== undefined) {
                console.log(`  ${field}: ${student[field]}`);
              }
            });
          });
        } else {
          console.log('❌ student_profiles 中没有发现毕业去向相关字段');
        }
      }
    }
    
  } catch (err) {
    console.error('检查 API 表失败:', err);
  }
}

checkApiTables();