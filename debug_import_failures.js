// 调试导入失败信息的脚本
const { createClient } = require('@supabase/supabase-js');

// 需要配置你的Supabase连接
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'your-anon-key';

const supabase = createClient(supabaseUrl, supabaseKey);

async function debugImportFailures() {
  console.log('🔍 调试导入失败信息...');
  
  try {
    // 1. 获取最新的导入批次
    console.log('\n1. 获取最新导入批次...');
    const { data: batches, error: batchError } = await supabase
      .from('graduation_import_batches')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);
    
    if (batchError) {
      console.error('获取批次失败:', batchError);
      return;
    }
    
    console.log(`找到 ${batches.length} 个批次:`);
    batches.forEach((batch, index) => {
      console.log(`\n批次 ${index + 1}:`);
      console.log(`- 名称: ${batch.batch_name}`);
      console.log(`- 文件: ${batch.filename}`);
      console.log(`- 总数: ${batch.total_count}`);
      console.log(`- 成功: ${batch.success_count}`);
      console.log(`- 失败: ${batch.failed_count}`);
      console.log(`- 状态: ${batch.status}`);
      console.log(`- 创建时间: ${batch.created_at}`);
    });
    
    if (batches.length === 0) {
      console.log('没有找到导入批次');
      return;
    }
    
    // 2. 获取失败详情
    const latestBatch = batches[0];
    if (latestBatch.failed_count > 0) {
      console.log(`\n2. 获取批次 "${latestBatch.batch_name}" 的失败详情...`);
      
      const { data: failures, error: failureError } = await supabase
        .from('graduation_import_failures')
        .select('*')
        .eq('batch_id', latestBatch.id)
        .order('row_number', { ascending: true });
      
      if (failureError) {
        console.error('获取失败详情错误:', failureError);
        return;
      }
      
      console.log(`\n📋 失败详情 (${failures.length} 条):`);
      failures.forEach((failure, index) => {
        console.log(`\n${index + 1}. 第${failure.row_number}行失败:`);
        console.log(`   学号: ${failure.student_id}`);
        console.log(`   错误: ${failure.error_message}`);
        console.log(`   原始数据: ${JSON.stringify(failure.original_data, null, 2)}`);
      });
      
      // 3. 分析常见错误类型
      console.log('\n3. 错误分析:');
      const errorTypes = {};
      failures.forEach(failure => {
        const errorMsg = failure.error_message;
        errorTypes[errorMsg] = (errorTypes[errorMsg] || 0) + 1;
      });
      
      console.log('错误类型统计:');
      Object.entries(errorTypes).forEach(([error, count]) => {
        console.log(`- ${error}: ${count}次`);
      });
    }
    
    // 4. 检查学生数据是否存在
    console.log('\n4. 检查学生数据...');
    const { data: students, error: studentError } = await supabase
      .from('student_profiles')
      .select('student_number, full_name, class_name')
      .limit(10);
    
    if (studentError) {
      console.error('获取学生数据失败:', studentError);
    } else {
      console.log(`系统中有 ${students.length} 个学生:`);
      students.forEach(student => {
        console.log(`- ${student.student_number}: ${student.full_name} (${student.class_name})`);
      });
    }
    
    // 5. 检查毕业去向表结构
    console.log('\n5. 检查表结构...');
    const { data: tableInfo, error: tableError } = await supabase
      .from('graduation_destinations')
      .select('*')
      .limit(1);
    
    if (tableError) {
      console.error('毕业去向表错误:', tableError);
    } else {
      console.log('毕业去向表结构正常');
    }
    
  } catch (error) {
    console.error('调试过程中发生错误:', error);
  }
}

// 运行调试
debugImportFailures();