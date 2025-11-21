#!/usr/bin/env node

/**
 * 毕业导入问题快速修复脚本
 * 解决 "导入完成！成功 0 条，失败 5 条" 问题
 */

console.log('🔧 毕业导入问题快速修复');
console.log('=====================================');

const fs = require('fs');
const path = require('path');

// 检查SQL文件是否存在
const sqlFile = 'simple_fix_final.sql';

if (fs.existsSync(sqlFile)) {
  console.log('✅ 找到修复SQL文件:', sqlFile);
  
  // 读取SQL文件内容
  const sqlContent = fs.readFileSync(sqlFile, 'utf8');
  
  console.log('📋 修复内容包括:');
  console.log('   1. 创建/修复用户表和学生档案表');
  console.log('   2. 创建毕业去向表和导入相关表');
  console.log('   3. 创建 simple_import_graduation_data 存储过程');
  console.log('   4. 禁用RLS策略');
  console.log('   5. 插入测试数据');
  
  console.log('\n🚀 执行步骤:');
  console.log('   1. 登录 Supabase Dashboard');
  console.log('   2. 进入 SQL Editor');
  console.log('   3. 复制并执行 ' + sqlFile + ' 的全部内容');
  console.log('   4. 等待执行完成');
  console.log('   5. 重新测试导入功能');
  
  // 创建一个可复制的内容摘要
  const summary = `
-- 简单测试语句（执行完SQL后可以运行这个测试）
SELECT '测试学生数据:' as info;
SELECT student_number, full_name, class_name FROM student_profiles LIMIT 3;

SELECT '测试导入函数:' as info;
SELECT simple_import_graduation_data('2021001', 'employment', '测试公司', '测试职位', 10000) as result;

SELECT '验证导入结果:' as info;
SELECT COUNT(*) as graduation_count FROM graduation_destinations;
`;
  
  console.log('\n📝 测试验证SQL:');
  console.log(summary);
  
  // 检查关键内容
  const hasImportFunction = sqlContent.includes('simple_import_graduation_data');
  const hasStudentData = sqlContent.includes('2021001');
  const hasTables = sqlContent.includes('graduation_destinations') && sqlContent.includes('graduation_import_batches');
  
  console.log('\n🔍 文件完整性检查:');
  console.log('   ✅ 包含导入函数:', hasImportFunction);
  console.log('   ✅ 包含测试数据:', hasStudentData);
  console.log('   ✅ 包含必要表:', hasTables);
  
  if (hasImportFunction && hasStudentData && hasTables) {
    console.log('\n🎉 SQL文件完整，可以执行修复！');
  } else {
    console.log('\n⚠️  SQL文件可能不完整，请检查内容');
  }
  
} else {
  console.log('❌ 未找到修复文件:', sqlFile);
  console.log('请确保在正确的项目目录中运行此脚本');
}

console.log('\n📞 如果问题持续存在，请检查:');
console.log('   1. Supabase 连接是否正常');
console.log('   2. 是否有足够的权限执行DDL操作');
console.log('   3. Excel文件中的学号是否存在于数据库中');
console.log('   4. 去向类型是否使用正确的英文值');

console.log('\n✨ 修复完成后，应该能看到导入成功的记录！');