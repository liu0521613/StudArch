import { RewardPunishmentApi } from './src/supabase/rewardPunishmentApi.js';

async function testRewardPunishmentAPI() {
  console.log('🧪 开始测试奖惩信息API...');

  try {
    // 测试数据库连接
    console.log('\n1. 🔗 测试数据库连接...');
    const isConnected = await RewardPunishmentApi.checkConnection();
    console.log(isConnected ? '✅ 数据库连接成功' : '❌ 数据库连接失败');

    // 测试获取奖惩统计
    console.log('\n2. 📊 测试获取奖惩统计...');
    const stats = await RewardPunishmentApi.getRewardPunishmentStats('test-student-id');
    console.log('📈 统计结果:', stats);

    // 测试获取奖惩列表
    console.log('\n3. 📋 测试获取奖惩列表...');
    const listResult = await RewardPunishmentApi.getStudentRewardPunishments('test-student-id', {
      page: 1,
      limit: 10
    });
    console.log(`📝 获取到 ${listResult.items.length} 条记录`);
    
    if (listResult.items.length > 0) {
      console.log('🏷️  示例数据:');
      listResult.items.forEach((item, index) => {
        console.log(`  ${index + 1}. ${item.type === 'reward' ? '🏆 奖励' : '⚠️ 惩罚'}: ${item.name}`);
      });
    }

    // 测试创建奖惩记录
    console.log('\n4. ➕ 测试创建奖惩记录...');
    const newReward = {
      student_id: 'test-student-id',
      type: 'reward',
      name: 'API测试奖励',
      level: 'school',
      category: '测试',
      description: '这是一个通过API创建的测试奖励记录',
      date: '2024-01-15',
      created_by: 'test-user'
    };

    try {
      const created = await RewardPunishmentApi.createRewardPunishment(newReward);
      console.log('✅ 创建成功:', created.id);
      
      // 测试更新
      console.log('\n5. ✏️  测试更新奖惩记录...');
      const updated = await RewardPunishmentApi.updateRewardPunishment(created.id, {
        name: 'API测试奖励-已更新',
        description: '这是一个通过API更新的测试奖励记录'
      });
      console.log('✅ 更新成功:', updated.name);

      // 测试删除
      console.log('\n6. 🗑️  测试删除奖惩记录...');
      await RewardPunishmentApi.deleteRewardPunishment(created.id);
      console.log('✅ 删除成功');

    } catch (createError) {
      console.log('❌ 创建/更新/删除测试失败:', createError.message);
      console.log('💡 这可能是因为表不存在，请先执行数据库设置');
    }

    console.log('\n🎉 API测试完成！');

  } catch (error) {
    console.error('\n❌ API测试失败:', error.message);
    console.log('\n📋 可能的解决方案:');
    console.log('1. 检查 .env 文件中的Supabase配置');
    console.log('2. 在Supabase控制台中执行 create_reward_punishment_tables.sql');
    console.log('3. 确保Supabase项目已启动且可访问');
  }
}

// 执行测试
testRewardPunishmentAPI().then(() => {
  console.log('\n🏁 测试脚本执行完成');
}).catch((error) => {
  console.error('\n💥 测试脚本执行失败:', error);
});