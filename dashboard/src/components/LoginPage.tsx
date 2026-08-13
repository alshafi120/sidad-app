import React, { useState } from 'react'
import { api } from '../lib/api'
import { useApp } from './AppContext'
import { LogIn, ShieldAlert, Sparkles, Moon, Sun, Languages } from 'lucide-react'

export default function LoginPage() {
  const { setUser, theme, toggleTheme, lang, toggleLanguage, dir } = useApp()
  const [email, setEmail] = useState('admin@sidad.app')
  const [password, setPassword] = useState('password')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const response = await api.login(email, password)
      setUser(response.user)
    } catch (err: any) {
      setError(lang === 'ar' ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة' : 'Invalid email or password')
    } finally {
      setLoading(false)
    }
  };

  const loginDemo = async () => {
    setLoading(true)
    setError('')
    try {
      const response = await api.login('admin@sidad.app', 'password')
      setUser(response.user)
    } catch (err: any) {
      setError(String(err))
    } finally {
      setLoading(false)
    }
  }

  const isAr = lang === 'ar'

  return (
    <div className={`min-h-screen flex items-center justify-center bg-background px-4 relative overflow-hidden transition-colors duration-300`}>
      {/* Background gradients */}
      <div className="absolute top-[-10%] right-[-10%] w-[500px] h-[500px] bg-primary/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-[-10%] left-[-10%] w-[500px] h-[500px] bg-secondary/10 rounded-full blur-3xl pointer-events-none" />

      {/* Top tools */}
      <div className="absolute top-4 start-4 end-4 flex justify-between items-center z-10">
        <div className="flex items-center gap-2">
          <span className="text-2xl">⚡</span>
          <span className="font-extrabold text-xl tracking-tight text-primary font-english">SIDAD</span>
        </div>
        
        <div className="flex items-center gap-2">
          <button
            onClick={toggleLanguage}
            className="p-2.5 rounded-xl border border-border bg-card text-foreground hover:bg-muted transition duration-200"
            title={isAr ? 'English' : 'العربية'}
          >
            <Languages className="w-5 h-5" />
          </button>
          <button
            onClick={toggleTheme}
            className="p-2.5 rounded-xl border border-border bg-card text-foreground hover:bg-muted transition duration-200"
          >
            {theme === 'light' ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
          </button>
        </div>
      </div>

      <div className="w-full max-w-md slide-up">
        {/* Card wrapper */}
        <div className="premium-card p-8 backdrop-blur-md bg-card/80 border border-border/80 relative">
          <div className="text-center mb-8">
            <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mx-auto mb-4 border border-primary/20">
              <Sparkles className="w-8 h-8 text-primary" />
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-foreground">
              {isAr ? 'تسجيل الدخول إلى سداد' : 'Sign in to Sidad'}
            </h1>
            <p className="text-sm text-muted-foreground mt-2">
              {isAr ? 'لوحة تحكم إدارة منصة الديون والمدفوعات' : 'Fintech Debt & Payments Admin Panel'}
            </p>
          </div>

          {error && (
            <div className="mb-6 p-4 rounded-xl border border-destructive/20 bg-destructive/10 text-destructive text-sm flex items-center gap-3">
              <ShieldAlert className="w-5 h-5 flex-shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">
                {isAr ? 'البريد الإلكتروني' : 'Email Address'}
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@sidad.app"
                className="w-full px-4 py-3 rounded-xl border border-border bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition duration-200"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">
                {isAr ? 'كلمة المرور' : 'Password'}
              </label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full px-4 py-3 rounded-xl border border-border bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition duration-200"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 px-4 rounded-xl bg-primary text-primary-foreground font-semibold flex items-center justify-center gap-2 hover:opacity-95 disabled:opacity-50 transition duration-200 cursor-pointer shadow-lg shadow-primary/10"
            >
              {loading ? (
                <span className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
              ) : (
                <>
                  <LogIn className="w-5 h-5" />
                  <span>{isAr ? 'تسجيل الدخول' : 'Sign In'}</span>
                </>
              )}
            </button>
          </form>

          {/* Divider */}
          <div className="relative my-6">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-border"></div>
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-card px-2 text-muted-foreground">
                {isAr ? 'أو الدخول للتجربة السريعة' : 'Or Sandbox Access'}
              </span>
            </div>
          </div>

          <button
            onClick={loginDemo}
            disabled={loading}
            className="w-full py-3 px-4 rounded-xl border border-primary/30 bg-primary/5 text-primary font-semibold flex items-center justify-center gap-2 hover:bg-primary/10 transition duration-200 cursor-pointer"
          >
            <Sparkles className="w-5 h-5 text-primary" />
            <span>{isAr ? 'الدخول السريع كمدير نظام (Demo)' : 'Quick Demo Admin Login'}</span>
          </button>
        </div>
      </div>
    </div>
  )
}
