import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { Payment } from '../lib/api'
import { useApp } from '../components/AppContext'
import {
  Search,
  CreditCard,
  Download,
  Calendar,
  CheckCircle,
  XCircle,
  Eye,
  Building,
  Printer,
  Sparkles,
} from 'lucide-react'

export const Route = createFileRoute('/payments')({
  component: PaymentsPage,
})

function PaymentsPage() {
  const { lang, dir } = useApp()
  const isAr = lang === 'ar'
  const [searchTerm, setSearchTerm] = useState('')
  const [methodFilter, setMethodFilter] = useState('all')
  const [selectedReceipt, setSelectedReceipt] = useState<Payment | null>(null)

  // Fetch payments list
  const { data: payments = [], isLoading } = useQuery({
    queryKey: ['payments'],
    queryFn: () => api.getPayments(),
  })

  // Filter payments
  const filteredPayments = payments.filter((p) => {
    const matchesSearch = p.reference.toLowerCase().includes(searchTerm.toLowerCase()) || p.id.includes(searchTerm)
    const matchesMethod = methodFilter === 'all' || p.method === methodFilter
    return matchesSearch && matchesMethod
  })

  return (
    <div className="space-y-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {isAr ? 'سجل المدفوعات والعمليات' : 'Payments & Ledger'}
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            {isAr ? 'مراقبة حركة تحصيل الديون ومراجعة فواتير الدفع الرقمية' : 'Audit general ledger, transactions, and printable receipts.'}
          </p>
        </div>
      </div>

      {/* Filters Toolbar */}
      <div className="premium-card p-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="w-4.5 h-4.5 text-muted-foreground absolute start-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder={isAr ? 'البحث بالرقم المرجعي للعملية...' : 'Search by reference...'}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full ps-9 pe-4 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
          />
        </div>

        {/* Filters */}
        <div className="flex items-center gap-3 self-end md:self-auto">
          <select
            value={methodFilter}
            onChange={(e) => setMethodFilter(e.target.value)}
            className="px-3 py-2 text-xs font-semibold rounded-xl border border-border bg-card text-foreground focus:outline-none"
          >
            <option value="all">{isAr ? 'كل وسائل الدفع' : 'All Methods'}</option>
            <option value="mada">مدى / mada</option>
            <option value="apple_pay">Apple Pay</option>
            <option value="visa">Visa</option>
            <option value="bank_transfer">{isAr ? 'تحويل بنكي' : 'Bank Transfer'}</option>
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
        ) : filteredPayments.length === 0 ? (
          <div className="p-12 text-center text-muted-foreground">
            <CreditCard className="w-16 h-16 mx-auto text-muted-foreground/30 mb-4" />
            <p className="font-bold">{isAr ? 'لا يوجد عمليات دفع مسجلة' : 'No transactions recorded'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs text-start border-collapse">
              <thead>
                <tr className="border-b border-border bg-muted/30 text-muted-foreground font-semibold uppercase">
                  <th className="py-4 px-4 text-start">{isAr ? 'الرقم المرجعي' : 'Reference Code'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'القيمة' : 'Amount'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'وسيلة الدفع' : 'Payment Method'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'الحالة' : 'Status'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'التاريخ والوقت' : 'Date & Time'}</th>
                  <th className="py-4 px-4 text-center">{isAr ? 'سند القبض' : 'Receipt'}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40 font-medium">
                {filteredPayments.map((p) => (
                  <tr key={p.id} className="hover:bg-muted/30 transition">
                    
                    {/* Reference */}
                    <td className="py-4 px-4 font-english font-bold text-foreground text-sm">
                      {p.reference}
                    </td>

                    {/* Amount */}
                    <td className="py-4 px-4 font-english text-foreground font-bold text-sm">
                      {p.amount.toLocaleString()} <span className="text-[10px] font-normal text-muted-foreground">{isAr ? 'ر.س' : 'SAR'}</span>
                    </td>

                    {/* Method */}
                    <td className="py-4 px-4 font-english uppercase text-muted-foreground font-semibold">
                      {p.method === 'bank_transfer' ? (isAr ? 'تحويل بنكي' : 'Bank') : p.method}
                    </td>

                    {/* Status */}
                    <td className="py-4 px-4">
                      <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full font-bold text-[9px] uppercase
                        ${p.status === 'completed' ? 'bg-green-500/10 text-green-600' : ''}
                        ${p.status === 'failed' ? 'bg-red-500/10 text-red-600' : ''}
                      `}>
                        {p.status === 'completed' && <CheckCircle className="w-3 h-3" />}
                        {p.status === 'failed' && <XCircle className="w-3 h-3" />}
                        {p.status === 'completed' ? (isAr ? 'مقبول' : 'Completed') : (isAr ? 'مرفوض' : 'Failed')}
                      </span>
                    </td>

                    {/* Date */}
                    <td className="py-4 px-4 text-muted-foreground font-english">
                      {p.created_at.replace('T', ' ').replace('Z', '').split('.')[0]}
                    </td>

                    {/* Action Receipt */}
                    <td className="py-4 px-4 text-center">
                      <button
                        onClick={() => setSelectedReceipt(p)}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-border bg-card hover:bg-muted text-foreground transition cursor-pointer font-bold"
                      >
                        <Eye className="w-4 h-4 text-primary" />
                        <span>{isAr ? 'عرض الفاتورة' : 'View Invoice'}</span>
                      </button>
                    </td>

                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Digital Receipt Modal */}
      {selectedReceipt && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/50 backdrop-blur-xs" onClick={() => setSelectedReceipt(null)} />
          
          <div className="bg-card text-foreground rounded-2xl w-full max-w-sm p-6 border border-border relative z-10 slide-up shadow-2xl space-y-6">
            
            {/* Header Voucher */}
            <div className="text-center pb-4 border-b border-border/80 relative">
              <span className="text-3xl">⚡</span>
              <h3 className="font-extrabold text-md mt-2 tracking-wide font-english text-foreground">SIDAD FINANCIAL</h3>
              <p className="text-[10px] text-muted-foreground uppercase tracking-widest mt-0.5">{isAr ? 'سند استلام دفعة مالية' : 'PAYMENT RECEIPT VOUCHER'}</p>
            </div>

            {/* Receipt Summary Grid */}
            <div className="space-y-4 text-xs font-semibold">
              <div className="flex justify-between">
                <span className="text-muted-foreground">{isAr ? 'الرقم المرجعي للعملية' : 'Transaction Ref'}</span>
                <span className="font-english text-foreground">{selectedReceipt.reference}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">{isAr ? 'تاريخ العملية والوقت' : 'Payment Date'}</span>
                <span className="font-english text-foreground">{selectedReceipt.created_at.replace('T', ' ').split('.')[0]}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">{isAr ? 'وسيلة الدفع المستخدمة' : 'Method'}</span>
                <span className="font-english uppercase text-foreground">{selectedReceipt.method}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">{isAr ? 'حالة القيد والتحصيل' : 'Status'}</span>
                <span className="text-green-600 font-bold uppercase">{selectedReceipt.status}</span>
              </div>
              
              <div className="border-t border-dashed border-border/85 pt-4 flex justify-between items-center text-sm">
                <span className="font-bold text-foreground">{isAr ? 'المبلغ الإجمالي المحصل' : 'Total Amount Paid'}</span>
                <span className="font-english font-black text-primary text-base">
                  {selectedReceipt.amount.toLocaleString()} ر.س
                </span>
              </div>
            </div>

            {/* QR Code Placeholder */}
            <div className="bg-muted/30 p-4 rounded-xl border border-border/50 flex flex-col items-center justify-center gap-2">
              <div className="w-24 h-24 bg-foreground/5 rounded-lg flex items-center justify-center border border-border">
                {/* Simulated QR Code */}
                <div className="grid grid-cols-6 gap-0.5 w-18 h-18 opacity-80">
                  {Array.from({ length: 36 }).map((_, i) => (
                    <div key={i} className={`w-2.5 h-2.5 rounded-xs ${Math.random() > 0.4 ? 'bg-foreground' : 'bg-transparent'}`} />
                  ))}
                </div>
              </div>
              <span className="text-[9px] text-muted-foreground font-english">SECURE FINANCIAL QR CODE</span>
            </div>

            {/* Print and Actions */}
            <div className="flex justify-end gap-2 pt-2 text-xs">
              <button
                onClick={() => setSelectedReceipt(null)}
                className="px-4 py-2 rounded-xl border border-border bg-muted/10 font-bold cursor-pointer"
              >
                {isAr ? 'إغلاق' : 'Close'}
              </button>
              <button
                onClick={() => {
                  window.print()
                }}
                className="px-4 py-2 rounded-xl bg-primary text-primary-foreground font-bold flex items-center gap-1.5 cursor-pointer shadow-md shadow-primary/10"
              >
                <Printer className="w-4 h-4" />
                <span>{isAr ? 'طباعة السند' : 'Print'}</span>
              </button>
            </div>

          </div>
        </div>
      )}

    </div>
  )
}
