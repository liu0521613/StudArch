const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function checkTables() {
  try {
    console.log('🔍 检查student_profiles表结构...');
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(1);
    
    if (studentError) {
      console.log('❌ 学生表错误:', studentError.message);
    } else {
      console.log('✅ 学生表结构:', students.length > 0 ? Object.keys(students[0]) : '无数据');
    }
    
    console.log('🔍 检查reward_punishments表结构...');
    const { data: rewards, error: rewardError } = await supabase
      .from('reward_punishments')
      .select('*')
      .limit(1);
    
    if (rewardError) {
      console.log('❌ 奖惩表错误:', rewardError.message);
    } else {
      console.log('✅ 奖惩表结构:', rewards.length > 0 ? Object.keys(rewards[0]) : '无数据');
    }
    
  } catch (err) {
    console.log('❌ 检查异常:', err.message);
  }
}

checkTables();