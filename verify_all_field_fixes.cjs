#!/usr/bin/env node

/**
 * 验证所有字段修复是否完成
 */

const fs = require('fs');

console.log('🔧 验证所有字段修复');
console.log('=====================================');

const serviceFile = 'src/services/graduationDestinationService.ts';
const pageFile = 'src/pages/p-teacher_graduation_management/index.tsx';
const sqlFile = 'fix_login_tables.sql';

console.log('📋 检查修复内容...');

let allPassed = true;

// 检查服务文件
if (fs.existsSync(serviceFile)) {
  const serviceContent = fs.readFileSync(serviceFile, 'utf8');
  
  const checks = [
    {
      name: 'total_records 字段',
      test: serviceContent.includes('total_records: data.length') && 
            !serviceContent.includes('total_count:')
    },
    {
      name: 'import_file_path 字段',
      test: serviceContent.includes('import_file_path: filename') && 
            serviceContent.includes('import_file_path: filename,')
    },
    {
      name: 'raw_data 字段',
      test: serviceContent.includes('raw_data: row') && 
            !serviceContent.includes('original_data:')
    },
    {
      name: 'student_number 字段',
      test: serviceContent.includes('student_number: row.student_number') && 
            !serviceContent.includes('student_id: row.student_number')
    },
    {
      name: '接口定义更新',
      test: serviceContent.includes('import_file_path?: string') &&
            serviceContent.includes('raw_data: any') &&
            serviceContent.includes('student_number?: string')
    }
  ];
  
  checks.forEach(check => {
    console.log(`🔍 ${check.name}:`, check.test ? '✅ 通过' : '❌ 失败');
    if (!check.test) allPassed = false;
  });
} else {
  console.log('❌ 找不到服务文件');
  allPassed = false;
}

// 检查页面文件
if (fs.existsSync(pageFile)) {
  const pageContent = fs.readFileSync(pageFile, 'utf8');
  const pageCheck = pageContent.includes('batch.import_file_path') && 
                   !pageContent.includes('batch.filename');
  console.log('🔍 页面文件字段:', pageCheck ? '✅ 通过' : '❌ 失败');
  if (!pageCheck) allPassed = false;
} else {
  console.log('❌ 找不到页面文件');
  allPassed = false;
}

// 检查SQL文件
if (fs.existsSync(sqlFile)) {
  const sqlContent = fs.readFileSync(sqlFile, 'utf8');
  const sqlChecks = [
    {
      name: '数据库表结构正确',
      test: sqlContent.includes('CREATE TABLE graduation_import_batches') &&
            sqlContent.includes('total_records INTEGER') &&
            sqlContent.includes('success_count INTEGER') &&
            sqlContent.includes('failure_count INTEGER') &&
            sqlContent.includes('import_file_path TEXT')
    },
    {
      name: '失败记录表结构正确',
      test: sqlContent.includes('CREATE TABLE graduation_import_failures') &&
            sqlContent.includes('raw_data JSONB') &&
            sqlContent.includes('student_number TEXT')
    }
  ];
  
  sqlChecks.forEach(check => {
    console.log(`🔍 ${check.name}:`, check.test ? '✅ 通过' : '❌ 失败');
    if (!check.test) allPassed = false;
  });
} else {
  console.log('❌ 找不到SQL文件');
  allPassed = false;
}

console.log('\n📝 修复摘要:');
console.log('1. filename -> import_file_path');
console.log('2. total_count -> total_records');
console.log('3. original_data -> raw_data');
console.log('4. student_id -> student_number');
console.log('5. 更新所有相关接口定义');

console.log('\n🚀 下一步:');
if (allPassed) {
  console.log('✅ 所有字段修复完成！');
  console.log('1. 重新启动应用程序');
  console.log('2. 测试毕业去向批量导入');
  console.log('3. 验证不再出现字段错误');
} else {
  console.log('❌ 仍有字段不匹配问题需要修复');
}

console.log('\n✨ 预期结果:');
console.log('- 不再出现 "Could not find column" 错误');
console.log('- 批量导入批次能正常创建');
console.log('- 导入历史能正确显示文件名');
console.log('- 导入失败记录能正常保存');