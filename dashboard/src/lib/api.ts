/**
 * Sidad API Client Layer
 * Connects to Laravel 12 API (Sanctum SPA authentication)
 * Implements a local storage-backed mock engine when Laravel is offline.
 */

export interface User {
  id: string
  name: string
  email: string
  role: 'admin' | 'merchant' | 'superadmin'
  avatar?: string
  created_at: string
}

export interface Merchant {
  id: string
  name: string
  email: string
  phone: string
  logo?: string
  plan: 'Basic' | 'Premium' | 'Enterprise'
  subscription: 'monthly' | 'yearly'
  status: 'active' | 'suspended' | 'expired'
  customers_count: number
  debts_count: number
  created_at: string
  remaining_days: number
}

export interface Customer {
  id: string
  merchant_id: string
  name: string
  phone: string
  email: string
  is_active: boolean
  total_debt: number
  paid_amount: number
  debts_count: number
  created_at: string
}

export interface Debt {
  id: string
  merchant_id: string
  customer_id: string
  customer?: {
    id: string
    name: string
    phone: string
  }
  total_amount: number // In decimal SAR
  paid_amount: number  // In decimal SAR
  remaining_amount: number // In decimal SAR
  status: 'pending' | 'approved' | 'rejected' | 'settled'
  rejection_reason?: string
  installments_count: number
  created_at: string
}

export interface Payment {
  id: string
  merchant_id: string
  debt_id: string
  amount: number
  method: 'mada' | 'visa' | 'bank_transfer' | 'apple_pay'
  reference: string
  status: 'completed' | 'failed' | 'refunded'
  created_at: string
}

export interface Package {
  id: string
  name: string
  price: number
  interval: 'monthly' | 'yearly'
  features: string[]
  max_customers: number
  max_debts: number
}

export interface AuditLog {
  id: string
  admin_name: string
  action: string
  ip: string
  browser: string
  created_at: string
}

export interface SystemSettings {
  general: {
    site_name: string
    support_email: string
    currency: string
  }
  branding: {
    primary_color: string
    logo_url?: string
  }
  smtp: {
    host: string
    port: number
    encryption: string
    username: string
  }
  sms: {
    provider: string
    api_key: string
    sender_name: string
  }
  whatsapp: {
    instance_id: string
    token: string
  }
  payment_methods: {
    mada: boolean
    visa: boolean
    apple_pay: boolean
  }
}

// Global API settings
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api'
const TOKEN_KEY = 'sidad_auth_token'
const USER_KEY = 'sidad_auth_user'

class ApiClient {
  private useMock: boolean = true

  constructor() {
    this.checkBackendConnection()
  }

  private async checkBackendConnection() {
    try {
      const controller = new AbortController()
      const id = setTimeout(() => controller.abort(), 2000)
      const res = await fetch(`${API_BASE_URL}/health-check`, { signal: controller.signal })
      clearTimeout(id)
      if (res.ok) {
        this.useMock = false
        console.log('[Sidad API] Connected to Laravel backend API')
      }
    } catch (e) {
      console.warn('[Sidad API] Laravel API is unreachable. Falling back to local storage mock database.')
      this.useMock = true
    }
  }

  // Set mock mode manually
  setMockMode(enable: boolean) {
    this.useMock = enable
  }

  isMockMode() {
    return this.useMock
  }

