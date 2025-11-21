// UUID处理辅助函数
function generateMockUUID() {
  return '00000000-0000-0000-0000-000000000001';
}

function generateMockUUID2() {
  return '00000000-0000-0000-0000-000000000002';
}

function isValidUUID(uuid) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

// 导出函数
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    generateMockUUID,
    generateMockUUID2,
    isValidUUID
  };
}

console.log('UUID辅助函数已加载');
console.log('示例UUID:', generateMockUUID());
console.log('UUID有效性检查:', isValidUUID(generateMockUUID()));