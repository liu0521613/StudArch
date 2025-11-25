// 修复后的alert代码片段
// 复制这些代码到文件中相应位置

// 第1处修复 - 批量删除成功
if (successCount > 0 && failedCount === 0) {
  alert(`✅ 成功删除 ${successCount} 个学生`);
}

// 第2处修复 - 部分删除成功
else if (successCount > 0 && failedCount > 0) {
  const errorDetails = errors.slice(0, 3).join('\n');
  const moreErrors = errors.length > 3 ? `\n...还有 ${errors.length - 3} 个错误` : '';
  let message = `⚠️ 部分删除完成

✅ 成功删除: ${successCount} 个
❌ 删除失败: ${failedCount} 个

失败详情:
${errorDetails}${moreErrors}`;
  alert(message);
}

// 第3处修复 - 删除全部失败
else {
  let message = `❌ 删除失败，共 ${failedCount} 个学生删除失败

${errors.slice(0, 2).join('\n')}`;
  alert(message);
}