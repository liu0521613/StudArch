const { createClient } = require('@supabase/supabase-js');

// 从环境变量读取配置
const supabaseUrl = 'https://mddpbyibesqewcktlqle.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzM1NDM0OSwiZXhwIjoyMDc4OTMwMzQ5fQ.P2Y3IaRqJn6Tf7NjaHztGSd__3bTb_aBVioKoIK9Rq8';

const supabase = createClient(supabaseUrl, supabaseKey);

async function executeSQL() {
    const fs = require('fs');
    
    try {
        console.log('开始创建数据库表...');
        
        // 读取并执行SQL脚本
        const sqlScript = fs.readFileSync('./check_and_create_tables.sql', 'utf8');
        
        // 分割SQL语句（简单的分号分割）
        const statements = sqlScript.split(';').filter(s => s.trim().length > 0);
        
        for (let i = 0; i < statements.length; i++) {
            const statement = statements[i].trim();
            if (statement.startsWith('--') || statement.length < 10) continue;
            
            console.log(`执行语句 ${i + 1}/${statements.length}:`, statement.substring(0, 50) + '...');
            
            try {
                const { data, error } = await supabase.rpc('exec_sql', { sql_statement: statement });
                if (error) {
                    console.error('语句执行失败:', error);
                } else {
                    console.log('执行成功');
                }
            } catch (err) {
                console.error('执行出错:', err.message);
            }
        }
        
        console.log('数据库表创建完成！');
        
        // 验证表是否创建成功
        const { data: tables, error: tablesError } = await supabase
            .from('information_schema.tables')
            .select('table_name')
            .eq('table_schema', 'public')
            .in('table_name', ['users', 'student_profiles', 'graduation_destinations', 'graduation_import_batches']);
            
        if (tablesError) {
            console.error('查询表失败:', tablesError);
        } else {
            console.log('已创建的表:', tables.map(t => t.table_name));
        }
        
    } catch (error) {
        console.error('执行失败:', error);
    }
}

executeSQL();