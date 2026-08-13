import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { AuditLog } from '../lib/api'
import { useApp } from '../components/AppContext'
import { History, Search, Laptop, Shield } from 'lucide-react'

export const Route = createFileRoute('/audit-logs')({
  component: AuditLogsPage,
})

function AuditLogsPage() {
  const { lang } = useApp()
  const isAr = lang === 'ar'
  const [searchTerm, setSearchTerm] = useState('')

  // Fetch audit logs
  const { data: logs = [], isLoading } = useQuery({
    queryKey: ['auditLogs'],
    queryFn: () => api.getAuditLogs(),
  })

  // Filter logs
  const filteredLogs = logs.filter((log) => {
    return (
      log.action.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.admin_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.ip.includes(searchTerm)
    )
  })

  return (
    <div className="space-y-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {isAr ? 'سجل العمليات (Audit Logs)' : 'Security Audit Logs'}
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            {isAr ? 'مراقبة وتتبع جميع العمليات الإدارية وأنشطة لوحة التحكم والأمان' : 'Monitor administrative actions, security updates, and access controls.'}
          </p>
        </div>
      </div>

      {/* Filters Toolbar */}
      <div className="premium-card p-4">
        <div className="relative max-w-md">
          <Search className="w-4.5 h-4.5 text-muted-foreground absolute start-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder={isAr ? 'البحث بالحدث، اسم المسؤول، أو عنوان IP...' : 'Search by action, admin, IP...'}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full ps-9 pe-4 py-2 text-sm rounded-xl border border-border bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
          />
        </div>
      </div>

      {/* Table grid */}
      <div className="premium-card overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center animate-pulse space-y-4">
            <div className="h-8 bg-muted rounded w-full" />
            <div className="h-8 bg-muted rounded w-full" />
          </div>
        ) : filteredLogs.length === 0 ? (
          <div className="p-12 text-center text-muted-foreground">
            <History className="w-16 h-16 mx-auto text-muted-foreground/30 mb-4" />
            <p className="font-bold">{isAr ? 'لا توجد عمليات مسجلة مطابقة' : 'No audit records found'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs text-start border-collapse">
              <thead>
                <tr className="border-b border-border bg-muted/30 text-muted-foreground font-semibold uppercase">
                  <th className="py-4 px-4 text-start">{isAr ? 'المسؤول' : 'Administrator'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'العملية / الإجراء' : 'Action Details'}</th>
                  <th className="py-4 px-4 text-start">IP Address</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'نظام العميل / المتصفح' : 'Client Browser'}</th>
                  <th className="py-4 px-4 text-start">{isAr ? 'التاريخ والوقت' : 'Timestamp'}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40 font-medium">
                {filteredLogs.map((log) => (
                  <tr key={log.id} className="hover:bg-muted/30 transition">
                    
                    {/* Admin Name */}
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-2">
                        <div className="w-7 h-7 rounded-lg bg-indigo-50/50 text-primary border border-border flex items-center justify-center">
                          <Shield className="w-4 h-4" />
                        </div>
                        <span className="font-bold text-foreground">{log.admin_name}</span>
                      </div>
                    </td>

                    {/* Action */}
                    <td className="py-4 px-4 text-foreground text-sm font-semibold">
                      {log.action}
                    </td>

                    {/* IP */}
                    <td className="py-4 px-4 font-english text-muted-foreground">
                      {log.ip}
                    </td>

                    {/* Browser client */}
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-1.5 text-muted-foreground">
                        <Laptop className="w-4 h-4 flex-shrink-0" />
                        <span className="truncate max-w-[200px] font-english">{log.browser}</span>
                      </div>
                    </td>

                    {/* Timestamp */}
                    <td className="py-4 px-4 text-muted-foreground font-english">
                      {log.created_at.replace('T', ' ').replace('Z', '')}
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
