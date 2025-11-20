import fs from 'fs';

// 读取环境配置
const envContent = fs.readFileSync('.env', 'utf8');
const supabaseUrl = envContent.split('\n').find(line => line.startsWith('VITE_SUPABASE_URL='))?.split('=')[1] || '';
const serviceKey = envContent.split('\n').find(line => line.startsWith('VITE_SUPABASE_SERVICE_ROLE_KEY='))?.split('=')[1] || '';

const projectRef = supabaseUrl.replace('https://', '').replace('.supabase.co', '');

console.log('=== 直接执行RLS禁用脚本 ===\n');

// 创建一个可以在浏览器控制台中执行的脚本
const browserScript = `
// 在Supabase Dashboard的SQL编辑器中运行此脚本
const { createClient } = supabase;

// 使用你的服务角色密钥（需要先获取）
const supabaseUrl = '${supabaseUrl}';
const supabaseKey = '${serviceKey}';

const client = createClient(supabaseUrl, supabaseKey);

async function disableAllRLS() {
    const tables = [
        'users', 'user_profiles', 'students', 'teachers', 
        'student_profiles', 'teacher_profiles', 'teacher_student_relations',
        'courses', 'classes', 'enrollments', 'assignments', 
        'submissions', 'grades', 'attendance', 'notifications',
        'messages', 'documents', 'schedules', 'subjects',
        'semesters', 'departments', 'roles', 'permissions',
        'user_roles', 'teacher_classes'
    ];
    
    console.log('开始禁用所有表的RLS...');
    
    for (const table of tables) {
        try {
            // 禁用RLS
            await client.rpc('exec_sql', {
                sql_query: \`ALTER TABLE IF EXISTS public.\${table} DISABLE ROW LEVEL SECURITY;\`
            });
            
            console.log(\`✓ 已禁用表 \${table} 的RLS\`);
        } catch (error) {
            console.log(\`⚠ 表 \${table} 处理失败:\`, error.message);
        }
    }
    
    console.log('RLS禁用操作完成！');
}

// 执行函数
disableAllRLS();
`;

console.log('方法一：浏览器控制台执行');
console.log('1. 打开 https://app.supabase.com');
console.log(`2. 选择项目: ${projectRef}`);
console.log('3. 进入 SQL Editor');
console.log('4. 在浏览器控制台中粘贴并运行以下代码：');
console.log('\n' + '='.repeat(60));
console.log(browserScript);
console.log('='.repeat(60));

console.log('\n方法二：直接SQL执行');
console.log('在SQL Editor中运行以下简化版本：');

const simpleSQL = `
-- 简化的RLS禁用脚本
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teachers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.student_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_student_relations DISABLE ROW LEVEL SECURITY;

-- 验证结果
SELECT 
    'RLS status after disable:' as info,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('users', 'user_profiles', 'students', 'teachers', 'student_profiles', 'teacher_profiles', 'teacher_student_relations')
ORDER BY tablename;
`;

console.log(simpleSQL);

// 保存浏览器脚本到文件
fs.writeFileSync('browser_rls_disable.js', browserScript);
console.log('\n✅ 浏览器脚本已保存到: browser_rls_disable.js');