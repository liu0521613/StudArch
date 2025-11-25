const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

async function checkTableStructure() {
  try {
    console.log('🔍 检查 student_profiles 表结构...');
    
    // 获取一条记录来查看字段
    const { data, error } = await supabase
      .from('student_profiles')
      .select('*')
      .limit(1);

    if (error) {
      console.error('❌ 查询失败:', error.message);
      return;
    }

    if (data && data.length > 0) {
      console.log('✅ 表结构:');
      const fields = Object.keys(data[0]);
      fields.forEach((field, index) => {
        const value = data[0][field];
        console.log(`  ${index + 1}. ${field}: ${value !== null ? value : 'NULL'}`);
      });
    } else {
      console.log('❌ 表为空');
    }
  } catch (err) {
    console.error('❌ 检查失败:', err.message);
  }
}

checkTableStructure();