  private getHeaders(): HeadersInit {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    }
    const token = typeof window !== 'undefined' ? localStorage.getItem(TOKEN_KEY) : null
    if (token) {
      headers['Authorization'] = `Bearer ${token}`
    }
    return headers
  }

  // Generic request handler
  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const url = `${API_BASE_URL}${endpoint}`
    const response = await fetch(url, {
      ...options,
      headers: {
        ...this.getHeaders(),
        ...options.headers,
      },
    })

    if (response.status === 401) {
      if (typeof window !== 'undefined') {
        localStorage.removeItem(TOKEN_KEY)
        localStorage.removeItem(USER_KEY)
        window.dispatchEvent(new Event('auth-change'))
      }
      throw new Error('Unauthenticated')
    }

    const data = await response.json()
    if (!response.ok || !data.success) {
      throw new Error(data.message || 'API request failed')
    }

    return data.data as T
  }

  // --- AUTHENTICATION ---
  async login(email: string, password: string, device_name = 'Web Admin'): Promise<{ user: User; token: string }> {
    if (this.useMock) {
      return mockDb.login(email, password)
    }
    
    const result = await this.request<{ user: User; token: string }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password, device_name }),
    })
    
    localStorage.setItem(TOKEN_KEY, result.token)
    localStorage.setItem(USER_KEY, JSON.stringify(result.user))
    window.dispatchEvent(new Event('auth-change'))
    return result
  }

  async logout(): Promise<void> {
    if (this.useMock) {
      mockDb.logout()
      return
    }

    try {
      await this.request('/auth/logout', { method: 'POST' })
    } finally {
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(USER_KEY)
      window.dispatchEvent(new Event('auth-change'))
    }
  }

  async getProfile(): Promise<User> {
    if (this.useMock) {
      return mockDb.getProfile()
    }
    return this.request<User>('/profile')
  }

  // --- DASHBOARD STATISTICS ---
  async getDashboardStats() {
    if (this.useMock) {
      return mockDb.getDashboardStats()
    }
    return this.request<{
      total_merchants: number
      active_merchants: number
      expired_subscriptions: number
      expiring_soon: number
      total_customers: number
      total_debts: number
      settled_debts: number
      pending_debts: number
      monthly_revenue: number
      recent_transactions: Debt[]
      top_customers: Customer[]
    }>('/dashboard')
  }

  // --- MERCHANTS ---
  async getMerchants(): Promise<Merchant[]> {
    if (this.useMock) return mockDb.getMerchants()
    return this.request<Merchant[]>('/merchants')
  }

  async createMerchant(merchant: Partial<Merchant>): Promise<Merchant> {
    if (this.useMock) return mockDb.createMerchant(merchant)
    return this.request<Merchant>('/merchants', {
      method: 'POST',
      body: JSON.stringify(merchant),
    })
  }

  async updateMerchant(id: string, merchant: Partial<Merchant>): Promise<Merchant> {
    if (this.useMock) return mockDb.updateMerchant(id, merchant)
    return this.request<Merchant>(`/merchants/${id}`, {
      method: 'PUT',
      body: JSON.stringify(merchant),
    })
  }

  // --- CUSTOMERS ---
  async getCustomers(params?: { search?: string; is_active?: boolean }): Promise<Customer[]> {
    if (this.useMock) return mockDb.getCustomers(params)
    const query = new URLSearchParams()
    if (params?.search) query.append('search', params.search)
    if (params?.is_active !== undefined) query.append('is_active', String(params.is_active))
    return this.request<Customer[]>(`/customers?${query.toString()}`)
  }

  async createCustomer(customer: Partial<Customer>): Promise<Customer> {
    if (this.useMock) return mockDb.createCustomer(customer)
    return this.request<Customer>('/customers', {
      method: 'POST',
      body: JSON.stringify(customer),
    })
  }

  async updateCustomer(id: string, customer: Partial<Customer>): Promise<Customer> {
    if (this.useMock) return mockDb.updateCustomer(id, customer)
    return this.request<Customer>(`/customers/${id}`, {
      method: 'PUT',
      body: JSON.stringify(customer),
    })
  }

  // --- DEBTS ---
  async getDebts(params?: { status?: string; customer_id?: string }): Promise<Debt[]> {
    if (this.useMock) return mockDb.getDebts(params)
    const query = new URLSearchParams()
    if (params?.status) query.append('status', params.status)
    if (params?.customer_id) query.append('customer_id', params.customer_id)
    return this.request<Debt[]>(`/debts?${query.toString()}`)
  }

  async createDebt(debt: Partial<Debt>): Promise<Debt> {
    if (this.useMock) return mockDb.createDebt(debt)
    return this.request<Debt>('/debts', {
      method: 'POST',
      body: JSON.stringify(debt),
    })
  }

  async approveDebt(id: string): Promise<Debt> {
    if (this.useMock) return mockDb.approveDebt(id)
    return this.request<Debt>(`/debts/${id}/approve`, { method: 'PATCH' })
  }

  async rejectDebt(id: string, reason: string): Promise<Debt> {
    if (this.useMock) return mockDb.rejectDebt(id, reason)
    return this.request<Debt>(`/debts/${id}/reject`, {
      method: 'PATCH',
      body: JSON.stringify({ rejection_reason: reason }),
    })
  }

  // --- PAYMENTS ---
  async getPayments(): Promise<Payment[]> {
    if (this.useMock) return mockDb.getPayments()
    return this.request<Payment[]>('/payments')
  }

  async createPayment(payment: Partial<Payment>): Promise<Payment> {
    if (this.useMock) return mockDb.createPayment(payment)
    return this.request<Payment>('/payments', {
      method: 'POST',
      body: JSON.stringify(payment),
    })
  }

  // --- PACKAGES ---
  async getPackages(): Promise<Package[]> {
    if (this.useMock) return mockDb.getPackages()
    return this.request<Package[]>('/packages')
  }

  async createPackage(pack: Partial<Package>): Promise<Package> {
    if (this.useMock) return mockDb.createPackage(pack)
    return this.request<Package>('/packages', {
      method: 'POST',
      body: JSON.stringify(pack),
    })
  }

  async updatePackage(id: string, pack: Partial<Package>): Promise<Package> {
    if (this.useMock) return mockDb.updatePackage(id, pack)
    return this.request<Package>(`/packages/${id}`, {
      method: 'PUT',
      body: JSON.stringify(pack),
    })
  }

  // --- AUDIT LOGS ---
  async getAuditLogs(): Promise<AuditLog[]> {
    if (this.useMock) return mockDb.getAuditLogs()
    return this.request<AuditLog[]>('/audit-logs')
  }

  // --- SETTINGS ---
  async getSettings(): Promise<SystemSettings> {
    if (this.useMock) return mockDb.getSettings()
    return this.request<SystemSettings>('/settings')
  }

  async updateSettings(settings: Partial<SystemSettings>): Promise<SystemSettings> {
    if (this.useMock) return mockDb.updateSettings(settings)
    return this.request<SystemSettings>('/settings', {
      method: 'PUT',
      body: JSON.stringify(settings),
    })
  }
}

