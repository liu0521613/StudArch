// 生成有效的UUID
function generateValidUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// 生成固定的有效UUID用于测试
const importUUID = '550e8400-e29b-41d4-a716-446655440001';
const reviewUUID = '550e8400-e29b-41d4-a716-446655440002';

console.log('导入UUID:', importUUID);
console.log('审核UUID:', reviewUUID);
console.log('随机UUID:', generateValidUUID());

// 验证UUID格式
function isValidUUID(uuid) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

console.log('\nUUID验证:');
console.log('导入UUID有效:', isValidUUID(importUUID));
console.log('审核UUID有效:', isValidUUID(reviewUUID));

module.exports = {
  importUUID,
  reviewUUID,
  generateValidUUID,
  isValidUUID
};