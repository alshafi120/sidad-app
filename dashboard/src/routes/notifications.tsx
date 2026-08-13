import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as zod from 'zod'
import { useApp } from '../components/AppContext'
import { Bell, Plus, MessageSquare, Send, CheckCircle, Info, AlertTriangle, ShieldAlert } from 'lucide-react'

export const Route = createFileRoute('/notifications')({
  component: NotificationsPage,
})

const broadcastSchema = zod.object({
  title: zod.string().min(3, 'العنوان مطلوب / Title is required'),
  type: zod.enum(['info', 'warning', 'danger']),
  message: zod.string().min(5, 'محتوى الرسالة مطلوب / Message content is required'),
})

type BroadcastFormValues = zod.infer<typeof broadcastSchema>

function NotificationsPage() {
  const { lang } = useApp()
  const isAr = lang === 'ar'
  const [success, setSuccess] = useState(false)

  const { register, handleSubmit, reset, formState: { errors } } = useForm<BroadcastFormValues>({
    resolver: zodResolver(broadcastSchema),
    defaultValues: {
      title: '',
      type: 'info',
      message: '',
    }
  })

  // Simulated notifications log
  const [notificationLogs, setNotificationLogs] = useState([
    { id: 1, title: 'صيانة طارئة لخادم المرفق الإلكتروني', type: 'warning', date: '2026-06-25 22:00', reach: 142 },
    { id: 2, title: 'إطلاق باقة "Enterprise" السعرية الجديدة', type: 'info', date: '2026-06-24 10:15', reach: 140 },
    { id: 3, title: 'فشل ربط بوابة الدفع مدى مع خوادم البنك المركزي', type: 'danger', date: '2026-06-20 14:30', reach: 120 },
  ])

  const onSubmit = (values: BroadcastFormValues) => {
    const newAlert = {
      id: notificationLogs.length + 1,
      title: values.title,
      type: values.type,
      date: new Date().toISOString().replace('T', ' ').substring(0, 16),
      reach: 142, // Simulated total active merchant reach
    }
    setNotificationLogs([newAlert, ...notificationLogs])
    setSuccess(true)
    reset()
    setTimeout(() => setSuccess(false), 3000)
  }

  return (
    <div className="space-y-8">
      
      {/* Title */}
      <div>
        <h1 className="text-3xl font-extrabold tracking-tight text-foreground font-arabic">
          {isAr ? 'إرسال التنبيهات والإشعارات' : 'Push Notification Dispatcher'}
        </h1>
        <p className="text-muted-foreground text-sm mt-1">
          {isAr ? 'إرسال التنبيهات العامة والرسائل المباشرة للمنشآت ومتابعة حالتها' : 'Broadcast notifications and audit alert histories.'}
        </p>
      </div>

      {success && (
        <div className="p-4 rounded-xl border border-green-500/20 bg-green-500/10 text-green-600 text-sm flex items-center gap-2 slide-up">
          <CheckCircle className="w-5 h-5" />
          <span>{isAr ? 'تم إرسال بث التنبيه بنجاح لجميع المشتركين.' : 'Notification broadcasted successfully to all active devices.'}</span>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Create Broadcast form */}
        <div className="lg:col-span-1 premium-card p-6 bg-card">
          <h3 className="text-sm font-bold mb-4 flex items-center gap-2"><Send className="w-4.5 h-4.5 text-primary" /> {isAr ? 'بث إشعار جديد' : 'New Broadcast Alert'}</h3>
          
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'عنوان التنبيه' : 'Alert Title'}</label>
              <input
                type="text"
                required
                {...register('title')}
                placeholder={isAr ? 'صيانة مجدولة للنظام...' : 'System Maintenance Update...'}
                className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
              />
              {errors.title && <p className="text-xs text-destructive mt-1">{errors.title.message}</p>}
            </div>

            <div>
              <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'نوع التنبيه وخطورته' : 'Severity Level'}</label>
              <select
                {...register('type')}
                className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:outline-none"
              >
                <option value="info">{isAr ? 'إرشادي / عادي (Info)' : 'Informational'}</option>
                <option value="warning">{isAr ? 'تحذيري متوسط (Warning)' : 'Medium Alert'}</option>
                <option value="danger">{isAr ? 'هام وعاجل جداً (Danger)' : 'Critical Alert'}</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'محتوى الرسالة' : 'Broadcast Message Body'}</label>
              <textarea
                required
                rows={4}
                {...register('message')}
                placeholder={isAr ? 'نود إحاطتكم علماً بأن المنصة ستخضع لأعمال صيانة...' : 'Please be informed that the platform will undergo scheduled operations...'}
                className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none resize-none"
              />
              {errors.message && <p className="text-xs text-destructive mt-1">{errors.message.message}</p>}
            </div>

            <div className="pt-2">
              <button
                type="submit"
                className="w-full py-2.5 rounded-xl bg-primary text-primary-foreground font-bold text-xs flex items-center justify-center gap-1.5 cursor-pointer hover:opacity-95 shadow-md shadow-primary/10"
              >
                <Bell className="w-4 h-4" />
                <span>{isAr ? 'إرسال بث فوري' : 'Dispatch Broadcast'}</span>
              </button>
            </div>

          </form>
        </div>

        {/* History timeline */}
        <div className="lg:col-span-2 premium-card p-6 bg-card">
          <h3 className="text-sm font-bold mb-4 flex items-center gap-2"><MessageSquare className="w-4.5 h-4.5 text-primary" /> {isAr ? 'سجل تاريخ الإشعارات المرسلة' : 'Sent Notification Logs'}</h3>
          
          <div className="divide-y divide-border/40 text-xs">
            {notificationLogs.map((log) => (
              <div key={log.id} className="py-4 flex justify-between items-start gap-4">
                <div className="flex gap-3">
                  <div className="mt-0.5">
                    {log.type === 'info' && <Info className="w-5 h-5 text-blue-600" />}
                    {log.type === 'warning' && <AlertTriangle className="w-5 h-5 text-amber-500" />}
                    {log.type === 'danger' && <ShieldAlert className="w-5 h-5 text-destructive" />}
                  </div>
                  <div>
                    <p className="font-bold text-foreground text-sm">{log.title}</p>
                    <time className="text-[10px] text-muted-foreground font-english mt-1 block">{log.date}</time>
                  </div>
                </div>

                <div className="text-end font-english text-[10px] text-muted-foreground font-semibold">
                  <span className="bg-muted px-2.5 py-1 rounded-full text-foreground">
                    {log.reach} {isAr ? 'تاجر مستلم' : 'merchants'}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

    </div>
  )
}
