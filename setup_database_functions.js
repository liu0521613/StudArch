// 简单的SQL执行脚本
const fs = require('fs');
const path = require('path');

// 读取数据库函数SQL文件
const sqlFile = path.join(__dirname, 'fix_database_functions_for_real_data.sql');

try {
  const sqlContent = fs.readFileSync(sqlFile, 'utf8');
  
  console.log('数据库函数创建脚本已准备');
  console.log('请在Supabase SQL编辑器中执行以下文件：');
  console.log(sqlFile);
  
  // 将SQL内容写入一个单独的文件供用户复制
  const outputFile = path.join(__dirname, 'database_functions_to_execute.sql');
  fs.writeFileSync(outputFile, sqlContent);
  console.log(`\nSQL内容已写入文件：${outputFile}`);
  console.log('请复制该文件内容到Supabase SQL编辑器中执行');
  
} catch (error) {
  console.error('读取SQL文件失败:', error.message);
}