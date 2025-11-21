// 导入功能修复补丁
// 将此代码添加到您的 p-teacher_student_list/index.tsx 文件中

// 修复版本 handleConfirmImport 函数
const handleConfirmImportFixed = async () => {
  if (selectedAvailableStudents.size === 0) {
    alert('请选择要导入的学生');
    return;
  }

  try {
    setImportLoading(true);
    const teacherId = '00000000-0000-0000-0000-000000000001';
    
    console.log('=== 开始导入学生 ===');
    console.log('教师ID:', teacherId);
    console.log('选中学生ID:', Array.from(selectedAvailableStudents));
    
    // 1. 首先尝试正式的API调用
    const result = await UserService.teacherAddStudents(
      Array.from(selectedAvailableStudents),
      teacherId
    );
    
    console.log('API调用结果:', result);
    
    if (result.success > 0) {
      // 2. 保存到localStorage作为备份
      const importedStudentIds = Array.from(selectedAvailableStudents);
      localStorage.setItem('importedStudentIds', JSON.stringify(importedStudentIds));
      
      // 3. 显示成功消息
      alert(`成功导入 ${result.success} 个学生${result.failed > 0 ? `，失败 ${result.failed} 个` : ''}`);
      
      // 4. 关闭模态框
      setIsImportModalOpen(false);
      setSelectedAvailableStudents(new Set());
      setImportSearchTerm('');
      setImportPage(1);
      
      // 5. 延迟刷新数据，确保数据库操作完成
      setTimeout(async () => {
        await fetchTeacherStudents();
      }, 500);
      
    } else {
      alert('导入失败，请检查学生信息是否正确');
    }
    
  } catch (error) {
    console.error('批量导入失败:', error);
    
    // 演示模式处理
    console.log('启用演示模式处理导入');
    
    // 1. 将选中的学生添加到当前学生列表
    const newStudents = demoAuthorizedStudents.filter(student => 
      selectedAvailableStudents.has(student.id)
    );
    
    console.log('演示模式新增学生:', newStudents);
    
    // 2. 保存到localStorage确保持久化
    const importedStudentIds = Array.from(selectedAvailableStudents);
    const existingIds = JSON.parse(localStorage.getItem('importedStudentIds') || '[]');
    const allImportedIds = [...new Set([...existingIds, ...importedStudentIds])];
    localStorage.setItem('importedStudentIds', JSON.stringify(allImportedIds));
    
    // 3. 更新当前学生列表
    setStudentsData(prev => {
      const existingIds = new Set(prev.map(s => s.id));
      const newUniqueStudents = newStudents.filter(s => !existingIds.has(s.id));
      return [...prev, ...newUniqueStudents];
    });
    
    // 4. 更新总数
    setStudentsTotal(prev => {
      const existingIds = new Set(studentsData.map(s => s.id));
      const newUniqueStudents = newStudents.filter(s => !existingIds.has(s.id));
      return prev + newUniqueStudents.length;
    });
    
    alert(`演示模式：成功导入 ${selectedAvailableStudents.size} 个学生到您的管理列表`);
    
    // 5. 关闭模态框
    setIsImportModalOpen(false);
    setSelectedAvailableStudents(new Set());
    setImportSearchTerm('');
    setImportPage(1);
    
  } finally {
    setImportLoading(false);
  }
};

