import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { Customer } from '../lib/api'
import { useApp } from '../components/AppContext'
import {
  Search,
  Plus,
  Download,
  Users,
  Mail,
  Phone,
  CheckCircle,
  XCircle,
  TrendingUp,
} from 'lucide-react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as zod from 'zod'

export const Route = createFileRoute('/customers')({
  component: CustomersPage,
})

const customerSchema = zod.object({
  name: zod.string().min(3, 'يجب أن يكون الاسم 3 أحرف على الأقل / Name must be at least 3 chars'),
  phone: zod.string().min(10, 'رقم هاتف غير صالح / Invalid phone number'),
  email: zod.string().email('بريد إلكتروني غير صالح / Invalid email'),
})

type CustomerFormValues = zod.infer<typeof customerSchema>

function CustomersPage() {
  const { lang, dir } = useApp()
  const isAr = lang === 'ar'
  const queryClient = useQueryClient()
  
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [showCreateModal, setShowCreateModal] = useState(false)

  const { register, handleSubmit, reset, formState: { errors } } = useForm<CustomerFormValues>({
    resolver: zodResolver(customerSchema),
    defaultValues: {
      name: '',
      phone: '',
      email: '',
    }
  })

  // TanStack Query
  const { data: customers = [], isLoading } = useQuery({
    queryKey: ['customers', searchTerm, statusFilter],
    queryFn: () => api.getCustomers({
      search: searchTerm,
      is_active: statusFilter === 'all' ? undefined : statusFilter === 'active',
    }),
  })

  const createMutation = useMutation({
    mutationFn: (newCust: Partial<Customer>) => api.createCustomer(newCust),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['customers'] })
      setShowCreateModal(false)
      reset()
    }
  })

  const handleCreate = (values: CustomerFormValues) => {
    createMutation.mutate({
      name: values.name,
      phone: values.phone,
      email: values.email,
      merchant_id: 'm1', // Default assigned merchant
    })
  }

  const exportCsv = () => {
    const headers = 'ID,Name,Phone,Email,Active,Total Debt,Paid Amount\n'
    const rows = customers.map((c) => `${c.id},"${c.name}",${c.phone},${c.email},${c.is_active},${c.total_debt},${c.paid_amount}`).join('\n')
    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.setAttribute('download', 'sidad_customers.csv')
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  return (
    <div className="space-y-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {isAr ? 'سجل العملاء' : 'Customers Registry'}
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            {isAr ? 'عرض بيانات العملاء ومراقبة إجمالي مديونياتهم ونشاطاتهم' : 'Review customer accounts, metrics, and debts.'}
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={exportCsv}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-border bg-card text-foreground font-semibold hover:bg-muted transition duration-200 cursor-pointer text-sm shadow-xs"
          >
            <Download className="w-4.5 h-4.5" />
            <span>{isAr ? 'تصدير البيانات' : 'Export CSV'}</span>
          </button>

          <button
            onClick={() => setShowCreateModal(true)}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-primary-foreground font-semibold hover:opacity-95 transition duration-200 cursor-pointer shadow-lg shadow-primary/10 text-sm"
          >
            <Plus className="w-5 h-5" />
            <span>{isAr ? 'إضافة عميل جديد' : 'New Customer'}</span>
          </button>
        </div>
      </div>

      {/* Filters Toolbar */}
      <div className="premium-card p-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="w-4.5 h-4.5 text-muted-foreground absolute start-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder={isAr ? 'البحث بالاسم، البريد أو الجوال...' : 'Search customers...'}
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
            className="px-3 py-2 text-xs font-semibold rounded-xl border border-border bg-card text-foreground focus:outline-none"
          >
            <option value="all">{isAr ? 'كل العملاء' : 'All Customers'}</option>
            <option value="active">{isAr ? 'العملاء النشطون' : 'Active Only'}</option>
            <option value="inactive">{isAr ? 'العملاء غير النشطين' : 'Inactive Only'}</option>
          </select>
        </div>

      </div>

      {/* Table grid */}
      <div className="premium-card overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center animate-pulse space-y-4">
            <div className="h-8 bg-muted rounded w-full" />
            <div className="h-8 bg-muted rounded w-full" />
            <div className="h-8 bg-muted rounded w-full" />
          </div>
        ) : customers.length === 0 ? (
          <div className="p-12 text-center text-muted-foreground">
            <Users className="w-16 h-16 mx-auto text-muted-foreground/30 mb-4" />
            <p className="font-bold">{isAr ? 'لا يوجد عملاء مطبقين للمرشحات' : 'No customers match the filters'}</p>
            <p className="text-xs mt-1">{isAr ? 'أضف عميلاً جديداً للبدء' : 'Try adding a new customer'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs text-start border-collapse">
              <thead>
                <tr className="border-b border-border bg-muted/30 text-muted-foreground font-semibold uppercase">
                  <th className="py-4 px-4 text-start">{isAr ? 'الاسم' : 'Name'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'بيانات الاتصال' : 'Contact'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'إجمالي المديونية' : 'Total Debt'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'المبالغ المدفوعة' : 'Paid Amount'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'عدد الديون' : 'Debts Count'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'الحالة' : 'Status'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'تاريخ التسجيل' : 'Created Date'}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40 font-medium">
                {customers.map((c) => (
                  <tr key={c.id} className="hover:bg-muted/30 transition">
                    
                    {/* Name */}
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold">
                          {c.name.charAt(0)}
                        </div>
                        <div>
                          <p className="font-bold text-foreground text-sm">{c.name}</p>
                          <span className="text-[10px] text-muted-foreground font-english">#{c.id}</span>
                        </div>
                      </div>
                    </td>

                    {/* Contact */}
                    <td className="py-4 px-4 space-y-0.5 text-muted-foreground">
                      <p className="flex items-center gap-1 font-english"><Mail className="w-3.5 h-3.5" /> {c.email}</p>
                      <p className="flex items-center gap-1 font-english"><Phone className="w-3.5 h-3.5" /> {c.phone}</p>
                    </td>

                    {/* Total Debt */}
                    <td className="py-4 px-4 font-english text-foreground font-bold text-sm">
                      {c.total_debt.toLocaleString()} <span className="text-[10px] font-normal text-muted-foreground">{isAr ? 'ر.س' : 'SAR'}</span>
                    </td>

                    {/* Paid */}
                    <td className="py-4 px-4 font-english text-green-600 font-semibold text-sm">
                      {c.paid_amount.toLocaleString()} <span className="text-[10px] font-normal text-muted-foreground">{isAr ? 'ر.س' : 'SAR'}</span>
                    </td>

                    {/* Debt Count */}
                    <td className="py-4 px-4 text-center sm:text-start">
                      <span className="bg-muted px-2 py-0.5 rounded-lg font-english text-foreground font-semibold">
                        {c.debts_count}
                      </span>
                    </td>

                    {/* Active */}
                    <td className="py-4 px-4">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-full font-bold text-[9px] uppercase
                        ${c.is_active ? 'bg-green-500/10 text-green-600' : 'bg-red-500/10 text-red-600'}
                      `}>
                        {c.is_active ? (isAr ? 'نشط' : 'Active') : (isAr ? 'معلق' : 'Inactive')}
                      </span>
                    </td>

                    {/* Date */}
                    <td className="py-4 px-4 text-muted-foreground font-english">{c.created_at}</td>

                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Create Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/50 backdrop-blur-xs" onClick={() => setShowCreateModal(false)} />
          
          <div className="bg-card text-foreground rounded-2xl w-full max-w-md p-6 border border-border relative z-10 slide-up shadow-2xl">
            <h3 className="text-xl font-bold mb-4">{isAr ? 'إضافة عميل جديد للنظام' : 'Create New Customer'}</h3>
            
            <form onSubmit={handleSubmit(handleCreate)} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'اسم العميل الكامل' : 'Full Name'}</label>
                <input
                  type="text"
                  required
                  {...register('name')}
                  placeholder={isAr ? 'أحمد بن عبد الله' : 'Ahmad Bin Abdullah'}
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
                  placeholder="customer@sidad.co"
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
                {errors.email && <p className="text-xs text-destructive mt-1">{errors.email.message}</p>}
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'رقم الهاتف' : 'Phone Number'}</label>
                <input
                  type="text"
                  required
                  {...register('phone')}
                  placeholder="+966 50 123 4567"
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
                {errors.phone && <p className="text-xs text-destructive mt-1">{errors.phone.message}</p>}
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
                    isAr ? 'إضافة عميل' : 'Add Customer'
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