// --- LOCAL STORAGE MOCK ENGINE ---
class MockDatabase {
  constructor() {
    this.init()
  }

  private init() {
    if (typeof window === 'undefined') return

    // Set default user
    if (!localStorage.getItem(USER_KEY)) {
      const defaultUser: User = {
        id: '1',
        name: 'عبد الرحمن العتيبي',
        email: 'admin@sidad.co',
        role: 'superadmin',
        avatar: 'https://api.dicebear.com/7.x/adventurer/svg?seed=sidad',
        created_at: '2025-01-01',
      }
      localStorage.setItem(USER_KEY, JSON.stringify(defaultUser))
      localStorage.setItem(TOKEN_KEY, 'mock-sanctum-token-12345')
    }

    // Set default merchants
    if (!localStorage.getItem('mock_merchants')) {
      const merchants: Merchant[] = [
        {
          id: 'm1',
          name: 'مؤسسة البناء الحديث للمقاولات',
          email: 'info@modernbuild.sa',
          phone: '+966 50 123 4567',
          logo: '🏢',
          plan: 'Premium',
          subscription: 'yearly',
          status: 'active',
          customers_count: 142,
          debts_count: 89,
          created_at: '2024-06-16',
          remaining_days: 15,
        },
        {
          id: 'm2',
          name: 'محل الخليج للمواد الغذائية',
          email: 'gulfshop@gmail.com',
          phone: '+966 55 234 5678',
          logo: '🛒',
          plan: 'Basic',
          subscription: 'monthly',
          status: 'active',
          customers_count: 45,
          debts_count: 22,
          created_at: '2024-06-08',
          remaining_days: 8,
        },
        {
          id: 'm3',
          name: 'شركة التقنية المتقدمة',
          email: 'contact@advtech.sa',
          phone: '+966 53 345 6789',
          logo: '💻',
          plan: 'Enterprise',
          subscription: 'yearly',
          status: 'active',
          customers_count: 812,
          debts_count: 512,
          created_at: '2024-06-13',
          remaining_days: 3,
        },
        {
          id: 'm4',
          name: 'مكتبة العلم والمعرفة',
          email: 'knowledge.lib@sidad.co',
          phone: '+966 54 456 7890',
          logo: '📚',
          plan: 'Basic',
          subscription: 'monthly',
          status: 'expired',
          customers_count: 12,
          debts_count: 6,
          created_at: '2024-06-15',
          remaining_days: 0,
        },
        {
          id: 'm5',
          name: 'معرض الأزياء الراقية',
          email: 'fashion.gallery@sidad.sa',
          phone: '+966 56 567 8901',
          logo: '👗',
          plan: 'Premium',
          subscription: 'yearly',
          status: 'suspended',
          customers_count: 320,
          debts_count: 150,
          created_at: '2024-06-16',
          remaining_days: 110,
        },
      ]
      localStorage.setItem('mock_merchants', JSON.stringify(merchants))
    }

    // Set default customers
    if (!localStorage.getItem('mock_customers')) {
      const customers: Customer[] = [
        {
          id: 'c1',
          merchant_id: 'm1',
          name: 'صالح بن محمد الأحمد',
          phone: '+966 50 987 6543',
          email: 'saleh@gmail.com',
          is_active: true,
          total_debt: 12500,
          paid_amount: 8500,
          debts_count: 4,
          created_at: '2024-06-16',
        },
        {
          id: 'c2',
          merchant_id: 'm1',
          name: 'خالد عبد الله الحربي',
          phone: '+966 55 876 5432',
          email: 'khaled.h@hotmail.com',
          is_active: true,
          total_debt: 8400,
          paid_amount: 3200,
          debts_count: 2,
          created_at: '2024-06-16',
        },
        {
          id: 'c3',
          merchant_id: 'm2',
          name: 'فهد سليمان الدوسري',
          phone: '+966 53 765 4321',
          email: 'fahad@dosari.sa',
          is_active: true,
          total_debt: 3100,
          paid_amount: 3100,
          debts_count: 1,
          created_at: '2024-06-15',
        },
        {
          id: 'c4',
          merchant_id: 'm3',
          name: 'يوسف عبد الرحمن العلي',
          phone: '+966 54 654 3210',
          email: 'yousef.ali@outlook.com',
          is_active: true,
          total_debt: 45000,
          paid_amount: 15000,
          debts_count: 8,
          created_at: '2024-06-15',
        },
      ]
      localStorage.setItem('mock_customers', JSON.stringify(customers))
    }

    // Set default debts
    if (!localStorage.getItem('mock_debts')) {
      const debts: Debt[] = [
        {
          id: 'd1',
          merchant_id: 'm1',
          customer_id: 'c1',
          customer: { id: 'c1', name: 'صالح بن محمد الأحمد', phone: '+966 50 987 6543' },
          total_amount: 5000,
          paid_amount: 3000,
          remaining_amount: 2000,
          status: 'approved',
          installments_count: 5,
          created_at: '2026-06-20T10:00:00Z',
        },
        {
          id: 'd2',
          merchant_id: 'm1',
          customer_id: 'c2',
          customer: { id: 'c2', name: 'خالد عبد الله الحربي', phone: '+966 55 876 5432' },
          total_amount: 8400,
          paid_amount: 3200,
          remaining_amount: 5200,
          status: 'approved',
          installments_count: 12,
          created_at: '2026-06-22T11:30:00Z',
        },
        {
          id: 'd3',
          merchant_id: 'm2',
          customer_id: 'c3',
          customer: { id: 'c3', name: 'فهد سليمان الدوسري', phone: '+966 53 765 4321' },
          total_amount: 3100,
          paid_amount: 3100,
          remaining_amount: 0,
          status: 'settled',
          installments_count: 1,
          created_at: '2026-06-23T08:15:00Z',
        },
        {
          id: 'd4',
          merchant_id: 'm3',
          customer_id: 'c4',
          customer: { id: 'c4', name: 'يوسف عبد الرحمن العلي', phone: '+966 54 654 3210' },
          total_amount: 25000,
          paid_amount: 0,
          remaining_amount: 25000,
          status: 'pending',
          installments_count: 24,
          created_at: '2026-06-25T14:45:00Z',
        },
      ]
      localStorage.setItem('mock_debts', JSON.stringify(debts))
    }

    // Set default payments
    if (!localStorage.getItem('mock_payments')) {
      const payments: Payment[] = [
        {
          id: 'p1',
          merchant_id: 'm1',
          debt_id: 'd1',
          amount: 1500,
          method: 'mada',
          reference: 'TXN-98234798',
          status: 'completed',
          created_at: '2026-06-24T09:00:00Z',
        },
        {
          id: 'p2',
          merchant_id: 'm1',
          debt_id: 'd2',
          amount: 3200,
          method: 'apple_pay',
          reference: 'TXN-56294719',
          status: 'completed',
          created_at: '2026-06-25T12:00:00Z',
        },
      ]
      localStorage.setItem('mock_payments', JSON.stringify(payments))
    }

    // Set default packages
    if (!localStorage.getItem('mock_packages')) {
      const packages: Package[] = [
        {
          id: 'pk1',
          name: 'الباقة الأساسية (Basic)',
          price: 99,
          interval: 'monthly',
          max_customers: 100,
          max_debts: 500,
          features: ['لوحة تحكم بسيطة', 'إدارة الديون', 'تنبيهات SMS محدودة', 'دعم عبر البريد الإلكتروني'],
        },
        {
          id: 'pk2',
          name: 'الباقة المتقدمة (Premium)',
          price: 299,
          interval: 'monthly',
          max_customers: 1000,
          max_debts: 5000,
          features: ['لوحة تحكم متقدمة مع رسومات بيانية', 'إدارة الديون والأقساط', 'تنبيهات SMS وواتساب غير محدودة', 'دعم فني 24/7', 'تصدير التقارير بصيغة PDF/Excel'],
        },
        {
          id: 'pk3',
          name: 'باقة الشركات (Enterprise)',
          price: 2499,
          interval: 'yearly',
          max_customers: 99999,
          max_debts: 99999,
          features: ['ربط API مخصص', 'مدير حساب مخصص', 'تخصيص الهوية بالكامل', 'دعم متعدد الفروع والمستخدمين', 'تقارير وتحليلات مدعومة بالذكاء الاصطناعي'],
        },
      ]
      localStorage.setItem('mock_packages', JSON.stringify(packages))
    }

    // Set default audit logs
    if (!localStorage.getItem('mock_audit_logs')) {
      const logs: AuditLog[] = [
        {
          id: 'l1',
          admin_name: 'عبد الرحمن العتيبي',
          action: 'تسجيل دخول إلى النظام',
          ip: '192.168.1.1',
          browser: 'Chrome 122.0.0 / Windows 11',
          created_at: '2026-06-26T02:00:00Z',
        },
        {
          id: 'l2',
          admin_name: 'عبد الرحمن العتيبي',
          action: 'تعديل باقة التاجر: مؤسسة البناء الحديث للمقاولات',
          ip: '192.168.1.1',
          browser: 'Chrome 122.0.0 / Windows 11',
          created_at: '2026-06-26T02:15:00Z',
        },
        {
          id: 'l3',
          admin_name: 'نظام سداد التلقائي',
          action: 'تحديث حالة اشتراك التاجر: مكتبة العلم والمعرفة إلى منتهي',
          ip: '127.0.0.1',
          browser: 'System Cron Job',
          created_at: '2026-06-26T00:00:00Z',
        },
      ]
      localStorage.setItem('mock_audit_logs', JSON.stringify(logs))
    }

    // Set default settings
    if (!localStorage.getItem('mock_settings')) {
      const settings: SystemSettings = {
        general: {
          site_name: 'منصة سداد للمدفوعات والديون',
          support_email: 'support@sidad.co',
          currency: 'SAR',
        },
        branding: {
          primary_color: '#312e81',
          logo_url: '/logo.png',
        },
        smtp: {
          host: 'smtp.mailgun.org',
          port: 587,
          encryption: 'tls',
          username: 'postmaster@sidad.co',
        },
        sms: {
          provider: 'Taqnyat',
          api_key: '********-****-****-****-************',
          sender_name: 'SidadFin',
        },
        whatsapp: {
          instance_id: 'inst_82937492',
          token: 'wa_token_98410283478912',
        },
        payment_methods: {
          mada: true,
          visa: true,
          apple_pay: true,
        },
      }
      localStorage.setItem('mock_settings', JSON.stringify(settings))
    }
  }

