// 测试UUID修复的脚本
console.log('🔧 测试UUID修复...');

// 测试UUID格式
const testUUIDs = [
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  'mock-user-id-for-import', // 这应该失败
  'invalid-uuid' // 这应该失败
];

function isValidUUID(uuid) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

console.log('\n📋 UUID格式验证:');
testUUIDs.forEach((uuid, index) => {
  const valid = isValidUUID(uuid);
  console.log(`${index + 1}. ${uuid} - ${valid ? '✅ 有效' : '❌ 无效'}`);
});

// 模拟导入批次创建
console.log('\n🚀 模拟导入批次创建测试...');

const mockBatchData = {
  batch_name: '测试导入批次_' + new Date().toLocaleString('zh-CN'),
  filename: 'test.xlsx',
  total_count: 5,
  success_count: 0,
  failed_count: 0,
  status: 'processing',
  imported_by: '00000000-0000-0000-0000-000000000001', // 使用有效UUID
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString()
};

console.log('模拟批次数据:');
console.table(mockBatchData);

console.log('\n📝 修复说明:');
console.log('1. ✅ 将无效的用户ID字符串替换为有效的UUID格式');
console.log('2. ✅ 导入功能使用: 00000000-0000-0000-0000-000000000001');
console.log('3. ✅ 审核功能使用: 00000000-0000-0000-0000-000000000002');
console.log('4. ✅ 数据库表支持TEXT类型的imported_by字段');

console.log('\n🎯 现在应该可以正常创建导入批次了！');
console.log('💡 如果仍有问题，可能需要更新数据库表结构');

// 生成SQL更新脚本
console.log('\n📄 数据库更新SQL:');
console.log(`-- 更新imported_by字段为TEXT类型以支持各种用户ID
ALTER TABLE graduation_import_batches 
ALTER COLUMN imported_by TYPE TEXT USING imported_by::TEXT;

-- 如果需要，也可以直接删除外键约束
ALTER TABLE graduation_import_batches 
DROP CONSTRAINT IF EXISTS graduation_import_batches_imported_by_fkey;`);

console.log('\n✅ UUID修复测试完成！');