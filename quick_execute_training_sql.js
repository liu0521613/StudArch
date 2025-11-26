// 快速执行培养方案SQL脚本
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// 环境变量
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.VITE_SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ 缺少Supabase配置');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function executeSqlFile(filePath, description) {
  try {
    console.log(`🔄 ${description}...`);
    
    if (!fs.existsSync(filePath)) {
      console.log(`⚠️  文件不存在: ${filePath}`);
      return false;
    }
    
    const sql = fs.readFileSync(filePath, 'utf8');
    
    // 拆分SQL语句（简单分割）
    const statements = sql
      .split(';\n')
      .filter(stmt => stmt.trim() && !stmt.trim().startsWith('--'))
      .map(stmt => stmt.trim() + (stmt.endsWith(';') ? '' : ';'));
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const statement of statements) {
      if (statement.trim() === '') continue;
      
      try {
        const { error } = await supabase.rpc('exec_sql', { sql_statement: statement });
        
        if (error) {
          // 如果exec_sql不存在，尝试直接执行
          console.log(`⚠️  exec_sql不可用，跳过语句: ${statement.substring(0, 50)}...`);
        } else {
          successCount++;
        }
      } catch (err) {
        console.log(`⚠️  执行失败: ${statement.substring(0, 50)}...`);
        errorCount++;
      }
    }
    
    console.log(`✅ ${description}完成: ${successCount} 成功, ${errorCount} 跳过`);
    return successCount > 0;
    
  } catch (error) {
    console.error(`❌ ${description}失败:`, error.message);
    return false;
  }
}

async function main() {
  console.log('🚀 开始执行培养方案SQL设置...\n');
  
  try {
    // 1. 创建基础表
    await executeSqlFile(
      path.join(__dirname, 'create_training_program_tables.sql'),
      '创建培养方案基础表'
    );
    
    // 2. 创建API函数
    await executeSqlFile(
      path.join(__dirname, 'training_program_api_functions.sql'),
      '创建API函数'
    );
    
    // 3. 应用更新
    await executeSqlFile(
      path.join(__dirname, 'update_training_program_tables_fixed.sql'),
      '应用表结构更新'
    );
    
    console.log('\n🔍 检查表是否创建成功...');
    
    // 检查关键表是否存在
    const tables = [
      'training_programs',
      'training_program_courses', 
      'training_program_import_batches',
      'student_training_programs',
      'student_course_progress'
    ];
    
    for (const table of tables) {
      try {
        const { data, error } = await supabase
          .from(table)
          .select('count')
          .limit(1);
          
        if (error) {
          console.log(`❌ 表 ${table}: ${error.message}`);
        } else {
          console.log(`✅ 表 ${table}: 存在`);
        }
      } catch (err) {
        console.log(`❌ 表 ${table}: 检查失败`);
      }
    }
    
    console.log('\n🎉 SQL执行完成!');
    console.log('\n📋 下一步:');
    console.log('1. 确保API服务器运行: npm run api');
    console.log('2. 确保前端服务器运行: npm run dev');
    console.log('3. 或者同时运行: npm run start:full');
    
  } catch (error) {
    console.error('❌ 执行过程出错:', error);
  }
}

main();