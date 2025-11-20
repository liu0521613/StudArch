
// 在Supabase Dashboard的SQL编辑器中运行此脚本
const { createClient } = supabase;

// 使用你的服务角色密钥（需要先获取）
const supabaseUrl = 'https://mddpbyibesqewcktlqle.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzM1NDM0OSwiZXhwIjoyMDc4OTMwMzQ5fQ.P2Y3IaRqJn6Tf7NjaHztGSd__3bTb_aBVioKoIK9Rq8';

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
                sql_query: `ALTER TABLE IF EXISTS public.${table} DISABLE ROW LEVEL SECURITY;`
            });
            
            console.log(`✓ 已禁用表 ${table} 的RLS`);
        } catch (error) {
            console.log(`⚠ 表 ${table} 处理失败:`, error.message);
        }
    }
    
    console.log('RLS禁用操作完成！');
}

// 执行函数
disableAllRLS();
