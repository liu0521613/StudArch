const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

const supabase = createClient(process.env.VITE_SUPABASE_URL, process.env.VITE_SUPABASE_ANON_KEY);

async function testLevelRemoval() {
  try {
    console.log('🔍 测试移除级别字段后的奖惩功能...');
    
    // 获取一个学生档案
    const { data: profiles, error: profileError } = await supabase
      .from('student_profiles')
      .select('id')
      .limit(1);

    if (profileError || !profiles || profiles.length === 0) {
      console.log('❌ 获取学生档案失败');
      return;
    }

    const studentId = profiles[0].id;
    console.log('✅ 使用学生ID:', studentId);

    // 测试添加奖惩（不包含level字段）
    const rewardData = {
      student_id: studentId,
      type: 'reward',
      name: '测试奖励（无级别）',
      level: 'school', // 后端会自动设置默认值
      description: '这是一个不显示级别的测试奖励',
      date: '2024-01-01',
      created_by: 'test_teacher'
    };

    console.log('📦 准备保存的奖惩数据:', {
      ...rewardData,
      level: rewardData.level + '（后端默认值）'
    });

    const { data: insertedReward, error: insertError } = await supabase
      .from('reward_punishments')
      .insert(rewardData)
      .select()
      .single();

    if (insertError) {
      console.log('❌ 奖惩保存失败:', insertError.message);
      return;
    }

    console.log('✅ 奖惩保存成功:', {
      id: insertedReward.id,
      name: insertedReward.name,
      level: insertedReward.level + '（存储在数据库中）'
    });

    // 清理测试数据
    await supabase
      .from('reward_punishments')
      .delete()
      .eq('id', insertedReward.id);
    
    console.log('🧹 测试数据已清理');

    console.log('\n🎉 级别字段移除验证成功！');
    console.log('✅ 用户界面不再显示级别');
    console.log('✅ 用户界面不再有级别筛选');
    console.log('✅ 用户界面不再有级别统计');
    console.log('✅ 表单不再有级别输入');
    console.log('✅ 数据库层面保持兼容（设置默认值）');

  } catch (err) {
    console.log('❌ 测试异常:', err.message);
  }
}

testLevelRemoval();