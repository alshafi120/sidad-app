import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { Merchant } from '../lib/api'
import { useApp } from '../components/AppContext'
import {
  CalendarCheck,
  Search,
  CheckCircle,
  AlertTriangle,
  XCircle,
  TrendingUp,
  CreditCard,
  History,
} from 'lucide-react'

export const Route = createFileRoute('/subscriptions')({
  component: SubscriptionsPage,
})

function SubscriptionsPage() {
  const { lang, dir } = useApp()
  const isAr = lang === 'ar'
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  const { data: merchants = [], isLoading } = useQuery({
    queryKey: ['merchants'],
    queryFn: () => api.getMerchants(),
  })

  // Filter subscriptions
  const filteredSubscriptions = merchants.filter((m) => {
    const matchesSearch = m.name.toLowerCase().includes(searchTerm.toLowerCase()) || m.email.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === 'all' || m.status === statusFilter
    return matchesSearch && matchesStatus
  })

  // Calculations
  const activeCount = merchants.filter((m) => m.status === 'active').length
  const expiredCount = merchants.filter((m) => m.status === 'expired').length
  const expiringSoonCount = merchants.filter((m) => m.status === 'active' && m.remaining_days <= 7).length

  return (
    <div className="space-y-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {isAr ? 'إدارة الاشتراكات والفوترة' : 'Subscriptions & Billing'}
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            {isAr ? 'مراقبة خطط اشتراك التجار وتواريخ التجديد والتحصيل التلقائي' : 'Review subscriber plans, auto-renewals, and expirations.'}
          </p>
        </div>
      </div>

      {/* Aggregate Counters */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
        
        <div className="premium-card p-6">
          <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'الاشتراكات النشطة' : 'Active Subscriptions'}</span>
          <div className="flex items-center gap-3 mt-3">
            <div className="p-2 rounded-xl bg-green-500/10 text-green-600">
              <CheckCircle className="w-5 h-5" />
            </div>
            <h3 className="text-2xl font-extrabold font-english">{activeCount}</h3>
          </div>
        </div>

        <div className="premium-card p-6">
          <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'الاشتراكات المنتهية' : 'Expired Subscriptions'}</span>
          <div className="flex items-center gap-3 mt-3">
            <div className="p-2 rounded-xl bg-red-500/10 text-red-600">
              <XCircle className="w-5 h-5" />
            </div>
            <h3 className="text-2xl font-extrabold font-english">{expiredCount}</h3>
          </div>
        </div>

        <div className="premium-card p-6">
          <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'تنتهي خلال 7 أيام' : 'Expiring Soon'}</span>
          <div className="flex items-center gap-3 mt-3">
            <div className="p-2 rounded-xl bg-orange-500/10 text-orange-600">
              <AlertTriangle className="w-5 h-5" />
            </div>
            <h3 className="text-2xl font-extrabold font-english">{expiringSoonCount}</h3>
          </div>
        </div>

      </div>

      {/* Toolbar */}
      <div className="premium-card p-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="w-4.5 h-4.5 text-muted-foreground absolute start-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder={isAr ? 'البحث عن اشتراك تاجر...' : 'Search subscription...'}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full ps-9 pe-4 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
          />
        </div>

        {/* Filters */}
        <div className="flex items-center gap-3">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 text-xs font-semibold rounded-xl border border-border bg-card text-foreground focus:outline-none"
          >
            <option value="all">{isAr ? 'كل الاشتراكات' : 'All Subscriptions'}</option>
            <option value="active">{isAr ? 'نشط' : 'Active Only'}</option>
            <option value="expired">{isAr ? 'منتهي' : 'Expired Only'}</option>
          </select>
        </div>

      </div>

      {/* Table */}
      <div className="premium-card overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center animate-pulse space-y-4">
            <div className="h-8 bg-muted rounded w-full" />
            <div className="h-8 bg-muted rounded w-full" />
          </div>
        ) : filteredSubscriptions.length === 0 ? (
          <div className="p-12 text-center text-muted-foreground">
            <CalendarCheck className="w-16 h-16 mx-auto text-muted-foreground/30 mb-4" />
            <p className="font-bold">{isAr ? 'لا يوجد اشتراكات مطابقة للمرشح' : 'No subscriptions found'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs text-start border-collapse">
              <thead>
                <tr className="border-b border-border bg-muted/30 text-muted-foreground font-semibold uppercase">
                  <th className="py-4 px-4 text-start">{isAr ? 'التاجر' : 'Merchant'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'الباقة الحالية' : 'Current Plan'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'نوع التجديد' : 'Cycle'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'المدة المتبقية' : 'Days Left'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'التجديد التلقائي' : 'Auto Renew'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'الحالة' : 'Status'}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40 font-medium">
                {filteredSubscriptions.map((m) => (
                  <tr key={m.id} className="hover:bg-muted/30 transition">
                    
                    {/* Brand */}
                    <td className="py-4 px-4 flex items-center gap-3">
                      <span className="text-xl w-8 h-8 rounded-lg bg-indigo-50/50 flex items-center justify-center border border-border">
                        {m.logo}
                      </span>
                      <div>
                        <p className="font-bold text-foreground text-sm">{m.name}</p>
                        <p className="text-[10px] text-muted-foreground font-english">{m.email}</p>
                      </div>
                    </td>

                    {/* Plan */}
                    <td className="py-4 px-4 font-english text-foreground font-bold">{m.plan}</td>

                    {/* Cycle */}
                    <td className="py-4 px-4 font-english uppercase text-muted-foreground">{m.subscription}</td>

                    {/* Remaining */}
                    <td className="py-4 px-4">
                      <span className={`font-english font-bold text-sm block
                        ${m.remaining_days <= 7 ? 'text-destructive font-black' : 'text-foreground'}
                      `}>
                        {m.remaining_days}
                      </span>
                      <span className="text-[10px] text-muted-foreground">{isAr ? 'أيام متبقية' : 'days left'}</span>
                    </td>

                    {/* Auto renew */}
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-1.5 text-green-600 dark:text-green-400 font-semibold">
                        <CheckCircle className="w-4 h-4" />
                        <span>{isAr ? 'نشط' : 'Enabled'}</span>
                      </div>
                    </td>

                    {/* Status */}
                    <td className="py-4 px-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full font-bold text-[9px] uppercase
                        ${m.status === 'active' ? 'bg-green-500/10 text-green-600' : ''}
                        ${m.status === 'expired' ? 'bg-red-500/10 text-red-600' : ''}
                        ${m.status === 'suspended' ? 'bg-amber-500/10 text-amber-600' : ''}
                      `}>
                        {m.status === 'active' ? (isAr ? 'نشط' : 'Active') : ''}
                        {m.status === 'expired' ? (isAr ? 'منتهي' : 'Expired') : ''}
                        {m.status === 'suspended' ? (isAr ? 'معلق' : 'Suspended') : ''}
                      </span>
                    </td>

                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

    </div>
  )
}
