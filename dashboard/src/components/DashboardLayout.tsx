import React from 'react'
import { useApp } from './AppContext'
import Sidebar from './Sidebar'
import Topbar from './Topbar'
import LoginPage from './LoginPage'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, sidebarCollapsed, setSidebarCollapsed, dir } = useApp()

  // If not logged in, force Login Page
  if (!isAuthenticated) {
    return <LoginPage />
  }

  return (
    <div className="min-h-screen bg-background text-foreground transition-colors duration-300 relative">
      {/* Sidebar Navigation */}
      <Sidebar />

      {/* Main Viewport */}
      <div
        className={`min-h-screen flex flex-col transition-all duration-300
          ${sidebarCollapsed ? 'lg:ps-20' : 'lg:ps-64'} 
          ps-0
        `}
      >
        {/* Top Header */}
        <Topbar />

        {/* Dynamic Route Content */}
        <main className="flex-1 p-6 md:p-8 max-w-7xl w-full mx-auto slide-up">
          {children}
        </main>

        {/* Mobile Sidebar Overlay */}
        {!sidebarCollapsed && (
          <div
            onClick={() => setSidebarCollapsed(true)}
            className="fixed inset-0 bg-black/40 z-30 lg:hidden backdrop-blur-xs"
          />
        )}
      </div>
    </div>
  )
}
