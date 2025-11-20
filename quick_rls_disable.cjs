const fs = require('fs');
const https = require('https');

// 从.env文件读取配置
function loadEnvFile() {
    try {
        const envContent = fs.readFileSync('.env', 'utf8');
        const lines = envContent.split('\n');
        const env = {};
        
        lines.forEach(line => {
            const trimmedLine = line.trim();
            if (trimmedLine && !trimmedLine.startsWith('#')) {
                const [key, ...valueParts] = trimmedLine.split('=');
                if (key && valueParts.length > 0) {
                    env[key] = valueParts.join('=');
                }
            }
        });
        
        return env;
    } catch (error) {
        console.error('读取.env文件失败:', error.message);
        return {};
    }
}

console.log('=== RLS策略禁用工具 ===\n');

const env = loadEnvFile();
const supabaseUrl = env.VITE_SUPABASE_URL;
const serviceKey = env.VITE_SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceKey) {
    console.error('❌ 找不到必要的配置信息');
    process.exit(1);
}

console.log('✅ 配置信息已读取');
console.log('📍 Supabase URL:', supabaseUrl);

// 从URL提取项目引用
const projectRef = supabaseUrl.replace('https://', '').replace('.supabase.co', '');
const restUrl = `https://${projectRef}.supabase.co/rest/v1/`;

// 准备关键SQL语句
const sqlStatements = `
-- 批量禁用RLS和删除策略的简化版本

-- 1. 禁用主要表的RLS
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teachers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.student_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teacher_student_relations DISABLE ROW LEVEL SECURITY;

-- 2. 删除常见策略
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.user_profiles;
DROP POLICY IF EXISTS "Students can view own data" ON public.students;
DROP POLICY IF EXISTS "Teachers can view students" ON public.students;
DROP POLICY IF EXISTS "Teachers can update students" ON public.students;
DROP POLICY IF EXISTS "Teachers can view own data" ON public.teachers;
DROP POLICY IF EXISTS "Teachers can update own data" ON public.teachers;
DROP POLICY IF EXISTS "Student profiles are viewable by everyone" ON public.student_profiles;
DROP POLICY IF EXISTS "Students can update own profile" ON public.student_profiles;
DROP POLICY IF EXISTS "Teachers can view student profiles" ON public.student_profiles;
DROP POLICY IF EXISTS "Teacher profiles are viewable by everyone" ON public.teacher_profiles;
DROP POLICY IF EXISTS "Teachers can update own profile" ON public.teacher_profiles;
DROP POLICY IF EXISTS "Teacher student relations are viewable by related users" ON public.teacher_student_relations;
DROP POLICY IF EXISTS "Teachers can manage own student relations" ON public.teacher_student_relations;
`;

console.log('\n=== 执行方案 ===\n');
console.log('由于安全限制，请选择以下任一方式执行：\n');

console.log('🔸 方式一：通过Supabase Dashboard（推荐）');
console.log('   1. 访问: https://app.supabase.com');
console.log(`   2. 选择项目: ${projectRef}`);
console.log('   3. 进入 SQL Editor');
console.log('   4. 粘贴并执行以下SQL：');
console.log('\n' + '='.repeat(50));
console.log(sqlStatements);
console.log('='.repeat(50));

console.log('\n🔸 方式二：使用生成的完整SQL文件');
console.log('   执行 disable_all_rls_policies.sql 文件内容');

console.log('\n🔸 方式三：使用Supabase CLI');
console.log(`   supabase sql --db-url "postgresql://postgres:[PASSWORD]@db.${projectRef}.supabase.co:5432/postgres" < disable_all_rls_policies.sql`);

console.log('\n=== 验证方法 ===\n');
console.log('执行完成后，可使用以下SQL验证：');
console.log(`
SELECT 
    'Tables with RLS enabled:' as status,
    COUNT(*) as count
FROM pg_tables 
WHERE rowsecurity = true 
    AND schemaname = 'public';

SELECT 
    'Policies remaining:' as status,
    COUNT(*) as count
FROM pg_policies 
WHERE schemaname = 'public';
`);

console.log('\n✅ RLS禁用指南已准备完成！');