  // --- ACTIONS ---
  login(email: string, password: string): { user: User; token: string } {
    if (email === 'admin@sidad.co' && password === 'admin') {
      const user = JSON.parse(localStorage.getItem(USER_KEY) || '{}')
      const token = 'mock-sanctum-token-12345'
      localStorage.setItem(TOKEN_KEY, token)
      return { user, token }
    }
    throw new Error('البريد الإلكتروني أو كلمة المرور غير صحيحة')
  }

  logout() {
    localStorage.removeItem(TOKEN_KEY)
  }

  getProfile(): User {
    const user = localStorage.getItem(USER_KEY)
    if (!user) throw new Error('Unauthenticated')
    return JSON.parse(user)
  }

  getDashboardStats() {
    const merchants = this.getMerchants()
    const customers = this.getCustomers()
    const debts = this.getDebts()
    const payments = this.getPayments()

    // Aggregate statistics
    const totalMerchants = merchants.length
    const activeMerchants = merchants.filter((m) => m.status === 'active').length
    const expiredMerchants = merchants.filter((m) => m.status === 'expired').length
    const expiringSoonMerchants = merchants.filter((m) => m.status === 'active' && m.remaining_days > 0 && m.remaining_days <= 7).length
    
    const totalCustomers = customers.length
    const totalDebtsAmount = debts.reduce((sum, d) => sum + d.total_amount, 0)
    const totalSettledAmount = debts.reduce((sum, d) => sum + d.paid_amount, 0)
    const totalPendingAmount = debts.reduce((sum, d) => sum + d.remaining_amount, 0)
    
    const monthlyRevenue = payments.reduce((sum, p) => sum + p.amount, 0) + 12540 // baseline

    return {
      total_merchants: totalMerchants,
      active_merchants: activeMerchants,
      expired_subscriptions: expiredMerchants,
      expiring_soon: expiringSoonMerchants,
      total_customers: totalCustomers,
      total_debts: totalDebtsAmount,
      settled_debts: totalSettledAmount,
      pending_debts: totalPendingAmount,
      monthly_revenue: monthlyRevenue,
      recent_transactions: debts.slice(0, 5),
      top_customers: customers.slice(0, 5),
    }
  }

