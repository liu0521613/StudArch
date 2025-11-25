import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTM0NDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function executeSQLFile(filePath) {
  try {
    // 如果没有提供文件路径，则检查默认的graduation_destinations表
    if (!filePath) {
      await checkAndCreateTables();
      return;
    }

    console.log(`执行SQL文件: ${filePath}`);
    
    // 检查文件是否存在
    if (!fs.existsSync(filePath)) {
      console.error(`❌ 文件不存在: ${filePath}`);
      return;
    }

    // 读取SQL文件内容
    const sqlContent = fs.readFileSync(filePath, 'utf8');
    
    // 将SQL内容按分号分割（但要注意函数定义中的分号）
    const sqlStatements = sqlContent
      .split(/;\s*(?=(?:[^']*'[^']*')*[^']*$)/)  // 分割SQL语句，忽略字符串中的分号
      .filter(stmt => stmt.trim() && !stmt.trim().startsWith('--'));

    console.log(`找到 ${sqlStatements.length} 个SQL语句，开始执行...`);

    let successCount = 0;
    let errorCount = 0;

    for (let i = 0; i < sqlStatements.length; i++) {
      const statement = sqlStatements[i].trim();
      if (!statement) continue;

      try {
        console.log(`\n执行语句 ${i + 1}/${sqlStatements.length}:`);
        console.log(statement.substring(0, 100) + (statement.length > 100 ? '...' : ''));

        // 使用supabase.rpc执行自定义SQL（需要先创建exec_sql函数）
        // 或者使用REST API的POST请求到/rest/v1/rpc/exec_sql
        const { error } = await supabase
          .from('rpc')
          .select('exec_sql')
          .eq('sql', statement);

        if (error) {
          console.warn(`⚠️  语句执行失败 (可能是因为需要手动执行):`, error.message);
          
          // 显示需要手动执行的语句
          console.log('\n需要手动执行的SQL:');
          console.log(statement);
          console.log(';');
          
          errorCount++;
        } else {
          console.log('✅ 执行成功');
          successCount++;
        }
      } catch (err) {
        console.error(`❌ 语句执行出错:`, err.message);
        errorCount++;
      }
    }

    console.log(`\n执行完成: 成功 ${successCount} 个，失败 ${errorCount} 个`);
    
    if (errorCount > 0) {
      console.log('\n⚠️  部分SQL语句可能需要在Supabase控制台的SQL编辑器中手动执行');
      console.log('请访问: https://mddpbyibesqewcktlqle.supabase.co/project/sql');
    }

  } catch (err) {
    console.error('执行SQL文件失败:', err);
  }
}

async function checkAndCreateTables() {
  try {
    console.log('检查 graduation_destinations 表是否存在...');
    
    // 先检查表是否存在
    const { data, error } = await supabase
      .from('graduation_destinations')
      .select('*')
      .limit(1);
    
    if (error && error.code === 'PGRST205') {
      console.log('❌ graduation_destinations 表不存在');
      console.log('请在 Supabase 控制台的 SQL 编辑器中执行以下命令：');
      console.log('文件路径: create_graduation_tables.sql');
      
      // 读取并显示SQL内容的前几行
      const sql = fs.readFileSync('create_graduation_tables.sql', 'utf8');
      console.log('\n=== SQL 脚本内容 ===');
      console.log(sql);
    } else if (error) {
      console.error('其他错误:', error);
    } else {
      console.log('✅ graduation_destinations 表已存在');
      console.log('数据记录:', data?.length || 0, '条');
      
      // 如果表存在但没数据，尝试插入示例数据
      if (!data || data.length === 0) {
        console.log('表中没有数据，请手动插入数据或检查导入流程');
      }
    }
    
  } catch (err) {
    console.error('检查失败:', err);
  }
}

// 获取命令行参数
const filePath = process.argv[2];
executeSQLFile(filePath);