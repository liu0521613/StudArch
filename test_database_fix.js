const { createClient } = require('@supabase/supabase-js');

// 从环境变量读取配置
const supabaseUrl = 'https://mddpbyibesqewcktlqle.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzM1NDM0OSwiZXhwIjoyMDc4OTMwMzQ5fQ.P2Y3IaRqJn6Tf7NjaHztGSd__3bTb_aBVioKoIK9Rq8';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testDatabaseFix() {
    console.log('🔍 开始验证数据库修复...\n');
    
    try {
        // 1. 检查表是否存在
        console.log('1️⃣ 检查表结构...');
        
        const tables = ['users', 'student_profiles', 'graduation_destinations', 'graduation_import_batches', 'graduation_import_failures'];
        
        for (const table of tables) {
            try {
                const { data, error } = await supabase.from(table).select('count', { count: 'exact', head: true });
                if (error) {
                    console.error(`❌ 表 ${table} 不存在或无权限访问:`, error.message);
                } else {
                    console.log(`✅ 表 ${table} 存在，记录数:`, data ? 'Unknown' : 0);
                }
            } catch (err) {
                console.error(`❌ 检查表 ${table} 时出错:`, err.message);
            }
        }
        
        console.log('\n2️⃣ 检查学生数据...');
        // 2. 检查学生数据
        try {
            const { data: students, error: studentError } = await supabase
                .from('student_profiles')
                .select('student_number, full_name, class_name')
                .limit(5);
                
            if (studentError) {
                console.error('❌ 获取学生数据失败:', studentError.message);
            } else {
                console.log('✅ 学生数据:');
                students?.forEach((student, index) => {
                    console.log(`   ${index + 1}. ${student.student_number} - ${student.full_name} (${student.class_name})`);
                });
            }
        } catch (err) {
            console.error('❌ 检查学生数据时出错:', err.message);
        }
        
        console.log('\n3️⃣ 测试导入函数...');
        // 3. 测试导入函数
        try {
            const { data: importResult, error: importError } = await supabase.rpc('simple_import_graduation_data', {
                p_student_number: '2021001',
                p_destination_type: 'employment',
                p_company_name: '测试公司',
                p_position: '测试岗位',
                p_salary: 10000
            });
            
            if (importError) {
                console.error('❌ 导入函数测试失败:', importError.message);
            } else {
                console.log('✅ 导入函数测试成功:', importResult);
            }
        } catch (err) {
            console.error('❌ 测试导入函数时出错:', err.message);
        }
        
        console.log('\n4️⃣ 检查毕业去向数据...');
        // 4. 检查毕业去向数据
        try {
            const { data: destinations, error: destError } = await supabase
                .from('graduation_destinations')
                .select(`
                    id,
                    destination_type,
                    company_name,
                    created_at,
                    student!inner (
                        student_number,
                        full_name
                    )
                `)
                .limit(3);
                
            if (destError) {
                console.error('❌ 获取毕业去向数据失败:', destError.message);
            } else {
                console.log('✅ 毕业去向数据:');
                destinations?.forEach((dest, index) => {
                    console.log(`   ${index + 1}. ${dest.student.student_number} - ${dest.student.full_name} -> ${dest.destination_type} (${dest.company_name})`);
                });
            }
        } catch (err) {
            console.error('❌ 检查毕业去向数据时出错:', err.message);
        }
        
        console.log('\n5️⃣ 测试批次创建...');
        // 5. 测试批次创建
        try {
            const { data: batchResult, error: batchError } = await supabase.rpc('create_import_batch', {
                p_batch_name: '测试批次',
                p_imported_by: 'test-user',
                p_total_records: 1
            });
            
            if (batchError) {
                console.error('❌ 批次创建测试失败:', batchError.message);
            } else {
                console.log('✅ 批次创建测试成功，批次ID:', batchResult);
            }
        } catch (err) {
            console.error('❌ 测试批次创建时出错:', err.message);
        }
        
        console.log('\n🎉 数据库验证完成！');
        
    } catch (error) {
        console.error('❌ 验证过程中发生严重错误:', error);
    }
}

// 运行测试
testDatabaseFix();