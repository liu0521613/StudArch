const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// 模拟前端环境
const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function debugFrontendSave() {
  console.log('🐛 调试前端保存流程...');

  try {
    // 步骤1: 获取有效的学生ID (模拟URL参数)
    console.log('\n1. 🆔 获取学生ID...');
    let studentId = null; // 模拟没有studentId的情况
    
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('id')
      .limit(3);

    if (studentError) {
      console.error('❌ 获取学生失败:', studentError.message);
      return;
    }

    if (students && students.length > 0) {
      studentId = students[0].id;
      console.log(`✅ 获取到学生ID: ${studentId}`);
    } else {
      console.log('❌ 没有找到学生数据');
      return;
    }

    // 步骤2: 模拟前端表单数据
    console.log('\n2. 📝 准备表单数据...');
    const formData = {
      type: 'reward',
      name: '调试测试奖励',
      level: 'school',
      category: '奖学金',
      description: '这是一个调试用的测试奖励记录',
      date: '2024-01-15'
    };
    console.log('表单数据:', formData);

    // 步骤3: 构建保存数据 (模拟handleSaveReward)
    console.log('\n3. 🏗️ 构建保存数据...');
    
    if (!studentId) {
      console.log('❌ 学生ID缺失');
      return;
    }

    const rewardData = {
      student_id: studentId,
      type: formData.type || 'reward',
      name: formData.name || '',
      level: formData.level || 'school',
      category: formData.category,
      description: formData.description || '',
      date: formData.date || new Date().toISOString().split('T')[0],
      created_by: 'teacher001'
    };
    console.log('保存数据:', rewardData);

    // 步骤4: 执行插入操作 (模拟API调用)
    console.log('\n4. 💾 执行数据库插入...');
    const { data: result, error: insertError } = await supabase
      .from('reward_punishments')
      .insert(rewardData)
      .select()
      .single();

    if (insertError) {
      console.error('❌ 插入失败:', insertError);
      console.error('错误详情:');
      console.error('- 代码:', insertError.code);
      console.error('- 消息:', insertError.message);
      console.error('- 详情:', insertError.details);
      console.error('- 提示:', insertError.hint);
      
      // 根据错误类型给出具体建议
      if (insertError.code === '23503') {
        console.log('\n💡 外键约束错误 - 可能的原因:');
        console.log('1. student_id 不存在于 student_profiles 表中');
        console.log('2. 外键约束配置错误');
      } else if (insertError.code === '23505') {
        console.log('\n💡 唯一约束错误 - 可能的原因:');
        console.log('1. 重复的记录');
      } else if (insertError.code === '42501') {
        console.log('\n💡 权限错误 - 可能的原因:');
        console.log('1. RLS策略阻止了插入操作');
        console.log('2. 用户权限不足');
      }
      
      return;
    }

    if (!result) {
      console.error('❌ 插入成功但未返回数据');
      return;
    }

    console.log('✅ 插入成功:', result.id);

    // 步骤5: 验证数据是否正确保存
    console.log('\n5. 🔍 验证保存的数据...');
    const { data: savedData, error: verifyError } = await supabase
      .from('reward_punishments')
      .select('*')
      .eq('id', result.id)
      .single();

    if (verifyError) {
      console.error('❌ 验证失败:', verifyError.message);
    } else {
      console.log('✅ 验证成功，数据正确保存');
      console.log('保存的记录:', savedData);
    }

    // 步骤6: 清理测试数据
    console.log('\n6. 🗑️ 清理测试数据...');
    await supabase
      .from('reward_punishments')
      .delete()
      .eq('id', result.id);
    console.log('✅ 清理完成');

    console.log('\n🎉 前端保存流程调试成功！');
    
  } catch (error) {
    console.error('\n❌ 调试过程中发生异常:', error);
  }
}

// 执行调试
debugFrontendSave().then(() => {
  console.log('\n🏁 调试脚本执行完成');
}).catch((error) => {
  console.error('\n💥 调试脚本执行失败:', error);
});