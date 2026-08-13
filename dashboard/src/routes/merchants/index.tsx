import { createFileRoute, Link } from '@tanstack/react-router'
import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../../lib/api'
import type { Merchant } from '../../lib/api'
import { useApp } from '../../components/AppContext'
import {
  Search,
  Plus,
  MoreVertical,
  Eye,
  Edit2,
  AlertTriangle,
  CheckCircle,
  RefreshCw,
  Key,
  ShieldCheck,
  UserCheck,
  Building,
  Mail,
  Phone,
  UserMinus,
  Settings,
} from 'lucide-react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as zod from 'zod'

export const Route = createFileRoute('/merchants/')({
  component: MerchantsPage,
})

// Validation Schema for Merchant creation/editing
const merchantSchema = zod.object({
  name: zod.string().min(3, 'يجب أن يكون اسم التاجر 3 أحرف على الأقل / Name must be at least 3 chars'),
  email: zod.string().email('بريد إلكتروني غير صالح / Invalid email'),
  phone: zod.string().min(10, 'رقم هاتف غير صالح / Invalid phone number'),
  plan: zod.enum(['Basic', 'Premium', 'Enterprise']),
  subscription: zod.enum(['monthly', 'yearly']),
})

type MerchantFormValues = zod.infer<typeof merchantSchema>

