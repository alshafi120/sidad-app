import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { User } from '../lib/api'
import { useApp } from '../components/AppContext'
import {
  UserCheck,
  Plus,
  Mail,
  Shield,
  CheckCircle,
  XCircle,
  Key,
  Lock,
  Eye,
  Sliders,
} from 'lucide-react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as zod from 'zod'

export const Route = createFileRoute('/users')({
  component: UsersPage,
})

const adminSchema = zod.object({
  name: zod.string().min(3, 'الاسم مطلوب / Name is required'),
  email: zod.string().email('بريد غير صالح / Invalid email'),
  role: zod.enum(['admin', 'support', 'superadmin']),
})

type AdminFormValues = zod.infer<typeof adminSchema>

function UsersPage() {
  const { lang, dir } = useApp()
  const isAr = lang === 'ar'
  const queryClient = useQueryClient()
  const [activeSubTab, setActiveSubTab] = useState<'admins' | 'roles'>('admins')
  const [showCreateModal, setShowCreateModal] = useState(false)

  // React Hook Form
  const { register, handleSubmit, reset, formState: { errors } } = useForm<AdminFormValues>({
    resolver: zodResolver(adminSchema),
    defaultValues: {
      name: '',
      email: '',
      role: 'admin',
    }
  })

  // Simulated list of admins
  const [adminsList, setAdminsList] = useState([
    { id: 'u1', name: 'عبد الرحمن العتيبي', email: 'admin@sidad.co', role: 'superadmin', status: 'active', date: '2025-01-01' },
    { id: 'u2', name: 'سارة القحطاني', email: 'sara@sidad.co', role: 'admin', status: 'active', date: '2025-03-12' },
    { id: 'u3', name: 'خالد الشهراني', email: 'khaled@sidad.co', role: 'support', status: 'active', date: '2025-05-20' },
  ])

  const handleCreate = (values: AdminFormValues) => {
    const newAdmin = {
      id: 'u' + (adminsList.length + 1),
      name: values.name,
      email: values.email,
      role: values.role,
      status: 'active',
      date: new Date().toISOString().split('T')[0],
    }
    setAdminsList([...adminsList, newAdmin])
    setShowCreateModal(false)
    reset()
  }

  const toggleAdminStatus = (id: string) => {
    setAdminsList(
      adminsList.map((a) => (a.id === id ? { ...a, status: a.status === 'active' ? 'suspended' : 'active' } : a))
    )
  }

  // Permissions matrix
  const permissionsList = [
    { id: 'p_merchants', descAr: 'إدارة التجار وتفعيلهم وتعليقهم', descEn: 'Manage, activate & suspend merchants' },
    { id: 'p_debts_approve', descAr: 'اعتماد وقبول الديون والتحصيل', descEn: 'Approve & confirm outstanding debts' },
    { id: 'p_packages', descAr: 'تعديل وإنشاء خطط الاشتراك السعرية', descEn: 'Create & edit pricing packages' },
    { id: 'p_settings', descAr: 'تعديل الإعدادات العامة وبوابات الدفع', descEn: 'Configure payment gates & server SMTP' },
    { id: 'p_logs', descAr: 'عرض واستعراض سجل العمليات الأمني', descEn: 'Review security audit logs' },
  ]

  return (
    <div className="space-y-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {isAr ? 'المستخدمون والصلاحيات' : 'Admins & Permissions'}
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            {isAr ? 'إدارة حسابات مسؤولي النظام وتخصيص صلاحيات الوصول والمجموعات' : 'Manage system administrators, security policies, and roles.'}
          </p>
        </div>

        {activeSubTab === 'admins' && (
          <button
            onClick={() => setShowCreateModal(true)}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-primary-foreground font-semibold hover:opacity-95 transition duration-200 cursor-pointer shadow-lg shadow-primary/10 text-sm"
          >
            <Plus className="w-5 h-5" />
            <span>{isAr ? 'إضافة مسؤول جديد' : 'New Admin'}</span>
          </button>
        )}
      </div>

      {/* Sub Tabs Switcher */}
      <div className="flex items-center gap-3 border-b border-border pb-px">
        <button
          onClick={() => setActiveSubTab('admins')}
          className={`px-4 py-3 text-xs font-semibold border-b-2 transition cursor-pointer
            ${activeSubTab === 'admins' ? 'border-primary text-primary font-bold' : 'border-transparent text-muted-foreground hover:text-foreground'}
          `}
        >
          {isAr ? 'مسؤولو النظام (Admins)' : 'Administrators'}
        </button>
        <button
          onClick={() => setActiveSubTab('roles')}
          className={`px-4 py-3 text-xs font-semibold border-b-2 transition cursor-pointer
            ${activeSubTab === 'roles' ? 'border-primary text-primary font-bold' : 'border-transparent text-muted-foreground hover:text-foreground'}
          `}
        >
          {isAr ? 'الأدوار والصلاحيات (Permissions)' : 'Roles & Permissions Matrix'}
        </button>
      </div>

      {/* Panels */}
      <div className="slide-up">
        
        {/* ADMINS PANEL */}
        {activeSubTab === 'admins' && (
          <div className="premium-card overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-xs text-start border-collapse">
                <thead>
                  <tr className="border-b border-border bg-muted/30 text-muted-foreground font-semibold uppercase">
                    <th className="py-4 px-4 text-start">{isAr ? 'المسؤول' : 'Admin User'}</th>
                    <th className="py-4 px-4 text-start">{isAr ? 'البريد الإلكتروني' : 'Email'}</th>
                    <th className="py-4 px-4 text-start">{isAr ? 'الدور المخصص' : 'System Role'}</th>
                    <th className="py-4 px-4 text-start">{isAr ? 'الحالة' : 'Status'}</th>
                    <th className="py-4 px-4 text-start">{isAr ? 'تاريخ التعيين' : 'Appointed Date'}</th>
                    <th className="py-4 px-4 text-center">{isAr ? 'الإجراءات' : 'Actions'}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border/40 font-medium">
                  {adminsList.map((a) => (
                    <tr key={a.id} className="hover:bg-muted/30 transition">
                      <td className="py-4 px-4 flex items-center gap-2">
                        <div className="w-8 h-8 rounded-lg bg-indigo-50/50 text-primary border border-border flex items-center justify-center font-bold font-english">
                          {a.name.charAt(0)}
                        </div>
                        <div>
                          <p className="font-bold text-foreground text-sm">{a.name}</p>
                          <span className="text-[10px] text-muted-foreground font-english">#{a.id}</span>
                        </div>
                      </td>
                      <td className="py-4 px-4 font-english text-muted-foreground">{a.email}</td>
                      <td className="py-4 px-4 font-english uppercase text-primary font-bold">
                        {a.role}
                      </td>
                      <td className="py-4 px-4">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full font-bold text-[9px] uppercase
                          ${a.status === 'active' ? 'bg-green-500/10 text-green-600' : 'bg-red-500/10 text-red-600'}
                        `}>
                          {a.status === 'active' ? (isAr ? 'نشط' : 'Active') : (isAr ? 'معلق' : 'Suspended')}
                        </span>
                      </td>
                      <td className="py-4 px-4 text-muted-foreground font-english">{a.date}</td>
                      <td className="py-4 px-4 text-center">
                        <div className="flex items-center justify-center gap-2">
                          <button
                            onClick={() => toggleAdminStatus(a.id)}
                            className={`px-2.5 py-1 rounded-lg text-[10px] font-bold border transition cursor-pointer
                              ${a.status === 'active' ? 'border-amber-500/20 bg-amber-500/5 text-amber-600 hover:bg-amber-500/10' : 'border-green-500/20 bg-green-500/5 text-green-600 hover:bg-green-500/10'}
                            `}
                          >
                            {a.status === 'active' ? (isAr ? 'تعطيل' : 'Suspend') : (isAr ? 'تنشيط' : 'Activate')}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* ROLES PANEL */}
        {activeSubTab === 'roles' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            
            {/* Roles Descriptions */}
            <div className="lg:col-span-1 space-y-4">
              <div className="premium-card p-5 bg-card space-y-4 text-xs font-semibold text-muted-foreground">
                <h4 className="text-sm font-bold text-foreground flex items-center gap-2"><Lock className="w-4.5 h-4.5 text-primary" /> {isAr ? 'تفاصيل الأدوار' : 'Roles Definition'}</h4>
                <p>{isAr ? 'مسؤول النظام لديه كامل الصلاحيات دون قيود.' : 'Superadmin has unrestricted, root-level permissions.'}</p>
                <p>{isAr ? 'المدير المالي المساعد يمكنه اعتماد الديون ومراجعة المدفوعات والاشتراكات.' : 'Financier handles debt approvals, billing statements, and payments.'}</p>
                <p>{isAr ? 'مسؤول الدعم الفني يمكنه تصفح بيانات التجار ومساعدتهم مع تعطيل الصلاحيات الأمنية والمالية.' : 'Support agent provides client diagnostics, read-only dashboard.'}</p>
              </div>
            </div>

            {/* Permissions Matrix */}
            <div className="lg:col-span-2 premium-card p-6 bg-card">
              <h4 className="text-sm font-bold mb-6 flex items-center gap-2"><Sliders className="w-4.5 h-4.5 text-primary" /> {isAr ? 'صلاحيات الوصول والعمليات' : 'Permissions Allocation Matrix'}</h4>
              
              <div className="space-y-4 font-semibold text-xs text-muted-foreground">
                {permissionsList.map((perm) => (
                  <div key={perm.id} className="flex items-center justify-between p-3 rounded-xl border border-border bg-background">
                    <div>
                      <p className="font-bold text-foreground">{isAr ? perm.descAr : perm.descEn}</p>
                      <span className="text-[10px] text-muted-foreground font-english">{perm.id}</span>
                    </div>
                    
                    <div className="flex items-center gap-6">
                      {/* Superadmin */}
                      <label className="flex items-center gap-1.5 cursor-not-allowed">
                        <input type="checkbox" defaultChecked disabled className="rounded text-primary focus:ring-primary/20" />
                        <span className="text-[10px] uppercase font-english text-primary">Super</span>
                      </label>

                      {/* Admin */}
                      <label className="flex items-center gap-1.5 cursor-pointer">
                        <input type="checkbox" defaultChecked={perm.id !== 'p_settings'} className="rounded text-primary focus:ring-primary/20" />
                        <span className="text-[10px] uppercase font-english">Admin</span>
                      </label>

                      {/* Support */}
                      <label className="flex items-center gap-1.5 cursor-pointer">
                        <input type="checkbox" defaultChecked={perm.id === 'p_logs'} className="rounded text-primary focus:ring-primary/20" />
                        <span className="text-[10px] uppercase font-english">Support</span>
                      </label>
                    </div>

                  </div>
                ))}
              </div>
            </div>

          </div>
        )}

      </div>

      {/* Create Admin Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/50 backdrop-blur-xs" onClick={() => setShowCreateModal(false)} />
          
          <div className="bg-card text-foreground rounded-2xl w-full max-w-md p-6 border border-border relative z-10 slide-up shadow-2xl">
            <h3 className="text-xl font-bold mb-4">{isAr ? 'إضافة مسؤول نظام جديد' : 'Invite Team Admin'}</h3>
            
            <form onSubmit={handleSubmit(handleCreate)} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'الاسم الكامل للمسؤول' : 'Full Name'}</label>
                <input
                  type="text"
                  required
                  {...register('name')}
                  placeholder={isAr ? 'خالد الحربي' : 'Khaled Alharbi'}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'البريد الإلكتروني' : 'Email Address'}</label>
                <input
                  type="email"
                  required
                  {...register('email')}
                  placeholder="admin@sidad.co"
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'الدور المخصص والصلاحيات' : 'Role Allocation'}</label>
                <select
                  {...register('role')}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:outline-none"
                >
                  <option value="superadmin">Super Admin</option>
                  <option value="admin">Admin Manager</option>
                  <option value="support">Customer Support Representative</option>
                </select>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-border/60">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="px-4 py-2.5 rounded-xl border border-border bg-muted/10 font-bold text-sm cursor-pointer"
                >
                  {isAr ? 'إلغاء' : 'Cancel'}
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 rounded-xl bg-primary text-primary-foreground font-bold text-sm cursor-pointer hover:opacity-95 shadow-md"
                >
                  {isAr ? 'إرسال دعوة' : 'Send Invite'}
                </button>
              </div>

            </form>
          </div>
        </div>
      )}

    </div>
  )
}
