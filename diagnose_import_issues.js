// 诊断导入问题的通用脚本
console.log('🔍 诊断导入失败问题...');

// 模拟常见导入错误类型
const commonErrors = [
  {
    type: '学生不存在',
    message: '找不到学号为 XXX 的学生',
    solution: '确保学号存在于系统中，或先导入学生数据'
  },
  {
    type: '去向类型无效', 
    message: '无效的去向类型: XXX',
    solution: '使用有效的去向类型：employment/furtherstudy/abroad/entrepreneurship/unemployed/other'
  },
  {
    type: '数据库连接',
    message: '数据库错误: connection failed',
    solution: '检查数据库连接配置和网络状态'
  },
  {
    type: '字段验证',
    message: '字段 XXX 不能为空',
    solution: '确保必填字段（学号、去向类型）不为空'
  },
  {
    type: '数据格式',
    message: 'invalid input syntax for type',
    solution: '检查数据格式是否正确，特别是日期和数字字段'
  },
  {
    type: '权限问题',
    message: 'permission denied for table graduation_destinations',
    solution: '检查用户权限和RLS策略设置'
  }
];

console.log('\n📋 常见导入错误类型:');
commonErrors.forEach((error, index) => {
  console.log(`${index + 1}. ${error.type}`);
  console.log(`   错误信息: ${error.message}`);
  console.log(`   解决方案: ${error.solution}`);
  console.log('');
});

// 检查清单
const checkList = [
  '📊 Excel文件格式是否正确？',
  '👥 学号是否存在于系统中？', 
  '🎯 去向类型是否有效？',
  '🔗 数据库连接是否正常？',
  '🔑 用户权限是否足够？',
  '📝 必填字段是否都有值？',
  '🗃️ 数据类型是否匹配？',
  '🚫 RLS策略是否阻止操作？'
];

console.log('\n🔍 导入失败检查清单:');
checkList.forEach((item, index) => {
  console.log(`${index + 1}. ${item}`);
});

// 模拟Excel数据验证
console.log('\n📝 Excel数据验证示例:');
const sampleRows = [
  ['2021001', 'employment', '阿里巴巴', '前端开发', '15000', '杭州', '', '', '', '', '', '', ''],
  ['2021002', 'furtherstudy', '', '', '', '清华大学', '计算机', '硕士', '', '', '', '', ''],
  ['2021003', 'invalid_type', '', '', '', '', '', '', '', '', '', '', ''], // 错误的去向类型
  ['', 'employment', '', '', '', '', '', '', '', '', '', '', ''], // 空学号
];

sampleRows.forEach((row, index) => {
  const [studentNumber, destType] = row;
  let status = '✅ 有效';
  let issue = '';
  
  if (!studentNumber || studentNumber.trim() === '') {
    status = '❌ 错误';
    issue = '学号不能为空';
  } else if (!/^\d{4,}$/.test(studentNumber)) {
    status = '⚠️ 警告';
    issue = '学号格式可能不正确';
  } else if (!destType || destType.trim() === '') {
    status = '❌ 错误';
    issue = '去向类型不能为空';
  } else if (!['employment', 'furtherstudy', 'abroad', 'entrepreneurship', 'unemployed', 'other'].includes(destType)) {
    status = '❌ 错误';
    issue = '去向类型无效';
  }
  
  console.log(`第${index + 1}行: ${status}`);
  if (issue) {
    console.log(`   问题: ${issue}`);
  }
  console.log(`   数据: [${row.join(', ')}]`);
  console.log('');
});

// 数据库修复建议
console.log('🔧 数据库修复建议:');
console.log('1. 执行 fix_graduation_import_function.sql 创建必要的函数');
console.log('2. 执行 fix_database_constraints.sql 修复外键约束');
console.log('3. 检查 student_profiles 表是否有测试数据');
console.log('4. 验证 graduation_destinations 表结构');
console.log('5. 确认 RLS 策略允许插入操作');

console.log('\n📞 如果问题持续存在:');
console.log('1. 查看浏览器控制台详细错误');
console.log('2. 运行 debug_import_failures.js 获取具体错误');
console.log('3. 检查数据库日志');
console.log('4. 验证 Supabase 配置');

console.log('\n✅ 导入问题诊断完成！');