  getMerchants(): Merchant[] {
    return JSON.parse(localStorage.getItem('mock_merchants') || '[]')
  }

  createMerchant(merchant: Partial<Merchant>): Merchant {
    const list = this.getMerchants()
    const newMerchant: Merchant = {
      id: 'm' + (list.length + 1),
      name: merchant.name || 'تاجر جديد',
      email: merchant.email || 'new@merchant.co',
      phone: merchant.phone || '+966 50 000 0000',
      logo: merchant.logo || '🏢',
      plan: merchant.plan || 'Basic',
      subscription: merchant.subscription || 'monthly',
      status: 'active',
      customers_count: 0,
      debts_count: 0,
      created_at: new Date().toISOString().split('T')[0],
      remaining_days: merchant.subscription === 'yearly' ? 365 : 30,
    }
    list.unshift(newMerchant)
    localStorage.setItem('mock_merchants', JSON.stringify(list))
    return newMerchant
  }

  updateMerchant(id: string, merchant: Partial<Merchant>): Merchant {
    const list = this.getMerchants()
    const idx = list.findIndex((m) => m.id === id)
    if (idx === -1) throw new Error('التاجر غير موجود')
    const updated = { ...list[idx], ...merchant }
    list[idx] = updated
    localStorage.setItem('mock_merchants', JSON.stringify(list))
    return updated
  }

