import React, { useState } from 'react'
import { useLocation, Link } from '@tanstack/react-router'
import { useApp } from './AppContext'
import {
  Search,
  Bell,
  Languages,
  Sun,
  Moon,
  Menu,
  ChevronDown,
  User,
  LogOut,
  Settings,
} from 'lucide-react'

export default function Topbar() {
  const { theme, toggleTheme, lang, toggleLanguage, dir, sidebarCollapsed, setSidebarCollapsed, user, logout } = useApp()
  const location = useLocation()
  const [showNotifications, setShowNotifications] = useState(false)
  const [showUserMenu, setShowUserMenu] = useState(false)

  const isAr = lang === 'ar'

  // Dynamic breadcrumbs based on pathname
  const getBreadcrumbs = () => {
    const paths = location.pathname.split('/').filter(Boolean)
    const breadcrumbs = []

    // Base main route
    breadcrumbs.push({
      label: isAr ? 'الرئيسية' : 'Home',
      to: '/',
    })

    let currentPath = ''
    paths.forEach((p) => {
      currentPath += `/${p}`
      let label = p
      
      // Match route segments
      if (p === 'merchants') label = isAr ? 'التجار' : 'Merchants'
      else if (p === 'customers') label = isAr ? 'العملاء' : 'Customers'
      else if (p === 'debts') label = isAr ? 'الديون' : 'Debts'
      else if (p === 'payments') label = isAr ? 'المدفوعات' : 'Payments'
      else if (p === 'analytics') label = isAr ? 'التقارير والتحليلات' : 'Analytics'
      else if (p === 'notifications') label = isAr ? 'الإشعارات' : 'Notifications'
      else if (p === 'packages') label = isAr ? 'الباقات' : 'Packages'
      else if (p === 'users') label = isAr ? 'المستخدمون' : 'Users'
      else if (p === 'audit-logs') label = isAr ? 'سجل العمليات' : 'Audit Logs'
      else if (p === 'settings') label = isAr ? 'الإعدادات' : 'Settings'
      else if (p === 'profile') label = isAr ? 'الملف الشخصي' : 'Profile'

      breadcrumbs.push({
        label,
        to: currentPath,
      })
    })

    return breadcrumbs
  }

  const breadcrumbs = getBreadcrumbs()

  return (
    <header className="h-16 border-b border-border bg-card/85 text-foreground sticky top-0 z-30 flex items-center justify-between px-6 backdrop-blur-md transition-colors duration-300">
      
      {/* Left side (RTL: Right side): Breadcrumbs & Mobile menu */}
      <div className="flex items-center gap-4">
        {/* Mobile Sidebar Trigger */}
        <button
          onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
          className="p-2 -ms-2 rounded-xl lg:hidden hover:bg-muted text-muted-foreground hover:text-foreground transition duration-200"
        >
          <Menu className="w-5 h-5" />
        </button>

        {/* Breadcrumbs */}
        <nav className="hidden md:flex items-center gap-1.5 text-sm font-medium">
          {breadcrumbs.map((bc, idx) => (
            <React.Fragment key={bc.to}>
              {idx > 0 && <span className="text-muted-foreground/40 font-english">/</span>}
              {idx === breadcrumbs.length - 1 ? (
                <span className="text-foreground font-semibold">{bc.label}</span>
              ) : (
                <Link
                  to={bc.to}
                  className="text-muted-foreground hover:text-foreground transition-all duration-200"
                >
                  {bc.label}
                </Link>
              )}
            </React.Fragment>
          ))}
        </nav>
      </div>

      {/* Right side (RTL: Left side): Actions */}
      <div className="flex items-center gap-2">
        
        {/* Global Search */}
        <div className="relative hidden sm:block">
          <Search className="w-4.5 h-4.5 text-muted-foreground absolute start-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder={isAr ? 'بحث سريع...' : 'Search...'}
            className="w-52 md:w-64 ps-9 pe-4 py-1.5 text-sm rounded-xl border border-border bg-background/50 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary focus:w-72 transition-all duration-300"
          />
        </div>

        {/* Notifications */}
        <div className="relative">
          <button
            onClick={() => {
              setShowNotifications(!showNotifications)
              setShowUserMenu(false)
            }}
            className="p-2.5 rounded-xl hover:bg-muted text-muted-foreground hover:text-foreground relative transition duration-200"
          >
            <Bell className="w-5 h-5" />
            <span className="absolute top-1.5 end-1.5 w-4 h-4 bg-destructive text-destructive-foreground font-bold text-[9px] rounded-full flex items-center justify-center border border-card font-english">
              5
            </span>
          </button>

          {/* Notifications Dropdown */}
          {showNotifications && (
            <div className={`absolute top-12 ${dir === 'rtl' ? 'left-0' : 'right-0'} w-80 premium-card p-2 bg-card border border-border mt-1 shadow-2xl`}>
              <div className="px-3 py-2 border-b border-border flex justify-between items-center">
                <span className="font-bold text-sm">{isAr ? 'آخر الإشعارات' : 'Notifications'}</span>
                <span className="text-xs text-primary font-semibold hover:underline cursor-pointer">
                  {isAr ? 'تحديد كالمقروءة' : 'Mark as read'}
                </span>
              </div>
              <div className="max-h-64 overflow-y-auto py-1">
                {[
                  { id: 1, title: isAr ? 'طلب اشتراك تاجر جديد' : 'New merchant subscription request', time: '5m' },
                  { id: 2, title: isAr ? 'اقتراب موعد انتهاء باقة "مكتبة العلم"' : 'Subscription package expiring soon', time: '1h' },
                  { id: 3, title: isAr ? 'دفعة جديدة مستلمة بقيمة 3,200 ر.س' : 'New payment received: 3,200 SAR', time: '3h' },
                ].map((item) => (
                  <div key={item.id} className="p-3 hover:bg-muted rounded-xl cursor-pointer text-xs transition duration-200">
                    <p className="font-medium text-foreground">{item.title}</p>
                    <span className="text-[10px] text-muted-foreground font-english mt-1 block">{item.time}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Language Switch */}
        <button
          onClick={toggleLanguage}
          className="p-2.5 rounded-xl hover:bg-muted text-muted-foreground hover:text-foreground transition duration-200"
          title={isAr ? 'English' : 'العربية'}
        >
          <Languages className="w-5 h-5" />
        </button>

        {/* Theme Switch */}
        <button
          onClick={toggleTheme}
          className="p-2.5 rounded-xl hover:bg-muted text-muted-foreground hover:text-foreground transition duration-200"
          title={isAr ? 'تبديل المظهر' : 'Toggle Theme'}
        >
          {theme === 'light' ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
        </button>

        {/* User Menu */}
        {user && (
          <div className="relative">
            <button
              onClick={() => {
                setShowUserMenu(!showUserMenu)
                setShowNotifications(false)
              }}
              className="flex items-center gap-1.5 p-1 rounded-xl hover:bg-muted transition duration-200"
            >
              <img
                src={user.avatar || 'https://api.dicebear.com/7.x/adventurer/svg?seed=sidad'}
                alt={user.name}
                className="w-8 h-8 rounded-lg bg-gray-150 border border-border"
              />
              <ChevronDown className="w-4 h-4 text-muted-foreground" />
            </button>

            {showUserMenu && (
              <div className={`absolute top-12 ${dir === 'rtl' ? 'left-0' : 'right-0'} w-52 premium-card p-1.5 bg-card border border-border mt-1 shadow-2xl`}>
                <div className="px-3 py-2 border-b border-border text-xs">
                  <p className="font-semibold text-foreground truncate">{user.name}</p>
                  <p className="text-muted-foreground truncate">{user.email}</p>
                </div>
                <div className="py-1 text-xs">
                  <Link
                    to="/profile"
                    onClick={() => setShowUserMenu(false)}
                    className="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-muted text-foreground"
                  >
                    <User className="w-4 h-4" />
                    <span>{isAr ? 'الملف الشخصي' : 'My Profile'}</span>
                  </Link>
                  <Link
                    to="/settings"
                    onClick={() => setShowUserMenu(false)}
                    className="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-muted text-foreground"
                  >
                    <Settings className="w-4 h-4" />
                    <span>{isAr ? 'الإعدادات' : 'Settings'}</span>
                  </Link>
                  <button
                    onClick={() => {
                      setShowUserMenu(false)
                      logout()
                    }}
                    className="w-full flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-destructive/10 hover:text-destructive text-muted-foreground text-start cursor-pointer"
                  >
                    <LogOut className="w-4 h-4" />
                    <span>{isAr ? 'تسجيل الخروج' : 'Log Out'}</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

      </div>
    </header>
  )
}
