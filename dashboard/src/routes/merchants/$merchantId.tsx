import { createFileRoute, useParams } from '@tanstack/react-router'
import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../../lib/api'
import type { Merchant, Customer, Debt, Payment } from '../../lib/api'
import { useApp } from '../../components/AppContext'
import {
  Building,
  Mail,
  Phone,
  Calendar,
  Layers,
  ArrowRight,
  TrendingUp,
  Users,
  Receipt,
  CreditCard,
  Laptop,
  Smartphone,
  History,
  Info,
  CheckCircle,
  AlertTriangle,
  UserCheck,
} from 'lucide-react'

export const Route = createFileRoute('/merchants/$merchantId')({
  component: MerchantDetailsPage,
})

function MerchantDetailsPage() {
  const { merchantId } = useParams({ from: '/merchants/$merchantId' })
  const { lang, dir } = useApp()
  const isAr = lang === 'ar'
  const queryClient = useQueryClient()
  const [activeTab, setActiveTab] = useState<'overview' | 'customers' | 'debts' | 'payments' | 'subscription' | 'activity' | 'devices'>('overview')

  // Fetch all merchants to filter for this single merchant
  const { data: merchants = [], isLoading } = useQuery({
    queryKey: ['merchants'],
    queryFn: () => api.getMerchants(),
  })

  const { data: customers = [] } = useQuery({
    queryKey: ['customers'],
    queryFn: () => api.getCustomers(),
  })

  const { data: debts = [] } = useQuery({
    queryKey: ['debts'],
    queryFn: () => api.getDebts(),
  })

  const { data: payments = [] } = useQuery({
    queryKey: ['payments'],
    queryFn: () => api.getPayments(),
  })

  const merchant = merchants.find((m) => m.id === merchantId)

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Merchant> }) => api.updateMerchant(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['merchants'] })
    }
  })

  if (isLoading) {
    return <div className="p-8 text-center animate-pulse">{isAr ? 'جاري تحميل تفاصيل التاجر...' : 'Loading merchant details...'}</div>
  }

  if (!merchant) {
    return (
      <div className="p-8 text-center text-destructive">
        <AlertTriangle className="w-12 h-12 mx-auto mb-4" />
        <h3 className="font-bold text-lg">{isAr ? 'التاجر غير موجود' : 'Merchant Not Found'}</h3>
        <p className="text-xs text-muted-foreground mt-1">{isAr ? 'رقم التاجر المطلوب غير مسجل في النظام.' : 'The requested merchant ID does not exist.'}</p>
      </div>
    )
  }

  // Fetch data subsets for this specific merchant
  const allCustomers = customers.filter((c) => c.merchant_id === merchant.id)
  const allDebts = debts.filter((d) => d.merchant_id === merchant.id)
  const allPayments = payments.filter((p) => p.merchant_id === merchant.id)

  const totalOutstanding = allDebts.reduce((sum: number, d: Debt) => sum + d.remaining_amount, 0)
  const totalSettled = allDebts.reduce((sum: number, d: Debt) => sum + d.paid_amount, 0)

  return (
    <div className="space-y-6">
      
      {/* Back Button */}
      <div>
        <a
          href="/merchants"
          className="inline-flex items-center gap-2 text-xs font-bold text-muted-foreground hover:text-foreground transition-all duration-200"
        >
          <ArrowRight className={`w-4 h-4 ${dir === 'rtl' ? '' : 'rotate-180'}`} />
          <span>{isAr ? 'العودة لقائمة التجار' : 'Back to Merchants'}</span>
        </a>
      </div>

      {/* Brand Header Card */}
      <div className="premium-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div className="flex items-center gap-4">
          <span className="text-4xl w-16 h-16 rounded-2xl bg-indigo-50/50 flex items-center justify-center border border-border">
            {merchant.logo || '🏢'}
          </span>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-xl font-bold text-foreground">{merchant.name}</h2>
              <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold uppercase
                ${merchant.status === 'active' ? 'bg-green-500/10 text-green-600' : 'bg-red-500/10 text-red-600'}
              `}>
                {merchant.status === 'active' ? (isAr ? 'نشط' : 'Active') : (isAr ? 'معطل' : 'Inactive')}
              </span>
            </div>
            <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground mt-1.5 font-english">
              <span className="flex items-center gap-1"><Mail className="w-3.5 h-3.5" /> {merchant.email}</span>
              <span className="flex items-center gap-1"><Phone className="w-3.5 h-3.5" /> {merchant.phone}</span>
              <span className="flex items-center gap-1"><Calendar className="w-3.5 h-3.5" /> {merchant.created_at}</span>
            </div>
          </div>
        </div>

        {/* Dynamic Action Buttons */}
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <button
            onClick={() => updateMutation.mutate({ id: merchant.id, data: { status: merchant.status === 'active' ? 'suspended' : 'active' } })}
            className={`flex-1 sm:flex-none px-4 py-2 rounded-xl text-xs font-bold transition duration-200 cursor-pointer
              ${merchant.status === 'active' ? 'bg-amber-500/10 hover:bg-amber-500/20 text-amber-600 border border-amber-500/20' : 'bg-green-500/10 hover:bg-green-500/20 text-green-600 border border-green-500/20'}
            `}
          >
            {merchant.status === 'active' ? (isAr ? 'تعليق الحساب' : 'Suspend Account') : (isAr ? 'تنشيط الحساب' : 'Activate Account')}
          </button>
        </div>
      </div>

      {/* Tabs Switcher */}
      <div className="border-b border-border flex items-center gap-2 overflow-x-auto pb-px">
        {[
          { id: 'overview', labelAr: 'نظرة عامة', labelEn: 'Overview' },
          { id: 'customers', labelAr: 'العملاء', labelEn: 'Customers' },
          { id: 'debts', labelAr: 'الديون', labelEn: 'Debts' },
          { id: 'payments', labelAr: 'المدفوعات', labelEn: 'Payments' },
          { id: 'subscription', labelAr: 'الاشتراك والفوترة', labelEn: 'Subscription' },
          { id: 'activity', labelAr: 'سجل العمليات', labelEn: 'Activity Log' },
          { id: 'devices', labelAr: 'الأجهزة المتصلة', labelEn: 'Devices' },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`px-4 py-3 text-xs font-semibold border-b-2 whitespace-nowrap transition duration-200 cursor-pointer
              ${activeTab === tab.id ? 'border-primary text-primary font-bold' : 'border-transparent text-muted-foreground hover:text-foreground'}
            `}
          >
            {isAr ? tab.labelAr : tab.labelEn}
          </button>
        ))}
      </div>

      {/* Tab Panels */}
      <div className="slide-up">
        
        {/* OVERVIEW PANEL */}
        {activeTab === 'overview' && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
              
              {/* Stat Cards */}
              <div className="premium-card p-5">
                <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'إجمالي العملاء' : 'Total Customers'}</span>
                <div className="flex items-center gap-3 mt-3">
                  <div className="p-2 rounded-xl bg-blue-500/10 text-blue-600"><Users className="w-5 h-5" /></div>
                  <h3 className="text-2xl font-extrabold font-english">{allCustomers.length}</h3>
                </div>
              </div>

              <div className="premium-card p-5">
                <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'إجمالي الديون المسجلة' : 'Total Debts'}</span>
                <div className="flex items-center gap-3 mt-3">
                  <div className="p-2 rounded-xl bg-indigo-500/10 text-indigo-600"><Receipt className="w-5 h-5" /></div>
                  <h3 className="text-xl font-extrabold font-english">{ (totalOutstanding + totalSettled).toLocaleString() } <span className="text-xs font-normal">SAR</span></h3>
                </div>
              </div>

              <div className="premium-card p-5">
                <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'المبالغ المحصلة' : 'Collected Payments'}</span>
                <div className="flex items-center gap-3 mt-3">
                  <div className="p-2 rounded-xl bg-green-500/10 text-green-600"><CreditCard className="w-5 h-5" /></div>
                  <h3 className="text-xl font-extrabold font-english">{ totalSettled.toLocaleString() } <span className="text-xs font-normal">SAR</span></h3>
                </div>
              </div>

              <div className="premium-card p-5">
                <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'المبالغ المستحقة المتبقية' : 'Outstanding Debts'}</span>
                <div className="flex items-center gap-3 mt-3">
                  <div className="p-2 rounded-xl bg-orange-500/10 text-orange-600"><AlertTriangle className="w-5 h-5" /></div>
                  <h3 className="text-xl font-extrabold font-english">{ totalOutstanding.toLocaleString() } <span className="text-xs font-normal">SAR</span></h3>
                </div>
              </div>

            </div>

            <div className="premium-card p-6">
              <h4 className="text-sm font-bold mb-4 flex items-center gap-2"><Info className="w-4.5 h-4.5 text-primary" /> {isAr ? 'تفاصيل التاجر العامة' : 'General Merchant Details'}</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 text-xs border-t border-border/40 pt-4">
                <div>
                  <span className="text-muted-foreground block mb-1">{isAr ? 'باقة الاشتراك الحالية' : 'Current Subscription Plan'}</span>
                  <span className="font-bold text-foreground font-english text-sm">{merchant.plan}</span>
                </div>
                <div>
                  <span className="text-muted-foreground block mb-1">{isAr ? 'نوع الفوترة' : 'Billing Cycle'}</span>
                  <span className="font-bold text-foreground font-english text-sm uppercase">{merchant.subscription}</span>
                </div>
                <div>
                  <span className="text-muted-foreground block mb-1">{isAr ? 'المدة المتبقية للاشتراك' : 'Remaining Days'}</span>
                  <span className="font-bold text-foreground font-english text-sm">{merchant.remaining_days} {isAr ? 'يوم' : 'days'}</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* CUSTOMERS PANEL */}
        {activeTab === 'customers' && (
          <div className="premium-card p-6">
            <h4 className="text-sm font-bold mb-4">{isAr ? 'العملاء المسجلون للتاجر' : 'Customers Directory'}</h4>
            {allCustomers.length === 0 ? (
              <p className="text-muted-foreground text-center text-xs py-6">{isAr ? 'لا يوجد عملاء مسجلين لهذا التاجر.' : 'No customers registered.'}</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-xs text-start">
                  <thead>
                    <tr className="border-b border-border text-muted-foreground font-semibold">
                      <th className="py-3 px-2 text-start">{isAr ? 'الاسم' : 'Name'}</th>
                      <th className="py-3 px-2 text-start">{isAr ? 'الهاتف' : 'Phone'}</th>
                      <th className="py-3 px-2 text-start">{isAr ? 'الديون' : 'Debts'}</th>
                      <th className="py-3 px-2 text-start">{isAr ? 'الحالة' : 'Status'}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border/40 font-medium">
                    {allCustomers.map((c) => (
                      <tr key={c.id} className="hover:bg-muted/30">
                        <td className="py-3 px-2 font-bold">{c.name}</td>
                        <td className="py-3 px-2 font-english text-muted-foreground">{c.phone}</td>
                        <td className="py-3 px-2 font-english">{c.total_debt.toLocaleString()} ر.س</td>
                        <td className="py-3 px-2">
                          <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-bold uppercase
                            ${c.is_active ? 'bg-green-500/10 text-green-600' : 'bg-muted text-muted-foreground'}
                          `}>
                            {c.is_active ? (isAr ? 'نشط' : 'Active') : (isAr ? 'غير نشط' : 'Inactive')}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* DEBTS PANEL */}
        {activeTab === 'debts' && (
          <div className="premium-card p-6">
            <h4 className="text-sm font-bold mb-4">{isAr ? 'الديون المسجلة والأقساط' : 'Registered Debts & Installments'}</h4>
            {allDebts.length === 0 ? (
              <p className="text-muted-foreground text-center text-xs py-6">{isAr ? 'لا يوجد ديون مسجلة.' : 'No debts registered.'}</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-xs text-start">
                  <thead>
                    <tr className="border-b border-border text-muted-foreground font-semibold">
                      <th className="py-3 px-2 text-start">{isAr ? 'العميل' : 'Customer'}</th>
                      <th className="py-3 px-2 text-start">{isAr ? 'إجمالي المبلغ' : 'Total Amount'}</th>
                      <th className="py-3 px-2 text-start">{isAr ? 'المبلغ المحصل' : 'Collected'}</th>
                      <th className="py-3 px-2 text-start">{isAr ? 'المبلغ المتبقي' : 'Outstanding'}</th>
                      <th className="py-3 px-2 text-start">{isAr ? 'الحالة' : 'Status'}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border/40 font-medium">
                    {allDebts.map((d) => (
                      <tr key={d.id} className="hover:bg-muted/30">
                        <td className="py-3 px-2 font-bold">{d.customer?.name}</td>
                        <td className="py-3 px-2 font-english">{d.total_amount.toLocaleString()} ر.س</td>
                        <td className="py-3 px-2 font-english text-green-600">{d.paid_amount.toLocaleString()} ر.س</td>
                        <td className="py-3 px-2 font-english text-orange-500">{d.remaining_amount.toLocaleString()} ر.س</td>
                        <td className="py-3 px-2">
                          <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-bold uppercase
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
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* PAYMENTS PANEL */}
        {activeTab === 'payments' && (
          <div className="premium-card p-6">
            <h4 className="text-sm font-bold mb-4">{isAr ? 'عمليات الدفع المستلمة' : 'Payments Received'}</h4>
            {allPayments.length === 0 ? (
              <p className="text-muted-foreground text-center text-xs py-6">{isAr ? 'لا يوجد مدفوعات مسجلة.' : 'No payments found.'}</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-xs text-start">
                  <thead>
                    <tr className="border-b border-border text-muted-foreground font-semibold">
                      <th className="py-3 px-2 text-start">{isAr ? 'العملية' : 'Transaction Ref'}</th>
                      <th className="py-3 px-2 text-start">{isAr ? 'المبلغ' : 'Amount'}</th>
                      <th className="py-3 px-2 text-start">{isAr ? 'وسيلة الدفع' : 'Payment Method'}</th>
                      <th className="py-3 px-2 text-start">{isAr ? 'التاريخ' : 'Date'}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border/40 font-medium">
                    {allPayments.map((p) => (
                      <tr key={p.id} className="hover:bg-muted/30">
                        <td className="py-3 px-2 font-english font-bold text-foreground">{p.reference}</td>
                        <td className="py-3 px-2 font-english">{p.amount.toLocaleString()} ر.س</td>
                        <td className="py-3 px-2 font-english uppercase text-muted-foreground">{p.method}</td>
                        <td className="py-3 px-2 font-english text-muted-foreground">{p.created_at.split('T')[0]}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* SUBSCRIPTION PANEL */}
        {activeTab === 'subscription' && (
          <div className="premium-card p-6 space-y-6">
            <div className="flex justify-between items-center">
              <div>
                <h4 className="text-sm font-bold">{isAr ? 'تفاصيل الاشتراك والفوترة' : 'Billing & Subscriptions'}</h4>
                <p className="text-xs text-muted-foreground mt-1">{isAr ? 'تفاصيل الخطة السعرية والمحاسبة للتاجر' : 'Inspect package quotas and billing renewal date.'}</p>
              </div>
              <span className="text-xs bg-indigo-500/10 text-primary border border-indigo-500/20 px-3 py-1.5 rounded-xl font-bold font-english">
                {merchant.plan} Package
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 border-t border-border/40 pt-4 text-xs font-semibold">
              <div className="space-y-4">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">{isAr ? 'الحالة الحالية للاشتراك' : 'Subscription Status'}</span>
                  <span className="text-green-600 dark:text-green-400 uppercase font-bold">{merchant.status}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">{isAr ? 'تاريخ التسجيل بالمنصة' : 'Registration Date'}</span>
                  <span className="font-english text-foreground">{merchant.created_at}</span>
                </div>
              </div>

              <div className="space-y-4">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">{isAr ? 'المدة المتبقية للتجديد' : 'Days Until Expiry'}</span>
                  <span className="font-english text-foreground text-sm font-extrabold">{merchant.remaining_days} {isAr ? 'أيام' : 'days'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">{isAr ? 'دورة الفوترة الحالية' : 'Renewal Term'}</span>
                  <span className="text-foreground uppercase font-english">{merchant.subscription}</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ACTIVITY TIMELINE PANEL */}
        {activeTab === 'activity' && (
          <div className="premium-card p-6">
            <h4 className="text-sm font-bold mb-6">{isAr ? 'سجل الأنشطة والعمليات التاريخية للتاجر' : 'Activity Timeline'}</h4>
            <div className="relative border-s-2 border-border/60 ms-3 space-y-8 pb-4 text-xs">
              
              <div className="relative ps-6">
                <div className="absolute -start-2 top-0.5 w-3.5 h-3.5 rounded-full bg-primary border-4 border-card" />
                <time className="font-english text-muted-foreground block mb-1">2026-06-26 02:15</time>
                <p className="font-semibold text-foreground">{isAr ? 'تعديل تفاصيل باقة الاشتراك بنجاح من قبل مدير النظام' : 'Subscription package updated successfully by admin.'}</p>
              </div>

              <div className="relative ps-6">
                <div className="absolute -start-2 top-0.5 w-3.5 h-3.5 rounded-full bg-emerald-500 border-4 border-card" />
                <time className="font-english text-muted-foreground block mb-1">2026-06-25 12:00</time>
                <p className="font-semibold text-foreground">{isAr ? 'استلام دفعة مالية بقيمة 3,200 ر.س بنجاح' : 'Payment of 3,200 SAR successfully received.'}</p>
              </div>

              <div className="relative ps-6">
                <div className="absolute -start-2 top-0.5 w-3.5 h-3.5 rounded-full bg-indigo-600 border-4 border-card" />
                <time className="font-english text-muted-foreground block mb-1">2024-06-16 09:00</time>
                <p className="font-semibold text-foreground">{isAr ? 'تسجيل الحساب وتفعيل الباقة المتقدمة (Premium)' : 'Account registered and Premium subscription activated.'}</p>
              </div>

            </div>
          </div>
        )}

        {/* DEVICES PANEL */}
        {activeTab === 'devices' && (
          <div className="premium-card p-6">
            <h4 className="text-sm font-bold mb-4">{isAr ? 'الأجهزة النشطة المستخدمة للدخول' : 'Active Connected Devices'}</h4>
            <div className="divide-y divide-border/40 text-xs">
              
              <div className="py-4 flex justify-between items-center">
                <div className="flex items-center gap-3">
                  <Laptop className="w-8 h-8 text-muted-foreground" />
                  <div>
                    <p className="font-bold text-foreground">Chrome 122.0 / Windows 11</p>
                    <span className="font-english text-[10px] text-muted-foreground">IP: 192.168.1.1 — {isAr ? 'الرياض، السعودية' : 'Riyadh, SA'}</span>
                  </div>
                </div>
                <span className="text-[10px] bg-green-500/10 text-green-600 font-bold px-2 py-0.5 rounded-full uppercase">
                  {isAr ? 'نشط الآن' : 'Active Now'}
                </span>
              </div>

              <div className="py-4 flex justify-between items-center">
                <div className="flex items-center gap-3">
                  <Smartphone className="w-8 h-8 text-muted-foreground" />
                  <div>
                    <p className="font-bold text-foreground">Safari Mobile / iPhone 15 Pro</p>
                    <span className="font-english text-[10px] text-muted-foreground">IP: 176.44.20.12 — {isAr ? 'جدة، السعودية' : 'Jeddah, SA'}</span>
                  </div>
                </div>
                <span className="text-[10px] bg-muted text-muted-foreground font-bold px-2 py-0.5 rounded-full uppercase">
                  {isAr ? 'قبل يومين' : '2 days ago'}
                </span>
              </div>

            </div>
          </div>
        )}

      </div>

    </div>
  )
}
