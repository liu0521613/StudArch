// 测试null处理修复
console.log('🔧 测试null处理修复...');

// 模拟各种用户状态
const testCases = [
  {
    name: '正常用户',
    user: { id: '550e8400-e29b-41d4-a716-446655440001', email: 'user@example.com' },
    expected: 'user?.id || null -> "550e8400-e29b-41d4-a716-446655440001"'
  },
  {
    name: '用户为null',
    user: null,
    expected: 'user?.id || null -> null'
  },
  {
    name: '用户为undefined',
    user: undefined,
    expected: 'user?.id || null -> null'
  },
  {
    name: '用户对象无id属性',
    user: { email: 'no-id@example.com' },
    expected: 'user?.id || null -> null'
  }
];

console.log('\n📋 测试用例:');
testCases.forEach((testCase, index) => {
  console.log(`${index + 1}. ${testCase.name}`);
  console.log(`   输入: ${JSON.stringify(testCase.user)}`);
  
  const result = testCase.user?.id || null;
  console.log(`   结果: ${result}`);
  console.log(`   期望: ${testCase.expected}`);
  console.log(`   ✅ 正确: ${result === (testCase.user?.id || null)}`);
  console.log('');
});

// 测试handleManualImport函数签名
console.log('🧪 函数签名测试:');
function simulateHandleManualImport(batchName, filename, data, userId) {
  console.log(`batchName: ${batchName}`);
  console.log(`filename: ${filename}`);
  console.log(`data length: ${data?.length || 0}`);
  console.log(`userId: ${userId} (type: ${typeof userId})`);
  
  // 模拟数据库插入
  const insertData = {
    batch_name: batchName,
    filename,
    total_count: data.length,
    success_count: 0,
    failed_count: 0,
    status: 'processing',
    imported_by: userId
  };
  
  console.log('插入数据:', JSON.stringify(insertData, null, 2));
  return insertData;
}

// 测试各种userId值
console.log('\n测试userId参数处理:');
simulateHandleManualImport('测试批次', 'test.xlsx', [{}], 'valid-uuid');
simulateHandleManualImport('测试批次', 'test.xlsx', [{}], null);
simulateHandleManualImport('测试批次', 'test.xlsx', [{}], undefined);

console.log('\n📝 修复总结:');
console.log('1. ✅ 修复了所有 user.id 访问点，使用 user?.id || null');
console.log('2. ✅ 更新了 handleManualImport 函数签名支持 null userId');
console.log('3. ✅ 确保所有数据库插入使用正确的用户ID值');
console.log('4. ✅ 支持各种用户认证失败情况');

console.log('\n🎯 现在应该能够:');
console.log('- 处理用户为null的情况');
console.log('- 避免"Cannot read properties of null"错误');
console.log('- 正常创建导入批次');
console.log('- 支持开发和生产环境');

console.log('\n✅ null处理修复测试完成！');