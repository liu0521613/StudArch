import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://mddpbyibesqewcktlqle.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZHBieWliZXNxZXdja3RscWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNTQzNDksImV4cCI6MjA3ODkzMDM0OX0.T8QHCT3UK5f2mp76Oe9-AZpdrmPOFy1wVutxfmg49EU'
);

async function listAllTables() {
  try {
    console.log('=== 检查所有可能存在的毕业去向相关表 ===');
    
    const possibleTables = [
      'graduation_destinations',
      'graduation_destination', 
      'student_graduation_destinations',
      'student_graduation_destination',
      'student_batch_operations',
      'batch_imports',
      'graduation_import_batches',
      'import_batches',
      'student_profiles',
      'profiles',
      'users'
    ];
    
    const existingTables = [];
    
    for (const tableName of possibleTables) {
      try {
        const { data, error, count } = await supabase
          .from(tableName)
          .select('*', { count: 'exact', head: true });
        
        if (error) {
          console.log(`❌ ${tableName}: 不存在`);
        } else {
          console.log(`✅ ${tableName}: 存在 (${count} 条记录)`);
          existingTables.push(tableName);
          
          // 如果是毕业去向相关的表，查看详细信息
          if (tableName.includes('graduation') || tableName.includes('batch')) {
            const { data: tableData, error: dataError } = await supabase
              .from(tableName)
              .select('*')
              .limit(2);
            
            if (!dataError && tableData && tableData.length > 0) {
              console.log(`   字段: ${Object.keys(tableData[0]).join(', ')}`);
            }
          }
        }
      } catch (err) {
        console.log(`❌ ${tableName}: 检查失败`);
      }
    }
    
    console.log('\n=== 总结 ===');
    console.log('实际存在的表:', existingTables);
    
    // 如果找到了包含毕业数据的表，尝试查询
    const graduationTables = existingTables.filter(table => 
      table.includes('graduation') || table.includes('batch')
    );
    
    if (graduationTables.length > 0) {
      console.log('\n=== 检查毕业去向数据 ===');
      for (const table of graduationTables) {
        try {
          const { data, error } = await supabase
            .from(table)
            .select('*')
            .limit(5);
          
          if (!error && data && data.length > 0) {
            console.log(`\n表 ${table} 中的数据:`);
            data.forEach((record, index) => {
              console.log(`  记录 ${index + 1}:`, record);
            });
          }
        } catch (err) {
          console.log(`查询 ${table} 数据失败`);
        }
      }
    }
    
  } catch (err) {
    console.error('列出表失败:', err);
  }
}

listAllTables();