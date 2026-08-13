import React from 'react'
import { Link } from '@tanstack/react-router'
import { useApp } from './AppContext'
import {
  LayoutDashboard,
  Store,
  CalendarCheck,
  Users,
  Receipt,
  CreditCard,
  BarChart3,
  Bell,
  Box,
  UserCheck,
  History,
  Settings,
  User,
  LogOut,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react'

interface SidebarItem {
  to: string
  labelAr: string
  labelEn: string
  icon: React.ComponentType<{ className?: string }>
  badge?: number
}

const SIDEBAR_ITEMS: SidebarItem[] = [
  { to: '/', labelAr: 'لوحة التحكم', labelEn: 'Dashboard', icon: LayoutDashboard },
  { to: '/merchants', labelAr: 'التجار', labelEn: 'Merchants', icon: Store },
  { to: '/subscriptions', labelAr: 'الاشتراكات', labelEn: 'Subscriptions', icon: CalendarCheck },
  { to: '/customers', labelAr: 'العملاء', labelEn: 'Customers', icon: Users },
  { to: '/debts', labelAr: 'الديون', labelEn: 'Debts', icon: Receipt },
  { to: '/payments', labelAr: 'المدفوعات', labelEn: 'Payments', icon: CreditCard },
  { to: '/analytics', labelAr: 'التقارير والتحليلات', labelEn: 'Analytics', icon: BarChart3 },
  { to: '/notifications', labelAr: 'الإشعارات', labelEn: 'Notifications', icon: Bell, badge: 12 },
  { to: '/packages', labelAr: 'الباقات', labelEn: 'Packages', icon: Box },
  { to: '/users', labelAr: 'المستخدمون', labelEn: 'Users & Admins', icon: UserCheck },
  { to: '/audit-logs', labelAr: 'سجل العمليات', labelEn: 'Audit Logs', icon: History },
  { to: '/settings', labelAr: 'الإعدادات', labelEn: 'System Settings', icon: Settings },
  { to: '/profile', labelAr: 'الملف الشخصي', labelEn: 'Profile', icon: User },
]

export default function Sidebar() {
  const { sidebarCollapsed, toggleSidebar, lang, dir, user, logout } = useApp()
  const isAr = lang === 'ar'

  return (
    <aside
      className={`fixed top-0 bottom-0 z-40 flex flex-col bg-[var(--sidebar-bg)] border-inline-end border-[var(--sidebar-border)] text-[var(--sidebar-fg)] transition-all duration-300
        ${sidebarCollapsed ? 'w-20' : 'w-64'} 
        ${dir === 'rtl' ? 'right-0' : 'left-0'}
      `}
    >
      {/* Header / Logo */}
      <div className="h-16 flex items-center justify-between px-4 border-b border-[var(--sidebar-border)]">
        {!sidebarCollapsed && (
          <div className="flex items-center gap-2">
            <span className="text-2xl">⚡</span>
            <span className="font-extrabold text-xl tracking-tight text-white font-english">SIDAD</span>
            <span className="text-[10px] bg-primary/30 text-primary-foreground border border-primary/20 px-1.5 py-0.5 rounded-md font-english">
              V12
            </span>
          </div>
        )}
        {sidebarCollapsed && (
          <span className="text-2xl mx-auto">⚡</span>
        )}

        {/* Collapse Button */}
        <button
          onClick={toggleSidebar}
          className="p-1 rounded-lg hover:bg-[var(--sidebar-hover)] text-gray-400 hover:text-white transition duration-200"
        >
          {dir === 'rtl' ? (
            sidebarCollapsed ? <ChevronLeft className="w-5 h-5" /> : <ChevronRight className="w-5 h-5" />
          ) : (
            sidebarCollapsed ? <ChevronRight className="w-5 h-5" /> : <ChevronLeft className="w-5 h-5" />
          )}
        </button>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 py-4 overflow-y-auto px-3 space-y-1">
        {SIDEBAR_ITEMS.map((item) => {
          const Icon = item.icon
          const label = isAr ? item.labelAr : item.labelEn

          return (
            <Link
              key={item.to}
              to={item.to}
              className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 group text-gray-400 hover:text-white hover:bg-[var(--sidebar-hover)]"
              activeProps={{
                className: 'bg-primary! text-white! font-semibold',
              }}
            >
              <Icon className="w-5 h-5 flex-shrink-0" />
              {!sidebarCollapsed && (
                <span className="flex-1 truncate">{label}</span>
              )}
              {!sidebarCollapsed && item.badge && (
                <span className="bg-destructive text-destructive-foreground text-[11px] px-2 py-0.5 rounded-full font-bold">
                  {item.badge}
                </span>
              )}
            </Link>
          )
        })}
      </nav>

      {/* Footer / User Profile */}
      <div className="p-4 border-t border-[var(--sidebar-border)] bg-black/10">
        {!sidebarCollapsed && user ? (
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <img
                src={user.avatar || 'https://api.dicebear.com/7.x/adventurer/svg?seed=sidad'}
                alt={user.name}
                className="w-10 h-10 rounded-xl bg-gray-800 border border-gray-700"
              />
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold truncate text-white">{user.name}</p>
                <p className="text-xs truncate text-gray-400">
                  {user.role === 'superadmin' ? (isAr ? 'مدير النظام' : 'System Admin') : (isAr ? 'تاجر' : 'Merchant')}
                </p>
              </div>
            </div>
            
            <button
              onClick={logout}
              className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-xl text-sm font-semibold border border-gray-800 hover:bg-destructive/10 hover:text-destructive hover:border-destructive/20 text-gray-400 transition-all duration-200 cursor-pointer"
            >
              <LogOut className="w-4 h-4" />
              <span>{isAr ? 'تسجيل الخروج' : 'Log Out'}</span>
            </button>
          </div>
        ) : (
          <button
            onClick={logout}
            className="w-full flex items-center justify-center p-2.5 rounded-xl hover:bg-destructive/10 text-gray-400 hover:text-destructive transition duration-200 cursor-pointer"
            title={isAr ? 'تسجيل الخروج' : 'Log Out'}
          >
            <LogOut className="w-5 h-5" />
          </button>
        )}
      </div>
    </aside>
  )
}
