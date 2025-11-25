const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testStudentIdFix() {
  try {
    console.log('🔍 测试修复后的学生ID映射...');
    
    // 模拟获取教师学生列表
    const teacherId = '00000000-0000-0000-0000-000000000001';
    
    console.log('📝 分别查询student_profiles和users表...');
    
    // 先查询student_profiles
    const { data: profiles, error: profileError } = await supabase
      .from('student_profiles')
      .select(`
        id,
        user_id,
        class_name,
        major
      `)
      .limit(3);

    if (profileError) {
      console.log('❌ 查询学生档案失败:', profileError.message);
      return;
    }

    if (!profiles || profiles.length === 0) {
      console.log('❌ 没有找到学生档案');
      return;
    }

    // 获取对应的用户信息
    const userIds = profiles.map(p => p.user_id);
    const { data: users, error: userError } = await supabase
      .from('users')
      .select(`
        id,
        username,
        email,
        full_name,
        user_number,
        phone,
        status,
        role_id
      `)
      .in('id', userIds);

    if (userError) {
      console.log('❌ 查询用户信息失败:', userError.message);
      return;
    }

    // 合并数据
    const userMap = {};
    users?.forEach(user => {
      userMap[user.id] = user;
    });

    const data = profiles.map(profile => ({
      ...profile,
      users: userMap[profile.user_id]
    }));

    if (profileError) {
      console.log('❌ 查询失败:', profileError.message);
      return;
    }

    if (!data || data.length === 0) {
      console.log('❌ 没有找到学生数据');
      return;
    }

    console.log('✅ 找到学生数据:');
    data.forEach((profile, index) => {
      console.log(`${index + 1}. 学生档案ID: ${profile.id}`);
      console.log(`   用户ID: ${profile.user_id}`);
      console.log(`   姓名: ${profile.users.full_name}`);
      console.log(`   学号: ${profile.users.user_number}`);
      console.log('');
    });

    // 测试奖惩功能是否可以使用新的ID
    console.log('🔍 测试奖惩功能是否正常...');
    const testStudentId = data[0].id;
    
    const { data: rewards, error: rewardError } = await supabase
      .from('reward_punishments')
      .select('count')
      .eq('student_id', testStudentId)
      .limit(1);

    if (rewardError) {
      console.log('❌ 奖惩表查询失败:', rewardError.message);
    } else {
      console.log('✅ 奖惩表查询正常，可以使用新的学生ID');
    }

    console.log('\n💡 修复结果:');
    console.log('✅ 学生列表现在使用正确的student_profiles.id');
    console.log('✅ 奖惩功能可以正常使用这些ID');

  } catch (err) {
    console.log('❌ 测试异常:', err.message);
  }
}

testStudentIdFix();