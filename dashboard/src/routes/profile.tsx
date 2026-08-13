import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { useApp } from '../components/AppContext'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as zod from 'zod'
import { api } from '../lib/api'
import { User, Shield, Key, CheckCircle, ShieldAlert } from 'lucide-react'

export const Route = createFileRoute('/profile')({
  component: ProfilePage,
})

const passwordSchema = zod.object({
  current_password: zod.string().min(1, 'كلمة المرور الحالية مطلوبة / Current password is required'),
  new_password: zod.string().min(6, 'يجب أن تكون كلمة المرور الجديدة 6 أحرف على الأقل / New password must be at least 6 chars'),
})

type PasswordFormValues = zod.infer<typeof passwordSchema>

function ProfilePage() {
  const { lang, user, setUser } = useApp()
  const isAr = lang === 'ar'
  const [successMsg, setSuccessMsg] = useState('')
  const [errorMsg, setErrorMsg] = useState('')
  const [loading, setLoading] = useState(false)

  const { register, handleSubmit, reset, formState: { errors } } = useForm<PasswordFormValues>({
    resolver: zodResolver(passwordSchema),
  })

  if (!user) {
    return <div className="p-8 text-center text-destructive">{isAr ? 'عذراً، يجب تسجيل الدخول.' : 'Please sign in.'}</div>
  }

  const handlePasswordChange = async (values: PasswordFormValues) => {
    setLoading(true)
    setSuccessMsg('')
    setErrorMsg('')
    try {
      if (api.isMockMode()) {
        // Simulate password change
        setTimeout(() => {
          setSuccessMsg(isAr ? 'تم تغيير كلمة المرور بنجاح (بيئة افتراضية)' : 'Password changed successfully (sandbox mode)')
          reset()
          setLoading(false)
        }, 1000)
        return
      }
      
      const response = await fetch('http://localhost:8000/api/profile/password', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('sidad_auth_token')}`,
        },
        body: JSON.stringify(values),
      })
      const data = await response.json()
      if (response.ok && data.success) {
        setSuccessMsg(isAr ? 'تم تحديث كلمة المرور بنجاح.' : 'Password updated successfully.')
        reset()
      } else {
        setErrorMsg(data.message || (isAr ? 'خطأ في تغيير كلمة المرور' : 'Error changing password'))
      }
    } catch (e) {
      setErrorMsg(isAr ? 'خادم الملحق غير متوفر حالياً.' : 'Backend connection unavailable.')
    } finally {
      if (!api.isMockMode()) setLoading(false)
    }
  }

  return (
    <div className="space-y-8 max-w-4xl mx-auto">
      
      {/* Title */}
      <div>
        <h1 className="text-3xl font-extrabold tracking-tight text-foreground font-arabic">
          {isAr ? 'الملف الشخصي' : 'My Account Settings'}
        </h1>
        <p className="text-muted-foreground text-sm mt-1">
          {isAr ? 'إدارة وتحديث بيانات الحساب الشخصي وكلمات المرور الأمنية' : 'Manage your system profile information and credentials.'}
        </p>
      </div>

      {successMsg && (
        <div className="p-4 rounded-xl border border-green-500/20 bg-green-500/10 text-green-600 text-sm flex items-center gap-2 slide-up">
          <CheckCircle className="w-5 h-5" />
          <span>{successMsg}</span>
        </div>
      )}

      {errorMsg && (
        <div className="p-4 rounded-xl border border-red-500/20 bg-red-500/10 text-red-600 text-sm flex items-center gap-2 slide-up">
          <ShieldAlert className="w-5 h-5" />
          <span>{errorMsg}</span>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        
        {/* Profile Card Summary */}
        <div className="md:col-span-1 premium-card p-6 bg-card flex flex-col items-center justify-center text-center">
          <img
            src={user.avatar || 'https://api.dicebear.com/7.x/adventurer/svg?seed=sidad'}
            alt={user.name}
            className="w-20 h-20 rounded-2xl bg-muted border border-border/80 mb-4"
          />
          <h3 className="font-bold text-base text-foreground">{user.name}</h3>
          <p className="text-xs text-muted-foreground font-english mt-1">{user.email}</p>
          <span className="mt-4 px-3 py-1 rounded-full text-[10px] bg-primary/10 text-primary border border-primary/20 font-bold uppercase font-english">
            {user.role}
          </span>
        </div>

        {/* Edit Security Password */}
        <div className="md:col-span-2 space-y-6">
          
          {/* General Details */}
          <div className="premium-card p-6 bg-card">
            <h4 className="text-sm font-bold mb-4 flex items-center gap-2"><User className="w-4.5 h-4.5 text-primary" /> {isAr ? 'البيانات الشخصية' : 'Personal Details'}</h4>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs font-semibold">
              <div>
                <span className="text-muted-foreground block mb-1">{isAr ? 'الاسم بالكامل' : 'Full Name'}</span>
                <span className="text-foreground text-sm font-bold">{user.name}</span>
              </div>
              <div>
                <span className="text-muted-foreground block mb-1">{isAr ? 'البريد الإلكتروني الحالي' : 'Email Address'}</span>
                <span className="text-foreground text-sm font-bold font-english">{user.email}</span>
              </div>
            </div>
          </div>

          {/* Change Password */}
          <div className="premium-card p-6 bg-card">
            <h4 className="text-sm font-bold mb-4 flex items-center gap-2"><Key className="w-4.5 h-4.5 text-primary" /> {isAr ? 'تغيير كلمة المرور' : 'Change Password'}</h4>
            
            <form onSubmit={handleSubmit(handlePasswordChange)} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'كلمة المرور الحالية' : 'Current Password'}</label>
                <input
                  type="password"
                  required
                  {...register('current_password')}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
                {errors.current_password && <p className="text-xs text-destructive mt-1">{errors.current_password.message}</p>}
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'كلمة المرور الجديدة' : 'New Password'}</label>
                <input
                  type="password"
                  required
                  {...register('new_password')}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
                {errors.new_password && <p className="text-xs text-destructive mt-1">{errors.new_password.message}</p>}
              </div>

              <div className="flex justify-end pt-4 border-t border-border/60">
                <button
                  type="submit"
                  disabled={loading}
                  className="px-5 py-2.5 rounded-xl bg-primary text-primary-foreground font-bold text-xs cursor-pointer hover:opacity-95 shadow-md shadow-primary/10 flex items-center gap-2"
                >
                  {loading ? (
                    <span className="w-4 h-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin block" />
                  ) : (
                    isAr ? 'تحديث كلمة المرور' : 'Update Password'
                  )}
                </button>
              </div>

            </form>
          </div>

        </div>

      </div>

    </div>
  )
}
