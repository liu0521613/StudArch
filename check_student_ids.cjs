const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function checkStudentIds() {
  try {
    console.log('🔍 检查student_profiles表中的ID格式...');
    
    const { data: students, error } = await supabase
      .from('student_profiles')
      .select('id, user_id')
      .limit(5);
    
    if (error) {
      console.log('❌ 查询失败:', error.message);
      return;
    }
    
    if (!students || students.length === 0) {
      console.log('❌ 没有找到学生记录');
      return;
    }
    
    console.log('✅ 找到学生记录:');
    students.forEach((student, index) => {
      console.log(`${index + 1}. ID: ${student.id}, User ID: ${student.user_id || 'null'}`);
      console.log(`   ID 类型: ${typeof student.id}`);
      console.log(`   ID 格式: ${student.id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i) ? '有效UUID' : '无效UUID'}`);
    });
    
  } catch (err) {
    console.log('❌ 检查异常:', err.message);
  }
}

checkStudentIds();