function MerchantsPage() {
  const { lang, dir, setUser } = useApp()
  const isAr = lang === 'ar'
  const queryClient = useQueryClient()
  
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [selectedMerchant, setSelectedMerchant] = useState<Merchant | null>(null)
  const [activeDropdown, setActiveDropdown] = useState<string | null>(null)
  
  // React Hook Form
  const { register, handleSubmit, reset, formState: { errors } } = useForm<MerchantFormValues>({
    resolver: zodResolver(merchantSchema),
    defaultValues: {
      name: '',
      email: '',
      phone: '',
      plan: 'Basic',
      subscription: 'monthly',
    }
  })

  // Queries & Mutations
  const { data: merchants = [], isLoading } = useQuery({
    queryKey: ['merchants'],
    queryFn: () => api.getMerchants(),
  })

  const createMutation = useMutation({
    mutationFn: (newMerchant: Partial<Merchant>) => api.createMerchant(newMerchant),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['merchants'] })
      setShowCreateModal(false)
      reset()
    }
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Merchant> }) => api.updateMerchant(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['merchants'] })
      setSelectedMerchant(null)
      setActiveDropdown(null)
    }
  })

  const handleCreate = (values: MerchantFormValues) => {
    createMutation.mutate({
      name: values.name,
      email: values.email,
      phone: values.phone,
      plan: values.plan,
      subscription: values.subscription,
      logo: '🏢',
    })
  }

  const toggleStatus = (m: Merchant) => {
    const nextStatus = m.status === 'active' ? 'suspended' : 'active'
    updateMutation.mutate({
      id: m.id,
      data: { status: nextStatus }
    })
  }

  const renewSubscription = (m: Merchant) => {
    const addedDays = m.subscription === 'yearly' ? 365 : 30
    updateMutation.mutate({
      id: m.id,
      data: {
        status: 'active',
        remaining_days: (m.remaining_days || 0) + addedDays
      }
    })
  }

  const loginAsMerchant = (m: Merchant) => {
    // Simulate logging in as the merchant
    setUser({
      id: m.id,
      name: m.name,
      email: m.email,
      role: 'merchant',
      avatar: 'https://api.dicebear.com/7.x/initials/svg?seed=' + m.name,
      created_at: m.created_at,
    })
    window.location.href = '/'
  }

  // Filters
  const filteredMerchants = merchants.filter((m) => {
    const matchesSearch =
      m.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      m.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      m.phone.includes(searchTerm)
    
    if (statusFilter === 'all') return matchesSearch
    return matchesSearch && m.status === statusFilter
  })

  return (
    <div className="space-y-8 relative">
      
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {isAr ? 'إدارة التجار' : 'Merchant Management'}
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            {isAr ? 'استعراض الحسابات التجارية للشركات والتحكم باشتراكاتهم' : 'Inspect commercial accounts, status, and subscriptions.'}
          </p>
        </div>

        <button
          onClick={() => setShowCreateModal(true)}
          className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-primary-foreground font-semibold hover:opacity-95 transition duration-200 cursor-pointer shadow-lg shadow-primary/10 text-sm"
        >
          <Plus className="w-5 h-5" />
          <span>{isAr ? 'إضافة تاجر جديد' : 'New Merchant'}</span>
        </button>
      </div>

      {/* Filters Toolbar */}
      <div className="premium-card p-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="w-4.5 h-4.5 text-muted-foreground absolute start-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder={isAr ? 'البحث عن تاجر بالاسم أو الهاتف...' : 'Search merchant...'}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full ps-9 pe-4 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
          />
        </div>

        {/* Filters */}
        <div className="flex items-center gap-3 self-end md:self-auto">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 text-xs font-semibold rounded-xl border border-border bg-card text-foreground focus:outline-none focus:ring-2 focus:ring-primary/20"
          >
            <option value="all">{isAr ? 'كل الحالات' : 'All Statuses'}</option>
            <option value="active">{isAr ? 'نشط' : 'Active'}</option>
            <option value="suspended">{isAr ? 'معلق' : 'Suspended'}</option>
            <option value="expired">{isAr ? 'منتهي' : 'Expired'}</option>
          </select>
        </div>

      </div>

      {/* Table Content */}
      <div className="premium-card overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center animate-pulse space-y-4">
            <div className="h-8 bg-muted rounded w-full" />
            <div className="h-8 bg-muted rounded w-full" />
            <div className="h-8 bg-muted rounded w-full" />
          </div>
        ) : filteredMerchants.length === 0 ? (
          <div className="p-12 text-center text-muted-foreground">
            <Building className="w-16 h-16 mx-auto text-muted-foreground/30 mb-4" />
            <p className="font-bold">{isAr ? 'لا يوجد تجار حالياً' : 'No merchants found'}</p>
            <p className="text-xs mt-1">{isAr ? 'أضف تاجراً جديداً للبدء' : 'Try adding a merchant to begin'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs text-start border-collapse">
              <thead>
                <tr className="border-b border-border bg-muted/30 text-muted-foreground font-semibold uppercase">
                  <th className="py-4 px-4 text-start">{isAr ? 'التاجر' : 'Merchant'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'الاتصال' : 'Contact'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'الباقة' : 'Plan'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'الحالة' : 'Status'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'العملاء / الديون' : 'Cust/Debts'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'المدة المتبقية' : 'Remaining Days'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'تاريخ التسجيل' : 'Created Date'}</th>
                  <th className="py-4 px-4 text-center">{isAr ? 'الإجراءات' : 'Actions'}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40 font-medium">
                {filteredMerchants.map((m) => (
                  <tr key={m.id} className="hover:bg-muted/30 transition">
                    
                    {/* Brand Logo & Name */}
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-3">
                        <span className="text-2xl w-10 h-10 rounded-xl bg-indigo-50/50 flex items-center justify-center border border-border">
                          {m.logo}
                        </span>
                        <div>
                          <p className="font-bold text-foreground text-sm hover:text-primary transition">
                            <Link to="/merchants/$merchantId" params={{ merchantId: m.id }}>{m.name}</Link>
                          </p>
                          <span className="text-[10px] text-muted-foreground font-english">#{m.id}</span>
                        </div>
                      </div>
                    </td>

                    {/* Contact Details */}
                    <td className="py-4 px-4 space-y-1">
                      <p className="flex items-center gap-1 text-muted-foreground">
                        <Mail className="w-3.5 h-3.5" />
                        <span className="font-english">{m.email}</span>
                      </p>
                      <p className="flex items-center gap-1 text-muted-foreground">
                        <Phone className="w-3.5 h-3.5" />
                        <span className="font-english">{m.phone}</span>
                      </p>
                    </td>

                    {/* Subscription Package */}
                    <td className="py-4 px-4">
                      <div>
                        <p className="font-bold text-foreground font-english">{m.plan}</p>
                        <p className="text-[10px] text-muted-foreground uppercase font-english">
                          {m.subscription === 'yearly' ? (isAr ? 'سنوي' : 'Yearly') : (isAr ? 'شهري' : 'Monthly')}
                        </p>
                      </div>
                    </td>

                    {/* Status Badge */}
                    <td className="py-4 px-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full font-bold text-[10px] uppercase
                        ${m.status === 'active' ? 'bg-green-500/10 text-green-600' : ''}
                        ${m.status === 'suspended' ? 'bg-amber-500/10 text-amber-600' : ''}
                        ${m.status === 'expired' ? 'bg-red-500/10 text-red-600' : ''}
                      `}>
                        {m.status === 'active' && (isAr ? 'نشط' : 'Active')}
                        {m.status === 'suspended' && (isAr ? 'معلق' : 'Suspended')}
                        {m.status === 'expired' && (isAr ? 'منتهي' : 'Expired')}
                      </span>
                    </td>

                    {/* Customer & Debt counts */}
                    <td className="py-4 px-4 text-muted-foreground">
                      <p>{isAr ? 'عملاء:' : 'Cust:'} <span className="font-english font-bold text-foreground">{m.customers_count}</span></p>
                      <p>{isAr ? 'ديون:' : 'Debts:'} <span className="font-english font-bold text-foreground">{m.debts_count}</span></p>
                    </td>

                    {/* Days Left */}
                    <td className="py-4 px-4">
                      <span className={`font-english font-bold text-sm block
                        ${m.remaining_days <= 5 ? 'text-destructive' : m.remaining_days <= 15 ? 'text-warning' : 'text-green-600 dark:text-green-400'}
                      `}>
                        {m.remaining_days}
                      </span>
                      <span className="text-[10px] text-muted-foreground">{isAr ? 'يوم متبقي' : 'days left'}</span>
                    </td>

                    {/* Created date */}
                    <td className="py-4 px-4 text-muted-foreground font-english">{m.created_at}</td>

                    {/* Dropdown Actions */}
                    <td className="py-4 px-4 text-center relative">
                      <button
                        onClick={() => setActiveDropdown(activeDropdown === m.id ? null : m.id)}
                        className="p-1 rounded-lg hover:bg-muted text-muted-foreground hover:text-foreground transition"
                      >
                        <MoreVertical className="w-5 h-5" />
                      </button>

                      {activeDropdown === m.id && (
                        <>
                          {/* Close overlay */}
                          <div className="fixed inset-0 z-10" onClick={() => setActiveDropdown(null)} />
                          
                          <div className={`absolute z-20 top-10 ${dir === 'rtl' ? 'left-4' : 'right-4'} w-52 premium-card p-1 bg-card border border-border shadow-xl text-xs text-start`}>
                            <Link
                              to="/merchants/$merchantId"
                              params={{ merchantId: m.id }}
                              className="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-muted text-foreground"
                            >
                              <Eye className="w-4 h-4" />
                              <span>{isAr ? 'عرض التفاصيل' : 'View Details'}</span>
                            </Link>

                            <button
                              onClick={() => {
                                toggleStatus(m)
                                setActiveDropdown(null)
                              }}
                              className="w-full flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-muted text-foreground cursor-pointer"
                            >
                              {m.status === 'active' ? (
                                <>
                                  <UserMinus className="w-4 h-4 text-amber-500" />
                                  <span>{isAr ? 'تعليق الحساب' : 'Suspend Account'}</span>
                                </>
                              ) : (
                                <>
                                  <CheckCircle className="w-4 h-4 text-green-500" />
                                  <span>{isAr ? 'تنشيط الحساب' : 'Activate Account'}</span>
                                </>
                              )}
                            </button>

                            <button
                              onClick={() => {
                                renewSubscription(m)
                                setActiveDropdown(null)
                              }}
                              className="w-full flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-muted text-foreground cursor-pointer"
                            >
                              <RefreshCw className="w-4 h-4 text-primary" />
                              <span>{isAr ? 'تجديد الاشتراك' : 'Renew Subscription'}</span>
                            </button>

                            <button
                              onClick={() => {
                                alert(isAr ? 'تم إرسال رابط تعيين كلمة المرور إلى بريد التاجر الإلكتروني.' : 'Password reset link sent to merchant email.')
                                setActiveDropdown(null)
                              }}
                              className="w-full flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-muted text-foreground cursor-pointer"
                            >
                              <Key className="w-4 h-4 text-blue-500" />
                              <span>{isAr ? 'إعادة تعيين كلمة المرور' : 'Reset Password'}</span>
                            </button>

                            <div className="border-t border-border/60 my-1" />

                            <button
                              onClick={() => loginAsMerchant(m)}
                              className="w-full flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-primary/10 text-primary cursor-pointer font-semibold"
                            >
                              <ShieldCheck className="w-4 h-4" />
                              <span>{isAr ? 'تسجيل دخول باسم التاجر' : 'Login As Merchant'}</span>
                            </button>
                          </div>
                        </>
                      )}
                    </td>

                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Creation Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/50 backdrop-blur-xs" onClick={() => setShowCreateModal(false)} />
          
          <div className="bg-card text-foreground rounded-2xl w-full max-w-lg p-6 border border-border relative z-10 slide-up shadow-2xl">
            <h3 className="text-xl font-bold mb-4">{isAr ? 'إضافة تاجر جديد للنظام' : 'Create New Commercial Merchant'}</h3>
            
            <form onSubmit={handleSubmit(handleCreate)} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'اسم التاجر / المنشأة' : 'Merchant/Brand Name'}</label>
                <input
                  type="text"
                  required
                  {...register('name')}
                  placeholder={isAr ? 'شركة التقنيات الحديثة' : 'Modern Tech LLC'}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
                {errors.name && <p className="text-xs text-destructive mt-1">{errors.name.message}</p>}
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'البريد الإلكتروني' : 'Email Address'}</label>
                <input
                  type="email"
                  required
                  {...register('email')}
                  placeholder="merchant@sidad.sa"
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
                {errors.email && <p className="text-xs text-destructive mt-1">{errors.email.message}</p>}
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'رقم الجوال' : 'Phone Number'}</label>
                <input
                  type="text"
                  required
                  {...register('phone')}
                  placeholder="+966 50 123 4567"
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
                {errors.phone && <p className="text-xs text-destructive mt-1">{errors.phone.message}</p>}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'باقة الاشتراك' : 'Subscription Plan'}</label>
                  <select
                    {...register('plan')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:outline-none"
                  >
                    <option value="Basic">Basic</option>
                    <option value="Premium">Premium</option>
                    <option value="Enterprise">Enterprise</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'دورة الاشتراك' : 'Subscription Cycle'}</label>
                  <select
                    {...register('subscription')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:outline-none"
                  >
                    <option value="monthly">{isAr ? 'شهري' : 'Monthly'}</option>
                    <option value="yearly">{isAr ? 'سنوي' : 'Yearly'}</option>
                  </select>
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-border/60">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="px-4 py-2.5 rounded-xl border border-border bg-muted/10 font-bold text-sm cursor-pointer hover:bg-muted/20"
                >
                  {isAr ? 'إلغاء' : 'Cancel'}
                </button>
                <button
                  type="submit"
                  disabled={createMutation.isPending}
                  className="px-5 py-2.5 rounded-xl bg-primary text-primary-foreground font-bold text-sm cursor-pointer hover:opacity-95 shadow-md shadow-primary/10"
                >
                  {createMutation.isPending ? (
                    <span className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin block" />
                  ) : (
                    isAr ? 'حفظ وإضافة' : 'Save & Add'
                  )}
                </button>
              </div>

            </form>
          </div>
        </div>
      )}

    </div>
  )
}
