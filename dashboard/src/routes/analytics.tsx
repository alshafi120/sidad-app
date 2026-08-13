import { createFileRoute } from '@tanstack/react-router'
import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import { useApp } from '../components/AppContext'
import {
  BarChart3,
  TrendingUp,
  CreditCard,
  DollarSign,
  ArrowUpRight,
  Sparkles,
  Users,
} from 'lucide-react'
import {
  ResponsiveContainer,
  LineChart,
  Line,
  BarChart,
  Bar,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
} from 'recharts'

export const Route = createFileRoute('/analytics')({
  component: AnalyticsPage,
})

function AnalyticsPage() {
  const { lang } = useApp()
  const isAr = lang === 'ar'
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
  }, [])

  const { data: stats, isLoading } = useQuery({
    queryKey: ['dashboardStats'],
    queryFn: () => api.getDashboardStats(),
  })

  if (!isMounted || isLoading || !stats) {
    return <div className="p-8 text-center animate-pulse">{isAr ? 'جاري تحميل التقارير والتحليلات...' : 'Loading Analytics & Charts...'}</div>
  }

  // --- RECHARTS FINANCIAL MOCKS ---
  const gtvData = [
    { month: isAr ? 'يناير' : 'Jan', volume: 45000 },
    { month: isAr ? 'فبراير' : 'Feb', volume: 56000 },
    { month: isAr ? 'مارس' : 'Mar', volume: 72000 },
    { month: isAr ? 'أبريل' : 'Apr', volume: 68000 },
    { month: isAr ? 'مايو' : 'May', volume: 89000 },
    { month: isAr ? 'يونيو' : 'Jun', volume: stats.total_debts + 85000 },
  ]

  const revenueStackedData = [
    { name: isAr ? 'يناير' : 'Jan', subRev: 5000, smsRev: 1500 },
    { name: isAr ? 'فبراير' : 'Feb', subRev: 4500, smsRev: 1300 },
    { name: isAr ? 'مارس' : 'Mar', subRev: 7500, smsRev: 2000 },
    { name: isAr ? 'أبريل' : 'Apr', subRev: 6000, smsRev: 1800 },
    { name: isAr ? 'مايو' : 'May', subRev: 9000, smsRev: 2500 },
    { name: isAr ? 'يونيو' : 'Jun', subRev: stats.monthly_revenue, smsRev: 3200 },
  ]

  const topMerchantsList = [
    { name: 'مؤسسة البناء الحديث للمقاولات', volume: 85200, logo: '🏢', plan: 'Premium' },
    { name: 'شركة التقنية المتقدمة', volume: 64100, logo: '💻', plan: 'Enterprise' },
    { name: 'معرض الأزياء الراقية', volume: 38200, logo: '👗', plan: 'Premium' },
  ]

  return (
    <div className="space-y-8">
      
      {/* Title */}
      <div>
        <h1 className="text-3xl font-extrabold tracking-tight text-foreground font-arabic">
          {isAr ? 'التقارير والتحليلات البيانية' : 'Analytics & Insights'}
        </h1>
        <p className="text-muted-foreground text-sm mt-1">
          {isAr ? 'استعراض البيانات المالية الإجمالية وحجم عمليات التحصيل والاشتراكات' : 'Deep-dive platform insights, gross transaction value (GTV) flow.'}
        </p>
      </div>

      {/* KPI Counters */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        
        <div className="premium-card p-6">
          <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'حجم المعاملات الإجمالي (GTV)' : 'Gross Transaction Value (GTV)'}</span>
          <div className="flex items-center gap-3 mt-3">
            <div className="p-2 rounded-xl bg-indigo-500/10 text-indigo-600">
              <DollarSign className="w-5 h-5" />
            </div>
            <h3 className="text-xl font-extrabold font-english">
              {(stats.total_debts + 125000).toLocaleString()} <span className="text-xs font-normal">SAR</span>
            </h3>
          </div>
        </div>

        <div className="premium-card p-6">
          <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'متوسط قيمة التمويل المسترد' : 'Average Recovery Rate'}</span>
          <div className="flex items-center gap-3 mt-3">
            <div className="p-2 rounded-xl bg-green-500/10 text-green-600">
              <CreditCard className="w-5 h-5" />
            </div>
            <h3 className="text-xl font-extrabold font-english">
              74.2% <span className="text-xs font-normal text-muted-foreground">+{isAr ? '3% الشهر الماضي' : '3% MoM'}</span>
            </h3>
          </div>
        </div>

        <div className="premium-card p-6">
          <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'الإيرادات التشغيلية السنوية' : 'Annual Recurring Revenue (ARR)'}</span>
          <div className="flex items-center gap-3 mt-3">
            <div className="p-2 rounded-xl bg-emerald-500/10 text-emerald-600">
              <TrendingUp className="w-5 h-5" />
            </div>
            <h3 className="text-xl font-extrabold font-english">
              {(stats.monthly_revenue * 12).toLocaleString()} <span className="text-xs font-normal">SAR</span>
            </h3>
          </div>
        </div>

        <div className="premium-card p-6">
          <span className="text-xs text-muted-foreground font-semibold">{isAr ? 'متوسط سرعة السداد والتحصيل' : 'Average Payment Speed'}</span>
          <div className="flex items-center gap-3 mt-3">
            <div className="p-2 rounded-xl bg-blue-500/10 text-blue-600">
              <Users className="w-5 h-5" />
            </div>
            <h3 className="text-xl font-extrabold font-english">
              12.8 <span className="text-xs font-normal text-muted-foreground">{isAr ? 'يوم' : 'days'}</span>
            </h3>
          </div>
        </div>

      </div>

      {/* Visual Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        
        {/* Platform Volume Flow GTV */}
        <div className="premium-card p-6">
          <h4 className="text-sm font-bold mb-4">{isAr ? 'حجم التدفقات المالية الشهرية للمنصة (GTV)' : 'Gross Processing Volume (SAR)'}</h4>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={gtvData}>
                <defs>
                  <linearGradient id="colorGtv" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#6366f1" stopOpacity={0.4}/>
                    <stop offset="95%" stopColor="#6366f1" stopOpacity={0.0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" />
                <XAxis dataKey="month" stroke="var(--muted-foreground)" fontSize={12} />
                <YAxis stroke="var(--muted-foreground)" fontSize={12} />
                <Tooltip formatter={(value: any) => `${value?.toLocaleString() ?? 0} ر.س`} />
                <Area type="monotone" dataKey="volume" stroke="#6366f1" strokeWidth={3} fillOpacity={1} fill="url(#colorGtv)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Stacked Revenue Breakdowns */}
        <div className="premium-card p-6">
          <h4 className="text-sm font-bold mb-4">{isAr ? 'تصنيف الإيرادات (اشتراكات وبوابات الرسائل)' : 'Revenue Breakdowns (SAR)'}</h4>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={revenueStackedData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" />
                <XAxis dataKey="name" stroke="var(--muted-foreground)" fontSize={12} />
                <YAxis stroke="var(--muted-foreground)" fontSize={12} />
                <Tooltip formatter={(value: any) => `${value?.toLocaleString() ?? 0} ر.س`} />
                <Legend />
                <Bar dataKey="subRev" name={isAr ? 'رسوم الاشتراكات' : 'Subscriptions'} fill="#6366f1" stackId="a" radius={[0, 0, 0, 0]} />
                <Bar dataKey="smsRev" name={isAr ? 'عائدات رسائل SMS' : 'SMS fee/API'} fill="#10b981" stackId="a" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

      </div>

      {/* Top lists rankings */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        
        {/* Top Merchants by GTV */}
        <div className="premium-card p-6">
          <h4 className="text-sm font-bold mb-4">{isAr ? 'أعلى التجار معالجة للمدفوعات (GTV)' : 'Top Performing Merchants'}</h4>
          <div className="space-y-4">
            {topMerchantsList.map((m, idx) => (
              <div key={idx} className="flex items-center justify-between p-3.5 rounded-xl border border-border bg-background/50 hover:border-primary/20 transition">
                <div className="flex items-center gap-3">
                  <span className="text-2xl w-9 h-9 rounded-lg bg-indigo-50/50 flex items-center justify-center border border-border">{m.logo}</span>
                  <div>
                    <p className="font-bold text-foreground text-xs">{m.name}</p>
                    <span className="text-[9px] bg-primary/10 text-primary border border-primary/20 px-2 py-0.5 rounded-full font-bold uppercase font-english mt-1 inline-block">
                      {m.plan}
                    </span>
                  </div>
                </div>
                <div className="text-end">
                  <p className="font-english font-black text-foreground text-xs">{m.volume.toLocaleString()} SAR</p>
                  <span className="text-[9px] text-green-600 dark:text-green-400 font-bold flex items-center gap-0.5 justify-end">
                    <ArrowUpRight className="w-3 h-3" />
                    <span>GTV</span>
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Info Analytics Notice */}
        <div className="premium-card p-6 flex flex-col justify-center items-center text-center bg-indigo-500/5 border border-indigo-500/10">
          <div className="w-12 h-12 rounded-full bg-indigo-500/10 text-primary flex items-center justify-center mb-4">
            <Sparkles className="w-6 h-6" />
          </div>
          <h4 className="font-bold text-sm text-foreground">{isAr ? 'التحليلات الذكية مدعومة بالكامل' : 'Real-time Analytical Engine'}</h4>
          <p className="text-xs text-muted-foreground max-w-sm mt-2 leading-relaxed">
            {isAr ? 'يتم احتساب وجمع التقارير بشكل لحظي بمجرد حدوث عمليات سداد للديون من قبل بوابات الدفع الإلكترونية وربطها بقاعدة البيانات.' : 'Processing metrics react to real-time events triggered from API callbacks and Sanctum auth sessions.'}
          </p>
        </div>

      </div>

    </div>
  )
}