  getCustomers(params?: { search?: string; is_active?: boolean }): Customer[] {
    let list: Customer[] = JSON.parse(localStorage.getItem('mock_customers') || '[]')
    if (params?.search) {
      const q = params.search.toLowerCase()
      list = list.filter((c) => c.name.toLowerCase().includes(q) || c.phone.includes(q))
    }
    if (params?.is_active !== undefined) {
      list = list.filter((c) => c.is_active === params.is_active)
    }
    return list
  }

  createCustomer(customer: Partial<Customer>): Customer {
    const list = this.getCustomers()
    const newCustomer: Customer = {
      id: 'c' + (list.length + 1),
      merchant_id: customer.merchant_id || 'm1',
      name: customer.name || 'عميل جديد',
      phone: customer.phone || '+966 50 000 0000',
      email: customer.email || 'customer@sidad.sa',
      is_active: true,
      total_debt: 0,
      paid_amount: 0,
      debts_count: 0,
      created_at: new Date().toISOString().split('T')[0],
    }
    list.unshift(newCustomer)
    localStorage.setItem('mock_customers', JSON.stringify(list))
    return newCustomer
  }

  updateCustomer(id: string, customer: Partial<Customer>): Customer {
    const list = this.getCustomers()
    const idx = list.findIndex((c) => c.id === id)
    if (idx === -1) throw new Error('العميل غير موجود')
    const updated = { ...list[idx], ...customer }
    list[idx] = updated
    localStorage.setItem('mock_customers', JSON.stringify(list))
    return updated
  }

