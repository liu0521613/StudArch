import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import styles from './styles.module.css';
import { UserService } from '../../services/userService';
import { UserWithRole } from '../../types/user';
import { demoAuthorizedStudents, demoTeacherStudents } from '../../data/demoData';

const TeacherStudentList: React.FC = () => {
  const navigate = useNavigate();
  
  // 教师管理的学生数据
  const [studentsData, setStudentsData] = useState<UserWithRole[]>([]);
  const [studentsLoading, setStudentsLoading] = useState(false);
  const [studentsTotal, setStudentsTotal] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize] = useState(10);
  const [selectedStudents, setSelectedStudents] = useState<Set<string>>(new Set());
  const [searchTerm, setSearchTerm] = useState('');
  const [classFilter, setClassFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [isStudentModalOpen, setIsStudentModalOpen] = useState(false);
  const [editingStudent, setEditingStudent] = useState<UserWithRole | null>(null);
  
  // 导入相关状态
  const [isImportModalOpen, setIsImportModalOpen] = useState(false);
  const [availableStudents, setAvailableStudents] = useState<UserWithRole[]>([]);
  const [selectedAvailableStudents, setSelectedAvailableStudents] = useState<Set<string>>(new Set());
  const [importLoading, setImportLoading] = useState(false);
  const [importSearchTerm, setImportSearchTerm] = useState('');
  const [importPage, setImportPage] = useState(1);
  const [importTotalCount, setImportTotalCount] = useState(0);

  // 获取教师管理的学生列表
  const fetchTeacherStudents = async () => {
    try {
      setStudentsLoading(true);
      // 这里应该从认证状态中获取当前教师的ID，暂时使用固定的UUID
      const currentTeacherId = '00000000-0000-0000-0000-000000000001';
      
      const result = await UserService.getTeacherStudents(currentTeacherId, {
        keyword: searchTerm,
        page: currentPage,
        limit: pageSize
      });
      
      setStudentsData(result.students);
      setStudentsTotal(result.total);
    } catch (error) {
      console.error('获取教师学生列表失败:', error);
      // 使用演示数据作为fallback，确保只显示学生角色
      // 这里应该显示当前教师管理的学生，包括新导入的
      let filteredStudents = demoTeacherStudents.filter(student => 
        student.role_id === '3' && student.status === 'active'
      );
      
      // 从localStorage读取已导入的学生ID
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
      
      // 获取已导入的学生（不管是否在基础列表中，确保包含所有导入的学生）
      const importedStudents = demoAuthorizedStudents.filter(student => 
        importedIds.has(student.id)
      );
      
      console.log('找到的已导入学生数量:', importedStudents.length);
      console.log('已导入学生:', importedStudents.map(s => ({ id: s.id, name: s.full_name })));
      
      // 合并基础学生和已导入的学生，避免重复
      const existingIds = new Set(filteredStudents.map(s => s.id));
      const newImportedStudents = importedStudents.filter(student => !existingIds.has(student.id));
      
      if (newImportedStudents.length > 0) {
        console.log('新增导入学生:', newImportedStudents.map(s => ({ id: s.id, name: s.full_name })));
        filteredStudents = [...filteredStudents, ...newImportedStudents];
      }
      
      if (searchTerm) {
        const searchTermLower = searchTerm.toLowerCase();
        filteredStudents = filteredStudents.filter(student => 
          student.full_name.toLowerCase().includes(searchTermLower) ||
          student.user_number.toLowerCase().includes(searchTermLower) ||
          student.department?.toLowerCase().includes(searchTermLower) ||
          student.class_name?.toLowerCase().includes(searchTermLower)
        );
        console.log('搜索过滤后的学生数量:', filteredStudents.length);
      }
      
      // 分页处理
      const startIndex = (currentPage - 1) * pageSize;
      const endIndex = startIndex + pageSize;
      const paginatedStudents = filteredStudents.slice(startIndex, endIndex);
      
      setStudentsData(paginatedStudents);
      setStudentsTotal(filteredStudents.length);
    } finally {
      setStudentsLoading(false);
    }
  };

  // 获取可导入的学生列表
  const fetchAvailableStudents = async () => {
    try {
      setImportLoading(true);
      const result = await UserService.getAuthorizedStudents({
        keyword: importSearchTerm,
        page: importPage,
        limit: 20
      });
      setAvailableStudents(result.students);
      setImportTotalCount(result.total);
    } catch (error) {
      console.error('获取可导入学生失败:', error);
      // 使用演示数据，确保只显示学生角色
      let filteredStudents = demoAuthorizedStudents.filter(student => 
        student.role_id === '3' && student.status === 'active'
      );
      if (importSearchTerm) {
        const searchTermLower = importSearchTerm.toLowerCase();
        filteredStudents = filteredStudents.filter(student => 
          student.full_name.toLowerCase().includes(searchTermLower) ||
          student.user_number.toLowerCase().includes(searchTermLower) ||
          student.email.toLowerCase().includes(searchTermLower) ||
          student.department?.toLowerCase().includes(searchTermLower) ||
          student.class_name?.toLowerCase().includes(searchTermLower)
        );
      }
      
      // 分页处理
      const startIndex = (importPage - 1) * 20;
      const endIndex = startIndex + 20;
      const paginatedStudents = filteredStudents.slice(startIndex, endIndex);
      
      setAvailableStudents(paginatedStudents);
      setImportTotalCount(filteredStudents.length);
    } finally {
      setImportLoading(false);
    }
  };

  // 当导入模态框打开时获取可用学生
  useEffect(() => {
    if (isImportModalOpen) {
      fetchAvailableStudents();
    }
  }, [isImportModalOpen, importSearchTerm, importPage]);

  // 页面加载时获取教师学生数据
  useEffect(() => {
    // 从localStorage恢复已导入的学生ID
    const savedImportedIds = localStorage.getItem('importedStudentIds');
    if (savedImportedIds) {
      try {
        const parsedIds = JSON.parse(savedImportedIds);
        setSelectedAvailableStudents(new Set(parsedIds));
      } catch (e) {
        console.error('解析localStorage中的导入学生ID失败:', e);
      }
    }
    
    fetchTeacherStudents();
  }, [searchTerm, currentPage, pageSize]);

  // 当筛选条件改变时，重新获取数据
  useEffect(() => {
    fetchTeacherStudents();
  }, [searchTerm, classFilter, statusFilter]);

  // 设置页面标题
  useEffect(() => {
    const originalTitle = document.title;
    document.title = '我的学生 - 学档通';
    return () => { document.title = originalTitle; };
  }, []);

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      const newSelected = new Set(selectedStudents);
      studentsData.forEach(student => newSelected.add(student.id));
      setSelectedStudents(newSelected);
    } else {
      setSelectedStudents(new Set());
    }
  };

  const handleStudentSelect = (studentId: string, checked: boolean) => {
    const newSelected = new Set(selectedStudents);
    if (checked) {
      newSelected.add(studentId);
    } else {
      newSelected.delete(studentId);
    }
    setSelectedStudents(newSelected);
  };

  const isAllSelected = (): boolean => {
    return studentsData.length > 0 && studentsData.every(student => selectedStudents.has(student.id));
  };

  const isIndeterminate = (): boolean => {
    const selectedCount = studentsData.filter(student => selectedStudents.has(student.id)).length;
    return selectedCount > 0 && selectedCount < studentsData.length;
  };

  const handlePageChange = (page: number) => {
    const totalPages = Math.ceil(studentsTotal / pageSize);
    if (page >= 1 && page <= totalPages) {
      setCurrentPage(page);
    }
  };

  const handleAddStudent = () => {
    setEditingStudent(null);
    setIsStudentModalOpen(true);
  };

  const handleEditStudent = (student: UserWithRole) => {
    setEditingStudent(student);
    setIsStudentModalOpen(true);
  };

  const handleSaveStudent = (formData: Partial<UserWithRole>) => {
    if (editingStudent) {
      // 编辑学生
      setStudentsData(prev => prev.map(student => 
        student.id === editingStudent.id ? { ...student, ...formData } : student
      ));
    } else {
      // 新增学生
      const newStudent: UserWithRole = {
        id: Date.now().toString(),
        username: formData.username || '',
        email: formData.email || '',
        user_number: formData.user_number || '',
        full_name: formData.full_name || '',
        role_id: '3',
        status: 'active',
        phone: formData.phone,
        department: formData.department,
        grade: formData.grade,
        class_name: formData.class_name,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        role: {
          id: '3',
          role_name: 'student',
          role_description: '学生',
          permissions: {},
          is_system_default: true,
          created_at: '2021-01-01',
          updated_at: '2021-01-01'
        }
      };
      setStudentsData(prev => [...prev, newStudent]);
    }

    setIsStudentModalOpen(false);
    setEditingStudent(null);
  };

  const handleBatchDelete = async () => {
    if (selectedStudents.size > 0 && confirm('确定要移除选中的学生吗？')) {
      try {
        const currentTeacherId = '00000000-0000-0000-0000-000000000001';
        const promises = Array.from(selectedStudents).map(studentId =>
          UserService.removeStudentFromTeacher(currentTeacherId, studentId)
        );
        
        await Promise.all(promises);
        setSelectedStudents(new Set());
        fetchTeacherStudents(); // 重新获取数据
      } catch (error) {
        console.error('批量移除学生失败:', error);
        alert('批量移除学生失败，请稍后重试');
      }
    }
  };

  const handleBatchResetPassword = () => {
    if (selectedStudents.size > 0) {
      // 实际应用中这里会处理密码重置逻辑
      alert('批量重置密码功能');
    }
  };

  const handleAvailableStudentSelect = (studentId: string, checked: boolean) => {
    const newSelected = new Set(selectedAvailableStudents);
    if (checked) {
      newSelected.add(studentId);
    } else {
      newSelected.delete(studentId);
    }
    setSelectedAvailableStudents(newSelected);
  };

  const handleSelectAllAvailable = (checked: boolean) => {
    if (checked) {
      const newSelected = new Set(selectedAvailableStudents);
      availableStudents.forEach(student => newSelected.add(student.id));
      setSelectedAvailableStudents(newSelected);
    } else {
      setSelectedAvailableStudents(new Set());
    }
  };

  const handleConfirmImport = async () => {
    if (selectedAvailableStudents.size === 0) {
      alert('请选择要导入的学生');
      return;
    }

    try {
      setImportLoading(true);
      // 假设当前教师的ID是固定的，实际应用中应该从认证状态中获取
      const teacherId = '00000000-0000-0000-0000-000000000001';
      
      console.log('开始导入学生:', Array.from(selectedAvailableStudents));
      const result = await UserService.teacherAddStudents(
        Array.from(selectedAvailableStudents),
        teacherId
      );
      
      if (result.success > 0) {
        alert(`成功导入 ${result.success} 个学生${result.failed > 0 ? `，失败 ${result.failed} 个` : ''}`);
        
        // 重新刷新当前学生列表
        fetchTeacherStudents();
        
        // 关闭模态框并重置状态
        setIsImportModalOpen(false);
        setSelectedAvailableStudents(new Set());
        setImportSearchTerm('');
        setImportPage(1);
      } else {
        alert('导入失败，请检查学生信息是否正确');
      }
    } catch (error) {
      console.error('批量导入失败:', error);
      
      // 检查各种错误条件，直接进入演示模式
      console.log('启用演示模式处理导入');
      
      // 将选中的学生添加到当前学生列表
      const newStudents = demoAuthorizedStudents.filter(student => 
        selectedAvailableStudents.has(student.id)
      );
      
      // 保存到localStorage以确保持久化
      const importedStudentIds = Array.from(selectedAvailableStudents);
      localStorage.setItem('importedStudentIds', JSON.stringify(importedStudentIds));
      
      // 添加到当前学生列表
      setStudentsData(prev => [...prev, ...newStudents]);
      setStudentsTotal(prev => prev + newStudents.length);
      
      alert(`演示模式：成功导入 ${selectedAvailableStudents.size} 个学生到您的管理列表`);
      
      // 关闭模态框并重置状态
      setIsImportModalOpen(false);
      setSelectedAvailableStudents(new Set());
      setImportSearchTerm('');
      setImportPage(1);
      
      // 强制刷新一下页面状态
      setTimeout(() => {
        fetchTeacherStudents();
      }, 100);
      
    } finally {
      setImportLoading(false);
    }
  };

  const handleLogout = () => {
    if (confirm('确定要退出登录吗？')) {
      navigate('/login');
    }
  };

  const renderPaginationNumbers = () => {
    const totalPages = Math.ceil(studentsTotal / pageSize);
    const pages = [];
    
    for (let i = 1; i <= totalPages; i++) {
      if (i === 1 || i === totalPages || (i >= currentPage - 1 && i <= currentPage + 1)) {
        pages.push(
          <button
            key={i}
            className={`px-3 py-1 text-sm rounded-lg transition-colors ${
              i === currentPage 
                ? 'bg-secondary text-white' 
                : 'border border-border-light hover:bg-gray-50'
            }`}
            onClick={() => handlePageChange(i)}
          >
            {i}
          </button>
        );
      } else if (i === currentPage - 2 || i === currentPage + 2) {
        pages.push(
          <span key={`ellipsis-${i}`} className="px-2 text-text-secondary">
            ...
          </span>
        );
      }
    }
    
    return pages;
  };

  const startIndex = (currentPage - 1) * pageSize + 1;
  const endIndex = Math.min(currentPage * pageSize, studentsTotal);

  return (
    <div className={styles.pageWrapper}>
      {/* 顶部导航栏 */}
      <header className="fixed top-0 left-0 right-0 bg-white border-b border-border-light h-16 z-50">
        <div className="flex items-center justify-between h-full px-6">
          {/* Logo和系统名称 */}
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-br from-secondary to-accent rounded-lg flex items-center justify-center">
              <i className="fas fa-graduation-cap text-white text-lg"></i>
            </div>
            <h1 className="text-xl font-bold text-text-primary">学档通</h1>
          </div>
          
          {/* 用户信息和操作 */}
          <div className="flex items-center space-x-4">
            {/* 消息通知 */}
            <button className="relative p-2 text-text-secondary hover:text-secondary transition-colors">
              <i className="fas fa-bell text-lg"></i>
              <span className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center">3</span>
            </button>
            
            {/* 用户信息 */}
            <div className="flex items-center space-x-3 cursor-pointer hover:bg-gray-50 rounded-lg p-2 transition-colors">
              <img 
                src="https://s.coze.cn/image/hatzc53pi4k/" 
                alt="教师头像" 
                className="w-8 h-8 rounded-full" 
              />
              <div className="text-sm">
                <div className="font-medium text-text-primary">张老师</div>
                <div className="text-text-secondary">辅导员</div>
              </div>
              <i className="fas fa-chevron-down text-xs text-text-secondary"></i>
            </div>
            
            {/* 退出登录 */}
            <button 
              onClick={handleLogout}
              className="text-text-secondary hover:text-red-500 transition-colors"
            >
              <i className="fas fa-sign-out-alt text-lg"></i>
            </button>
          </div>
        </div>
      </header>

      {/* 左侧菜单 */}
      <aside className={`fixed left-0 top-16 bottom-0 w-64 bg-white border-r border-border-light z-40 ${styles.sidebarTransition}`}>
        <nav className="p-4 space-y-2">
          <Link 
            to="/teacher-dashboard" 
            className={`${styles.navItem} flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors text-text-secondary`}
          >
            <i className="fas fa-home text-lg"></i>
            <span className="font-medium">教师管理平台</span>
          </Link>
          
          <Link 
            to="/teacher-student-list" 
            className={`${styles.navItem} ${styles.navItemActive} flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors`}
          >
            <i className="fas fa-users text-lg"></i>
            <span className="font-medium">我的学生</span>
          </Link>
          

          <Link 
            to="/teacher-graduation-management" 
            className={`${styles.navItem} flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors text-text-secondary`}
          >
            <i className="fas fa-rocket text-lg"></i>
            <span className="font-medium">毕业去向管理</span>
          </Link>
          
          <Link 
            to="/teacher-report" 
            className={`${styles.navItem} flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors text-text-secondary`}
          >
            <i className="fas fa-chart-bar text-lg"></i>
            <span className="font-medium">统计报表</span>
          </Link>
        </nav>
      </aside>

      {/* 主内容区 */}
      <main className="ml-64 mt-16 p-6 min-h-screen">
        {/* 页面头部 */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-text-primary mb-2">我的学生</h2>
              <nav className="text-sm text-text-secondary">
                <span>首页</span>
                <i className="fas fa-chevron-right mx-2"></i>
                <span>我的学生</span>
              </nav>
            </div>
            <div className="flex space-x-3">
              <button 
                onClick={() => setIsImportModalOpen(true)}
                className="px-4 py-2 bg-white border border-border-light rounded-lg hover:bg-gray-50 transition-colors flex items-center space-x-2"
              >
                <i className="fas fa-upload text-secondary"></i>
                <span className="text-text-primary">批量导入</span>
              </button>
              <button 
                onClick={handleAddStudent}
                className="px-4 py-2 bg-secondary text-white rounded-lg hover:bg-accent transition-colors flex items-center space-x-2"
              >
                <i className="fas fa-plus"></i>
                <span>新增学生</span>
              </button>
            </div>
          </div>
        </div>

        {/* 工具栏区域 */}
        <div className="bg-white rounded-xl shadow-card p-6 mb-6">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
            {/* 搜索框 */}
            <div className="flex items-center space-x-4">
              <div className="relative">
                <i className="fas fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-text-secondary"></i>
                <input 
                  type="text" 
                  placeholder="搜索学号或姓名" 
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className={`pl-10 pr-4 py-2 border border-border-light rounded-lg w-64 ${styles.searchInput}`}
                />
              </div>
              
              {/* 筛选条件 */}
              <select 
                value={classFilter}
                onChange={(e) => setClassFilter(e.target.value)}
                className={`px-4 py-2 border border-border-light rounded-lg ${styles.filterSelect}`}
              >
                <option value="">全部班级</option>
                <option value="cs1">计算机科学与技术1班</option>
                <option value="cs2">计算机科学与技术2班</option>
                <option value="cs3">计算机科学与技术3班</option>
                <option value="se1">软件工程1班</option>
                <option value="se2">软件工程2班</option>
              </select>
              
              <select 
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className={`px-4 py-2 border border-border-light rounded-lg ${styles.filterSelect}`}
              >
                <option value="">全部状态</option>
                <option value="enrolled">在读</option>
                <option value="suspended">休学</option>
                <option value="withdrawn">退学</option>
                <option value="graduated">毕业</option>
                <option value="completed">结业</option>
              </select>
            </div>
            
            {/* 批量操作 */}
            <div className="flex items-center space-x-3">
              <button 
                onClick={handleBatchDelete}
                disabled={selectedStudents.size === 0}
                className="px-4 py-2 text-red-600 border border-red-200 rounded-lg hover:bg-red-50 transition-colors flex items-center space-x-2 disabled:opacity-50"
              >
                <i className="fas fa-trash"></i>
                <span>批量删除</span>
              </button>
              <button 
                onClick={handleBatchResetPassword}
                disabled={selectedStudents.size === 0}
                className="px-4 py-2 text-orange-600 border border-orange-200 rounded-lg hover:bg-orange-50 transition-colors flex items-center space-x-2 disabled:opacity-50"
              >
                <i className="fas fa-key"></i>
                <span>批量重置密码</span>
              </button>
            </div>
          </div>
        </div>

        {/* 学生列表 */}
        <div className="bg-white rounded-xl shadow-card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">
                    <input 
                      type="checkbox" 
                      checked={isAllSelected()}
                      ref={(input) => {
                        if (input) input.indeterminate = isIndeterminate();
                      }}
                      onChange={(e) => handleSelectAll(e.target.checked)}
                      className="rounded border-border-light"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">学号</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">姓名</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">班级</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">学籍状态</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">联系方式</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">操作</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-border-light">
                {studentsLoading ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center">
                      <i className="fas fa-spinner fa-spin text-2xl text-secondary mb-4"></i>
                      <p className="text-text-secondary">加载中...</p>
                    </td>
                  </tr>
                ) : studentsData.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center">
                      <i className="fas fa-users text-4xl text-gray-300 mb-4"></i>
                      <p className="text-text-secondary mb-4">暂无管理的学生</p>
                      <button 
                        onClick={() => setIsImportModalOpen(true)}
                        className="px-4 py-2 bg-secondary text-white rounded-lg hover:bg-accent transition-colors"
                      >
                        批量导入学生
                      </button>
                    </td>
                  </tr>
                ) : studentsData.map(student => (
                  <tr key={student.id} className={styles.tableRow}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <input 
                        type="checkbox" 
                        checked={selectedStudents.has(student.id)}
                        onChange={(e) => handleStudentSelect(student.id, e.target.checked)}
                        className="rounded border-border-light"
                      />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-text-primary">{student.user_number}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <img 
                          className="h-8 w-8 rounded-full mr-3" 
                          src="https://s.coze.cn/image/zycTkZ9PWs0/" 
                          alt={`${student.full_name}头像`}
                        />
                        <Link 
                          to={`/teacher-student-detail?studentId=${student.id}`}
                          className="text-secondary hover:text-accent font-medium"
                        >
                          {student.full_name}
                        </Link>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-text-primary">{student.class_name}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full">
                        {student.status === 'active' ? '在读' : '其他'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-text-secondary">{student.phone}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm space-x-2">
                      <Link 
                        to={`/teacher-student-detail?studentId=${student.id}`}
                        className="text-secondary hover:text-accent transition-colors" 
                        title="查看档案"
                      >
                        <i className="fas fa-eye"></i>
                      </Link>
                      <button 
                        onClick={() => handleEditStudent(student)}
                        className="text-text-secondary hover:text-secondary transition-colors" 
                        title="编辑信息"
                      >
                        <i className="fas fa-edit"></i>
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          
          {/* 分页 */}
          <div className="px-6 py-4 border-t border-border-light flex items-center justify-between">
            <div className="text-sm text-text-secondary">
              显示 <span>{studentsData.length > 0 ? startIndex : 0}</span>-<span>{Math.min(currentPage * pageSize, studentsTotal)}</span> 条，共 <span>{studentsTotal}</span> 条记录
            </div>
            <div className="flex items-center space-x-2">
              <button 
                onClick={() => handlePageChange(currentPage - 1)}
                disabled={currentPage === 1}
                className="px-3 py-1 text-sm border border-border-light rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
              >
                <i className="fas fa-chevron-left"></i>
              </button>
              <div className="flex space-x-1">
                {renderPaginationNumbers()}
              </div>
              <button 
                onClick={() => handlePageChange(currentPage + 1)}
                disabled={currentPage >= Math.ceil(studentsTotal / pageSize)}
                className="px-3 py-1 text-sm border border-border-light rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
              >
                <i className="fas fa-chevron-right"></i>
              </button>
            </div>
          </div>
        </div>
      </main>

      {/* 新增/编辑学生模态弹窗 */}
      {isStudentModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 z-50">
          <div className="flex items-center justify-center min-h-screen p-4">
            <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
              <div className="p-6 border-b border-border-light">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-text-primary">
                    {editingStudent ? '编辑学生' : '新增学生'}
                  </h3>
                  <button 
                    onClick={() => {
                      setIsStudentModalOpen(false);
                      setEditingStudent(null);
                    }}
                    className="text-text-secondary hover:text-text-primary transition-colors"
                  >
                    <i className="fas fa-times text-xl"></i>
                  </button>
                </div>
              </div>
              <StudentForm 
                student={editingStudent}
                onSave={handleSaveStudent}
                onCancel={() => {
                  setIsStudentModalOpen(false);
                  setEditingStudent(null);
                }}
              />
            </div>
          </div>
        </div>
      )}

      {/* 批量导入模态弹窗 */}
      {isImportModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 z-50">
          <div className="flex items-center justify-center min-h-screen p-4">
            <div className="bg-white rounded-xl shadow-xl w-full max-w-4xl max-h-[80vh] overflow-hidden flex flex-col">
              <div className="p-6 border-b border-border-light">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-text-primary">批量导入学生</h3>
                  <button 
                    onClick={() => {
                      setIsImportModalOpen(false);
                      setSelectedAvailableStudents(new Set());
                      setImportSearchTerm('');
                      setImportPage(1);
                    }}
                    className="text-text-secondary hover:text-text-primary transition-colors"
                  >
                    <i className="fas fa-times text-xl"></i>
                  </button>
                </div>
              </div>
              
              <div className="p-6 flex-1 overflow-hidden flex flex-col">
                {/* 搜索和筛选 */}
                <div className="mb-4">
                  <div className="flex items-center space-x-4">
                    <div className="relative flex-1">
                      <i className="fas fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-text-secondary"></i>
                      <input 
                        type="text" 
                        placeholder="搜索学号、姓名或邮箱" 
                        value={importSearchTerm}
                        onChange={(e) => setImportSearchTerm(e.target.value)}
                        className="pl-10 pr-4 py-2 border border-border-light rounded-lg w-full"
                      />
                    </div>
                    <button 
                      onClick={fetchAvailableStudents}
                      disabled={importLoading}
                      className="px-4 py-2 bg-secondary text-white rounded-lg hover:bg-accent transition-colors disabled:opacity-50"
                    >
                      {importLoading ? '搜索中...' : '搜索'}
                    </button>
                  </div>
                </div>

                {/* 选中数量显示 */}
                <div className="mb-4 flex items-center justify-between">
                  <div className="text-sm text-text-secondary">
                    已选择 <span className="font-semibold text-secondary">{selectedAvailableStudents.size}</span> 个学生
                  </div>
                  <div className="text-sm text-text-secondary">
                    共找到 <span className="font-semibold">{importTotalCount}</span> 个已授权学生
                  </div>
                </div>

                {/* 学生列表 */}
                <div className="flex-1 overflow-y-auto border border-border-light rounded-lg">
                  {importLoading ? (
                    <div className="flex items-center justify-center h-64">
                      <div className="text-center">
                        <i className="fas fa-spinner fa-spin text-3xl text-secondary mb-4"></i>
                        <p className="text-text-secondary">加载中...</p>
                      </div>
                    </div>
                  ) : availableStudents.length === 0 ? (
                    <div className="flex items-center justify-center h-64">
                      <div className="text-center">
                        <i className="fas fa-users text-3xl text-gray-300 mb-4"></i>
                        <p className="text-text-secondary">暂无可导入的学生</p>
                      </div>
                    </div>
                  ) : (
                    <table className="w-full">
                      <thead className="bg-gray-50 sticky top-0">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">
                            <input 
                              type="checkbox" 
                              checked={availableStudents.length > 0 && availableStudents.every(s => selectedAvailableStudents.has(s.id))}
                              onChange={(e) => handleSelectAllAvailable(e.target.checked)}
                              className="rounded border-border-light"
                            />
                          </th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">学号</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">姓名</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">邮箱</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">院系</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">年级</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-text-secondary uppercase tracking-wider">班级</th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-border-light">
                        {availableStudents.map(student => (
                          <tr key={student.id} className="hover:bg-gray-50">
                            <td className="px-6 py-4 whitespace-nowrap">
                              <input 
                                type="checkbox" 
                                checked={selectedAvailableStudents.has(student.id)}
                                onChange={(e) => handleAvailableStudentSelect(student.id, e.target.checked)}
                                className="rounded border-border-light"
                              />
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-text-primary">{student.user_number}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-text-primary">{student.full_name}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-text-secondary">{student.email}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-text-primary">{student.department}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-text-primary">{student.grade}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-text-primary">{student.class_name}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </div>

                {/* 分页 */}
                {availableStudents.length > 0 && (
                  <div className="mt-4 flex items-center justify-between">
                    <div className="text-sm text-text-secondary">
                      显示第 {Math.min((importPage - 1) * 20 + 1, importTotalCount)} - {Math.min(importPage * 20, importTotalCount)} 条，共 {importTotalCount} 条
                    </div>
                    <div className="flex items-center space-x-2">
                      <button 
                        onClick={() => setImportPage(prev => Math.max(1, prev - 1))}
                        disabled={importPage === 1}
                        className="px-3 py-1 text-sm border border-border-light rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
                      >
                        <i className="fas fa-chevron-left"></i>
                      </button>
                      <span className="px-3 py-1 text-sm text-text-primary">
                        第 {importPage} 页
                      </span>
                      <button 
                        onClick={() => setImportPage(prev => Math.min(Math.ceil(importTotalCount / 20), prev + 1))}
                        disabled={importPage >= Math.ceil(importTotalCount / 20)}
                        className="px-3 py-1 text-sm border border-border-light rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
                      >
                        <i className="fas fa-chevron-right"></i>
                      </button>
                    </div>
                  </div>
                )}
              </div>
              
              <div className="p-6 border-t border-border-light flex justify-end space-x-3">
                <button 
                  onClick={() => {
                    setIsImportModalOpen(false);
                    setSelectedAvailableStudents(new Set());
                    setImportSearchTerm('');
                    setImportPage(1);
                  }}
                  className="px-4 py-2 border border-border-light rounded-lg hover:bg-gray-50 transition-colors"
                >
                  取消
                </button>
                <button 
                  onClick={handleConfirmImport}
                  disabled={selectedAvailableStudents.size === 0 || importLoading}
                  className="px-4 py-2 bg-secondary text-white rounded-lg hover:bg-accent transition-colors disabled:opacity-50"
                >
                  {importLoading ? '导入中...' : `确认导入 (${selectedAvailableStudents.size})`}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// 学生表单组件
interface StudentFormProps {
  student: UserWithRole | null;
  onSave: (data: Partial<UserWithRole>) => void;
  onCancel: () => void;
}

const StudentForm: React.FC<StudentFormProps> = ({ student, onSave, onCancel }) => {
  const [formData, setFormData] = useState({
    username: student?.username || '',
    email: student?.email || '',
    user_number: student?.user_number || '',
    full_name: student?.full_name || '',
    phone: student?.phone || '',
    department: student?.department || '',
    grade: student?.grade || '',
    class_name: student?.class_name || '',
    status: student?.status || 'active'
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="student-number" className="block text-sm font-medium text-text-primary mb-2">学号 *</label>
          <input 
            type="text" 
            id="student-number" 
            value={formData.user_number}
            onChange={(e) => setFormData(prev => ({ ...prev, user_number: e.target.value }))}
            required
            className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:border-secondary"
          />
        </div>
        <div>
          <label htmlFor="student-name" className="block text-sm font-medium text-text-primary mb-2">姓名 *</label>
          <input 
            type="text" 
            id="student-name" 
            value={formData.full_name}
            onChange={(e) => setFormData(prev => ({ ...prev, full_name: e.target.value }))}
            required
            className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:border-secondary"
          />
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="student-email" className="block text-sm font-medium text-text-primary mb-2">邮箱 *</label>
          <input 
            type="email" 
            id="student-email" 
            value={formData.email}
            onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
            required
            className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:border-secondary"
          />
        </div>
        <div>
          <label htmlFor="student-department" className="block text-sm font-medium text-text-primary mb-2">院系</label>
          <input 
            type="text" 
            id="student-department" 
            value={formData.department}
            onChange={(e) => setFormData(prev => ({ ...prev, department: e.target.value }))}
            className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:border-secondary"
          />
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="student-grade" className="block text-sm font-medium text-text-primary mb-2">年级</label>
          <input 
            type="text" 
            id="student-grade" 
            value={formData.grade}
            onChange={(e) => setFormData(prev => ({ ...prev, grade: e.target.value }))}
            className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:border-secondary"
          />
        </div>
        <div>
          <label htmlFor="student-class" className="block text-sm font-medium text-text-primary mb-2">班级</label>
          <input 
            type="text" 
            id="student-class" 
            value={formData.class_name}
            onChange={(e) => setFormData(prev => ({ ...prev, class_name: e.target.value }))}
            className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:border-secondary"
          />
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="student-phone" className="block text-sm font-medium text-text-primary mb-2">联系方式</label>
          <input 
            type="tel" 
            id="student-phone" 
            value={formData.phone}
            onChange={(e) => setFormData(prev => ({ ...prev, phone: e.target.value }))}
            className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:border-secondary"
          />
        </div>
        <div>
          <label htmlFor="student-status" className="block text-sm font-medium text-text-primary mb-2">状态</label>
          <select 
            id="student-status" 
            value={formData.status}
            onChange={(e) => setFormData(prev => ({ ...prev, status: e.target.value as UserWithRole['status'] }))}
            className="w-full px-3 py-2 border border-border-light rounded-lg focus:outline-none focus:border-secondary"
          >
            <option value="active">在读</option>
            <option value="inactive">离校</option>
          </select>
        </div>
      </div>
      <div className="p-6 border-t border-border-light flex justify-end space-x-3">
        <button 
          type="button"
          onClick={onCancel}
          className="px-4 py-2 border border-border-light rounded-lg hover:bg-gray-50 transition-colors"
        >
          取消
        </button>
        <button 
          type="submit"
          className="px-4 py-2 bg-secondary text-white rounded-lg hover:bg-accent transition-colors"
        >
          保存
        </button>
      </div>
    </form>
  );
};

export default TeacherStudentList;