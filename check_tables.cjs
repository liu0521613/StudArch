const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

async function checkCommonTables() {
  const commonTables = [
    'students',
    'student_profiles',
    'users',
    'teacher_students',
    'graduation_destinations',
    'reward_punishments'
  ];

  console.log('🔍 检查常见的表是否存在...\n');

  for (const tableName of commonTables) {
    try {
      const { data, error } = await supabase
        .from(tableName)
        .select('*')
        .limit(1);

      if (error) {
        console.log(`❌ ${tableName}: 不存在或无法访问 (${error.code})`);
      } else {
        console.log(`✅ ${tableName}: 存在且可访问`);
      }
    } catch (err) {
      console.log(`❌ ${tableName}: 检查失败`);
    }
  }
}

checkCommonTables();