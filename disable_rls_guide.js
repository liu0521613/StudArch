import fs from 'fs';

// 读取.env文件内容
const envContent = fs.readFileSync('.env', 'utf8');
const lines = envContent.split('\n');

let supabaseUrl = '';
let supabaseServiceKey = '';

lines.forEach(line => {
    if (line.startsWith('VITE_SUPABASE_URL=')) {
        supabaseUrl = line.split('=')[1];
    }
    if (line.startsWith('VITE_SUPABASE_SERVICE_ROLE_KEY=')) {
        supabaseServiceKey = line.split('=')[1];
    }
});

console.log('正在生成禁用所有RLS策略的SQL脚本...');
console.log('Supabase URL:', supabaseUrl);
console.log('服务密钥已配置');

// 输出执行指南
console.log(`
===============================================
禁用所有RLS策略执行指南
===============================================

1. 方法一：通过Supabase Dashboard执行
   - 登录到 https://app.supabase.com
   - 选择您的项目 (${supabaseUrl})
   - 进入 "SQL Editor"
   - 复制并执行 disable_all_rls_policies.sql 文件中的内容

2. 方法二：使用命令行工具
   - 安装 Supabase CLI: npm install -g supabase
   - 登录: supabase login
   - 执行: supabase db push --db-url "postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres"

3. 已生成的文件：
   - disable_all_rls_policies.sql (完整的SQL脚本)

===============================================
SQL脚本包含以下操作：
- 禁用所有表的RLS功能
- 删除所有已定义的策略
- 验证清理结果
===============================================
`);

// 读取并显示SQL文件的关键部分
const sqlContent = fs.readFileSync('disable_all_rls_policies.sql', 'utf8');
console.log('SQL脚本已准备就绪，包含以下关键操作：');

// 提取关键操作
const keyOperations = [
    'ALTER TABLE.*DISABLE ROW LEVEL SECURITY',
    'DROP POLICY.*ON'
];

keyOperations.forEach(pattern => {
    const regex = new RegExp(pattern, 'g');
    const matches = sqlContent.match(regex);
    if (matches) {
        console.log(`- ${matches.length} 个 ${pattern} 操作`);
    }
});

console.log('\n脚本执行完成后，所有表将不再有行级安全限制。');