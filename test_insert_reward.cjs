const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testInsert() {
  try {
    // 获取学生记录
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('id')
      .limit(1);
    
    if (studentError || !students || students.length === 0) {
      console.log('❌ 无学生记录:', studentError?.message);
      return;
    }
    
    const studentId = students[0].id;
    console.log('✅ 使用学生ID:', studentId);
    
    // 测试插入
    const { data, error } = await supabase
      .from('reward_punishments')
      .insert({
        student_id: studentId,
        type: 'reward',
        name: '测试奖励',
        level: 'school',
        description: '这是一个测试记录',
        date: '2024-01-01',
        created_by: 'test_teacher'
      })
      .select();
    
    if (error) {
      console.log('❌ 插入失败:', error.message);
      console.log('错误详情:', error);
    } else {
      console.log('✅ 插入成功:', data);
      
      // 清理测试数据
      if (data && data.length > 0) {
        await supabase
          .from('reward_punishments')
          .delete()
          .eq('id', data[0].id);
        console.log('🧹 测试数据已清理');
      }
    }
  } catch (err) {
    console.log('❌ 测试异常:', err.message);
  }
}

testInsert();