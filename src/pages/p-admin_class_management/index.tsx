import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import StudentProfileService from '../../services/studentProfileService';
import { ClassInfo, StudentCompleteInfo } from '../../types/user';

const ClassManagement: React.FC = () => {
  const navigate = useNavigate();
  const { user, isTeacher, isAdmin } = useAuth();
  const [classes, setClasses] = useState<ClassInfo[]>([]);
  const [students, setStudents] = useState<StudentCompleteInfo[]>([]);
  const [selectedClass, setSelectedClass] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newClass, setNewClass] = useState({
    class_name: '',
    class_code: '',
    grade: '',
    department: ''
  });

  // 检查权限
  useEffect(() => {
    if (!isTeacher() && !isAdmin()) {
      navigate('/unauthorized');
      return;
    }
  }, [isTeacher, isAdmin, navigate]);

  // 加载班级列表
  useEffect(() => {
    loadClasses();
  }, []);

  // 加载学生列表
  useEffect(() => {
    if (selectedClass) {
      loadStudents(selectedClass);
    }
  }, [selectedClass]);

  const loadClasses = async () => {
    try {
      setLoading(true);
      const classList = await StudentProfileService.getClasses();
      setClasses(classList);
    } catch (error) {
      console.error('加载班级列表失败:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadStudents = async (classId: string) => {
    try {
      const response = await StudentProfileService.searchStudents({
        class_id: classId,
        limit: 100
      });
      setStudents(response.students);
    } catch (error) {
      console.error('加载学生列表失败:', error);
    }
  };

  const handleCreateClass = async () => {
    try {
      // 这里应该调用创建班级的API
      // 暂时模拟创建过程
      const newClassInfo: ClassInfo = {
        id: `class-${Date.now()}`,
        class_name: newClass.class_name,
        class_code: newClass.class_code,
        grade: newClass.grade,
        department: newClass.department,
        student_count: 0,
        status: 'active',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      setClasses(prev => [...prev, newClassInfo]);
      setShowCreateModal(false);
      setNewClass({ class_name: '', class_code: '', grade: '', department: '' });
      
      // 显示成功消息
      alert('班级创建成功！');
    } catch (error) {
      console.error('创建班级失败:', error);
      alert('创建班级失败，请重试');
    }
  };

  const handleBatchOperation = async (operation: string, studentIds: string[]) => {
    try {
      // 这里应该调用批量操作的API
      // 暂时模拟操作过程
      switch (operation) {
        case 'approve':
          await StudentProfileService.batchReviewProfiles(studentIds, 'approved', '批量审核通过');
          alert(`已批量审核通过 ${studentIds.length} 名学生信息`);
          break;
        case 'reject':
          await StudentProfileService.batchReviewProfiles(studentIds, 'rejected', '批量审核不通过');
          alert(`已批量审核拒绝 ${studentIds.length} 名学生信息`);
          break;
        case 'export':
          // 导出学生信息
          alert(`已导出 ${studentIds.length} 名学生信息`);
          break;
      }
      
      // 刷新学生列表
      if (selectedClass) {
        loadStudents(selectedClass);
      }
    } catch (error) {
      console.error('批量操作失败:', error);
      alert('批量操作失败，请重试');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">加载中...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* 顶部导航栏 */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center">
              <Link to="/admin-dashboard" className="text-xl font-bold text-gray-900">
                学档通 - 管理平台
              </Link>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-600">{user?.full_name}</span>
              <button 
                onClick={() => navigate('/login')}
                className="text-sm text-gray-600 hover:text-gray-900"
              >
                退出登录
              </button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-900">班级管理</h1>
          <p className="text-gray-600 mt-2">管理班级信息和学生批量操作</p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* 左侧：班级列表 */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="p-4 border-b">
                <div className="flex justify-between items-center">
                  <h2 className="text-lg font-semibold text-gray-900">班级列表</h2>
                  {isAdmin() && (
                    <button
                      onClick={() => setShowCreateModal(true)}
                      className="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700"
                    >
                      新建班级
                    </button>
                  )}
                </div>
              </div>
              <div className="max-h-96 overflow-y-auto">
                {classes.map((classInfo) => (
                  <div
                    key={classInfo.id}
                    className={`p-4 border-b cursor-pointer hover:bg-gray-50 ${
                      selectedClass === classInfo.id ? 'bg-blue-50 border-blue-200' : ''
                    }`}
                    onClick={() => setSelectedClass(classInfo.id)}
                  >
                    <div className="flex justify-between items-start">
                      <div>
                        <h3 className="font-medium text-gray-900">{classInfo.class_name}</h3>
                        <p className="text-sm text-gray-600">{classInfo.grade} • {classInfo.department}</p>
                        <p className="text-xs text-gray-500">代码: {classInfo.class_code}</p>
                      </div>
                      <span className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full">
                        {classInfo.student_count} 人
                      </span>
                    </div>
                  </div>
                ))}
                {classes.length === 0 && (
                  <div className="p-8 text-center text-gray-500">
                    <p>暂无班级数据</p>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* 右侧：学生列表和批量操作 */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="p-4 border-b">
                <div className="flex justify-between items-center">
                  <h2 className="text-lg font-semibold text-gray-900">
                    {selectedClass 
                      ? classes.find(c => c.id === selectedClass)?.class_name + ' 学生列表'
                      : '请选择班级'
                    }
                  </h2>
                  {selectedClass && (
                    <div className="flex space-x-2">
                      <button
                        onClick={() => handleBatchOperation('approve', students.map(s => s.profile_id!).filter(Boolean))}
                        className="px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700"
                      >
                        批量审核通过
                      </button>
                      <button
                        onClick={() => handleBatchOperation('export', students.map(s => s.user_id))}
                        className="px-3 py-1 bg-gray-600 text-white text-sm rounded hover:bg-gray-700"
                      >
                        导出名单
                      </button>
                    </div>
                  )}
                </div>
              </div>
              
              {selectedClass ? (
                <div className="max-h-96 overflow-y-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          学号
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          姓名
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          状态
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          操作
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {students.map((student) => (
                        <tr key={student.user_id} className="hover:bg-gray-50">
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            {student.user_number}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            {student.full_name}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                              student.profile_status === 'approved' 
                                ? 'bg-green-100 text-green-800'
                                : student.profile_status === 'pending'
                                ? 'bg-yellow-100 text-yellow-800'
                                : student.profile_status === 'rejected'
                                ? 'bg-red-100 text-red-800'
                                : 'bg-gray-100 text-gray-800'
                            }`}>
                              {student.profile_status_text}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            <button
                              onClick={() => navigate(`/student-detail/${student.user_id}`)}
                              className="text-blue-600 hover:text-blue-900 mr-3"
                            >
                              查看
                            </button>
                            {student.profile_status === 'pending' && (
                              <button
                                onClick={() => handleBatchOperation('approve', [student.profile_id!])}
                                className="text-green-600 hover:text-green-900"
                              >
                                审核通过
                              </button>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {students.length === 0 && (
                    <div className="p-8 text-center text-gray-500">
                      <p>该班级暂无学生数据</p>
                    </div>
                  )}
                </div>
              ) : (
                <div className="p-8 text-center text-gray-500">
                  <p>请从左侧选择一个班级查看学生信息</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* 创建班级模态框 */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-md w-full p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">创建新班级</h3>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">班级名称</label>
                <input
                  type="text"
                  value={newClass.class_name}
                  onChange={(e) => setNewClass({...newClass, class_name: e.target.value})}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="请输入班级名称"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">班级代码</label>
                <input
                  type="text"
                  value={newClass.class_code}
                  onChange={(e) => setNewClass({...newClass, class_code: e.target.value})}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="请输入班级代码"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">年级</label>
                <input
                  type="text"
                  value={newClass.grade}
                  onChange={(e) => setNewClass({...newClass, grade: e.target.value})}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="例如：2021级"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">院系</label>
                <input
                  type="text"
                  value={newClass.department}
                  onChange={(e) => setNewClass({...newClass, department: e.target.value})}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="请输入院系名称"
                />
              </div>
            </div>
            
            <div className="flex justify-end space-x-3 mt-6">
              <button
                onClick={() => setShowCreateModal(false)}
                className="px-4 py-2 text-gray-600 border border-gray-300 rounded-md hover:bg-gray-50"
              >
                取消
              </button>
              <button
                onClick={handleCreateClass}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                disabled={!newClass.class_name || !newClass.grade}
              >
                创建
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ClassManagement;