  getDebts(params?: { status?: string; customer_id?: string }): Debt[] {
    let list: Debt[] = JSON.parse(localStorage.getItem('mock_debts') || '[]')
    if (params?.status) {
      list = list.filter((d) => d.status === params.status)
    }
    if (params?.customer_id) {
      list = list.filter((d) => d.customer_id === params.customer_id)
    }
    return list
  }

  createDebt(debt: Partial<Debt>): Debt {
    const list = this.getDebts()
    const customers = this.getCustomers()
    const cust = customers.find((c) => c.id === debt.customer_id)
    const newDebt: Debt = {
      id: 'd' + (list.length + 1),
      merchant_id: debt.merchant_id || 'm1',
      customer_id: debt.customer_id || 'c1',
      customer: cust ? { id: cust.id, name: cust.name, phone: cust.phone } : undefined,
      total_amount: debt.total_amount || 0,
      paid_amount: 0,
      remaining_amount: debt.total_amount || 0,
      status: 'pending',
      installments_count: debt.installments_count || 1,
      created_at: new Date().toISOString(),
    }
    list.unshift(newDebt)
    localStorage.setItem('mock_debts', JSON.stringify(list))

    // Update customer stats
    if (cust) {
      cust.total_debt += newDebt.total_amount
      cust.debts_count += 1
      this.updateCustomer(cust.id, cust)
    }

    return newDebt
  }

