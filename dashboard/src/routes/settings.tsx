import { createFileRoute } from '@tanstack/react-router'
import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { SystemSettings } from '../lib/api'
import { useApp } from '../components/AppContext'
import {
  Settings,
  Mail,
  Smartphone,
  MessageSquare,
  CreditCard,
  Sliders,
  CheckCircle,
} from 'lucide-react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as zod from 'zod'

export const Route = createFileRoute('/settings')({
  component: SettingsPage,
})

const settingsSchema = zod.object({
  general: zod.object({
    site_name: zod.string().min(3, 'الاسم مطلوب / Name is required'),
    support_email: zod.string().email('بريد غير صالح / Invalid email'),
    currency: zod.string(),
  }),
  smtp: zod.object({
    host: zod.string().min(1, 'Host is required'),
    port: zod.number().min(1),
    encryption: zod.string(),
    username: zod.string(),
  }),
  sms: zod.object({
    provider: zod.string(),
    api_key: zod.string(),
    sender_name: zod.string(),
  }),
  whatsapp: zod.object({
    instance_id: zod.string(),
    token: zod.string(),
  }),
  payment_methods: zod.object({
    mada: zod.boolean(),
    visa: zod.boolean(),
    apple_pay: zod.boolean(),
  }),
})

type SettingsFormValues = zod.infer<typeof settingsSchema>

