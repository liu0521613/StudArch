// 培养方案系统快速启动脚本
// 一键设置并启动培养方案系统

import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { exec } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 加载环境变量
import dotenv from 'dotenv';
dotenv.config();

// 颜色输出函数
const colors = {
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  white: '\x1b[37m',
  reset: '\x1b[0m'
};

function log(message, color = colors.white) {
  console.log(`${color}${message}${colors.reset}`);
}

function logSuccess(message) {
  log(`✅ ${message}`, colors.green);
}

function logInfo(message) {
  log(`ℹ️  ${message}`, colors.blue);
}

function logWarning(message) {
  log(`⚠️  ${message}`, colors.yellow);
}

function logError(message) {
  log(`❌ ${message}`, colors.red);
}

// 执行命令的辅助函数
function executeCommand(command, description) {
  return new Promise((resolve, reject) => {
    logInfo(`正在${description}...`);
    exec(command, (error, stdout, stderr) => {
      if (error) {
        logError(`${description}失败: ${error.message}`);
        reject(error);
      } else {
        logSuccess(`${description}完成`);
        resolve({ stdout, stderr });
      }
    });
  });
}

// 主要设置流程
async function quickStart() {
  log('🚀 培养方案系统快速启动', colors.blue);
  log('=====================================', colors.white);
  
  try {
    // 1. 检查环境变量
    logInfo('检查环境配置...');
    const supabaseUrl = process.env.VITE_SUPABASE_URL;
    const supabaseKey = process.env.VITE_SUPABASE_SERVICE_ROLE_KEY;
    
    if (!supabaseUrl || !supabaseKey) {
      logError('环境变量配置不完整！请检查 .env 文件');
      log('需要配置以下环境变量：', colors.yellow);
      log('- VITE_SUPABASE_URL', colors.yellow);
      log('- VITE_SUPABASE_SERVICE_ROLE_KEY', colors.yellow);
      process.exit(1);
    }
    
    logSuccess('环境变量配置检查通过');
    
    // 2. 测试数据库连接
    logInfo('测试数据库连接...');
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    try {
      const { data, error } = await supabase.from('users').select('count', { count: 'exact', head: true });
      if (error) throw error;
      logSuccess('数据库连接正常');
    } catch (dbError) {
      logError('数据库连接失败: ' + dbError.message);
      process.exit(1);
    }
    
    // 3. 执行数据库设置
    logInfo('设置培养方案数据库表...');
    
    // 读取并执行SQL文件
    const tableSQL = fs.readFileSync(path.join(__dirname, 'create_training_program_tables.sql'), 'utf8');
    const functionSQL = fs.readFileSync(path.join(__dirname, 'training_program_api_functions.sql'), 'utf8');
    const updateSQL = fs.readFileSync(path.join(__dirname, 'update_training_program_tables.sql'), 'utf8');
    
    log('正在执行数据库脚本...', colors.yellow);
    
    // 由于直接执行SQL可能需要特殊权限，我们提供手动执行指导
    logWarning('请手动在Supabase控制台执行以下SQL文件（按顺序）：');
    log('1. create_training_program_tables.sql', colors.white);
    log('2. training_program_api_functions.sql', colors.white);
    log('3. update_training_program_tables.sql', colors.white);
    log('', colors.white);
    
    log('或者运行以下命令：', colors.blue);
    log('npm run setup-training', colors.white);
    log('', colors.white);
    
    // 4. 启动服务
    const startServices = async () => {
      logInfo('启动服务...');
      
      try {
        // 检查是否已安装依赖
        const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        const requiredDeps = ['express', 'cors', 'concurrently'];
        const missingDeps = requiredDeps.filter(dep => !packageJson.dependencies[dep]);
        
        if (missingDeps.length > 0) {
          logWarning(`缺少依赖: ${missingDeps.join(', ')}`);
          await executeCommand('npm install', '安装依赖');
        }
        
        logSuccess('依赖检查完成');
        
        // 启动服务
        logInfo('启动API服务器和前端开发服务器...');
        log('API服务器: http://localhost:3001', colors.blue);
        log('前端开发服务器: http://localhost:5173', colors.blue);
        log('', colors.white);
        log('按 Ctrl+C 停止服务', colors.yellow);
        
        // 启动服务
        const { spawn } = await import('cross-spawn');
        const child = spawn('npm', ['run', 'start:full'], { stdio: 'inherit' });
        
        child.on('close', (code) => {
          if (code !== 0) {
            logError(`服务启动失败，退出码: ${code}`);
          } else {
            logInfo('服务已停止');
          }
        });
        
      } catch (error) {
        logError('启动服务失败: ' + error.message);
        log('请手动执行: npm run start:full', colors.yellow);
      }
    };
    
    // 询问是否继续启动服务
    const readline = await import('readline');
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    rl.question('是否现在启动服务？(y/n): ', (answer) => {
      if (answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes') {
        startServices();
      } else {
        logInfo('您可以稍后运行以下命令启动服务：');
        log('npm run start:full', colors.white);
      }
      rl.close();
    });
    
  } catch (error) {
    logError('启动过程中发生错误: ' + error.message);
    process.exit(1);
  }
}

// 显示帮助信息
function showHelp() {
  log('培养方案系统快速启动脚本', colors.blue);
  log('=====================================', colors.white);
  log('', colors.white);
  log('使用方法：', colors.white);
  log('node 快速启动培养方案系统.js', colors.green);
  log('', colors.white);
  log('功能：', colors.white);
  log('✅ 检查环境配置', colors.white);
  log('✅ 测试数据库连接', colors.white);
  log('✅ 设置数据库表结构', colors.white);
  log('✅ 启动前后端服务', colors.white);
  log('', colors.white);
  log('手动启动步骤：', colors.yellow);
  log('1. npm run setup-training  # 设置数据库', colors.white);
  log('2. npm run start:full        # 启动服务', colors.white);
  log('', colors.white);
  log('访问地址：', colors.blue);
  log('前端: http://localhost:5173', colors.white);
  log('API:  http://localhost:3001/api/health', colors.white);
}

// 主程序
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  showHelp();
} else {
  quickStart();
}

export { quickStart };