  approveDebt(id: string): Debt {
    const list = this.getDebts()
    const idx = list.findIndex((d) => d.id === id)
    if (idx === -1) throw new Error('الدين غير موجود')
    list[idx].status = 'approved'
    localStorage.setItem('mock_debts', JSON.stringify(list))
    return list[idx]
  }

  rejectDebt(id: string, reason: string): Debt {
    const list = this.getDebts()
    const idx = list.findIndex((d) => d.id === id)
    if (idx === -1) throw new Error('الدين غير موجود')
    list[idx].status = 'rejected'
    list[idx].rejection_reason = reason
    localStorage.setItem('mock_debts', JSON.stringify(list))
    return list[idx]
  }

  getPayments(): Payment[] {
    return JSON.parse(localStorage.getItem('mock_payments') || '[]')
  }

  createPayment(payment: Partial<Payment>): Payment {
    const list = this.getPayments()
    const newPayment: Payment = {
      id: 'p' + (list.length + 1),
      merchant_id: payment.merchant_id || 'm1',
      debt_id: payment.debt_id || 'd1',
      amount: payment.amount || 0,
      method: payment.method || 'mada',
      reference: 'TXN-' + Math.floor(10000000 + Math.random() * 90000000),
      status: 'completed',
      created_at: new Date().toISOString(),
    }
    list.unshift(newPayment)
    localStorage.setItem('mock_payments', JSON.stringify(list))

    // Update debt details
    const debts = this.getDebts()
    const debtIdx = debts.findIndex((d) => d.id === newPayment.debt_id)
    if (debtIdx !== -1) {
      const debt = debts[debtIdx]
      debt.paid_amount += newPayment.amount
      debt.remaining_amount = Math.max(0, debt.total_amount - debt.paid_amount)
      if (debt.remaining_amount === 0) {
        debt.status = 'settled'
      }
      localStorage.setItem('mock_debts', JSON.stringify(debts))

      // Update customer stats
      const customers = this.getCustomers()
      const custIdx = customers.findIndex((c) => c.id === debt.customer_id)
      if (custIdx !== -1) {
        customers[custIdx].paid_amount += newPayment.amount
        localStorage.setItem('mock_customers', JSON.stringify(customers))
      }
    }

    return newPayment
  }

  getPackages(): Package[] {
    return JSON.parse(localStorage.getItem('mock_packages') || '[]')
  }

  createPackage(pack: Partial<Package>): Package {
    const list = this.getPackages()
    const newPack: Package = {
      id: 'pk' + (list.length + 1),
      name: pack.name || 'باقة جديدة',
      price: pack.price || 0,
      interval: pack.interval || 'monthly',
      max_customers: pack.max_customers || 100,
      max_debts: pack.max_debts || 500,
      features: pack.features || [],
    }
    list.push(newPack)
    localStorage.setItem('mock_packages', JSON.stringify(list))
    return newPack
  }

  updatePackage(id: string, pack: Partial<Package>): Package {
    const list = this.getPackages()
    const idx = list.findIndex((p) => p.id === id)
    if (idx === -1) throw new Error('الباقة غير موجودة')
    const updated = { ...list[idx], ...pack }
    list[idx] = updated
    localStorage.setItem('mock_packages', JSON.stringify(list))
    return updated
  }

  getAuditLogs(): AuditLog[] {
    return JSON.parse(localStorage.getItem('mock_audit_logs') || '[]')
  }

  getSettings(): SystemSettings {
    return JSON.parse(localStorage.getItem('mock_settings') || '{}')
  }

  updateSettings(settings: Partial<SystemSettings>): SystemSettings {
    const current = this.getSettings()
    const updated = { ...current, ...settings }
    localStorage.setItem('mock_settings', JSON.stringify(updated))
    return updated
  }
}

const mockDb = new MockDatabase()
export const api = new ApiClient()
export default api
