import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { Package } from '../lib/api'
import { useApp } from '../components/AppContext'
import {
  Plus,
  Edit2,
  Check,
  TrendingUp,
  Box,
  Users,
  Receipt,
  Sparkles,
} from 'lucide-react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as zod from 'zod'

export const Route = createFileRoute('/packages')({
  component: PackagesPage,
})

const packageSchema = zod.object({
  name: zod.string().min(3, 'الاسم يجب أن يكون 3 أحرف على الأقل / Name must be at least 3 chars'),
  price: zod.number().min(0, 'السعر يجب أن يكون 0 أو أكثر / Price must be at least 0'),
  interval: zod.enum(['monthly', 'yearly']),
  max_customers: zod.number().min(1, 'الحد الأدنى للعملاء 1 / At least 1 customer'),
  max_debts: zod.number().min(1, 'الحد الأدنى للديون 1 / At least 1 debt'),
  featuresString: zod.string().min(3, 'أدخل ميزة واحدة على الأقل مفصولة بفاصلة / Enter features'),
})

type PackageFormValues = zod.infer<typeof packageSchema>

function PackagesPage() {
  const { lang, dir } = useApp()
  const isAr = lang === 'ar'
  const queryClient = useQueryClient()

  const [showCreateModal, setShowCreateModal] = useState(false)
  const [editingPackage, setEditingPackage] = useState<Package | null>(null)

  const { register, handleSubmit, reset, setValue, formState: { errors } } = useForm<PackageFormValues>({
    resolver: zodResolver(packageSchema),
    defaultValues: {
      name: '',
      price: 0,
      interval: 'monthly',
      max_customers: 100,
      max_debts: 500,
      featuresString: '',
    }
  })

  // Queries
  const { data: packages = [], isLoading } = useQuery({
    queryKey: ['packages'],
    queryFn: () => api.getPackages(),
  })

  // Mutations
  const createMutation = useMutation({
    mutationFn: (newPack: Partial<Package>) => api.createPackage(newPack),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['packages'] })
      setShowCreateModal(false)
      reset()
    }
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Package> }) => api.updatePackage(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['packages'] })
      setEditingPackage(null)
      reset()
    }
  })

  const handleCreate = (values: PackageFormValues) => {
    const payload = {
      name: values.name,
      price: values.price,
      interval: values.interval,
      max_customers: values.max_customers,
      max_debts: values.max_debts,
      features: values.featuresString.split(',').map((f) => f.trim()),
    }
    createMutation.mutate(payload)
  }

  const handleEdit = (values: PackageFormValues) => {
    if (!editingPackage) return
    const payload = {
      name: values.name,
      price: values.price,
      interval: values.interval,
      max_customers: values.max_customers,
      max_debts: values.max_debts,
      features: values.featuresString.split(',').map((f) => f.trim()),
    }
    updateMutation.mutate({ id: editingPackage.id, data: payload })
  }

  const startEdit = (pack: Package) => {
    setEditingPackage(pack)
    setValue('name', pack.name)
    setValue('price', pack.price)
    setValue('interval', pack.interval)
    setValue('max_customers', pack.max_customers)
    setValue('max_debts', pack.max_debts)
    setValue('featuresString', pack.features.join(', '))
  }

  return (
    <div className="space-y-8">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {isAr ? 'الباقات والأسعار' : 'Subscription Plans'}
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            {isAr ? 'إدارة وتخصيص باقات اشتراك التجار في منصة سداد' : 'Manage core pricing tiers, limits, and quotas.'}
          </p>
        </div>

        <button
          onClick={() => {
            setEditingPackage(null)
            reset()
            setShowCreateModal(true)
          }}
          className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-primary-foreground font-semibold hover:opacity-95 transition duration-200 cursor-pointer shadow-lg shadow-primary/10 text-sm"
        >
          <Plus className="w-5 h-5" />
          <span>{isAr ? 'إنشاء باقة جديدة' : 'Create Package'}</span>
        </button>
      </div>

      {/* Pricing Tiers Grid */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 animate-pulse">
          {Array.from({ length: 3 }).map((_, idx) => (
            <div key={idx} className="premium-card p-6 h-96" />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {packages.map((pack) => (
            <div
              key={pack.id}
              className={`premium-card p-6 flex flex-col justify-between relative overflow-hidden transition-all duration-300
                ${pack.price > 100 && pack.price < 1000 ? 'border-primary shadow-xl ring-2 ring-primary/10' : ''}
              `}
            >
              {/* Most popular badge */}
              {pack.price > 100 && pack.price < 1000 && (
                <div className="absolute top-3 end-3 bg-primary text-primary-foreground text-[10px] font-bold px-2 py-0.5 rounded-full uppercase flex items-center gap-1">
                  <Sparkles className="w-3 h-3" />
                  <span>{isAr ? 'الأكثر طلباً' : 'Popular'}</span>
                </div>
              )}

              {/* Package header info */}
              <div>
                <span className="text-muted-foreground text-[10px] uppercase font-bold tracking-widest">{isAr ? 'الخطة السعرية' : 'Tier'}</span>
                <h3 className="text-lg font-bold text-foreground mt-1">{pack.name}</h3>

                {/* Price */}
                <div className="mt-4 flex items-baseline font-english">
                  <span className="text-3xl font-black text-foreground">{pack.price.toLocaleString()}</span>
                  <span className="text-xs text-muted-foreground ms-1">
                    SAR / {pack.interval === 'yearly' ? (isAr ? 'سنوياً' : 'yr') : (isAr ? 'شهرياً' : 'mo')}
                  </span>
                </div>

                {/* Limits summary */}
                <div className="mt-6 space-y-2 border-t border-b border-border/50 py-4 text-xs font-semibold text-muted-foreground">
                  <p className="flex items-center gap-2">
                    <Users className="w-4 h-4 text-primary" />
                    <span>{isAr ? 'حد أقصى للعملاء:' : 'Max Customers:'} <span className="text-foreground font-bold font-english">{pack.max_customers.toLocaleString()}</span></span>
                  </p>
                  <p className="flex items-center gap-2">
                    <Receipt className="w-4 h-4 text-primary" />
                    <span>{isAr ? 'حد أقصى للديون:' : 'Max Debts:'} <span className="text-foreground font-bold font-english">{pack.max_debts.toLocaleString()}</span></span>
                  </p>
                </div>

                {/* Features list */}
                <ul className="mt-6 space-y-2.5 text-xs">
                  {pack.features.map((feature, index) => (
                    <li key={index} className="flex items-start gap-2">
                      <Check className="w-4 h-4 text-emerald-600 dark:text-emerald-400 mt-0.5 flex-shrink-0" />
                      <span className="text-foreground">{feature}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Action Button */}
              <div className="mt-8 pt-4 border-t border-border/40">
                <button
                  onClick={() => {
                    startEdit(pack)
                    setShowCreateModal(true)
                  }}
                  className="w-full py-2.5 rounded-xl border border-border bg-card hover:bg-muted text-foreground transition font-bold text-xs flex items-center justify-center gap-1.5 cursor-pointer"
                >
                  <Edit2 className="w-3.5 h-3.5" />
                  <span>{isAr ? 'تعديل الباقة' : 'Edit Plan'}</span>
                </button>
              </div>

            </div>
          ))}
        </div>
      )}

      {/* Creation/Editing Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/50 backdrop-blur-xs" onClick={() => setShowCreateModal(false)} />
          
          <div className="bg-card text-foreground rounded-2xl w-full max-w-md p-6 border border-border relative z-10 slide-up shadow-2xl">
            <h3 className="text-xl font-bold mb-4">
              {editingPackage ? (isAr ? 'تعديل باقة الاشتراك' : 'Edit Subscription Plan') : (isAr ? 'إنشاء باقة جديدة' : 'Create Subscription Plan')}
            </h3>
            
            <form onSubmit={handleSubmit(editingPackage ? handleEdit : handleCreate)} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'اسم الباقة' : 'Plan Name'}</label>
                <input
                  type="text"
                  required
                  {...register('name')}
                  placeholder={isAr ? 'الباقة الفضية' : 'Silver Plan'}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                />
                {errors.name && <p className="text-xs text-destructive mt-1">{errors.name.message}</p>}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'السعر (ر.س)' : 'Price (SAR)'}</label>
                  <input
                    type="number"
                    required
                    {...register('price', { valueAsNumber: true })}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                  />
                  {errors.price && <p className="text-xs text-destructive mt-1">{errors.price.message}</p>}
                </div>

                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'الدورة الزمنية' : 'Interval'}</label>
                  <select
                    {...register('interval')}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:outline-none"
                  >
                    <option value="monthly">{isAr ? 'شهرياً' : 'Monthly'}</option>
                    <option value="yearly">{isAr ? 'سنوياً' : 'Yearly'}</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'أقصى عدد للعملاء' : 'Max Customers'}</label>
                  <input
                    type="number"
                    required
                    {...register('max_customers', { valueAsNumber: true })}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'أقصى عدد للديون' : 'Max Debts'}</label>
                  <input
                    type="number"
                    required
                    {...register('max_debts', { valueAsNumber: true })}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold mb-1 text-muted-foreground">{isAr ? 'الميزات والخواص (مفصولة بفاصلة)' : 'Plan Features (comma-separated)'}</label>
                <textarea
                  required
                  rows={3}
                  {...register('featuresString')}
                  placeholder={isAr ? 'ميزة أولى، ميزة ثانية، ميزة ثالثة' : 'Feature A, Feature B, Feature C'}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-border bg-background focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none resize-none"
                />
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
                  disabled={createMutation.isPending || updateMutation.isPending}
                  className="px-5 py-2.5 rounded-xl bg-primary text-primary-foreground font-bold text-sm cursor-pointer hover:opacity-95 shadow-md"
                >
                  {isAr ? 'حفظ البيانات' : 'Save Plan'}
                </button>
              </div>

            </form>
          </div>
        </div>
      )}

    </div>
  )
}
