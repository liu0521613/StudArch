const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function fixStudentIdMapping() {
  try {
    console.log('🔍 检查users和student_profiles表的ID映射关系...');
    
    // 获取前几个学生用户
    const { data: studentUsers, error: userError } = await supabase
      .from('users')
      .select('id, username, email, full_name')
      .eq('role_id', '3')
      .limit(5);
    
    if (userError) {
      console.log('❌ 获取用户失败:', userError.message);
      return;
    }
    
    if (!studentUsers || studentUsers.length === 0) {
      console.log('❌ 没有找到学生用户');
      return;
    }
    
    console.log('✅ 找到学生用户:');
    for (const user of studentUsers) {
      console.log(`  用户ID: ${user.id}, 姓名: ${user.full_name}`);
      
      // 查找对应的student_profiles记录
      const { data: profiles, error: profileError } = await supabase
        .from('student_profiles')
        .select('id, user_id')
        .eq('user_id', user.id);
      
      if (profileError) {
        console.log(`  ❌ 查找学生档案失败: ${profileError.message}`);
      } else if (profiles && profiles.length > 0) {
        console.log(`  ✅ 找到学生档案ID: ${profiles[0].id}`);
      } else {
        console.log(`  ⚠️  未找到对应的学生档案`);
      }
    }
    
    console.log('\n💡 建议修复方案:');
    console.log('1. 在学生列表页面，链接应该使用student_profiles.id而不是users.id');
    console.log('2. 需要通过user_id查找对应的student_profiles.id');
    
  } catch (err) {
    console.log('❌ 检查异常:', err.message);
  }
}

fixStudentIdMapping();