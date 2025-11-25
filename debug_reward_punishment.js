import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';

// 加载环境变量
config({ path: '.env' });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.log('❌ Supabase配置缺失');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testRewardPunishment() {
  try {
    console.log('🔍 检查reward_punishments表是否存在...');
    const { data, error } = await supabase
      .from('reward_punishments')
      .select('count')
      .limit(1);
    
    if (error) {
      console.log('❌ 表不存在或权限错误:', error.message);
      console.log('详细错误:', error);
      return false;
    }
    
    console.log('✅ 表存在且有访问权限');
    
    // 检查学生表
    console.log('🔍 检查student_profiles表...');
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('id, name')
      .limit(3);
    
    if (studentError) {
      console.log('❌ 学生表错误:', studentError.message);
      return false;
    }
    
    if (!students || students.length === 0) {
      console.log('❌ 没有找到学生记录');
      return false;
    }
    
    console.log('✅ 找到学生记录:', students);
    
    // 尝试插入一条测试记录
    console.log('🔍 测试插入奖惩记录...');
    const testInsert = await supabase
      .from('reward_punishments')
      .insert({
        student_id: students[0].id,
        type: 'reward',
        name: '测试奖励',
        level: 'school',
        description: '这是一个测试记录',
        date: '2024-01-01',
        created_by: 'test_teacher'
      })
      .select();
    
    if (testInsert.error) {
      console.log('❌ 插入失败:', testInsert.error.message);
      console.log('详细错误:', testInsert.error);
      return false;
    }
    
    console.log('✅ 插入成功:', testInsert.data);
    
    // 删除测试记录
    if (testInsert.data && testInsert.data.length > 0) {
      await supabase
        .from('reward_punishments')
        .delete()
        .eq('id', testInsert.data[0].id);
      console.log('🧹 测试记录已清理');
    }
    
    return true;
    
  } catch (err) {
    console.log('❌ 测试异常:', err.message);
    return false;
  }
}

testRewardPunishment().then(success => {
  console.log(success ? '\n✅ 数据库测试通过' : '\n❌ 数据库测试失败');
  process.exit(success ? 0 : 1);
});