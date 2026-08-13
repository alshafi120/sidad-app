import React, { createContext, useContext, useState, useEffect } from 'react'

type Theme = 'light' | 'dark'
type Language = 'ar' | 'en'
type Direction = 'rtl' | 'ltr'

export interface User {
  id: string
  name: string
  email: string
  role: 'admin' | 'merchant' | 'superadmin'
  avatar?: string
  created_at: string
}

interface AppContextType {
  theme: Theme
  setTheme: (theme: Theme) => void
  lang: Language
  setLang: (lang: Language) => void
  dir: Direction
  sidebarCollapsed: boolean
  setSidebarCollapsed: (collapsed: boolean) => void
  toggleSidebar: () => void
  toggleTheme: () => void
  toggleLanguage: () => void
  // Auth state
  user: User | null
  setUser: (user: User | null) => void
  isAuthenticated: boolean
  logout: () => void
}

const AppContext = createContext<AppContextType | undefined>(undefined)

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<Theme>(() => {
    if (typeof window !== 'undefined') {
      const stored = window.localStorage.getItem('theme') as Theme
      if (stored === 'light' || stored === 'dark') return stored
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      return prefersDark ? 'dark' : 'light'
    }
    return 'light'
  })

  const [lang, setLangState] = useState<Language>(() => {
    if (typeof window !== 'undefined') {
      const stored = window.localStorage.getItem('lang') as Language
      if (stored === 'ar' || stored === 'en') return stored
    }
    return 'ar'
  })

  const [sidebarCollapsed, setSidebarCollapsed] = useState(false)
  const [user, setUserState] = useState<User | null>(null)

  // Initialize user from localStorage
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const storedUser = localStorage.getItem('sidad_auth_user')
      const token = localStorage.getItem('sidad_auth_token')
      if (storedUser && token) {
        try {
          setUserState(JSON.parse(storedUser))
        } catch (e) {
          localStorage.removeItem('sidad_auth_user')
          localStorage.removeItem('sidad_auth_token')
        }
      }
    }
  }, [])

  // Listen to auth changes from other tabs or actions
  useEffect(() => {
    const handleAuthChange = () => {
      const storedUser = localStorage.getItem('sidad_auth_user')
      if (storedUser) {
        setUserState(JSON.parse(storedUser))
      } else {
        setUserState(null)
      }
    }
    window.addEventListener('auth-change', handleAuthChange)
    return () => window.removeEventListener('auth-change', handleAuthChange)
  }, [])

  const dir: Direction = lang === 'ar' ? 'rtl' : 'ltr'

  useEffect(() => {
    const root = window.document.documentElement
    root.classList.remove('light', 'dark')
    root.classList.add(theme)
    window.localStorage.setItem('theme', theme)
  }, [theme])

  useEffect(() => {
    const root = window.document.documentElement
    root.setAttribute('lang', lang)
    root.setAttribute('dir', dir)
    window.localStorage.setItem('lang', lang)
  }, [lang, dir])

  const setTheme = (t: Theme) => setThemeState(t)
  const setLang = (l: Language) => setLangState(l)
  const toggleSidebar = () => setSidebarCollapsed((prev) => !prev)

  const toggleTheme = () => {
    setThemeState((prev) => (prev === 'light' ? 'dark' : 'light'))
  }

  const toggleLanguage = () => {
    setLangState((prev) => (prev === 'ar' ? 'en' : 'ar'))
  }

  const setUser = (u: User | null) => {
    setUserState(u)
    if (u) {
      localStorage.setItem('sidad_auth_user', JSON.stringify(u))
    } else {
      localStorage.removeItem('sidad_auth_user')
      localStorage.removeItem('sidad_auth_token')
    }
  }

  const logout = () => {
    setUser(null)
    window.dispatchEvent(new Event('auth-change'))
  }

  const isAuthenticated = !!user

  return (
    <AppContext.Provider
      value={{
        theme,
        setTheme,
        lang,
        setLang,
        dir,
        sidebarCollapsed,
        setSidebarCollapsed,
        toggleSidebar,
        toggleTheme,
        toggleLanguage,
        user,
        setUser,
        isAuthenticated,
        logout,
      }}
    >
      {children}
    </AppContext.Provider>
  )
}

export function useApp() {
  const context = useContext(AppContext)
  if (context === undefined) {
    throw new Error('useApp must be used within an AppProvider')
  }
  return context
}
