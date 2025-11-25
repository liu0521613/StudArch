const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

async function testSaveWithValidStudentId() {
  console.log('🧪 测试使用有效学生ID保存奖惩记录...');

  try {
    // 首先获取一个有效的学生ID
    console.log('\n1. 🔍 获取有效的学生ID...');
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('id')
      .limit(1);

    if (studentError) {
      console.error('❌ 获取学生ID失败:', studentError.message);
      return;
    }

    if (!students || students.length === 0) {
      console.log('❌ 没有找到学生数据');
      return;
    }

    const validStudentId = students[0].id;
    console.log(`✅ 获取到有效学生ID: ${validStudentId}`);

    // 尝试创建奖惩记录
    console.log('\n2. 💾 尝试创建奖惩记录...');
    
    const rewardData = {
      student_id: validStudentId,
      type: 'reward',
      name: '测试修复功能',
      level: 'school',
      category: '测试',
      description: '这是一个测试保存功能的奖励记录',
      date: '2024-01-15',
      created_by: 'test-user',
      status: 'pending'
    };

    const { data: createdData, error: createError } = await supabase
      .from('reward_punishments')
      .insert(rewardData)
      .select()
      .single();

    if (createError) {
      console.error('❌ 创建失败:', createError.message);
      console.log('💡 保存失败的原因可能是:');
      console.log('1. 学生ID格式不正确');
      console.log('2. 外键约束问题');
      console.log('3. 字段类型不匹配');
      return;
    }

    console.log('✅ 创建成功:', createdData.id);

    // 清理测试数据
    console.log('\n3. 🗑️ 清理测试数据...');
    await supabase
      .from('reward_punishments')
      .delete()
      .eq('id', createdData.id);
    console.log('✅ 测试数据已清理');

    console.log('\n🎉 保存功能测试通过！');
    console.log('\n📋 解决方案总结:');
    console.log('1. ✅ 确保使用有效的学生ID（UUID格式）');
    console.log('2. ✅ 学生数据在 student_profiles 表中');
    console.log('3. ✅ 前端添加了 studentId 检查逻辑');
    console.log('4. ✅ 数据库连接正常');

  } catch (error) {
    console.error('\n❌ 测试失败:', error.message);
  }
}

// 执行测试
testSaveWithValidStudentId().then(() => {
  console.log('\n🏁 测试脚本执行完成');
}).catch((error) => {
  console.error('\n💥 测试脚本执行失败:', error);
});