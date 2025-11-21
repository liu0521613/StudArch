// 精确查找 "user is not defined" 错误位置

const fs = require('fs');
const path = require('path');

console.log('🎯 精确查找 user 变量问题...\n');

function analyzeFile(filePath) {
    try {
        const fullPath = path.join(__dirname, filePath);
        if (!fs.existsSync(fullPath)) {
            return;
        }

        const content = fs.readFileSync(fullPath, 'utf8');
        const lines = content.split('\n');
        
        let issues = [];
        
        lines.forEach((line, index) => {
            const lineNum = index + 1;
            const trimmed = line.trim();
            
            // 跳过注释
            if (trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('/*')) {
                return;
            }
            
            // 查找使用 user. 的行
            if (trimmed.includes('user.')) {
                // 检查上下文，看是否有 user 定义
                const contextStart = Math.max(0, index - 10);
                const contextEnd = Math.min(lines.length - 1, index + 10);
                const context = lines.slice(contextStart, contextEnd).join('\n');
                
                // 检查是否在当前作用域有 user 定义
                const hasUserDefinition = 
                    context.includes('let user') ||
                    context.includes('const user') ||
                    context.includes('var user') ||
                    context.includes('user:') ||
                    context.includes('user =') ||
                    context.includes('getUser') ||
                    context.includes('auth.user') ||
                    context.includes('JSON.parse(userInfo).user');
                
                if (!hasUserDefinition && !trimmed.includes('localStorage.getItem')) {
                    // 进一步检查更大的作用域
                    const largerContext = lines.slice(0, index).join('\n');
                    const hasUserInLargerScope = 
                        largerContext.includes('let user') ||
                        largerContext.includes('const user') ||
                        largerContext.includes('var user') ||
                        largerContext.includes('user:') ||
                        largerContext.includes('user =') ||
                        largerContext.includes('getUser') ||
                        largerContext.includes('auth.user');
                    
                    if (!hasUserInLargerScope) {
                        issues.push({
                            line: lineNum,
                            content: trimmed,
                            reason: '可能未定义 user 变量'
                        });
                    }
                }
            }
        });
        
        if (issues.length > 0) {
            console.log(`❌ ${filePath}:`);
            issues.forEach(issue => {
                console.log(`   行 ${issue.line}: ${issue.content}`);
                console.log(`     问题: ${issue.reason}`);
                console.log('');
            });
        } else {
            console.log(`✅ ${filePath}: 没有发现明显的 user 未定义问题`);
        }
        
    } catch (error) {
        console.log(`❌ 检查 ${filePath} 时出错:`, error.message);
    }
}

// 检查最可能有问题的文件
const criticalFiles = [
    'src/services/graduationDestinationService.ts',
    'src/services/studentProfileService.ts', 
    'src/pages/p-teacher_graduation_management/index.tsx'
];

criticalFiles.forEach(analyzeFile);

console.log('\n💡 如果仍然有问题，建议:');
console.log('1. 检查浏览器控制台的完整错误堆栈');
console.log('2. 使用 debugger 语句在可疑位置断点调试');
console.log('3. 检查是否有动态加载的代码使用了 user 变量');