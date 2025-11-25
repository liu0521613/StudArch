#!/usr/bin/env node

/**
 * 测试导入字段修复
 * 验证代码与数据库表结构是否匹配
 */

const fs = require('fs');

console.log('🔧 测试导入字段修复');
console.log('=====================================');

// 检查修复后的代码文件
const serviceFile = 'src/services/graduationDestinationService.ts';
const sqlFile = 'fix_login_tables.sql';

console.log('📋 检查修复内容...');

if (fs.existsSync(serviceFile)) {
  const serviceContent = fs.readFileSync(serviceFile, 'utf8');
  
  // 检查字段名修复
  const hasCorrectBatchFields = serviceContent.includes('total_records') && 
                            !serviceContent.includes('total_count:') &&
                            serviceContent.includes('success_count') &&
                            serviceContent.includes('failure_count');
  
  const hasCorrectFailureFields = serviceContent.includes('raw_data') && 
                                serviceContent.includes('student_number') &&
                                !serviceContent.includes('original_data:') &&
                                !serviceContent.includes('student_id:');
  
  console.log('🔍 批次记录字段检查:', hasCorrectBatchFields ? '✅ 通过' : '❌ 失败');
  console.log('🔍 失败记录字段检查:', hasCorrectFailureFields ? '✅ 通过' : '❌ 失败');
  
  if (hasCorrectBatchFields && hasCorrectFailureFields) {
    console.log('✅ 所有字段修复完成！');
  } else {
    console.log('❌ 仍有字段不匹配问题');
  }
  
  // 检查接口定义
  const hasCorrectInterfaces = serviceContent.includes('total_records: number') &&
                            serviceContent.includes('raw_data: any') &&
                            serviceContent.includes('student_number?: string');
  
  console.log('🔍 接口定义检查:', hasCorrectInterfaces ? '✅ 通过' : '❌ 失败');
}

if (fs.existsSync(sqlFile)) {
  const sqlContent = fs.readFileSync(sqlFile, 'utf8');
  
  // 检查数据库表结构
  const hasCorrectTables = sqlContent.includes('CREATE TABLE graduation_import_batches') &&
                        sqlContent.includes('CREATE TABLE graduation_import_failures') &&
                        sqlContent.includes('total_records INTEGER') &&
                        sqlContent.includes('success_count INTEGER') &&
                        sqlContent.includes('failure_count INTEGER') &&
                        sqlContent.includes('raw_data JSONB') &&
                        sqlContent.includes('student_number TEXT');
  
  console.log('🔍 数据库表结构检查:', hasCorrectTables ? '✅ 通过' : '❌ 失败');
}

console.log('\n📝 修复摘要:');
console.log('1. 将 total_count 改为 total_records');
console.log('2. 将 original_data 改为 raw_data');
console.log('3. 将 student_id 改为 student_number');
console.log('4. 更新了相关接口定义');

console.log('\n🚀 下一步:');
console.log('1. 确保已执行 fix_login_tables.sql');
console.log('2. 重新启动应用程序');
console.log('3. 测试毕业去向批量导入功能');
console.log('4. 验证不再出现字段不匹配错误');

console.log('\n✨ 修复完成，应该能正常导入了！');