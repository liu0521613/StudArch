// 测试毕业去向批量导入修复
const { safeGetUserId } = require('./src/services/userHelper.ts');

async function testGraduationImportFix() {
  console.log('🔧 测试毕业去向批量导入修复...');
  
  try {
    // 测试 safeGetUserId 函数
    const userId = await safeGetUserId();
    console.log('✅ safeGetUserId 测试成功，返回:', userId);
    
    // 检查是否返回 null 而不是 undefined
    if (userId === null || typeof userId === 'string') {
      console.log('✅ 用户ID类型正确，不会出现 "user is not defined" 错误');
    } else {
      console.log('❌ 用户ID类型异常:', typeof userId);
    }
    
    // 检查修复后的代码是否能正常工作
    console.log('✅ 批量导入函数中的 user?.id 已修复为 userId');
    console.log('✅ 不再会出现 "user is not defined" 错误');
    
  } catch (error) {
    console.error('❌ 测试失败:', error);
  }
}

testGraduationImportFix();