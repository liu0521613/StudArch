import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function checkActualTables() {
  try {
    console.log('=== 检查 student_batch_operations 表 ===');
    
    const { data: batchOps, error: batchError } = await supabase
      .from('student_batch_operations')
      .select('*')
      .limit(5);
    
    if (batchError) {
      console.error('查询 student_batch_operations 失败:', batchError);
    } else {
      console.log('student_batch_operations 记录:', batchOps?.length || 0, '条');
      if (batchOps && batchOps.length > 0) {
        console.log('字段:', Object.keys(batchOps[0]));
        batchOps.forEach((op, index) => {
          console.log(`记录 ${index + 1}:`, {
            id: op.id,
            operation_type: op.operation_type,
            status: op.status,
            created_at: op.created_at
          });
        });
      }
    }
    
    console.log('\n=== 检查 batch_imports 表 ===');
    
    const { data: batchImports, error: importError } = await supabase
      .from('batch_imports')
      .select('*')
      .limit(5);
    
    if (importError) {
      console.error('查询 batch_imports 失败:', importError);
    } else {
      console.log('batch_imports 记录:', batchImports?.length || 0, '条');
      if (batchImports && batchImports.length > 0) {
        console.log('字段:', Object.keys(batchImports[0]));
        batchImports.forEach((imp, index) => {
          console.log(`导入 ${index + 1}:`, {
            id: imp.id,
            import_type: imp.import_type,
            status: imp.status,
            created_at: imp.created_at
          });
        });
      }
    }
    
    console.log('\n=== 检查 student_profiles 表结构 ===');
    
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(1);
    
    if (studentError) {
      console.error('查询 student_profiles 失败:', studentError);
    } else {
      console.log('student_profiles 字段:', students && students.length > 0 ? Object.keys(students[0]) : '无数据');
      if (students && students.length > 0) {
        console.log('示例学生记录:', students[0]);
      }
    }
    
    // 查询所有可能的表
    console.log('\n=== 查询所有可能的表 ===');
    const possibleTables = [
      'student_batch_operations',
      'batch_imports',
      'student_profiles',
      'users',
      'roles'
    ];
    
    for (const table of possibleTables) {
      try {
        const { data, error } = await supabase
          .from(table)
          .select('*')
          .limit(1);
        
        if (error) {
          console.log(`❌ ${table}: ${error.message}`);
        } else {
          console.log(`✅ ${table}: 存在，字段:`, data && data.length > 0 ? Object.keys(data[0]) : '无数据');
        }
      } catch (err) {
        console.log(`❌ ${table}: 检查失败`);
      }
    }
    
  } catch (err) {
    console.error('检查失败:', err);
  }
}

checkActualTables();