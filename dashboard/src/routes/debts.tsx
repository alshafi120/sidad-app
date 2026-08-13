import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { Debt, Customer } from '../lib/api'
import { useApp } from '../components/AppContext'
import {
  Search,
  Plus,
  Receipt,
  CheckCircle,
  XCircle,
  Clock,
  Check,
  AlertTriangle,
  User,
  Calculator,
  Calendar,
} from 'lucide-react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as zod from 'zod'

export const Route = createFileRoute('/debts')({
  component: DebtsPage,
})

// Validation Schema for Debt creation
const debtSchema = zod.object({
  customer_id: zod.string().min(1, 'يجب اختيار عميل / Customer is required'),
  total_amount: zod.number().min(1, 'يجب أن يكون المبلغ أكبر من 0 / Amount must be greater than 0'),
  installments_count: zod.number().min(1, 'يجب أن يكون عدد الأقساط 1 على الأقل / Installments must be at least 1'),
})

type DebtFormValues = zod.infer<typeof debtSchema>

function DebtsPage() {
  const { lang, dir } = useApp()
  const isAr = lang === 'ar'
  const queryClient = useQueryClient()
  
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [showPayModal, setShowPayModal] = useState<Debt | null>(null)
  const [payAmount, setPayAmount] = useState<number>(0)
  const [payMethod, setPayMethod] = useState<'mada' | 'visa' | 'bank_transfer' | 'apple_pay'>('mada')

  const { register, handleSubmit, reset, setValue, formState: { errors } } = useForm<DebtFormValues>({
    resolver: zodResolver(debtSchema),
    defaultValues: {
      customer_id: '',
      total_amount: 0,
      installments_count: 1,
    }
  })

  // Queries
  const { data: debts = [], isLoading } = useQuery({
    queryKey: ['debts', statusFilter],
    queryFn: () => api.getDebts({
      status: statusFilter === 'all' ? undefined : statusFilter
    }),
  })

  const { data: customers = [] } = useQuery({
    queryKey: ['customers'],
    queryFn: () => api.getCustomers(),
  })

  // Mutations
  const createMutation = useMutation({
    mutationFn: (newDebt: Partial<Debt>) => api.createDebt(newDebt),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['debts'] })
      queryClient.invalidateQueries({ queryKey: ['customers'] })
      setShowCreateModal(false)
      reset()
    }
  })

  const approveMutation = useMutation({
    mutationFn: (id: string) => api.approveDebt(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['debts'] })
    }
  })

  const rejectMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) => api.rejectDebt(id, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['debts'] })
    }
  })

  const payMutation = useMutation({
    mutationFn: ({ debtId, amount, method }: { debtId: string; amount: number; method: any }) =>
      api.createPayment({ debt_id: debtId, amount, method }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['debts'] })
      queryClient.invalidateQueries({ queryKey: ['customers'] })
      setShowPayModal(null)
      setPayAmount(0)
    }
  })

  const handleCreate = (values: DebtFormValues) => {
    createMutation.mutate({
      customer_id: values.customer_id,
      total_amount: values.total_amount,
      installments_count: values.installments_count,
      merchant_id: 'm1',
    })
  }

  const handlePay = () => {
    if (!showPayModal) return
    payMutation.mutate({
      debtId: showPayModal.id,
      amount: payAmount,
      method: payMethod,
    })
  }

  // Calculations
  const pendingDebts = debts.filter((d) => d.status === 'pending')
  const approvedDebts = debts.filter((d) => d.status === 'approved' || d.status === 'settled')

  const totalOutstanding = approvedDebts.reduce((sum, d) => sum + d.remaining_amount, 0)
  const totalSettled = approvedDebts.reduce((sum, d) => sum + d.paid_amount, 0)
  const totalDebtsAmount = totalOutstanding + totalSettled

  // Filters for client-side search
  const filteredDebts = debts.filter((d) => {
    const custName = d.customer?.name || ''
    const matchesSearch = custName.toLowerCase().includes(searchTerm.toLowerCase())
    return matchesSearch
  })

  return (
    <div className="space-y-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {isAr ? 'إدارة الديون والتحصيل' : 'Debts & Collection'}
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            {isAr ? 'تسجيل الديون الجديدة واعتمادها ومتابعة تحصيل الأقساط' : 'Record and approve customer debts, track collection rates.'}
          </p>
        </div>

        <button
          onClick={() => setShowCreateModal(true)}
          className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-primary-foreground font-semibold hover:opacity-95 transition duration-200 cursor-pointer shadow-lg shadow-primary/10 text-sm"
        >
          <Plus className="w-5 h-5" />
          <span>{isAr ? 'تسجيل دين جديد' : 'Record New Debt'}</span>
        </button>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
        
        {/* Outstanding Balance */}
        <div className="premium-card p-6">
          <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'إجمالي الديون القائمة المستحقة' : 'Outstanding Debts'}</span>
          <div className="flex items-center gap-3 mt-3">
            <div className="p-2 rounded-xl bg-orange-500/10 text-orange-600">
              <Clock className="w-5 h-5" />
            </div>
            <h3 className="text-xl font-extrabold font-english">
              {totalOutstanding.toLocaleString()} <span className="text-xs font-normal">{isAr ? 'ر.س' : 'SAR'}</span>
            </h3>
          </div>
        </div>

        {/* Settled Balance */}
        <div className="premium-card p-6">
          <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'إجمالي المبالغ المدفوعة' : 'Collected Amount'}</span>
          <div className="flex items-center gap-3 mt-3">
            <div className="p-2 rounded-xl bg-emerald-500/10 text-emerald-600">
              <CheckCircle className="w-5 h-5" />
            </div>
            <h3 className="text-xl font-extrabold font-english">
              {totalSettled.toLocaleString()} <span className="text-xs font-normal">{isAr ? 'ر.س' : 'SAR'}</span>
            </h3>
          </div>
        </div>

        {/* Total Debts Registered */}
        <div className="premium-card p-6">
          <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'إجمالي الديون المسجلة المعتمدة' : 'Total Approved Debts'}</span>
          <div className="flex items-center gap-3 mt-3">
            <div className="p-2 rounded-xl bg-indigo-500/10 text-indigo-600">
              <Receipt className="w-5 h-5" />
            </div>
            <h3 className="text-xl font-extrabold font-english">
              {totalDebtsAmount.toLocaleString()} <span className="text-xs font-normal">{isAr ? 'ر.س' : 'SAR'}</span>
            </h3>
          </div>
        </div>

      </div>

      {/* Filters Toolbar */}
      <div className="premium-card p-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="w-4.5 h-4.5 text-muted-foreground absolute start-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder={isAr ? 'البحث باسم العميل المدين...' : 'Search by customer name...'}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full ps-9 pe-4 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
          />
        </div>

        {/* Status filters */}
        <div className="flex items-center gap-3 self-end md:self-auto">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 text-xs font-semibold rounded-xl border border-border bg-card text-foreground focus:outline-none"
          >
            <option value="all">{isAr ? 'كل الحالات' : 'All Statuses'}</option>
            <option value="pending">{isAr ? 'قيد المراجعة' : 'Pending Approval'}</option>
            <option value="approved">{isAr ? 'معتمد' : 'Approved'}</option>
            <option value="settled">{isAr ? 'مسترد بالكامل' : 'Settled'}</option>
            <option value="rejected">{isAr ? 'مرفوض' : 'Rejected'}</option>
          </select>
        </div>

      </div>

      {/* Table Registry */}
      <div className="premium-card overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center animate-pulse space-y-4">
            <div className="h-8 bg-muted rounded w-full" />
            <div className="h-8 bg-muted rounded w-full" />
          </div>
        ) : filteredDebts.length === 0 ? (
          <div className="p-12 text-center text-muted-foreground">
            <Receipt className="w-16 h-16 mx-auto text-muted-foreground/30 mb-4" />
            <p className="font-bold">{isAr ? 'لا يوجد ديون مطابقة للحالة' : 'No debts found'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs text-start border-collapse">
              <thead>
                <tr className="border-b border-border bg-muted/30 text-muted-foreground font-semibold uppercase">
                  <th className="py-4 px-4 text-start">{isAr ? 'العميل' : 'Customer'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'قيمة الدين' : 'Debt Value'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'المسدد' : 'Settled'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'المتبقي المستحق' : 'Outstanding'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'الأقساط' : 'Installments'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'الحالة' : 'Status'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'التاريخ' : 'Date'}</th>
                  <th className="py-4 px-4 text-center">{isAr ? 'الإجراءات' : 'Actions'}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40 font-medium">
                {filteredDebts.map((d) => (
                  <tr key={d.id} className="hover:bg-muted/30 transition">
                    
                    {/* Customer */}
                    <td className="py-4 px-4 flex items-center gap-2">
                      <div className="w-8 h-8 rounded-lg bg-orange-50/50 border border-orange-200/40 text-orange-600 flex items-center justify-center font-bold">
                        <User className="w-4 h-4" />
                      </div>
                      <div>
                        <p className="font-bold text-foreground text-sm">{d.customer?.name || (isAr ? 'عميل مجهول' : 'Unknown Customer')}</p>
                        <p className="text-[10px] text-muted-foreground font-english">{d.customer?.phone}</p>
                      </div>
                    </td>

                    {/* Total Amount */}
                    <td className="py-4 px-4 font-english text-foreground font-bold text-sm">
                      {d.total_amount.toLocaleString()} <span className="text-[10px] font-normal text-muted-foreground">{isAr ? 'ر.س' : 'SAR'}</span>
                    </td>

                    {/* Paid */}
                    <td className="py-4 px-4 font-english text-green-600 font-semibold">
                      {d.paid_amount.toLocaleString()} <span className="text-[10px] font-normal text-muted-foreground">{isAr ? 'ر.س' : 'SAR'}</span>
                    </td>

                    {/* Remaining */}
                    <td className="py-4 px-4 font-english text-orange-500 font-semibold">
                      {d.remaining_amount.toLocaleString()} <span className="text-[10px] font-normal text-muted-foreground">{isAr ? 'ر.س' : 'SAR'}</span>
                    </td>

                    {/* Installments */}
                    <td className="py-4 px-4 font-english text-muted-foreground">
                      <span className="font-bold text-foreground">{d.installments_count}</span> {isAr ? 'أقساط' : 'installments'}
                    </td>

                    {/* Status badge */}
                    <td className="py-4 px-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full font-bold text-[9px] uppercase
                        ${d.status === 'settled' ? 'bg-green-500/10 text-green-600' : ''}
                        ${d.status === 'approved' ? 'bg-blue-500/10 text-blue-600' : ''}
                        ${d.status === 'pending' ? 'bg-amber-500/10 text-amber-600' : ''}
                        ${d.status === 'rejected' ? 'bg-red-500/10 text-red-600' : ''}
                      `}>
                        {d.status === 'settled' && (isAr ? 'مسترد كامل' : 'Settled')}
                        {d.status === 'approved' && (isAr ? 'معتمد' : 'Approved')}
                        {d.status === 'pending' && (isAr ? 'قيد المراجعة' : 'Pending')}
                        {d.status === 'rejected' && (isAr ? 'مرفوض' : 'Rejected')}
                      </span>
                    </td>

                    {/* Date */}
                    <td className="py-4 px-4 text-muted-foreground font-english">{d.created_at.split('T')[0]}</td>

                    {/* Actions */}
                    <td className="py-4 px-4 text-center">
                      <div className="flex items-center justify-center gap-1.5">
                        
                        {/* Pending approvals */}
                        {d.status === 'pending' && (
                          <>
                            <button
                              onClick={() => approveMutation.mutate(d.id)}
                              className="p-1 rounded bg-green-500/10 text-green-600 hover:bg-green-500/20 transition cursor-pointer"
                              title={isAr ? 'اعتماد المديونية' : 'Approve'}
                            >
                              <Check className="w-4.5 h-4.5" />
                            </button>
                            <button
                              onClick={() => {
                                const reason = prompt(isAr ? 'سبب الرفض:' : 'Rejection Reason:')
                                if (reason) rejectMutation.mutate({ id: d.id, reason })
                              }}
                              className="p-1 rounded bg-red-500/10 text-red-600 hover:bg-red-500/20 transition cursor-pointer"
                              title={isAr ? 'رفض الطلب' : 'Reject'}
                            >
                              <XCircle className="w-4.5 h-4.5" />
                            </button>
                          </>
                        )}

                        {/* Approved paying */}
                        {d.status === 'approved' && (
                          <button
                            onClick={() => {
                              setShowPayModal(d)
                              setPayAmount(d.remaining_amount)
                            }}
                            className="px-3 py-1 rounded-lg border border-primary/20 bg-primary/5 text-primary hover:bg-primary/10 transition cursor-pointer font-bold"
                          >
                            {isAr ? 'تسجيل دفعة' : 'Pay Installment'}
                          </button>
                        )}

                        {(d.status === 'settled' || d.status === 'rejected') && (
                          <span className="text-[10px] text-muted-foreground font-semibold">
                            {d.status === 'settled' ? (isAr ? 'مكتمل' : 'Completed') : (isAr ? 'ملغى' : 'Cancelled')}
                          </span>
                        )}

                      </div>
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
          
          <div className="bg-card text-foreground rounded-2xl w-full max-w-md p-6 border border-border relative z-10 slide-up shadow-2xl">
            <h3 className="text-xl font-bold mb-4">{isAr ? 'تسجيل مديونية جديدة للعميل' : 'Record Customer Debt'}</h3>
            
            <form onSubmit={handleSubmit(handleCreate)} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'اختيار العميل المدين' : 'Select Customer'}</label>
                <select
                  required
                  {...register('customer_id')}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:outline-none"
                >
                  <option value="">{isAr ? '-- اختر العميل --' : '-- Select Customer --'}</option>
                  {customers.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name} ({c.phone})
                    </option>
                  ))}
                </select>
                {errors.customer_id && <p className="text-xs text-destructive mt-1">{errors.customer_id.message}</p>}
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'قيمة الدين (ر.س)' : 'Debt Principal Amount (SAR)'}</label>
                <input
                  type="number"
                  required
                  {...register('total_amount', { valueAsNumber: true })}
                  placeholder="2500"
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
                {errors.total_amount && <p className="text-xs text-destructive mt-1">{errors.total_amount.message}</p>}
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'عدد الأقساط المحددة' : 'Installments Allocation'}</label>
                <input
                  type="number"
                  required
                  {...register('installments_count', { valueAsNumber: true })}
                  placeholder="5"
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
                {errors.installments_count && <p className="text-xs text-destructive mt-1">{errors.installments_count.message}</p>}
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
                    isAr ? 'تسجيل وحفظ' : 'Register Debt'
                  )}
                </button>
              </div>

            </form>
          </div>
        </div>
      )}

      {/* Pay Installment Modal */}
      {showPayModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/50 backdrop-blur-xs" onClick={() => setShowPayModal(null)} />
          
          <div className="bg-card text-foreground rounded-2xl w-full max-w-md p-6 border border-border relative z-10 slide-up shadow-2xl">
            <h3 className="text-xl font-bold mb-2">{isAr ? 'تسجيل دفعة نقدية قسط' : 'Record Installment Payment'}</h3>
            <p className="text-xs text-muted-foreground mb-4">
              {isAr ? 'تسجيل عملية سداد دين للعميل:' : 'Record payments on behalf of:'} <span className="font-bold text-foreground">{showPayModal.customer?.name}</span>
            </p>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'مبلغ السداد القائم (ر.س)' : 'Outstanding Balance (SAR)'}</label>
                <div className="px-3 py-2 border border-border rounded-xl bg-muted/50 font-english font-bold">
                  {showPayModal.remaining_amount.toLocaleString()} ر.س
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'المبلغ المستلم للسداد' : 'Payment Amount'}</label>
                <input
                  type="number"
                  required
                  value={payAmount}
                  onChange={(e) => setPayAmount(Number(e.target.value))}
                  placeholder="500"
                  max={showPayModal.remaining_amount}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'طريقة السداد' : 'Payment Method'}</label>
                <select
                  value={payMethod}
                  onChange={(e: any) => setPayMethod(e.target.value)}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:outline-none"
                >
                  <option value="mada">مدى / mada</option>
                  <option value="apple_pay">Apple Pay</option>
                  <option value="visa">Visa / MasterCard</option>
                  <option value="bank_transfer">{isAr ? 'تحويل بنكي' : 'Bank Transfer'}</option>
                </select>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-border/60">
                <button
                  type="button"
                  onClick={() => setShowPayModal(null)}
                  className="px-4 py-2.5 rounded-xl border border-border bg-muted/10 font-bold text-sm cursor-pointer hover:bg-muted/20"
                >
                  {isAr ? 'إلغاء' : 'Cancel'}
                </button>
                <button
                  onClick={handlePay}
                  disabled={payMutation.isPending || payAmount <= 0 || payAmount > showPayModal.remaining_amount}
                  className="px-5 py-2.5 rounded-xl bg-primary text-primary-foreground font-bold text-sm cursor-pointer hover:opacity-95 shadow-md shadow-primary/10"
                >
                  {payMutation.isPending ? (
                    <span className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin block" />
                  ) : (
                    isAr ? 'سداد وتأكيد' : 'Confirm Payment'
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

    </div>
  )
}