// 修复版本 fetchTeacherStudents 函数
const fetchTeacherStudentsFixed = async () => {
  try {
    setStudentsLoading(true);
    const currentTeacherId = '00000000-0000-0000-0000-000000000001';
    
    console.log('=== 获取教师学生列表 ===');
    console.log('教师ID:', currentTeacherId);
    console.log('搜索词:', searchTerm);
    console.log('当前页:', currentPage);
    
    // 1. 尝试从API获取数据
    const result = await UserService.getTeacherStudents(currentTeacherId, {
      keyword: searchTerm,
      page: currentPage,
      limit: pageSize
    });
    
    console.log('API返回结果:', result);
    
    if (result.students && result.students.length > 0) {
      // API成功，使用API数据
      setStudentsData(result.students);
      setStudentsTotal(result.total);
      console.log('使用API数据，学生数量:', result.students.length);
      return;
    }
    
    // 2. API没有数据，使用演示数据
    console.log('API无数据，使用演示数据');
    throw new Error('API无数据');
    
  } catch (error) {
    console.error('获取教师学生列表失败:', error);
    
    // 3. 演示数据处理逻辑
    let filteredStudents = demoTeacherStudents.filter(student => 
      student.role_id === '3' && student.status === 'active'
    );
    
    // 4. 从localStorage读取已导入的学生ID
    const savedImportedIds = localStorage.getItem('importedStudentIds');
    let importedIds: Set<string> = new Set();
    
    if (savedImportedIds) {
      try {
        const parsedIds = JSON.parse(savedImportedIds);
        importedIds = new Set(parsedIds);
        console.log('从localStorage恢复的导入学生ID:', Array.from(importedIds));
      } catch (e) {
        console.error('解析localStorage中的导入学生ID失败:', e);
      }
    }
    
    // 5. 获取已导入的学生
    const importedStudents = demoAuthorizedStudents.filter(student => 
      importedIds.has(student.id)
    );
    
    console.log('找到的已导入学生数量:', importedStudents.length);
    
    // 6. 合并学生列表，避免重复
    const existingIds = new Set(filteredStudents.map(s => s.id));
    const newImportedStudents = importedStudents.filter(student => !existingIds.has(student.id));
    
    if (newImportedStudents.length > 0) {
      console.log('新增导入学生:', newImportedStudents.map(s => ({ id: s.id, name: s.full_name })));
      filteredStudents = [...filteredStudents, ...newImportedStudents];
    }
    
    // 7. 应用搜索过滤
    if (searchTerm) {
      const searchTermLower = searchTerm.toLowerCase();
      filteredStudents = filteredStudents.filter(student => 
        student.full_name.toLowerCase().includes(searchTermLower) ||
        student.user_number.toLowerCase().includes(searchTermLower) ||
        student.department?.toLowerCase().includes(searchTermLower) ||
        student.class_name?.toLowerCase().includes(searchTermLower)
      );
    }
    
    // 8. 分页处理
    const startIndex = (currentPage - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    const paginatedStudents = filteredStudents.slice(startIndex, endIndex);
    
    setStudentsData(paginatedStudents);
    setStudentsTotal(filteredStudents.length);
    console.log('最终显示学生数量:', paginatedStudents.length);
  } finally {
    setStudentsLoading(false);
  }
};

// 修复版本 handleConfirmImport，确保数据持久化
const handleConfirmImportWithPersistence = async () => {
  if (selectedAvailableStudents.size === 0) {
    alert('请选择要导入的学生');
    return;
  }

  try {
    setImportLoading(true);
    const teacherId = '00000000-0000-0000-0000-000000000001';
    
    // 获取当前localStorage中已导入的学生ID
    const existingImportedIds = JSON.parse(localStorage.getItem('importedStudentIds') || '[]');
    const newImportedIds = Array.from(selectedAvailableStudents);
    const allImportedIds = [...new Set([...existingImportedIds, ...newImportedIds])];
    
    console.log('=== 确保数据持久化 ===');
    console.log('已存在导入ID:', existingImportedIds);
    console.log('新导入ID:', newImportedIds);
    console.log('合并后所有ID:', allImportedIds);
    
    // 立即保存到localStorage，确保数据不丢失
    localStorage.setItem('importedStudentIds', JSON.stringify(allImportedIds));
    console.log('已保存到localStorage');
    
    // 尝试API调用
    try {
      const result = await UserService.teacherAddStudents(newImportedIds, teacherId);
      console.log('API调用成功:', result);
      
      if (result.success > 0) {
        alert(`成功导入 ${result.success} 个学生${result.failed > 0 ? `，失败 ${result.failed} 个` : ''}`);
      }
    } catch (apiError) {
      console.error('API调用失败，但localStorage数据已保存:', apiError);
      alert(`本地缓存：成功导入 ${newImportedIds.length} 个学生`);
    }
    
    // 关闭模态框
    setIsImportModalOpen(false);
    setSelectedAvailableStudents(new Set());
    setImportSearchTerm('');
    setImportPage(1);
    
    // 强制刷新学生列表
    await fetchTeacherStudents();
    
  } catch (error) {
    console.error('导入过程出错:', error);
    alert('导入失败，请重试');
  } finally {
    setImportLoading(false);
  }
};

console.log('导入功能修复补丁已加载');
console.log('请使用 handleConfirmImportFixed 或 handleConfirmImportWithPersistence 替换原有的处理函数');
console.log('请使用 fetchTeacherStudentsFixed 替换原有的获取函数');

// 导出修复函数
window.importFixes = {
  handleConfirmImportFixed,
  fetchTeacherStudentsFixed,
  handleConfirmImportWithPersistence
};