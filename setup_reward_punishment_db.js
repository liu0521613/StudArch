import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import 'dotenv/config';

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

console.log('🔧 正在连接到Supabase数据库...');
const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function setupDatabase() {
  try {
    // 读取SQL文件
    console.log('📄 读取SQL脚本...');
    const sqlScript = readFileSync('./create_reward_punishment_tables.sql', 'utf8');

    // 分割SQL语句（简单分割，按分号分隔）
    const statements = sqlScript
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

    console.log(`🚀 准备执行 ${statements.length} 个SQL语句...`);

    let successCount = 0;
    let errorCount = 0;

    // 执行每个SQL语句
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      console.log(`\n📝 执行第 ${i + 1}/${statements.length} 个语句:`);
      console.log(statement.substring(0, 100) + (statement.length > 100 ? '...' : ''));

      try {
        const { data, error } = await supabase.rpc('exec_sql', { sql_query: statement });

        if (error) {
          // 如果rpc不存在，尝试直接使用SQL
          if (error.message.includes('function exec_sql')) {
            console.log('⚠️  exec_sql函数不存在，跳过直接SQL执行');
            console.log('ℹ️  请手动执行SQL脚本或在Supabase控制台中运行');
            continue;
          }
          throw error;
        }

        console.log('✅ 执行成功');
        successCount++;
      } catch (error) {
        console.log('❌ 执行失败:', error.message);
        errorCount++;
      }
    }

    console.log('\n📊 执行结果:');
    console.log(`✅ 成功: ${successCount} 个语句`);
    console.log(`❌ 失败: ${errorCount} 个语句`);

    // 验证表是否创建成功
    console.log('\n🔍 验证表创建情况...');
    try {
      const { data: tables, error: tablesError } = await supabase
        .from('information_schema.tables')
        .select('table_name')
        .eq('schema', 'public')
        .in('table_name', ['reward_punishments', 'reward_punishment_attachments']);

      if (tablesError) {
        console.log('⚠️  无法验证表创建情况:', tablesError.message);
      } else {
        console.log('📋 已创建的表:', tables.map(t => t.table_name));
      }

      // 检查数据
      const { data: rewardData, error: rewardError } = await supabase
        .from('reward_punishments')
        .select('count')
        .limit(1);

      if (rewardError) {
        console.log('⚠️  无法访问reward_punishments表:', rewardError.message);
      } else {
        console.log('🎉 reward_punishments表可正常访问');
      }
    } catch (verifyError) {
      console.log('⚠️  验证过程出错:', verifyError.message);
    }

    if (successCount > 0) {
      console.log('\n🎉 数据库设置完成！');
      console.log('📖 现在您可以使用奖惩信息管理功能了');
    } else {
      console.log('\n❌ 数据库设置失败');
      console.log('💡 请手动在Supabase控制台中执行以下SQL脚本:');
      console.log('📄 create_reward_punishment_tables.sql');
    }

  } catch (error) {
    console.error('❌ 数据库设置失败:', error.message);
    console.log('\n📋 手动设置步骤:');
    console.log('1. 打开Supabase控制台');
    console.log('2. 进入SQL编辑器');
    console.log('3. 复制并执行 create_reward_punishment_tables.sql 中的内容');
  }
}

// 执行设置
setupDatabase().then(() => {
  console.log('\n🏁 设置脚本执行完成');
  process.exit(0);
}).catch((error) => {
  console.error('\n💥 设置脚本执行失败:', error);
  process.exit(1);
});