// 检查并修复 "user is not defined" 问题的脚本

const fs = require('fs');
const path = require('path');

console.log('🔍 检查 "user is not defined" 问题...\n');

// 需要检查的文件
const filesToCheck = [
    'src/services/graduationDestinationService.ts',
    'src/services/studentProfileService.ts', 
    'src/services/authService.ts',
    'src/pages/p-teacher_graduation_management/index.tsx',
    'src/pages/p-teacher_student_list/index.tsx',
    'src/pages/p-teacher_report/index.tsx'
];

// 检查函数
function checkFile(filePath) {
    try {
        const fullPath = path.join(__dirname, filePath);
        if (!fs.existsSync(fullPath)) {
            console.log(`⚠️  文件不存在: ${filePath}`);
            return;
        }

        const content = fs.readFileSync(fullPath, 'utf8');
        
        // 查找可能的 "user is not defined" 问题模式
        const issues = [];
        
        // 检查: 在没有定义 user 变量的地方使用 user.
        const userWithoutDefinition = content.match(/(^|\s)user\./gm);
        if (userWithoutDefinition) {
            // 检查是否有用户定义
            const hasUserDefinition = content.match(/(let|const|var)\s+user\s*[=;]|\buser\s*:/) ||
                                    content.match(/async.*user\s*[=;]/) ||
                                    content.match(/\.user\s*[=:]/) ||
                                    content.match(/getUser.*user/);
            
            if (!hasUserDefinition) {
                issues.push('使用了 user. 但没有定义 user 变量');
            }
        }
        
        // 检查: 在闭包或回调中使用了外部作用域的 user
        const closureIssues = content.match(/\{[^}]*user\.[^}]*\}/g);
        if (closureIssues) {
            closureIssues.forEach(closure => {
                const hasUserInScope = content.substring(0, content.indexOf(closure))
                    .match(/(let|const|var)\s+user\s*[=;]|\buser\s*:/);
                if (!hasUserInScope) {
                    issues.push(`可能在闭包中使用了未定义的 user: ${closure.substring(0, 50)}...`);
                }
            });
        }
        
        // 检查: 在 async 函数中的问题
        const asyncFunctionPattern = /async\s+\([^)]*\)\s*=>\s*\{[^}]*user\.[^}]*\}/g;
        const asyncIssues = content.match(asyncFunctionPattern);
        if (asyncIssues) {
            issues.push('可能在 async 箭头函数中使用了未定义的 user');
        }
        
        if (issues.length > 0) {
            console.log(`❌ ${filePath}:`);
            issues.forEach(issue => console.log(`   - ${issue}`));
        } else {
            console.log(`✅ ${filePath}: 没有发现明显问题`);
        }
        
    } catch (error) {
        console.log(`❌ 检查 ${filePath} 时出错:`, error.message);
    }
}

// 执行检查
filesToCheck.forEach(checkFile);

console.log('\n🔧 常见修复建议:');
console.log('1. 确保在使用 user 变量前先定义:');
console.log('   const { data: { user } } = await supabase.auth.getUser()');
console.log('   或');
console.log('   let user;');
console.log('   try { user = (await supabase.auth.getUser()).data?.user; } catch {...}');
console.log('');
console.log('2. 在闭包中使用时，确保 user 变量在作用域内:');
console.log('   // 正确');
console.log('   let user;');
console.log('   try { user = await getUser(); }');
console.log('   someFunction(() => { console.log(user.id); });');
console.log('');
console.log('3. 使用可选链操作符避免空值错误:');
console.log('   user?.id 而不是 user.id');
console.log('');
console.log('4. 在模拟模式下，提供默认值:');
console.log('   const user = result.data?.user || null;');

console.log('\n🎯 如果仍有问题，请检查具体的错误堆栈信息以定位问题位置。');