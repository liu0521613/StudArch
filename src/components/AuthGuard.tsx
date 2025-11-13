import React, { useEffect, useState } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import AuthService from '../services/authService';

interface AuthGuardProps {
  children: React.ReactNode;
  requiredRole?: 'super_admin' | 'teacher' | 'student';
}

const AuthGuard: React.FC<AuthGuardProps> = ({ children, requiredRole }) => {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null);
  const [userRole, setUserRole] = useState<string | null>(null);
  const location = useLocation();

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const authResult = await AuthService.checkAuthStatus();
        
        if (authResult.success && authResult.user) {
          setIsAuthenticated(true);
          setUserRole(authResult.user.role.role_name);
        } else {
          setIsAuthenticated(false);
          setUserRole(null);
        }
      } catch (error) {
        console.error('认证检查失败:', error);
        setIsAuthenticated(false);
        setUserRole(null);
      }
    };

    checkAuth();
  }, [location.pathname]);

  // 等待认证检查完成
  if (isAuthenticated === null) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-secondary"></div>
        <span className="ml-4 text-text-primary">检查登录状态...</span>
      </div>
    );
  }

  // 未认证，重定向到登录页
  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // 检查角色权限
  if (requiredRole && userRole !== requiredRole) {
    // 根据当前用户角色重定向到对应页面
    const redirectPath = AuthService.getRedirectPath(userRole || 'student');
    return <Navigate to={redirectPath} replace />;
  }

  // 认证通过，显示子组件
  return <>{children}</>;
};

export default AuthGuard;