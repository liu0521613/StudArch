console.log('🔍 检查前端环境问题...\n');

// 检查 Vite 配置
const fs = require('fs');
const path = require('path');

try {
  // 1. 检查 vite.config.ts
  console.log('1. 📄 检查 vite.config.ts...');
  const viteConfigPath = path.join(__dirname, 'vite.config.ts');
  
  if (fs.existsSync(viteConfigPath)) {
    const viteConfig = fs.readFileSync(viteConfigPath, 'utf8');
    console.log('✅ vite.config.ts 存在');
    
    // 检查是否有环境变量相关配置
    if (viteConfig.includes('define') || viteConfig.includes('env')) {
      console.log('✅ 找到环境变量相关配置');
    } else {
      console.log('⚠️ 未找到环境变量相关配置');
    }
  } else {
    console.log('❌ vite.config.ts 不存在');
  }

  // 2. 检查 .env 文件
  console.log('\n2. 📄 检查 .env 文件...');
  const envPath = path.join(__dirname, '.env');
  
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf8');
    console.log('✅ .env 文件存在');
    
    if (envContent.includes('VITE_SUPABASE_URL')) {
      console.log('✅ 找到 VITE_SUPABASE_URL');
    } else {
      console.log('❌ 未找到 VITE_SUPABASE_URL');
    }
    
    if (envContent.includes('VITE_SUPABASE_ANON_KEY')) {
      console.log('✅ 找到 VITE_SUPABASE_ANON_KEY');
    } else {
      console.log('❌ 未找到 VITE_SUPABASE_ANON_KEY');
    }
  } else {
    console.log('❌ .env 文件不存在');
  }

  // 3. 检查 package.json
  console.log('\n3. 📦 检查 package.json...');
  const packageJsonPath = path.join(__dirname, 'package.json');
  
  if (fs.existsSync(packageJsonPath)) {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    console.log('✅ package.json 存在');
    
    if (packageJson.dependencies && packageJson.dependencies['@supabase/supabase-js']) {
      console.log('✅ @supabase/supabase-js 已安装');
    } else {
      console.log('❌ @supabase/supabase-js 未安装');
    }
  }

  // 4. 检查环境变量加载方式
  console.log('\n4. 🔧 检查环境变量加载方式...');
  const apiFilePath = path.join(__dirname, 'src', 'supabase', 'rewardPunishmentApi.ts');
  
  if (fs.existsSync(apiFilePath)) {
    const apiContent = fs.readFileSync(apiFilePath, 'utf8');
    
    if (apiContent.includes('import.meta.env')) {
      console.log('✅ 使用 import.meta.env (Vite 标准方式)');
    }
    
    if (apiContent.includes('process.env')) {
      console.log('⚠️ 使用 process.env (可能有问题)');
    }
    
    if (apiContent.includes('|| process.env.')) {
      console.log('⚠️ 使用了回退到 process.env，这在 Vite 中可能不工作');
    }
  }

} catch (error) {
  console.error('❌ 检查过程中出错:', error.message);
}

console.log('\n📋 可能的问题和解决方案:');
console.log('1. 环境变量在 Vite 中应该使用 import.meta.env 访问');
console.log('2. 确保环境变量以 VITE_ 开头');
console.log('3. 重启开发服务器以确保环境变量生效');
console.log('4. 检查浏览器控制台的错误信息');

console.log('\n🔧 建议的修复步骤:');
console.log('1. 确认 .env 文件配置正确');
console.log('2. 重启 Vite 开发服务器');
console.log('3. 在浏览器中访问 http://localhost:5177/');
console.log('4. 打开浏览器控制台查看错误信息');
console.log('5. 访问学生详情页面并尝试保存奖惩记录');