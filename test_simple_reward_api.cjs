const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Supabase配置
const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ 缺少Supabase配置信息');
  console.log('请检查 .env 文件中的以下变量:');
  console.log('- VITE_SUPABASE_URL');
  console.log('- VITE_SUPABASE_ANON_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testSimpleAPI() {
  console.log('🧪 开始简单的API测试...');

  try {
    // 测试数据库连接
    console.log('\n1. 🔗 测试数据库连接...');
    
    try {
      const { data, error } = await supabase
        .from('reward_punishments')
        .select('count')
        .limit(1);

      if (error) {
        console.log('❌ 连接失败:', error.message);
        console.log('\n💡 可能的原因:');
        console.log('1. reward_punishments表不存在');
        console.log('2. Supabase配置错误');
        console.log('3. 权限问题');
        
        console.log('\n📋 解决方案:');
        console.log('1. 登录Supabase控制台');
        console.log('2. 在SQL编辑器中执行 create_reward_punishment_tables.sql');
        console.log('3. 检查 .env 文件配置');
        return;
      }

      console.log('✅ 数据库连接成功！');
      
      // 获取现有数据
      const { data: existingData, error: dataError } = await supabase
        .from('reward_punishments')
        .select('*')
        .limit(5);

      if (dataError) {
        console.log('❌ 获取数据失败:', dataError.message);
      } else {
        console.log(`📋 现有 ${existingData.length} 条奖惩记录`);
        
        existingData.forEach((item, index) => {
          const icon = item.type === 'reward' ? '🏆' : '⚠️';
          const status = item.status === 'approved' ? '✅' : item.status === 'rejected' ? '❌' : '⏳';
          console.log(`  ${index + 1}. ${icon} ${item.name} ${status} (${item.date})`);
        });
      }

      // 尝试创建测试记录
      console.log('\n2. ➕ 测试创建奖惩记录...');
      
      const testStudentId = '00000000-0000-0000-0000-000000000001'; // 测试学生ID
      
      const testReward = {
        student_id: testStudentId,
        type: 'reward',
        name: 'API测试奖励',
        level: 'school',
        category: '测试',
        description: '这是一个通过API创建的测试奖励记录',
        date: '2024-01-15',
        created_by: 'test-user',
        status: 'pending'
      };

      const { data: createdData, error: createError } = await supabase
        .from('reward_punishments')
        .insert(testReward)
        .select()
        .single();

      if (createError) {
        console.log('❌ 创建失败:', createError.message);
        console.log('💡 这可能是由于外键约束（student_id不存在）');
      } else {
        console.log('✅ 创建成功:', createdData.id);
        
        // 删除测试数据
        console.log('\n3. 🗑️  清理测试数据...');
        await supabase
          .from('reward_punishments')
          .delete()
          .eq('id', createdData.id);
        console.log('✅ 测试数据已清理');
      }

    } catch (connectError) {
      console.log('❌ 连接异常:', connectError.message);
    }

  } catch (error) {
    console.error('\n❌ 测试失败:', error.message);
  }

  console.log('\n🎉 简单API测试完成！');
}

// 执行测试
testSimpleAPI().then(() => {
  console.log('\n🏁 测试脚本执行完成');
}).catch((error) => {
  console.error('\n💥 测试脚本执行失败:', error);
});