function SettingsPage() {
  const { lang, dir } = useApp()
  const isAr = lang === 'ar'
  const queryClient = useQueryClient()
  const [activeTab, setActiveTab] = useState<'general' | 'smtp' | 'sms' | 'whatsapp' | 'payment'>('general')
  const [savedSuccess, setSavedSuccess] = useState(false)

  // Query Settings
  const { data: currentSettings, isLoading } = useQuery({
    queryKey: ['settings'],
    queryFn: () => api.getSettings(),
  })

  const updateMutation = useMutation({
    mutationFn: (newSettings: Partial<SystemSettings>) => api.updateSettings(newSettings),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings'] })
      setSavedSuccess(true)
      setTimeout(() => setSavedSuccess(false), 3000)
    }
  })

  // Hook Form setup
  const { register, handleSubmit, reset, formState: { errors } } = useForm<SettingsFormValues>({
    resolver: zodResolver(settingsSchema),
  })

  // Load defaults when query resolves
  useEffect(() => {
    if (currentSettings) {
      reset(currentSettings)
    }
  }, [currentSettings, reset])

  const onSubmit = (values: SettingsFormValues) => {
    updateMutation.mutate(values)
  }

  return (
    <div className="space-y-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {isAr ? 'الإعدادات العامة للنظام' : 'System Settings'}
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            {isAr ? 'تخصيص بوابات الدفع والتنبيهات وإعدادات البريد ورسائل SMS' : 'Configure platform features, payment gateways, and API integrations.'}
          </p>
        </div>
      </div>

      {savedSuccess && (
        <div className="p-4 rounded-xl border border-green-500/20 bg-green-500/10 text-green-600 text-sm flex items-center gap-2 slide-up">
          <CheckCircle className="w-5 h-5" />
          <span>{isAr ? 'تم حفظ التعديلات بنجاح.' : 'Settings updated successfully.'}</span>
        </div>
      )}

      {isLoading ? (
        <div className="p-12 text-center animate-pulse">{isAr ? 'جاري تحميل الإعدادات...' : 'Loading Settings...'}</div>
      ) : (
        <form onSubmit={handleSubmit(onSubmit)} className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          
          {/* Settings Tabs Sidebar */}
          <div className="lg:col-span-1 space-y-1">
            {[
              { id: 'general', labelAr: 'الإعدادات العامة', labelEn: 'General Settings', icon: Sliders },
              { id: 'smtp', labelAr: 'إعدادات البريد SMTP', labelEn: 'SMTP Configuration', icon: Mail },
              { id: 'sms', labelAr: 'بوابة رسائل SMS', labelEn: 'SMS Gateway', icon: Smartphone },
              { id: 'whatsapp', labelAr: 'ربط الواتساب', labelEn: 'WhatsApp Integration', icon: MessageSquare },
              { id: 'payment', labelAr: 'بوابات الدفع الإلكتروني', labelEn: 'Payment Methods', icon: CreditCard },
            ].map((tab) => {
              const Icon = tab.icon
              return (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => setActiveTab(tab.id as any)}
                  className={`w-full flex items-center gap-3 px-4 py-3 text-xs font-semibold rounded-xl text-start transition duration-200 cursor-pointer
                    ${activeTab === tab.id ? 'bg-primary text-primary-foreground font-bold' : 'hover:bg-muted text-muted-foreground hover:text-foreground'}
                  `}
                >
                  <Icon className="w-4.5 h-4.5" />
                  <span>{isAr ? tab.labelAr : tab.labelEn}</span>
                </button>
              )
            })}
          </div>

          {/* Settings Tab Panels */}
          <div className="lg:col-span-3 premium-card p-6 bg-card">
            
            {/* General Panel */}
            {activeTab === 'general' && (
              <div className="space-y-4">
                <h3 className="text-md font-bold mb-4">{isAr ? 'الإعدادات العامة والهوية' : 'General & Branding'}</h3>
                
                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'اسم المنصة والخدمة' : 'Platform Site Name'}</label>
                  <input
                    type="text"
                    {...register('general.site_name')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:outline-none"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'بريد الدعم الفني' : 'Support Email'}</label>
                    <input
                      type="email"
                      {...register('general.support_email')}
                      className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:outline-none"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'العملة الافتراضية' : 'Currency Symbol'}</label>
                    <input
                      type="text"
                      {...register('general.currency')}
                      className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:outline-none"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* SMTP CONFIG PANEL */}
            {activeTab === 'smtp' && (
              <div className="space-y-4">
                <h3 className="text-md font-bold mb-4">{isAr ? 'إعداد خادم البريد SMTP' : 'SMTP Server Configurations'}</h3>
                
                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">SMTP Host</label>
                  <input
                    type="text"
                    {...register('smtp.host')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 font-english"
                  />
                </div>

                <div className="grid grid-cols-3 gap-4">
                  <div className="col-span-1">
                    <label className="block text-xs font-semibold mb-1 text-muted-foreground">Port</label>
                    <input
                      type="number"
                      {...register('smtp.port', { valueAsNumber: true })}
                      className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 font-english"
                    />
                  </div>

                  <div className="col-span-2">
                    <label className="block text-xs font-semibold mb-1 text-muted-foreground">Encryption</label>
                    <select
                      {...register('smtp.encryption')}
                      className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 font-english"
                    >
                      <option value="tls">TLS</option>
                      <option value="ssl">SSL</option>
                      <option value="none">None</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">Username / Email</label>
                  <input
                    type="text"
                    {...register('smtp.username')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 font-english"
                  />
                </div>
              </div>
            )}

            {/* SMS PANEL */}
            {activeTab === 'sms' && (
              <div className="space-y-4">
                <h3 className="text-md font-bold mb-4">{isAr ? 'إعدادات بوابة رسائل الجوال Short SMS' : 'SMS Notification Gateway'}</h3>
                
                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'مزود الخدمة' : 'Provider Service'}</label>
                  <input
                    type="text"
                    {...register('sms.provider')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 font-english"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">API Gateway Key</label>
                  <input
                    type="password"
                    {...register('sms.api_key')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 font-english"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'اسم المرسل المعتمد' : 'Sender Name ID'}</label>
                  <input
                    type="text"
                    {...register('sms.sender_name')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 font-english"
                  />
                </div>
              </div>
            )}

            {/* WHATSAPP PANEL */}
            {activeTab === 'whatsapp' && (
              <div className="space-y-4">
                <h3 className="text-md font-bold mb-4">{isAr ? 'إعداد بوابة وتنبيهات الواتساب' : 'WhatsApp Business API'}</h3>
                
                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">WhatsApp Instance ID</label>
                  <input
                    type="text"
                    {...register('whatsapp.instance_id')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 font-english"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">WhatsApp Authentication Token</label>
                  <input
                    type="password"
                    {...register('whatsapp.token')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 font-english"
                  />
                </div>
              </div>
            )}

            {/* PAYMENT METHOD PANEL */}
            {activeTab === 'payment' && (
              <div className="space-y-6">
                <div>
                  <h3 className="text-md font-bold">{isAr ? 'تفعيل قنوات بوابات الدفع الإلكتروني' : 'Electronic Payment Channels'}</h3>
                  <p className="text-xs text-muted-foreground mt-1">{isAr ? 'تحديد وسائل السداد المتاحة للعملاء لسداد ديون التجار' : 'Configure allowed checkout gates for customers.'}</p>
                </div>

                <div className="space-y-4 border-t border-border/40 pt-4 text-xs font-semibold">
                  
                  {/* Mada */}
                  <div className="flex items-center justify-between p-3 rounded-xl border border-border bg-background">
                    <div>
                      <p className="font-bold text-foreground">{isAr ? 'مدى (Mada)' : 'Mada Checkout Gateway'}</p>
                      <span className="text-[10px] text-muted-foreground">{isAr ? 'البوابة الرسمية السعودية للمدفوعات' : 'Local Saudi official debit card system'}</span>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        {...register('payment_methods.mada')}
                        className="sr-only peer"
                      />
                      <div className="w-9 h-5 bg-muted peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-primary" />
                    </label>
                  </div>

                  {/* Visa */}
                  <div className="flex items-center justify-between p-3 rounded-xl border border-border bg-background">
                    <div>
                      <p className="font-bold text-foreground">Visa / MasterCard</p>
                      <span className="text-[10px] text-muted-foreground">{isAr ? 'قبول البطاقات الائتمانية العالمية' : 'Accept global credit & charge cards'}</span>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        {...register('payment_methods.visa')}
                        className="sr-only peer"
                      />
                      <div className="w-9 h-5 bg-muted peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-primary" />
                    </label>
                  </div>

                  {/* Apple Pay */}
                  <div className="flex items-center justify-between p-3 rounded-xl border border-border bg-background">
                    <div>
                      <p className="font-bold text-foreground">Apple Pay</p>
                      <span className="text-[10px] text-muted-foreground">{isAr ? 'تسهيل السداد السريع عبر أجهزة آبل' : 'Quick one-tap mobile checkout'}</span>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        {...register('payment_methods.apple_pay')}
                        className="sr-only peer"
                      />
                      <div className="w-9 h-5 bg-muted peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-primary" />
                    </label>
                  </div>

                </div>
              </div>
            )}

            {/* Footer Buttons */}
            <div className="flex justify-end gap-3 pt-6 border-t border-border/40 mt-6">
              <button
                type="submit"
                disabled={updateMutation.isPending}
                className="px-6 py-2.5 rounded-xl bg-primary text-primary-foreground font-bold text-xs cursor-pointer hover:opacity-95 shadow-md shadow-primary/10 flex items-center gap-2"
              >
                {updateMutation.isPending ? (
                  <span className="w-4 h-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin block" />
                ) : (
                  isAr ? 'حفظ التعديلات' : 'Save Changes'
                )}
              </button>
            </div>

          </div>

        </form>
      )}

    </div>
  )
}
