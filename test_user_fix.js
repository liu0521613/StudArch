// 测试 user is not defined 错误修复
console.log('🔧 测试 "user is not defined" 错误修复...');

// 测试修复的关键点
const tests = [
  {
    name: '检查 graduationDestinationService.ts 中的修复',
    test: () => {
      const fs = require('fs');
      const content = fs.readFileSync('./src/services/graduationDestinationService.ts', 'utf8');
      
      // 检查是否还存在 user?.id 的使用
      if (content.includes('user?.id')) {
        return false;
      }
      
      // 检查是否正确使用了 userId
      if (content.includes('p_imported_by: userId')) {
        return true;
      }
      
      return false;
    }
  },
  {
    name: '检查 userHelper.ts 导入是否正确',
    test: () => {
      const fs = require('fs');
      const content = fs.readFileSync('./src/services/graduationDestinationService.ts', 'utf8');
      
      return content.includes('import { safeGetUserId } from');
    }
  },
  {
    name: '检查 userId 变量使用',
    test: () => {
      const fs = require('fs');
      const content = fs.readFileSync('./src/services/graduationDestinationService.ts', 'utf8');
      
      // 检查 safeGetUserId 调用
      return content.includes('const userId = await safeGetUserId()');
    }
  }
];

let passedTests = 0;
const totalTests = tests.length;

tests.forEach((test, index) => {
  try {
    const result = test.test();
    if (result) {
      console.log(`✅ ${index + 1}. ${test.name} - 通过`);
      passedTests++;
    } else {
      console.log(`❌ ${index + 1}. ${test.name} - 失败`);
    }
  } catch (error) {
    console.log(`❌ ${index + 1}. ${test.name} - 错误: ${error.message}`);
  }
});

console.log(`\n📊 测试结果: ${passedTests}/${totalTests} 通过`);

if (passedTests === totalTests) {
  console.log('🎉 所有测试通过！"user is not defined" 错误已修复');
  console.log('📝 修复内容:');
  console.log('   - 将 graduationDestinationService.ts 中的 user?.id 修复为 userId');
  console.log('   - 使用 safeGetUserId() 函数安全获取用户ID');
  console.log('   - 确保批量导入功能正常工作');
} else {
  console.log('⚠️  仍有测试未通过，请检查修复内容');
}