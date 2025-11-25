const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

async function checkStudentProfiles() {
  try {
    console.log('🔍 检查 student_profiles 表...');
    
    const { data, error } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(5);
    
    if (error) {
      console.error('❌ 查询失败:', error.message);
      return;
    }
    
    if (data && data.length > 0) {
      console.log('✅ 找到学生数据:');
      console.log('字段:', Object.keys(data[0]).join(', '));
      console.log();
      data.forEach((student, index) => {
        console.log(`  ${index + 1}. ID: ${student.id}, 姓名: ${student.name || student.student_name || '未知'}`);
      });
      
      console.log('\n📋 可用的学生ID (用于student_id字段):');
      data.forEach(student => {
        console.log(`  - ${student.id}`);
      });
    } else {
      console.log('❌ student_profiles表为空');
    }
  } catch (err) {
    console.error('❌ 检查失败:', err.message);
  }
}

checkStudentProfiles();