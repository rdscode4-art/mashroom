import React, { useState, useEffect } from 'react';
import {
  Menu,
  LayoutDashboard,
  Users,
  ShoppingBag,
  PlusCircle,
  LogOut,
  ShieldCheck,
  ChevronRight,
  ChevronDown,
  DollarSign,
  TrendingUp,
  ShoppingCart,
  Plus,
  Trash2,
  MapPin,
  RefreshCw,
  Lock,
  Phone,
  CreditCard,
  Settings,
  UserCheck,
  Bike,
  MessageSquare,
  Gift,
  Image as ImageIcon,
  Check,
  X,
  FileText,
  Tag,
  Star,
  LifeBuoy,
  Bell
} from 'lucide-react';

const API_BASE = 'http://localhost:5000/api';

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [token, setToken] = useState(localStorage.getItem('admin_token') || '');
  const [adminUser, setAdminUser] = useState(JSON.parse(localStorage.getItem('admin_user') || 'null'));

  // Login form state
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');

  // Notification state
  const [alert, setAlert] = useState({ type: '', message: '' });
  const [loading, setLoading] = useState(false);

  // Data states
  const [statsData, setStatsData] = useState(null);
  const [vendors, setVendors] = useState([]);
  const [orders, setOrders] = useState([]);
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);

  // UI states
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedOrders, setExpandedOrders] = useState({});
  const [newCategoryName, setNewCategoryName] = useState('');
  const [newCategoryImg, setNewCategoryImg] = useState('');

  // Settings states
  const [settings, setSettings] = useState(null);
  const [settingsForm, setSettingsForm] = useState({
    deliveryCharge: 30,
    taxPercent: 5,
    minimumOrder: 0,
    supportNumber: '',
    appVersion: '1.0.0',
    appName: 'RiFresh',
    isMaintenanceMode: false,
    deliveryPartnerRadius: 2,
    deliveryBaseFare: 25,
    deliveryPerKmRate: 5
  });

  // Withdrawals states
  const [withdrawals, setWithdrawals] = useState([]);
  const [rejectionModalOpen, setRejectionModalOpen] = useState(false);
  const [rejectionId, setRejectionId] = useState('');
  const [rejectionReason, setRejectionReason] = useState('');

  // ── NEW CUSTOMERS & FLEETS STATE ──
  const [customers, setCustomers] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [driverKycModalOpen, setDriverKycModalOpen] = useState(false);
  const [selectedDriver, setSelectedDriver] = useState(null);
  const [driverRejectionModalOpen, setDriverRejectionModalOpen] = useState(false);
  const [driverRejectionId, setDriverRejectionId] = useState('');
  const [driverRejectionReason, setDriverRejectionReason] = useState('');

  // ── NEW REVIEWS STATE ──
  const [reviews, setReviews] = useState([]);

  // ── NEW SUPPORT TICKETS STATE ──
  const [supportTickets, setSupportTickets] = useState([]);

  // ── NEW COUPONS STATE ──
  const [coupons, setCoupons] = useState([]);
  const [newCouponCode, setNewCouponCode] = useState('');
  const [newCouponType, setNewCouponType] = useState('percentage');
  const [newCouponValue, setNewCouponValue] = useState(0);
  const [newCouponMinOrder, setNewCouponMinOrder] = useState(0);
  const [newCouponExpiry, setNewCouponExpiry] = useState('');

  // ── NEW BANNERS STATE ──
  const [banners, setBanners] = useState([]);
  const [newBannerTitle, setNewBannerTitle] = useState('');
  const [newBannerFile, setNewBannerFile] = useState(null);
  const [newBannerRedirectType, setNewBannerRedirectType] = useState('none');
  const [newBannerRedirectId, setNewBannerRedirectId] = useState('');

  // ── NEW OFFERS STATE ──
  const [offers, setOffers] = useState([]);
  const [newOfferTitle, setNewOfferTitle] = useState('');
  const [newOfferDiscountText, setNewOfferDiscountText] = useState('');
  const [newOfferDescription, setNewOfferDescription] = useState('');
  const [newOfferBadgeText, setNewOfferBadgeText] = useState('');
  const [newOfferFile, setNewOfferFile] = useState(null);

  // ── NEW NOTIFICATIONS STATE ──
  const [notifTarget, setNotifTarget] = useState('all');
  const [notifTitle, setNotifTitle] = useState('');
  const [notifBody, setNotifBody] = useState('');

  const showToast = (type, message) => {
    setAlert({ type, message });
    setTimeout(() => setAlert({ type: '', message: '' }), 4000);
  };

  const isAuthenticated = !!(token && adminUser && adminUser.role === 'admin');

  const apiCall = async (endpoint, options = {}) => {
    const isMultipart = options.body instanceof FormData;
    const headers = {
      ...(isMultipart ? {} : { 'Content-Type': 'application/json' }),
      ...(token ? { 'Authorization': `Bearer ${token}` } : {})
    };
    const response = await fetch(`${API_BASE}${endpoint}`, {
      ...options,
      headers: { ...headers, ...(options.headers || {}) }
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.message || 'Request failed');
    return data;
  };

  const refreshData = async () => {
    if (!isAuthenticated) return;
    setLoading(true);
    try {
      if (activeTab === 'dashboard') {
        const res = await apiCall('/admin/stats');
        setStatsData(res);
      } else if (activeTab === 'vendors') {
        const res = await apiCall('/admin/vendors');
        setVendors(res.vendors || []);
      } else if (activeTab === 'orders') {
        const res = await apiCall('/admin/orders');
        setOrders(res.orders || []);
      } else if (activeTab === 'products') {
        const res = await apiCall('/admin/products');
        setProducts(res.products || []);
      } else if (activeTab === 'categories') {
        const res = await apiCall('/categories');
        setCategories(res.categories || []);
      } else if (activeTab === 'withdrawals') {
        const res = await apiCall('/admin/withdrawals');
        setWithdrawals(res.withdrawals || []);
      } else if (activeTab === 'customers') {
        const res = await apiCall('/admin/customers');
        setCustomers(res.customers || []);
      } else if (activeTab === 'drivers') {
        const res = await apiCall('/admin/delivery-partners');
        setDrivers(res.partners || []);
      } else if (activeTab === 'reviews') {
        const res = await apiCall('/admin/reviews');
        setReviews(res.reviews || []);
      } else if (activeTab === 'coupons') {
        const res = await apiCall('/admin/coupons');
        setCoupons(res.coupons || []);
      } else if (activeTab === 'banners') {
        const bannerRes = await apiCall('/admin/banners');
        setBanners(bannerRes.banners || []);
        const offerRes = await apiCall('/offers/all');
        setOffers(offerRes.offers || []);
      } else if (activeTab === 'support') {
        const res = await apiCall('/admin/tickets');
        setSupportTickets(res.tickets || []);
      } else if (activeTab === 'settings') {
        const res = await apiCall('/admin/settings');
        setSettings(res.settings);
        setSettingsForm({
          deliveryCharge: res.settings?.deliveryCharge ?? 30,
          taxPercent: res.settings?.taxPercent ?? 5,
          minimumOrder: res.settings?.minimumOrder ?? 0,
          supportNumber: res.settings?.supportNumber ?? '',
          appVersion: res.settings?.appVersion ?? '1.0.0',
          appName: res.settings?.appName ?? 'RiFresh',
          isMaintenanceMode: res.settings?.isMaintenanceMode ?? false,
          deliveryPartnerRadius: res.settings?.deliveryPartnerRadius ?? 2,
          deliveryBaseFare: res.settings?.deliveryBaseFare ?? 25,
          deliveryPerKmRate: res.settings?.deliveryPerKmRate ?? 5
        });
      }
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { refreshData(); }, [activeTab, token]);

  // SECURE LOGIN — Phone + Password only
  const handleLogin = async (e) => {
    e.preventDefault();
    if (!phone || phone.length < 10) return showToast('warning', 'Enter a valid 10-digit phone number');
    if (!password) return showToast('warning', 'Password is required');
    setLoading(true);
    try {
      const res = await apiCall('/admin/login', {
        method: 'POST',
        body: JSON.stringify({ phone, password })
      });
      localStorage.setItem('admin_token', res.token);
      localStorage.setItem('admin_user', JSON.stringify(res.user));
      setToken(res.token);
      setAdminUser(res.user);
      showToast('success', 'Welcome to the Admin Panel!');
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    setToken('');
    setAdminUser(null);
    setPhone('');
    setPassword('');
  };

  // Vendor actions
  const handleVendorApproval = async (vendorId, approve) => {
    try {
      const res = await apiCall(`/admin/vendors/${vendorId}/approve`, {
        method: 'PUT',
        body: JSON.stringify({ isApproved: approve })
      });
      showToast('success', res.message);
      setVendors(v => v.map(x => x._id === vendorId ? { ...x, isApproved: approve } : x));
    } catch (err) { showToast('danger', err.message); }
  };

  // Order status update
  const handleUpdateOrderStatus = async (orderId, newStatus) => {
    try {
      await apiCall(`/admin/orders/${orderId}/status`, {
        method: 'PUT',
        body: JSON.stringify({ orderStatus: newStatus })
      });
      showToast('success', 'Order status updated');
      setOrders(o => o.map(x => x._id === orderId ? { ...x, orderStatus: newStatus } : x));
    } catch (err) { showToast('danger', err.message); }
  };

  // Delete product
  const handleDeleteProduct = async (productId) => {
    if (!window.confirm('Delete this product from the global catalog?')) return;
    try {
      const res = await apiCall(`/admin/products/${productId}`, { method: 'DELETE' });
      showToast('success', res.message);
      setProducts(p => p.filter(x => x._id !== productId));
    } catch (err) { showToast('danger', err.message); }
  };

  // Toggle Featured product
  const handleToggleFeatured = async (productId) => {
    try {
      const res = await apiCall(`/admin/products/${productId}/feature`, { method: 'PUT' });
      showToast('success', res.message);
      setProducts(p => p.map(x => x._id === productId ? { ...x, isFeatured: res.product.isFeatured } : x));
    } catch (err) { showToast('danger', err.message); }
  };

  // Add category
  const handleAddCategory = async (e) => {
    e.preventDefault();
    if (!newCategoryName) return showToast('warning', 'Category name is required');
    setLoading(true);
    try {
      const res = await apiCall('/admin/categories', {
        method: 'POST',
        body: JSON.stringify({ name: newCategoryName, image: newCategoryImg || '' })
      });
      showToast('success', res.message);
      setCategories(c => [...c, res.category]);
      setNewCategoryName('');
      setNewCategoryImg('');
    } catch (err) { showToast('danger', err.message); }
    finally { setLoading(false); }
  };

  // Delete category
  const handleDeleteCategory = async (catId) => {
    if (!window.confirm('Delete this category?')) return;
    try {
      const res = await apiCall(`/admin/categories/${catId}`, { method: 'DELETE' });
      showToast('success', res.message);
      setCategories(c => c.filter(x => x._id !== catId));
    } catch (err) { showToast('danger', err.message); }
  };

  const toggleOrderExpand = (id) => setExpandedOrders(prev => ({ ...prev, [id]: !prev[id] }));

  // Save app settings
  const handleSaveSettings = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await apiCall('/admin/settings', {
        method: 'PUT',
        body: JSON.stringify(settingsForm)
      });
      setSettings(res.settings);
      showToast('success', res.message || 'Settings saved successfully');
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  // Update support ticket status
  const handleUpdateTicketStatus = async (id, newStatus) => {
    setLoading(true);
    try {
      const res = await apiCall(`/admin/tickets/${id}/status`, {
        method: 'PUT',
        body: JSON.stringify({ status: newStatus })
      });
      showToast('success', res.message || 'Ticket status updated successfully');
      setSupportTickets(tickets => tickets.map(x => x._id === id ? { ...x, status: newStatus } : x));
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  // Approve withdrawal
  const handleApproveWithdrawal = async (id) => {
    if (!window.confirm('Are you sure you want to approve this withdrawal request?')) return;
    setLoading(true);
    try {
      const res = await apiCall(`/admin/withdrawals/${id}/approve`, { method: 'PUT' });
      showToast('success', res.message || 'Withdrawal approved successfully');
      setWithdrawals(w => w.map(x => x._id === id ? { ...x, status: 'approved' } : x));
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  // Reject withdrawal trigger
  const handleRejectClick = (id) => {
    setRejectionId(id);
    setRejectionReason('');
    setRejectionModalOpen(true);
  };

  // Reject withdrawal submit
  const handleRejectWithdrawalSubmit = async (e) => {
    e.preventDefault();
    if (!rejectionReason.trim()) return showToast('warning', 'Please provide a rejection reason');
    setLoading(true);
    setRejectionModalOpen(false);
    try {
      const res = await apiCall(`/admin/withdrawals/${rejectionId}/reject`, {
        method: 'PUT',
        body: JSON.stringify({ rejectionReason })
      });
      showToast('success', res.message || 'Withdrawal rejected and refunded');
      setWithdrawals(w => w.map(x => x._id === rejectionId ? { ...x, status: 'rejected', rejectionReason } : x));
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };
  // ── NEW CUSTOMERS & FLEETS OPERATIONS ──

  // Detailed KYC trigger
  const handleInspectKyc = (driver) => {
    setSelectedDriver(driver);
    setDriverKycModalOpen(true);
  };

  // Approve driver KYC
  const handleApproveKyc = async (driverId) => {
    if (!window.confirm('Approve this driver KYC credentials and activate them?')) return;
    setLoading(true);
    try {
      const res = await apiCall(`/admin/delivery-partners/${driverId}/kyc`, {
        method: 'PUT',
        body: JSON.stringify({ status: 'approved' })
      });
      showToast('success', res.message || 'Driver approved successfully!');
      setDrivers(d => d.map(x => x._id === driverId ? { ...x, kycStatus: 'approved', isApproved: true, kycRejectionReason: '' } : x));
      setDriverKycModalOpen(false);
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  // Reject driver KYC trigger
  const handleRejectKycClick = (driverId) => {
    setDriverRejectionId(driverId);
    setDriverRejectionReason('');
    setDriverRejectionModalOpen(true);
  };

  // Reject driver KYC submit
  const handleRejectKycSubmit = async (e) => {
    e.preventDefault();
    if (!driverRejectionReason.trim()) return showToast('warning', 'Please specify a rejection reason');
    setLoading(true);
    setDriverRejectionModalOpen(false);
    try {
      const res = await apiCall(`/admin/delivery-partners/${driverRejectionId}/kyc`, {
        method: 'PUT',
        body: JSON.stringify({ status: 'rejected', rejectionReason: driverRejectionReason })
      });
      showToast('success', res.message || 'Driver KYC credentials rejected');
      setDrivers(d => d.map(x => x._id === driverRejectionId ? { ...x, kycStatus: 'rejected', isApproved: false, kycRejectionReason: driverRejectionReason } : x));
      setDriverKycModalOpen(false);
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  // ── NEW REVIEWS OPERATIONS ──
  const handleDeleteReview = async (id) => {
    if (!window.confirm('Delete this product review permanently?')) return;
    try {
      const res = await apiCall(`/admin/reviews/${id}`, { method: 'DELETE' });
      showToast('success', res.message || 'Review deleted successfully');
      setReviews(r => r.filter(x => x._id !== id));
    } catch (err) {
      showToast('danger', err.message);
    }
  };

  // ── NEW COUPONS OPERATIONS ──
  const handleAddCoupon = async (e) => {
    e.preventDefault();
    if (!newCouponCode) return showToast('warning', 'Coupon code is required');
    if (newCouponValue <= 0) return showToast('warning', 'Discount value must be greater than zero');
    setLoading(true);
    try {
      const res = await apiCall('/admin/coupons', {
        method: 'POST',
        body: JSON.stringify({
          code: newCouponCode.toUpperCase().trim(),
          discountType: newCouponType,
          discountValue: parseFloat(newCouponValue),
          minimumOrder: parseFloat(newCouponMinOrder),
          expiryDate: newCouponExpiry || undefined
        })
      });
      showToast('success', res.message || 'Coupon generated!');
      setCoupons(c => [res.coupon, ...c]);
      setNewCouponCode('');
      setNewCouponValue(0);
      setNewCouponMinOrder(0);
      setNewCouponExpiry('');
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteCoupon = async (id) => {
    if (!window.confirm('Revoke and delete this coupon code permanently?')) return;
    try {
      const res = await apiCall(`/admin/coupons/${id}`, { method: 'DELETE' });
      showToast('success', res.message || 'Coupon deleted successfully');
      setCoupons(c => c.filter(x => x._id !== id));
    } catch (err) {
      showToast('danger', err.message);
    }
  };

  // ── NEW BANNERS OPERATIONS ──
  const handleToggleBanner = async (id) => {
    try {
      const res = await apiCall(`/admin/banners/${id}/toggle`, { method: 'PUT' });
      showToast('success', res.message || 'Banner status toggled');
      setBanners(b => b.map(x => x._id === id ? { ...x, isActive: res.banner.isActive } : x));
    } catch (err) {
      showToast('danger', err.message);
    }
  };

  const handleDeleteBanner = async (id) => {
    if (!window.confirm('Delete this banner promotional flyer permanently?')) return;
    try {
      const res = await apiCall(`/admin/banners/${id}`, { method: 'DELETE' });
      showToast('success', res.message || 'Banner deleted successfully');
      setBanners(b => b.filter(x => x._id !== id));
    } catch (err) {
      showToast('danger', err.message);
    }
  };

  const handleAddBanner = async (e) => {
    e.preventDefault();
    if (!newBannerFile) return showToast('warning', 'Banner image file is required');
    setLoading(true);

    try {
      const formData = new FormData();
      formData.append('title', newBannerTitle.trim());
      formData.append('image', newBannerFile);
      formData.append('redirectType', newBannerRedirectType);
      formData.append('redirectId', newBannerRedirectId.trim());

      const res = await apiCall('/admin/banners', {
        method: 'POST',
        body: formData
      });
      showToast('success', res.message || 'Banner published successfully!');
      setBanners(b => [res.banner, ...b]);
      setNewBannerTitle('');
      setNewBannerFile(null);
      setNewBannerRedirectType('none');
      setNewBannerRedirectId('');
      const fileInput = document.getElementById('banner-file-input');
      if (fileInput) fileInput.value = '';
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  // ── NEW OFFERS OPERATIONS ──
  const handleToggleOffer = async (id) => {
    try {
      const res = await apiCall(`/offers/${id}/toggle`, { method: 'PUT' });
      showToast('success', res.message || 'Offer status toggled');
      setOffers(o => o.map(x => x._id === id ? { ...x, isActive: res.offer.isActive } : x));
    } catch (err) {
      showToast('danger', err.message);
    }
  };

  const handleDeleteOffer = async (id) => {
    if (!window.confirm('Delete this special offer permanently?')) return;
    try {
      const res = await apiCall(`/offers/${id}`, { method: 'DELETE' });
      showToast('success', res.message || 'Offer deleted successfully');
      setOffers(o => o.filter(x => x._id !== id));
    } catch (err) {
      showToast('danger', err.message);
    }
  };

  const handleAddOffer = async (e) => {
    e.preventDefault();
    if (!newOfferTitle.trim() || !newOfferDiscountText.trim() || !newOfferDescription.trim() || !newOfferBadgeText.trim()) {
      return showToast('warning', 'All text fields are required for the offer');
    }
    setLoading(true);

    try {
      const formData = new FormData();
      formData.append('title', newOfferTitle.trim());
      formData.append('discountText', newOfferDiscountText.trim());
      formData.append('description', newOfferDescription.trim());
      formData.append('badgeText', newOfferBadgeText.trim());
      if (newOfferFile) {
        formData.append('image', newOfferFile);
      }

      const res = await apiCall('/offers', {
        method: 'POST',
        body: formData
      });
      showToast('success', res.message || 'Special offer created successfully!');
      setOffers(o => [res.offer, ...o]);
      setNewOfferTitle('');
      setNewOfferDiscountText('');
      setNewOfferDescription('');
      setNewOfferBadgeText('');
      setNewOfferFile(null);
      const fileInput = document.getElementById('offer-file-input');
      if (fileInput) fileInput.value = '';
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  // ── NOTIFICATION HANDLER ──
  const handleSendNotification = async (e) => {
    e.preventDefault();
    if (!notifTitle || !notifBody) return showToast('warning', 'Title and body are required');
    setLoading(true);
    try {
      const res = await apiCall('/admin/send-notification', {
        method: 'POST',
        body: JSON.stringify({ target: notifTarget, title: notifTitle, body: notifBody })
      });
      showToast('success', res.message || 'Notification sent!');
      setNotifTitle('');
      setNotifBody('');
    } catch (err) {
      showToast('danger', err.message);
    } finally {
      setLoading(false);
    }
  };

  // Toast Component
  const Toast = () => alert.message ? (
    <div style={{
      position: 'fixed', top: '20px', right: '20px', zIndex: 9999,
      padding: '14px 20px', borderRadius: '12px', color: 'white',
      fontWeight: '600', fontSize: '14px', boxShadow: '0 4px 20px rgba(0,0,0,0.4)',
      backgroundColor: alert.type === 'success' ? '#10b981' : alert.type === 'warning' ? '#f59e0b' : '#ef4444',
      maxWidth: '360px', lineHeight: '1.4'
    }}>
      {alert.message}
    </div>
  ) : null;

  // ─────────────────────────────────────────────
  // LOGIN SCREEN
  // ─────────────────────────────────────────────
  if (!isAuthenticated) {
    return (
      <div className="login-container">
        <Toast />
        <div className="login-card glass-panel">
          <div className="login-header">
            <div style={{
              display: 'inline-flex', padding: '18px',
              background: 'var(--primary-glow)', color: 'var(--primary)',
              borderRadius: '50%', marginBottom: '8px'
            }}>
              <ShieldCheck size={40} />
            </div>
            <h1 className="login-title">RiFresh Admin</h1>
            <p className="login-subtitle">Secure administration portal — authorized access only</p>
          </div>

          <form onSubmit={handleLogin}>
            <div className="form-group">
              <label className="form-label">Admin Phone Number</label>
              <div style={{ position: 'relative' }}>
                <span style={{
                  position: 'absolute', left: '14px', top: '50%',
                  transform: 'translateY(-50%)', color: 'var(--text-muted)'
                }}>
                  <Phone size={16} />
                </span>
                <input
                  type="tel"
                  placeholder="10-digit registered number"
                  className="input-field"
                  style={{ paddingLeft: '40px' }}
                  value={phone}
                  onChange={e => setPhone(e.target.value.replace(/\D/g, '').slice(0, 10))}
                  disabled={loading}
                  autoComplete="off"
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Admin Password</label>
              <div style={{ position: 'relative' }}>
                <span style={{
                  position: 'absolute', left: '14px', top: '50%',
                  transform: 'translateY(-50%)', color: 'var(--text-muted)'
                }}>
                  <Lock size={16} />
                </span>
                <input
                  type="password"
                  placeholder="Enter your admin password"
                  className="input-field"
                  style={{ paddingLeft: '40px' }}
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  disabled={loading}
                  autoComplete="current-password"
                />
              </div>
            </div>

            <button type="submit" className="btn btn-primary" disabled={loading}>
              {loading ? 'Authenticating...' : 'Login to Admin Panel'}
            </button>
          </form>

          <p style={{
            textAlign: 'center', marginTop: '24px', fontSize: '12px',
            color: 'var(--text-muted)', lineHeight: '1.6'
          }}>
            🔒 This portal is restricted to authorized administrators only.<br />
            Unauthorized access attempts are logged and monitored.
          </p>
        </div>
      </div>
    );
  }

  // ─────────────────────────────────────────────
  // MAIN DASHBOARD LAYOUT
  // ─────────────────────────────────────────────
  return (
    <div className="app-container">
      <Toast />

      {/* SIDEBAR OVERLAY */}
        {mobileMenuOpen && (
          <div className="mobile-overlay" onClick={() => setMobileMenuOpen(false)}></div>
        )}
        {/* SIDEBAR */}
      <aside className={`sidebar ${mobileMenuOpen ? "mobile-open" : ""}`}>
        <div className="sidebar-brand">
          <div className="sidebar-logo">
            <ShieldCheck size={26} />
            <span>RiFresh Admin</span>
          </div>
        </div>

        <ul className="sidebar-menu">
          {[
            { id: 'dashboard',   icon: <LayoutDashboard size={20} />, label: 'Dashboard' },
            { id: 'vendors',     icon: <Users size={20} />,           label: 'Vendors' },
            { id: 'orders',      icon: <ShoppingCart size={20} />,    label: 'Orders' },
            { id: 'products',    icon: <ShoppingBag size={20} />,     label: 'Products' },
            { id: 'categories',  icon: <PlusCircle size={20} />,      label: 'Categories' },
            { id: 'customers',   icon: <UserCheck size={20} />,       label: 'Customers' },
            { id: 'drivers',     icon: <Bike size={20} />,            label: 'Drivers' },
            { id: 'withdrawals', icon: <CreditCard size={20} />,      label: 'Withdrawals' },
            { id: 'reviews',     icon: <MessageSquare size={20} />,   label: 'Reviews' },
            { id: 'support',     icon: <LifeBuoy size={20} />,        label: 'Support Tickets' },
            { id: 'coupons',     icon: <Gift size={20} />,            label: 'Coupons' },
            { id: 'banners',     icon: <ImageIcon size={20} />,          label: 'Banners & Offers' },
            { id: 'notifications',icon: <Bell size={20} />,           label: 'Push Notifications' },
            { id: 'settings',    icon: <Settings size={20} />,        label: 'Settings' },
          ].map(item => (
            <li key={item.id}>
              <div
                className={`sidebar-item ${activeTab === item.id ? 'active' : ''}`}
                onClick={() => { setActiveTab(item.id); setSearchQuery(''); setMobileMenuOpen(false); }}
              >
                {item.icon}
                <span>{item.label}</span>
              </div>
            </li>
          ))}
        </ul>

        <div className="sidebar-profile">
          <div className="avatar">
            {(adminUser?.name || 'A').charAt(0).toUpperCase()}
          </div>
          <div className="profile-info">
            <div className="profile-name">{adminUser?.name || 'Administrator'}</div>
            <div className="profile-role">{adminUser?.phone}</div>
          </div>
          <button className="logout-btn" onClick={handleLogout} title="Log Out">
            <LogOut size={20} />
          </button>
        </div>
      </aside>

      {/* MAIN CONTENT */}
      <main className="main-wrapper">
        <header className="top-bar">
            <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
              <button className="mobile-menu-btn" onClick={() => setMobileMenuOpen(true)}>
                <Menu size={24} />
              </button>
              <h1 className="page-title" style={{ textTransform: 'capitalize' }}>
  
            {activeTab === 'dashboard' ? 'Dashboard Overview' :
             activeTab === 'vendors' ? 'Vendor Management' :
             activeTab === 'orders' ? 'Order Processing' :
             activeTab === 'products' ? 'Product Catalog' :
             activeTab === 'categories' ? 'Category Manager' :
             activeTab === 'withdrawals' ? 'Driver Withdrawals' :
             activeTab === 'customers' ? 'Customer Directory' :
             activeTab === 'drivers' ? 'Driver KYC & Fleets' :
             activeTab === 'reviews' ? 'Product Reviews' :
             activeTab === 'support' ? 'Driver Support Tickets' :
             activeTab === 'coupons' ? 'Discount Coupons' :
             activeTab === 'banners' ? 'App Banners & Offers' :
             activeTab === 'notifications' ? 'Push Notifications' : 'App Settings'}
          
              </h1>
            </div>
          <div className="top-actions">
            <button
              onClick={refreshData}
              className="btn btn-outline"
              style={{ padding: '8px 14px', width: 'auto', fontSize: '13px', gap: '6px' }}
              disabled={loading}
            >
              <RefreshCw size={14} style={loading ? { animation: 'spin 1s linear infinite' } : {}} />
              Refresh
            </button>
            <div className="live-indicator">
              <span className="pulse-dot"></span>
              Live
            </div>
          </div>
        </header>

        <div className="content-container">
          {loading && (
            <div className="spinner-container" style={{ minHeight: '400px' }}>
              <div className="spinner"></div>
              <p style={{ color: 'var(--text-secondary)', marginTop: '12px' }}>Loading data...</p>
            </div>
          )}

          {!loading && (
            <>
              {/* ── NOTIFICATIONS ── */}
              {activeTab === 'notifications' && (
                <div className="glass-card">
                  <h2 className="section-title" style={{ marginBottom: '20px' }}>Broadcast Push Notification</h2>
                  <form onSubmit={handleSendNotification} style={{ maxWidth: '600px' }}>
                    <div className="form-group">
                      <label className="form-label">Target Audience</label>
                      <select className="input-field" value={notifTarget} onChange={e => setNotifTarget(e.target.value)} disabled={loading}>
                        <option value="all">All Users (Customers & Drivers)</option>
                        <option value="customers">Customers Only</option>
                        <option value="drivers">Delivery Drivers Only</option>
                      </select>
                    </div>
                    <div className="form-group">
                      <label className="form-label">Notification Title</label>
                      <input type="text" className="input-field" placeholder="e.g. Special Offer Today!" value={notifTitle} onChange={e => setNotifTitle(e.target.value)} disabled={loading} />
                    </div>
                    <div className="form-group">
                      <label className="form-label">Notification Message</label>
                      <textarea className="input-field" placeholder="Type your message here..." rows="4" value={notifBody} onChange={e => setNotifBody(e.target.value)} disabled={loading} style={{ resize: 'vertical' }}></textarea>
                    </div>
                    <button type="submit" className="btn btn-primary" style={{ display: 'inline-flex', alignItems: 'center', gap: '8px' }} disabled={loading}>
                      <Bell size={16} /> {loading ? 'Sending...' : 'Send Push Notification'}
                    </button>
                  </form>
                </div>
              )}

              {/* ── DASHBOARD ── */}
              {activeTab === 'dashboard' && statsData && (
                <div>
                  <div className="stats-grid">
                    {[
                      { label: 'Total Revenue', value: `₹${(statsData.stats?.totalRevenue || 0).toLocaleString('en-IN')}`, icon: <DollarSign size={22}/>, color: '#10b981', bg: 'rgba(16,185,129,0.1)', sub: 'From delivered orders' },
                      { label: 'Total Orders', value: statsData.stats?.totalOrders || 0, icon: <ShoppingCart size={22}/>, color: '#6366f1', bg: 'rgba(99,102,241,0.1)', sub: 'All customer placements' },
                      { label: 'Active Vendors', value: statsData.stats?.totalVendors || 0, icon: <Users size={22}/>, color: '#f59e0b', bg: 'rgba(245,158,11,0.1)', sub: 'Registered farmers' },
                      { label: 'Products Listed', value: statsData.stats?.totalProducts || 0, icon: <ShoppingBag size={22}/>, color: '#3b82f6', bg: 'rgba(59,130,246,0.1)', sub: 'Live catalog size' },
                    ].map((s, i) => (
                      <div className="glass-card" key={i}>
                        <div className="stat-icon" style={{ background: s.bg, color: s.color }}>{s.icon}</div>
                        <div className="stat-value">{s.value}</div>
                        <div className="stat-label">{s.label}</div>
                        <div style={{ fontSize: '11px', color: s.color, marginTop: '6px', fontWeight: 600 }}>{s.sub}</div>
                      </div>
                    ))}
                  </div>

                  <div className="dashboard-grid">
                    {/* SVG Donut Chart */}
                    <div className="glass-card">
                      <div className="section-header">
                        <h2 className="section-title">Order Status Distribution</h2>
                      </div>
                      <div className="chart-container" style={{ flexDirection: 'row', gap: '32px', justifyContent: 'flex-start', padding: '8px 20px' }}>
                        {(() => {
                          const dist = statsData.stats?.orderStatusDistribution || {};
                          const total = Object.values(dist).reduce((a, b) => a + b, 0) || 1;
                          const segments = [
                            { percent: ((dist.delivered||0)/total)*100, color: '#10b981', label: 'Delivered', val: dist.delivered||0 },
                            { percent: ((dist.pending||0)/total)*100,   color: '#f59e0b', label: 'Pending',   val: dist.pending||0 },
                            { percent: (((dist.accepted||0)+(dist.packed||0)+(dist.out_for_delivery||0))/total)*100, color: '#3b82f6', label: 'Processing', val: (dist.accepted||0)+(dist.packed||0)+(dist.out_for_delivery||0) },
                            { percent: ((dist.cancelled||0)/total)*100, color: '#ef4444', label: 'Cancelled', val: dist.cancelled||0 },
                          ];
                          let offset = 0;
                          return (
                            <>
                              <svg width="180" height="180" viewBox="0 0 42 42" style={{ transform: 'rotate(-90deg)', flexShrink: 0 }}>
                                <circle cx="21" cy="21" r="15.9" fill="transparent" stroke="rgba(255,255,255,0.03)" strokeWidth="5"/>
                                {segments.map((seg, idx) => {
                                  if (seg.percent === 0) return null;
                                  const dash = `${seg.percent} ${100 - seg.percent}`;
                                  const off = 100 - offset;
                                  offset += seg.percent;
                                  return <circle key={idx} cx="21" cy="21" r="15.9" fill="transparent" stroke={seg.color} strokeWidth="5" strokeDasharray={dash} strokeDashoffset={off}/>;
                                })}
                                <text x="21" y="22" textAnchor="middle" fill="white" fontSize="5" fontWeight="bold" style={{ transform: 'rotate(90deg)', transformOrigin: '50% 50%' }}>{total}</text>
                              </svg>
                              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', justifyContent: 'center' }}>
                                {segments.map((s, i) => (
                                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '13px' }}>
                                    <span style={{ width: '10px', height: '10px', borderRadius: '50%', background: s.color, flexShrink: 0 }}/>
                                    <span style={{ color: 'var(--text-secondary)' }}>{s.label}</span>
                                    <strong style={{ color: 'white', marginLeft: 'auto' }}>{s.val} <span style={{ color: 'var(--text-muted)', fontWeight: 400 }}>({Math.round((s.val/total)*100)}%)</span></strong>
                                  </div>
                                ))}
                              </div>
                            </>
                          );
                        })()}
                      </div>
                    </div>

                    {/* Recent vendor applications */}
                    <div className="glass-card">
                      <div className="section-header">
                        <h2 className="section-title">Recent Vendors</h2>
                      </div>
                      <div className="activity-list">
                        {!statsData.recentVendors?.length
                          ? <div className="no-data-card">No vendor applications yet</div>
                          : statsData.recentVendors.map(v => (
                            <div className="activity-item" key={v._id}>
                              <div className="activity-meta">
                                <div className="avatar" style={{ width: '32px', height: '32px', fontSize: '12px' }}>
                                  {(v.shopName||'S').charAt(0).toUpperCase()}
                                </div>
                                <div className="activity-details">
                                  <span className="activity-title">{v.shopName}</span>
                                  <span className="activity-subtitle">{v.ownerName} • {v.phone}</span>
                                </div>
                              </div>
                              <span className={`badge ${v.isApproved ? 'badge-success' : 'badge-warning'}`}>
                                {v.isApproved ? 'Approved' : 'Pending'}
                              </span>
                            </div>
                          ))
                        }
                      </div>
                    </div>
                  </div>

                  {/* Recent orders table */}
                  <div className="glass-card" style={{ marginTop: '0' }}>
                    <div className="section-header">
                      <h2 className="section-title">Recent Orders</h2>
                      <button onClick={() => setActiveTab('orders')} className="btn btn-outline" style={{ width: 'auto', padding: '6px 14px', fontSize: '13px' }}>
                        View All
                      </button>
                    </div>
                    <div className="data-table-container">
                      <table className="data-table">
                        <thead>
                          <tr>
                            <th>Order ID</th><th>Customer</th><th>Shop</th><th>Amount</th><th>Payment</th><th>Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          {!statsData.recentOrders?.length
                            ? <tr><td colSpan="6" style={{ color: 'var(--text-secondary)', padding: '24px', textAlign: 'center' }}>No orders yet</td></tr>
                            : statsData.recentOrders.map(o => (
                              <tr key={o._id}>
                                <td style={{ fontFamily: 'monospace', color: 'var(--text-secondary)', fontSize: '12px' }}>#{o._id.slice(-6).toUpperCase()}</td>
                                <td>{o.customerId?.name || '—'}</td>
                                <td>{o.vendorId?.shopName || '—'}</td>
                                <td style={{ fontWeight: 700, color: 'var(--primary)' }}>₹{o.totalAmount}</td>
                                <td><span className="badge badge-info" style={{ fontSize: '11px' }}>{o.paymentMethod}</span></td>
                                <td>
                                  <span className={`badge ${o.orderStatus === 'delivered' ? 'badge-success' : o.orderStatus === 'cancelled' ? 'badge-danger' : 'badge-warning'}`}>
                                    {o.orderStatus}
                                  </span>
                                </td>
                              </tr>
                            ))
                          }
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              )}

              {/* ── VENDORS ── */}
              {activeTab === 'vendors' && (
                <div className="glass-card">
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                    <h2 className="section-title">Vendor Directory ({vendors.length})</h2>
                    <input type="text" placeholder="Search shops or owners..." className="input-field" style={{ maxWidth: '320px' }} value={searchQuery} onChange={e => setSearchQuery(e.target.value)} />
                  </div>
                  <div className="data-table-container">
                    <table className="data-table">
                      <thead>
                        <tr><th>Shop</th><th>Owner</th><th>Phone</th><th>Radius</th><th>Rating</th><th>Status</th><th>Actions</th></tr>
                      </thead>
                      <tbody>
                        {vendors
                          .filter(v => v.shopName?.toLowerCase().includes(searchQuery.toLowerCase()) || v.ownerName?.toLowerCase().includes(searchQuery.toLowerCase()) || v.phone?.includes(searchQuery))
                          .map(v => (
                            <tr key={v._id}>
                              <td style={{ fontWeight: 700, color: 'white' }}>{v.shopName}</td>
                              <td>{v.ownerName}</td>
                              <td style={{ fontFamily: 'monospace' }}>{v.phone}</td>
                              <td>{v.serviceRadius || 10} km</td>
                              <td>⭐ {v.rating || 0}</td>
                              <td>
                                <span className={`badge ${v.isApproved ? 'badge-success' : 'badge-warning'}`}>
                                  {v.isApproved ? 'Approved' : 'Pending'}
                                </span>
                              </td>
                              <td>
                                {!v.isApproved
                                  ? <button onClick={() => handleVendorApproval(v._id, true)} className="btn btn-primary" style={{ width: 'auto', padding: '6px 12px', fontSize: '12px' }}>Approve</button>
                                  : <button onClick={() => handleVendorApproval(v._id, false)} className="btn btn-danger" style={{ width: 'auto', padding: '6px 12px', fontSize: '12px' }}>Suspend</button>
                                }
                              </td>
                            </tr>
                          ))
                        }
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* ── ORDERS ── */}
              {activeTab === 'orders' && (
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                    <h2 className="section-title">All Orders ({orders.length})</h2>
                    <input type="text" placeholder="Search by customer or order ID..." className="input-field" style={{ maxWidth: '320px' }} value={searchQuery} onChange={e => setSearchQuery(e.target.value)} />
                  </div>
                  {orders
                    .filter(o => o._id.includes(searchQuery) || o.customerId?.name?.toLowerCase().includes(searchQuery.toLowerCase()) || o.customerId?.phone?.includes(searchQuery))
                    .map(o => {
                      const expanded = !!expandedOrders[o._id];
                      return (
                        <div className={`order-card ${expanded ? 'expanded' : ''}`} key={o._id}>
                          <div className="order-header-row" onClick={() => toggleOrderExpand(o._id)}>
                            <div className="order-brief">
                              <div>
                                <span style={{ fontSize: '10px', color: 'var(--text-secondary)', display: 'block', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.5px' }}>Order ID</span>
                                <strong style={{ fontFamily: 'monospace', fontSize: '13px' }}>#{o._id.slice(-8).toUpperCase()}</strong>
                              </div>
                              <div>
                                <span style={{ fontSize: '10px', color: 'var(--text-secondary)', display: 'block', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.5px' }}>Customer</span>
                                <span>{o.customerId?.name || '—'} · {o.customerId?.phone}</span>
                              </div>
                              <div>
                                <span style={{ fontSize: '10px', color: 'var(--text-secondary)', display: 'block', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.5px' }}>Store</span>
                                <span>{o.vendorId?.shopName || '—'}</span>
                              </div>
                              <div>
                                <span style={{ fontSize: '10px', color: 'var(--text-secondary)', display: 'block', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.5px' }}>Total</span>
                                <strong style={{ color: 'var(--primary)' }}>₹{o.totalAmount}</strong>
                              </div>
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                              <span className={`badge ${o.orderStatus === 'delivered' ? 'badge-success' : o.orderStatus === 'cancelled' ? 'badge-danger' : 'badge-warning'}`}>
                                {o.orderStatus}
                              </span>
                              {expanded ? <ChevronDown size={16}/> : <ChevronRight size={16}/>}
                            </div>
                          </div>

                          {expanded && (
                            <div className="order-details-block">
                              <div>
                                <h4 className="form-label" style={{ marginBottom: '12px' }}>Items</h4>
                                <div className="order-products-list">
                                  {o.products?.map((item, idx) => (
                                    <div className="order-product-row" key={idx}>
                                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                        {item.productId?.images?.[0] && (
                                          <img src={item.productId.images[0].startsWith('http') ? item.productId.images[0] : `http://localhost:5000/${item.productId.images[0]}`}
                                            alt="" style={{ width: '38px', height: '38px', borderRadius: '6px', objectFit: 'cover' }} />
                                        )}
                                        <div>
                                          <strong style={{ fontSize: '13px' }}>{item.productId?.productName || 'Deleted Product'}</strong>
                                          <span style={{ display: 'block', fontSize: '11px', color: 'var(--text-secondary)' }}>{item.productId?.weight} {item.productId?.unit}</span>
                                        </div>
                                      </div>
                                      <div style={{ textAlign: 'right' }}>
                                        <span style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>₹{item.price} × {item.quantity}</span>
                                        <strong style={{ display: 'block' }}>₹{item.price * item.quantity}</strong>
                                      </div>
                                    </div>
                                  ))}
                                </div>
                                <div style={{ marginTop: '16px', display: 'flex', gap: '8px', alignItems: 'flex-start' }}>
                                  <MapPin size={15} style={{ color: '#ef4444', flexShrink: 0, marginTop: '2px' }} />
                                  <span style={{ fontSize: '13px', lineHeight: '1.5' }}>{o.deliveryAddress?.fullAddress || 'No address'}</span>
                                </div>
                              </div>

                              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                                <div className="order-actions-box">
                                  <span className="address-label">Update Status</span>
                                  <select value={o.orderStatus} onChange={e => handleUpdateOrderStatus(o._id, e.target.value)} className="order-status-select">
                                    <option value="pending">Pending</option>
                                    <option value="accepted">Accepted</option>
                                    <option value="packed">Packed</option>
                                    <option value="ready_for_pickup">Ready for Pickup (Assigning...)</option>
                                    <option value="out_for_delivery">Out for Delivery</option>
                                    <option value="delivered">Delivered</option>
                                    <option value="cancelled">Cancelled</option>
                                  </select>
                                </div>
                                <div className="order-actions-box">
                                  <span className="address-label">Payment Info</span>
                                  <div style={{ fontSize: '13px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                      <span>Method</span><strong style={{ textTransform: 'uppercase' }}>{o.paymentMethod}</strong>
                                    </div>
                                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                      <span>Status</span>
                                      <span className={`badge ${o.paymentStatus === 'paid' ? 'badge-success' : 'badge-warning'}`} style={{ fontSize: '10px', padding: '2px 8px' }}>{o.paymentStatus}</span>
                                    </div>
                                    <div style={{ borderTop: '1px solid var(--border)', paddingTop: '8px', display: 'flex', justifyContent: 'space-between', fontWeight: 700, color: 'white' }}>
                                      <span>Total</span><span>₹{o.totalAmount}</span>
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })
                  }
                  {orders.length === 0 && <div className="no-data-card">No orders in system yet</div>}
                </div>
              )}

              {/* ── PRODUCTS ── */}
              {activeTab === 'products' && (
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                    <h2 className="section-title">Product Catalog ({products.length})</h2>
                    <input type="text" placeholder="Search products..." className="input-field" style={{ maxWidth: '320px' }} value={searchQuery} onChange={e => setSearchQuery(e.target.value)} />
                  </div>
                  <div className="catalog-grid">
                    {products
                      .filter(p => p.productName?.toLowerCase().includes(searchQuery.toLowerCase()))
                      .map(p => (
                        <div className="glass-card product-card" key={p._id}>
                          <div className="product-img-wrapper">
                            {p.images?.[0]
                              ? <img src={p.images[0].startsWith('http') ? p.images[0] : `http://localhost:5000/${p.images[0]}`} alt={p.productName} className="product-img" />
                              : <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)', fontSize: '13px' }}>No Image</div>
                            }
                            <span className={`badge product-badge ${p.isAvailable ? 'badge-success' : 'badge-danger'}`}>
                              {p.isAvailable ? 'In Stock' : 'Out of Stock'}
                            </span>
                          </div>
                          <div className="product-info">
                            <span className="product-vendor">{p.vendorId?.shopName || 'Unknown Shop'}</span>
                            <h3 className="product-name">{p.productName}</h3>
                            <div className="product-prices">
                              <span className="selling-price">₹{p.sellingPrice}</span>
                              {p.mrpPrice > p.sellingPrice && <span className="mrp-price">₹{p.mrpPrice}</span>}
                            </div>
                            <div className="product-meta">
                              <span>{p.categoryId?.name || 'Uncategorized'}</span>
                              <span>{p.weight} {p.unit}</span>
                            </div>
                            <div className="product-actions" style={{ display: 'flex', gap: '8px' }}>
                              <button onClick={() => handleToggleFeatured(p._id)} className={`btn ${p.isFeatured ? 'btn-success' : 'btn-outline'}`} style={{ padding: '8px', fontSize: '13px', gap: '6px', flex: 1 }}>
                                <Star size={14} fill={p.isFeatured ? "currentColor" : "none"}/> {p.isFeatured ? 'Featured' : 'Feature'}
                              </button>
                              <button onClick={() => handleDeleteProduct(p._id)} className="btn btn-danger" style={{ padding: '8px', fontSize: '13px', gap: '6px', flex: 1 }}>
                                <Trash2 size={14}/> Delete
                              </button>
                            </div>
                          </div>
                        </div>
                      ))
                    }
                    {products.length === 0 && <div className="no-data-card" style={{ gridColumn: '1/-1' }}>No products in catalog</div>}
                  </div>
                </div>
              )}

              {/* ── CATEGORIES ── */}
              {activeTab === 'categories' && (
                <div className="category-manager-layout">
                  <div className="glass-card">
                    <h3 className="section-title" style={{ marginBottom: '20px' }}>Add New Category</h3>
                    <form onSubmit={handleAddCategory}>
                      <div className="form-group">
                        <label className="form-label">Category Name</label>
                        <input type="text" placeholder="e.g. Fresh Mushrooms" className="input-field" value={newCategoryName} onChange={e => setNewCategoryName(e.target.value)} disabled={loading} />
                      </div>
                      <div className="form-group">
                        <label className="form-label">Image URL (Optional)</label>
                        <input type="url" placeholder="https://..." className="input-field" value={newCategoryImg} onChange={e => setNewCategoryImg(e.target.value)} disabled={loading} />
                      </div>
                      <button type="submit" className="btn btn-primary" disabled={loading}>
                        <Plus size={16}/> {loading ? 'Creating...' : 'Create Category'}
                      </button>
                    </form>
                  </div>

                  <div className="glass-card">
                    <h3 className="section-title" style={{ marginBottom: '20px' }}>All Categories ({categories.length})</h3>
                    <div className="data-table-container">
                      <table className="data-table">
                        <thead>
                          <tr><th>Image</th><th>Name</th><th>Status</th><th>Delete</th></tr>
                        </thead>
                        <tbody>
                          {categories.length === 0
                            ? <tr><td colSpan="4" style={{ color: 'var(--text-secondary)', textAlign: 'center', padding: '24px' }}>No categories</td></tr>
                            : categories.map(c => (
                              <tr key={c._id}>
                                <td>
                                  {c.image
                                    ? <img src={c.image.startsWith('http') ? c.image : `http://localhost:5000/${c.image}`} alt={c.name} className="category-row-img" />
                                    : <div className="category-row-img" style={{ background: '#1e2230', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', color: 'var(--text-muted)' }}>—</div>
                                  }
                                </td>
                                <td style={{ fontWeight: 600, color: 'white' }}>{c.name}</td>
                                <td><span className="badge badge-success">Active</span></td>
                                <td>
                                  <button onClick={() => handleDeleteCategory(c._id)} className="logout-btn" title="Delete" style={{ color: 'var(--danger)' }}>
                                    <Trash2 size={16}/>
                                  </button>
                                </td>
                              </tr>
                            ))
                          }
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              )}

              {/* ── WITHDRAWALS ── */}
              {activeTab === 'withdrawals' && (
                <div className="glass-card">
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', flexWrap: 'wrap', gap: '16px' }}>
                    <h2 className="section-title">Withdrawal Requests ({withdrawals.length})</h2>
                    <input
                      type="text"
                      placeholder="Search driver by name or phone..."
                      className="input-field"
                      style={{ maxWidth: '320px' }}
                      value={searchQuery}
                      onChange={e => setSearchQuery(e.target.value)}
                    />
                  </div>

                  <div className="data-table-container">
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>Driver Info</th>
                          <th>Requested Amount</th>
                          <th>Payout Method Details</th>
                          <th>Request Date</th>
                          <th>Status</th>
                          <th>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {withdrawals
                          .filter(w => {
                            const name = w.deliveryPartnerId?.userId?.name || '';
                            const phone = w.deliveryPartnerId?.userId?.phone || '';
                            return name.toLowerCase().includes(searchQuery.toLowerCase()) || phone.includes(searchQuery);
                          })
                          .map(w => {
                            const driverName = w.deliveryPartnerId?.userId?.name || 'Unknown Driver';
                            const driverPhone = w.deliveryPartnerId?.userId?.phone || '—';
                            return (
                              <tr key={w._id}>
                                <td>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                    <div className="avatar" style={{ width: '32px', height: '32px', fontSize: '12px' }}>
                                      {driverName.charAt(0).toUpperCase()}
                                    </div>
                                    <div>
                                      <strong style={{ color: 'white', display: 'block', fontSize: '13px' }}>{driverName}</strong>
                                      <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>{driverPhone}</span>
                                    </div>
                                  </div>
                                </td>
                                <td>
                                  <strong style={{ fontSize: '15px', color: 'var(--primary)' }}>₹{w.amount}</strong>
                                </td>
                                <td>
                                  {w.method === 'upi' ? (
                                    <div style={{ fontSize: '13px' }}>
                                      <span className="badge badge-info" style={{ fontSize: '10px', padding: '2px 6px', marginBottom: '4px' }}>UPI Payout</span>
                                      <code style={{ display: 'block', color: 'var(--text-primary)', background: 'rgba(255,255,255,0.03)', padding: '4px 8px', borderRadius: '4px', border: '1px solid var(--border)' }}>{w.upiId}</code>
                                    </div>
                                  ) : (
                                    <div style={{ fontSize: '12px', display: 'flex', flexDirection: 'column', gap: '2px', background: 'rgba(255,255,255,0.03)', padding: '6px 10px', borderRadius: '6px', border: '1px solid var(--border)' }}>
                                      <div><span style={{ color: 'var(--text-secondary)' }}>Holder:</span> <strong style={{ color: 'white' }}>{w.bankDetails?.holderName}</strong></div>
                                      <div><span style={{ color: 'var(--text-secondary)' }}>Bank:</span> <strong style={{ color: 'white' }}>{w.bankDetails?.bankName}</strong></div>
                                      <div><span style={{ color: 'var(--text-secondary)' }}>A/C:</span> <code style={{ color: 'var(--primary)' }}>{w.bankDetails?.accountNumber}</code></div>
                                      <div><span style={{ color: 'var(--text-secondary)' }}>IFSC:</span> <code style={{ color: 'var(--accent)' }}>{w.bankDetails?.ifscCode}</code></div>
                                    </div>
                                  )}
                                </td>
                                <td style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                                  {new Date(w.createdAt).toLocaleString('en-IN')}
                                </td>
                                <td>
                                  <span className={`badge ${w.status === 'approved' ? 'badge-success' : w.status === 'rejected' ? 'badge-danger' : 'badge-warning'}`}>
                                    {w.status}
                                  </span>
                                  {w.status === 'rejected' && w.rejectionReason && (
                                    <span style={{ display: 'block', fontSize: '10px', color: 'var(--text-muted)', marginTop: '4px', maxWidth: '180px' }}>
                                      Reason: {w.rejectionReason}
                                    </span>
                                  )}
                                </td>
                                <td>
                                  {w.status === 'pending' ? (
                                    <div style={{ display: 'flex', gap: '8px' }}>
                                      <button
                                        onClick={() => handleApproveWithdrawal(w._id)}
                                        className="btn btn-primary"
                                        style={{ width: 'auto', padding: '6px 12px', fontSize: '12px', borderRadius: '8px' }}
                                      >
                                        Approve
                                      </button>
                                      <button
                                        onClick={() => handleRejectClick(w._id)}
                                        className="btn btn-danger"
                                        style={{ width: 'auto', padding: '6px 12px', fontSize: '12px', borderRadius: '8px' }}
                                      >
                                        Reject
                                      </button>
                                    </div>
                                  ) : (
                                    <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Processed</span>
                                  )}
                                </td>
                              </tr>
                            );
                          })
                        }
                        {withdrawals.length === 0 && (
                          <tr>
                            <td colSpan="6" style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '24px' }}>
                              No withdrawal requests submitted yet.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* ── CUSTOMERS ── */}
              {activeTab === 'customers' && (
                <div className="glass-card">
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', flexWrap: 'wrap', gap: '16px' }}>
                    <h2 className="section-title">Customer Accounts ({customers.length})</h2>
                    <input
                      type="text"
                      placeholder="Search customer by name, phone or email..."
                      className="input-field"
                      style={{ maxWidth: '320px' }}
                      value={searchQuery}
                      onChange={e => setSearchQuery(e.target.value)}
                    />
                  </div>

                  <div className="data-table-container">
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>Profile</th>
                          <th>Customer Details</th>
                          <th>Registered Address(es)</th>
                          <th>Verified</th>
                          <th>Registration Date</th>
                        </tr>
                      </thead>
                      <tbody>
                        {customers
                          .filter(c => {
                            const name = c.name || '';
                            const phone = c.phone || '';
                            const email = c.email || '';
                            return name.toLowerCase().includes(searchQuery.toLowerCase()) || phone.includes(searchQuery) || email.toLowerCase().includes(searchQuery.toLowerCase());
                          })
                          .map(c => (
                            <tr key={c._id}>
                              <td>
                                {c.profileImage ? (
                                  <img 
                                    src={c.profileImage.startsWith('http') ? c.profileImage : `http://localhost:5000/${c.profileImage}`} 
                                    alt={c.name} 
                                    className="avatar" 
                                    style={{ width: '40px', height: '40px', borderRadius: '50%', objectFit: 'cover' }}
                                  />
                                ) : (
                                  <div className="avatar" style={{ width: '40px', height: '40px', fontSize: '15px' }}>
                                    {(c.name || 'C').charAt(0).toUpperCase()}
                                  </div>
                                )}
                              </td>
                              <td>
                                <strong style={{ color: 'white', display: 'block', fontSize: '14px' }}>{c.name || 'Unnamed Customer'}</strong>
                                <span style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)' }}>📞 {c.phone || '—'}</span>
                                <span style={{ display: 'block', fontSize: '11px', color: 'var(--text-muted)' }}>✉️ {c.email || '—'}</span>
                              </td>
                              <td style={{ fontSize: '12px', maxWidth: '300px' }}>
                                {c.address && c.address.length > 0 ? (
                                  <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                                    {c.address.map((a, i) => (
                                      <div key={i} style={{ background: 'rgba(255,255,255,0.02)', padding: '4px 8px', borderRadius: '4px', border: '1px solid var(--border)' }}>
                                        <span style={{ fontWeight: 600, display: 'block', fontSize: '11px', color: 'var(--accent)' }}>{a.addressType?.toUpperCase() || 'ADDRESS'}</span>
                                        <span style={{ color: 'var(--text-primary)' }}>{a.flatNo}, {a.area}, {a.landmark}</span>
                                      </div>
                                    ))}
                                  </div>
                                ) : (
                                  <span style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>No addresses saved yet</span>
                                )}
                              </td>
                              <td>
                                <span className={`badge ${c.isVerified ? 'badge-success' : 'badge-danger'}`}>
                                  {c.isVerified ? 'Verified' : 'Unverified'}
                                </span>
                              </td>
                              <td style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                                {new Date(c.createdAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
                              </td>
                            </tr>
                          ))
                        }
                        {customers.length === 0 && (
                          <tr>
                            <td colSpan="5" style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '24px' }}>
                              No customers registered on the platform yet.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* ── DRIVERS ── */}
              {activeTab === 'drivers' && (
                <div className="glass-card">
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', flexWrap: 'wrap', gap: '16px' }}>
                    <h2 className="section-title">Delivery Partners ({drivers.length})</h2>
                    <input
                      type="text"
                      placeholder="Search driver by name, phone or vehicle plate..."
                      className="input-field"
                      style={{ maxWidth: '320px' }}
                      value={searchQuery}
                      onChange={e => setSearchQuery(e.target.value)}
                    />
                  </div>

                  <div className="data-table-container">
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>Driver Profile</th>
                          <th>Vehicle Info</th>
                          <th>Kyc Status</th>
                          <th>Wallet Balance</th>
                          <th>Online State</th>
                          <th>Action</th>
                        </tr>
                      </thead>
                      <tbody>
                        {drivers
                          .filter(d => {
                            const name = d.userId?.name || '';
                            const phone = d.userId?.phone || '';
                            const plate = d.vehicleInfo?.plateNumber || '';
                            return name.toLowerCase().includes(searchQuery.toLowerCase()) || phone.includes(searchQuery) || plate.toLowerCase().includes(searchQuery.toLowerCase());
                          })
                          .map(d => {
                            const driverName = d.userId?.name || 'Unnamed Driver';
                            const driverPhone = d.userId?.phone || '—';
                            return (
                              <tr key={d._id}>
                                <td>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                    <div className="avatar" style={{ width: '38px', height: '38px', fontSize: '13px' }}>
                                      {driverName.charAt(0).toUpperCase()}
                                    </div>
                                    <div>
                                      <strong style={{ color: 'white', display: 'block', fontSize: '13px' }}>{driverName}</strong>
                                      <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>📞 {driverPhone}</span>
                                    </div>
                                  </div>
                                </td>
                                <td>
                                  <div style={{ fontSize: '12px' }}>
                                    <span style={{ display: 'block', fontWeight: 600, color: 'var(--primary)' }}>{d.vehicleInfo?.vehicleType?.toUpperCase() || '—'}</span>
                                    <span style={{ color: 'var(--text-primary)', display: 'block' }}>{d.vehicleInfo?.model || '—'}</span>
                                    <code style={{ fontSize: '10px', color: 'var(--text-secondary)' }}>{d.vehicleInfo?.plateNumber || '—'}</code>
                                  </div>
                                </td>
                                <td>
                                  <span className={`badge ${d.kycStatus === 'approved' ? 'badge-success' : d.kycStatus === 'rejected' ? 'badge-danger' : 'badge-warning'}`}>
                                    {d.kycStatus}
                                  </span>
                                  {d.kycStatus === 'rejected' && d.kycRejectionReason && (
                                    <span style={{ display: 'block', fontSize: '10px', color: 'var(--text-muted)', marginTop: '4px', maxWidth: '140px' }}>
                                      Reason: {d.kycRejectionReason}
                                    </span>
                                  )}
                                </td>
                                <td>
                                  <strong style={{ fontSize: '14px', color: 'var(--primary)' }}>₹{(d.earnings || 0).toFixed(2)}</strong>
                                </td>
                                <td>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                    <span style={{
                                      width: '8px', height: '8px', borderRadius: '50%',
                                      backgroundColor: d.isOnline ? 'var(--primary)' : 'var(--danger)',
                                      display: 'inline-block'
                                    }}></span>
                                    <span style={{ fontSize: '12px' }}>{d.isOnline ? 'Online' : 'Offline'}</span>
                                  </div>
                                </td>
                                <td>
                                  <button
                                    onClick={() => handleInspectKyc(d)}
                                    className="btn btn-outline"
                                    style={{ width: 'auto', padding: '6px 12px', fontSize: '12px', borderRadius: '8px' }}
                                  >
                                    Inspect KYC
                                  </button>
                                </td>
                              </tr>
                            );
                          })
                        }
                        {drivers.length === 0 && (
                          <tr>
                            <td colSpan="6" style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '24px' }}>
                              No delivery partners registered yet.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* ── REVIEWS ── */}
              {activeTab === 'reviews' && (
                <div className="glass-card">
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', flexWrap: 'wrap', gap: '16px' }}>
                    <h2 className="section-title">Product Reviews ({reviews.length})</h2>
                    <input
                      type="text"
                      placeholder="Search reviews by comment or user..."
                      className="input-field"
                      style={{ maxWidth: '320px' }}
                      value={searchQuery}
                      onChange={e => setSearchQuery(e.target.value)}
                    />
                  </div>

                  <div className="data-table-container">
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>User</th>
                          <th>Product</th>
                          <th>Vendor</th>
                          <th>Rating</th>
                          <th>Comment</th>
                          <th>Date</th>
                          <th>Action</th>
                        </tr>
                      </thead>
                      <tbody>
                        {reviews
                          .filter(r => {
                            const user = r.userId?.name || '';
                            const comment = r.comment || '';
                            return user.toLowerCase().includes(searchQuery.toLowerCase()) || comment.toLowerCase().includes(searchQuery.toLowerCase());
                          })
                          .map(r => {
                            const reviewerName = r.userId?.name || 'Unnamed User';
                            const reviewerPhone = r.userId?.phone || '—';
                            const productName = r.productId?.productName || 'Deleted Product';
                            return (
                              <tr key={r._id}>
                                <td>
                                  <div>
                                    <strong style={{ color: 'white', display: 'block', fontSize: '13px' }}>{reviewerName}</strong>
                                    <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>{reviewerPhone}</span>
                                  </div>
                                </td>
                                <td>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                    {r.productId?.images && r.productId.images.length > 0 ? (
                                      <img 
                                        src={r.productId.images[0].startsWith('http') ? r.productId.images[0] : `http://localhost:5000/${r.productId.images[0]}`} 
                                        alt={productName} 
                                        style={{ width: '32px', height: '32px', borderRadius: '4px', objectFit: 'cover' }}
                                      />
                                    ) : (
                                      <div style={{ width: '32px', height: '32px', background: '#1e2230', borderRadius: '4px' }}></div>
                                    )}
                                    <span style={{ fontSize: '12px', fontWeight: 600, color: 'white' }}>{productName}</span>
                                  </div>
                                </td>
                                <td>
                                  <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{r.vendorId?.shopName || '—'}</span>
                                </td>
                                <td>
                                  <div style={{ display: 'flex', color: '#fbbf24', gap: '2px' }}>
                                    {[...Array(5)].map((_, i) => (
                                      <span key={i} style={{ fontSize: '14px' }}>
                                        {i < (r.rating || 0) ? '★' : '☆'}
                                      </span>
                                    ))}
                                  </div>
                                </td>
                                <td style={{ fontSize: '12px', maxWidth: '250px', color: 'var(--text-primary)', whiteSpace: 'normal', wordBreak: 'break-word' }}>
                                  {r.comment || <span style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>No comment left</span>}
                                </td>
                                <td style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>
                                  {new Date(r.createdAt).toLocaleString('en-IN')}
                                </td>
                                <td>
                                  <button
                                    onClick={() => handleDeleteReview(r._id)}
                                    className="logout-btn"
                                    title="Delete Review"
                                    style={{ color: 'var(--danger)' }}
                                  >
                                    <Trash2 size={16} />
                                  </button>
                                </td>
                              </tr>
                            );
                          })
                        }
                        {reviews.length === 0 && (
                          <tr>
                            <td colSpan="7" style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '24px' }}>
                              No product reviews submitted yet.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* ── COUPONS ── */}
              {activeTab === 'coupons' && (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '24px', alignItems: 'flex-start' }}>
                  
                  {/* Create Coupon Form */}
                  <form onSubmit={handleAddCoupon} className="glass-card" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    <h3 className="section-title">Generate Discount Coupon</h3>
                    
                    <div className="form-group">
                      <label className="form-label">Promo Code (Uppercase)</label>
                      <input
                        type="text"
                        className="input-field"
                        placeholder="e.g. FIFTYOFF"
                        value={newCouponCode}
                        onChange={e => setNewCouponCode(e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, ''))}
                        required
                      />
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                      <div className="form-group">
                        <label className="form-label">Discount Type</label>
                        <select
                          className="input-field"
                          value={newCouponType}
                          onChange={e => setNewCouponType(e.target.value)}
                        >
                          <option value="percentage">Percentage (%)</option>
                          <option value="flat">Flat Amount (₹)</option>
                        </select>
                      </div>
                      
                      <div className="form-group">
                        <label className="form-label">Discount Value</label>
                        <input
                          type="number"
                          className="input-field"
                          min="1"
                          placeholder="e.g. 50"
                          value={newCouponValue || ''}
                          onChange={e => setNewCouponValue(parseFloat(e.target.value) || 0)}
                          required
                        />
                      </div>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                      <div className="form-group">
                        <label className="form-label">Min Purchase (₹)</label>
                        <input
                          type="number"
                          className="input-field"
                          min="0"
                          placeholder="e.g. 299"
                          value={newCouponMinOrder || ''}
                          onChange={e => setNewCouponMinOrder(parseFloat(e.target.value) || 0)}
                        />
                      </div>
                      
                      <div className="form-group">
                        <label className="form-label">Expiry Date</label>
                        <input
                          type="date"
                          className="input-field"
                          value={newCouponExpiry}
                          onChange={e => setNewCouponExpiry(e.target.value)}
                        />
                      </div>
                    </div>

                    <button type="submit" className="btn btn-primary" style={{ marginTop: '8px' }}>
                      <Plus size={16} /> Publish Coupon Code
                    </button>
                  </form>

                  {/* List Coupons */}
                  <div className="glass-card">
                    <h3 className="section-title" style={{ marginBottom: '20px' }}>Active Promo Tickets ({coupons.length})</h3>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', maxHeight: '520px', overflowY: 'auto', paddingRight: '4px' }}>
                      {coupons.map(c => {
                        const expired = c.expiryDate && new Date(c.expiryDate) < new Date();
                        return (
                          <div 
                            key={c._id}
                            style={{
                              border: '2px dashed var(--border)',
                              borderRadius: '12px',
                              padding: '16px',
                              display: 'flex',
                              justifyContent: 'space-between',
                              alignItems: 'center',
                              background: expired ? 'rgba(239, 68, 68, 0.02)' : 'rgba(16, 185, 129, 0.01)',
                              borderColor: expired ? 'rgba(239, 68, 68, 0.2)' : 'rgba(16, 185, 129, 0.2)'
                            }}
                          >
                            <div>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                                <span style={{
                                  background: 'rgba(255,255,255,0.08)',
                                  color: 'white',
                                  fontWeight: 800,
                                  fontSize: '14px',
                                  padding: '4px 10px',
                                  borderRadius: '6px',
                                  letterSpacing: '1px',
                                  border: '1px solid var(--border)'
                                }}>{c.code}</span>
                                <span className={`badge ${expired ? 'badge-danger' : 'badge-success'}`} style={{ fontSize: '9px', padding: '1px 5px' }}>
                                  {expired ? 'Expired' : 'Active'}
                                </span>
                              </div>
                              <div style={{ fontSize: '13px', color: 'white', fontWeight: 600 }}>
                                {c.discountType === 'percentage' ? `${c.discountValue}% OFF` : `₹${c.discountValue} FLAT OFF`}
                              </div>
                              <div style={{ fontSize: '11px', color: 'var(--text-secondary)', marginTop: '4px' }}>
                                {c.minimumOrder > 0 ? `Min purchase: ₹${c.minimumOrder}` : 'No minimum order'}
                              </div>
                              {c.expiryDate && (
                                <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>
                                  Expires: {new Date(c.expiryDate).toLocaleDateString('en-IN')}
                                </div>
                              )}
                            </div>
                            <button
                              onClick={() => handleDeleteCoupon(c._id)}
                              className="logout-btn"
                              style={{ color: 'var(--danger)', padding: '8px', background: 'rgba(239, 68, 68, 0.05)', borderRadius: '8px' }}
                              title="Revoke Coupon"
                            >
                              <Trash2 size={16} />
                            </button>
                          </div>
                        );
                      })}
                      {coupons.length === 0 && (
                        <div style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '24px' }}>
                          No active promo coupons.
                        </div>
                      )}
                    </div>
                  </div>

                </div>
              )}

              {/* ── BANNERS & OFFERS ── */}
              {activeTab === 'banners' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
                  
                  {/* Banners Subsection */}
                  <div>
                    <h2 className="section-title" style={{ fontSize: '18px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <ImageIcon size={20} style={{ color: 'var(--primary)' }} /> Promotional Banners
                    </h2>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '24px', alignItems: 'flex-start' }}>
                      {/* Create Banner Form */}
                      <form onSubmit={handleAddBanner} className="glass-card" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                        <h3 className="section-title" style={{ fontSize: '15px' }}>Publish Promotional Banner</h3>
                        
                        <div className="form-group">
                          <label className="form-label">Banner Title (Optional)</label>
                          <input
                            type="text"
                            className="input-field"
                            placeholder="e.g. Monsoon Organic Fruits sale"
                            value={newBannerTitle}
                            onChange={e => setNewBannerTitle(e.target.value)}
                          />
                        </div>

                        <div className="form-group">
                          <label className="form-label">Select Banner Image (File Upload)</label>
                          <input
                            id="banner-file-input"
                            type="file"
                            accept="image/*"
                            className="input-field"
                            style={{ padding: '8px' }}
                            onChange={e => setNewBannerFile(e.target.files[0])}
                            required
                          />
                        </div>

                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                          <div className="form-group">
                            <label className="form-label">Redirect Type</label>
                            <select
                              className="input-field"
                              value={newBannerRedirectType}
                              onChange={e => setNewBannerRedirectType(e.target.value)}
                            >
                              <option value="none">No Redirect</option>
                              <option value="vendor">Shop/Vendor</option>
                              <option value="product">Product Page</option>
                            </select>
                          </div>

                          <div className="form-group">
                            <label className="form-label">Redirect Target ID</label>
                            <input
                              type="text"
                              className="input-field"
                              placeholder="DB Object ID"
                              value={newBannerRedirectId}
                              onChange={e => setNewBannerRedirectId(e.target.value)}
                              disabled={newBannerRedirectType === 'none'}
                              required={newBannerRedirectType !== 'none'}
                            />
                          </div>
                        </div>

                        <button type="submit" className="btn btn-primary" style={{ marginTop: '8px' }}>
                          <PlusCircle size={16} /> Publish App Banner
                        </button>
                      </form>

                      {/* List Banners */}
                      <div className="glass-card">
                        <h3 className="section-title" style={{ marginBottom: '20px', fontSize: '15px' }}>Active Promotional Banners ({banners.length})</h3>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', maxHeight: '560px', overflowY: 'auto', paddingRight: '4px' }}>
                          {banners.map(b => (
                            <div 
                              key={b._id}
                              style={{
                                border: '1px solid var(--border)',
                                borderRadius: '12px',
                                background: 'rgba(255,255,255,0.01)',
                                overflow: 'hidden',
                                position: 'relative'
                              }}
                            >
                              <img 
                                src={b.image.startsWith('http') ? b.image : `http://localhost:5000/${b.image}`} 
                                alt={b.title || 'App Promotion Banner'}
                                style={{ width: '100%', height: '140px', objectFit: 'cover', display: 'block' }}
                              />
                              <div style={{ padding: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <div>
                                  <strong style={{ color: 'white', display: 'block', fontSize: '13px' }}>{b.title || 'Untitled Banner'}</strong>
                                  <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>
                                    {b.redirectType !== 'none' ? `Redirects to ${b.redirectType}: ${b.redirectId}` : 'Static Display'}
                                  </span>
                                </div>
                                
                                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                                  {/* Toggle active switch */}
                                  <label style={{ position: 'relative', display: 'inline-block', width: '42px', height: '24px', cursor: 'pointer' }}>
                                    <input
                                      type="checkbox"
                                      checked={b.isActive}
                                      onChange={() => handleToggleBanner(b._id)}
                                      style={{ opacity: 0, width: 0, height: 0 }}
                                    />
                                    <span style={{
                                      position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
                                      backgroundColor: b.isActive ? 'var(--primary)' : 'rgba(255,255,255,0.1)',
                                      transition: '0.4s', borderRadius: '34px'
                                    }}>
                                      <span style={{
                                        position: 'absolute', content: '""', height: '16px', width: '16px', left: '4px', bottom: '4px',
                                        backgroundColor: 'white', transition: '0.4s', borderRadius: '50%',
                                        transform: b.isActive ? 'translateX(18px)' : 'translateX(0)'
                                      }}></span>
                                    </span>
                                  </label>

                                  {/* Delete button */}
                                  <button
                                    onClick={() => handleDeleteBanner(b._id)}
                                    className="logout-btn"
                                    style={{ color: 'var(--danger)', padding: '6px' }}
                                    title="Delete Banner"
                                  >
                                    <Trash2 size={16} />
                                  </button>
                                </div>
                              </div>
                            </div>
                          ))}
                          {banners.length === 0 && (
                            <div style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '24px' }}>
                              No banners published yet.
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Horizontal Divider */}
                  <div style={{ borderTop: '1px solid var(--border)', margin: '8px 0' }}></div>

                  {/* Special Offers Subsection */}
                  <div>
                    <h2 className="section-title" style={{ fontSize: '18px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <Tag size={20} style={{ color: 'var(--primary)' }} /> Special Offers (Mobile Carousel)
                    </h2>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '24px', alignItems: 'flex-start' }}>
                      {/* Create Special Offer Form */}
                      <form onSubmit={handleAddOffer} className="glass-card" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                        <h3 className="section-title" style={{ fontSize: '15px' }}>Publish Special Offer Card</h3>
                        
                        <div className="form-group">
                          <label className="form-label">Offer Title</label>
                          <input
                            type="text"
                            className="input-field"
                            placeholder="e.g. Special Season Discount"
                            value={newOfferTitle}
                            onChange={e => setNewOfferTitle(e.target.value)}
                            required
                          />
                        </div>

                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                          <div className="form-group">
                            <label className="form-label">Discount Text</label>
                            <input
                              type="text"
                              className="input-field"
                              placeholder="e.g. 50% OFF"
                              value={newOfferDiscountText}
                              onChange={e => setNewOfferDiscountText(e.target.value)}
                              required
                            />
                          </div>
                          <div className="form-group">
                            <label className="form-label">Badge Text</label>
                            <input
                              type="text"
                              className="input-field"
                              placeholder="e.g. LIMITED OFFER"
                              value={newOfferBadgeText}
                              onChange={e => setNewOfferBadgeText(e.target.value)}
                              required
                            />
                          </div>
                        </div>

                        <div className="form-group">
                          <label className="form-label">Description</label>
                          <input
                            type="text"
                            className="input-field"
                            placeholder="e.g. On all organic mushrooms today!"
                            value={newOfferDescription}
                            onChange={e => setNewOfferDescription(e.target.value)}
                            required
                          />
                        </div>

                        <div className="form-group">
                          <label className="form-label">Offer Image (Optional)</label>
                          <input
                            id="offer-file-input"
                            type="file"
                            accept="image/*"
                            className="input-field"
                            style={{ padding: '8px' }}
                            onChange={e => setNewOfferFile(e.target.files[0])}
                          />
                        </div>

                        <button type="submit" className="btn btn-primary" style={{ marginTop: '8px' }}>
                          <PlusCircle size={16} /> Publish Special Offer
                        </button>
                      </form>

                      {/* List Special Offers */}
                      <div className="glass-card">
                        <h3 className="section-title" style={{ marginBottom: '20px', fontSize: '15px' }}>Active Special Offers ({offers.length})</h3>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', maxHeight: '560px', overflowY: 'auto', paddingRight: '4px' }}>
                          {offers.map(o => (
                            <div 
                              key={o._id}
                              style={{
                                border: '1px solid var(--border)',
                                borderRadius: '12px',
                                background: 'rgba(255,255,255,0.01)',
                                overflow: 'hidden',
                                position: 'relative'
                              }}
                            >
                              {o.image ? (
                                <img 
                                  src={o.image.startsWith('http') ? o.image : `http://localhost:5000/${o.image}`} 
                                  alt={o.title}
                                  style={{ width: '100%', height: '140px', objectFit: 'cover', display: 'block' }}
                                />
                              ) : (
                                <div style={{
                                  width: '100%', height: '140px',
                                  background: 'linear-gradient(135deg, #1b5e20 0%, #4caf50 100%)',
                                  display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '16px'
                                }}>
                                  <span style={{
                                    backgroundColor: 'amber', color: 'black', fontWeight: 'bold', fontSize: '10px',
                                    padding: '2px 6px', borderRadius: '4px', alignSelf: 'flex-start', marginBottom: '8px'
                                  }}>{o.badgeText}</span>
                                  <h3 style={{ color: 'white', fontWeight: 'bold', fontSize: '20px', margin: 0 }}>{o.discountText}</h3>
                                  <p style={{ color: 'rgba(255,255,255,0.8)', fontSize: '12px', margin: '4px 0 0' }}>{o.description}</p>
                                </div>
                              )}
                              <div style={{ padding: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <div>
                                  <strong style={{ color: 'white', display: 'block', fontSize: '13px' }}>{o.title}</strong>
                                  <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>
                                    {o.badgeText} • {o.discountText}
                                  </span>
                                </div>
                                
                                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                                  {/* Toggle active switch */}
                                  <label style={{ position: 'relative', display: 'inline-block', width: '42px', height: '24px', cursor: 'pointer' }}>
                                    <input
                                      type="checkbox"
                                      checked={o.isActive}
                                      onChange={() => handleToggleOffer(o._id)}
                                      style={{ opacity: 0, width: 0, height: 0 }}
                                    />
                                    <span style={{
                                      position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
                                      backgroundColor: o.isActive ? 'var(--primary)' : 'rgba(255,255,255,0.1)',
                                      transition: '0.4s', borderRadius: '34px'
                                    }}>
                                      <span style={{
                                        position: 'absolute', content: '""', height: '16px', width: '16px', left: '4px', bottom: '4px',
                                        backgroundColor: 'white', transition: '0.4s', borderRadius: '50%',
                                        transform: o.isActive ? 'translateX(18px)' : 'translateX(0)'
                                      }}></span>
                                    </span>
                                  </label>

                                  {/* Delete button */}
                                  <button
                                    onClick={() => handleDeleteOffer(o._id)}
                                    className="logout-btn"
                                    style={{ color: 'var(--danger)', padding: '6px' }}
                                    title="Delete Offer"
                                  >
                                    <Trash2 size={16} />
                                  </button>
                                </div>
                              </div>
                            </div>
                          ))}
                          {offers.length === 0 && (
                            <div style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '24px' }}>
                              No special offers published yet.
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>

                </div>
              )}

              {/* ── SUPPORT TICKETS ── */}
              {activeTab === 'support' && (
                <div className="glass-card">
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', flexWrap: 'wrap', gap: '16px' }}>
                    <h2 className="section-title">Support Tickets ({supportTickets.length})</h2>
                    <input
                      type="text"
                      placeholder="Search by name, phone, subject, description..."
                      className="input-field"
                      style={{ maxWidth: '320px' }}
                      value={searchQuery}
                      onChange={e => setSearchQuery(e.target.value)}
                    />
                  </div>

                  <div className="data-table-container">
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>User / Partner</th>
                          <th>Subject</th>
                          <th>Message Details</th>
                          <th>Date Raised</th>
                          <th>Status</th>
                          <th>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {supportTickets
                          .filter(t => {
                            const user = t.userId?.name || '';
                            const phone = t.userId?.phone || '';
                            const sub = t.subject || '';
                            const msg = t.message || '';
                            const q = searchQuery.toLowerCase();
                            return user.toLowerCase().includes(q) ||
                                   phone.toLowerCase().includes(q) ||
                                   sub.toLowerCase().includes(q) ||
                                   msg.toLowerCase().includes(q);
                          })
                          .map(t => {
                            const uName = t.userId?.name || 'Unknown Partner';
                            const uPhone = t.userId?.phone || '—';
                            const uRole = t.userId?.role || 'delivery';
                            const roleBadgeColor = uRole === 'delivery' ? 'var(--primary)' : uRole === 'vendor' ? '#a855f7' : '#3b82f6';
                            return (
                              <tr key={t._id}>
                                <td>
                                  <div>
                                    <strong style={{ color: 'white', display: 'block', fontSize: '13px' }}>{uName}</strong>
                                    <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>{uPhone}</span>
                                    <span style={{
                                      display: 'inline-block',
                                      fontSize: '9px',
                                      padding: '1px 6px',
                                      borderRadius: '4px',
                                      background: `${roleBadgeColor}1a`,
                                      color: roleBadgeColor,
                                      border: `1px solid ${roleBadgeColor}33`,
                                      marginTop: '4px',
                                      fontWeight: 'bold',
                                      textTransform: 'uppercase'
                                    }}>
                                      {uRole}
                                    </span>
                                  </div>
                                </td>
                                <td>
                                  <strong style={{ color: 'white', fontSize: '12px' }}>{t.subject || '—'}</strong>
                                </td>
                                <td style={{ fontSize: '12px', maxWidth: '300px', color: 'var(--text-primary)', whiteSpace: 'normal', wordBreak: 'break-word' }}>
                                  {t.message || '—'}
                                </td>
                                <td style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>
                                  {new Date(t.createdAt).toLocaleString('en-IN')}
                                </td>
                                <td>
                                  <span className={`badge ${t.status === 'closed' ? 'badge-success' : t.status === 'pending' ? 'badge-warning' : 'badge-info'}`}>
                                    {t.status}
                                  </span>
                                </td>
                                <td>
                                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                                    {t.status === 'open' && (
                                      <>
                                        <button
                                          onClick={() => handleUpdateTicketStatus(t._id, 'pending')}
                                          className="btn btn-outline"
                                          style={{ width: 'auto', padding: '6px 12px', fontSize: '11px', borderRadius: '8px', color: 'var(--accent)', borderColor: 'var(--accent)' }}
                                        >
                                          Mark Pending
                                        </button>
                                        <button
                                          onClick={() => handleUpdateTicketStatus(t._id, 'closed')}
                                          className="btn btn-primary"
                                          style={{ width: 'auto', padding: '6px 12px', fontSize: '11px', borderRadius: '8px' }}
                                        >
                                          Resolve
                                        </button>
                                      </>
                                    )}
                                    {t.status === 'pending' && (
                                      <>
                                        <button
                                          onClick={() => handleUpdateTicketStatus(t._id, 'closed')}
                                          className="btn btn-primary"
                                          style={{ width: 'auto', padding: '6px 12px', fontSize: '11px', borderRadius: '8px' }}
                                        >
                                          Resolve
                                        </button>
                                        <button
                                          onClick={() => handleUpdateTicketStatus(t._id, 'open')}
                                          className="btn btn-outline"
                                          style={{ width: 'auto', padding: '6px 12px', fontSize: '11px', borderRadius: '8px' }}
                                        >
                                          Re-open
                                        </button>
                                      </>
                                    )}
                                    {t.status === 'closed' && (
                                      <button
                                        onClick={() => handleUpdateTicketStatus(t._id, 'open')}
                                        className="btn btn-outline"
                                        style={{ width: 'auto', padding: '6px 12px', fontSize: '11px', borderRadius: '8px' }}
                                      >
                                        Re-open
                                      </button>
                                    )}
                                  </div>
                                </td>
                              </tr>
                            );
                          })
                        }
                        {supportTickets.length === 0 && (
                          <tr>
                            <td colSpan="6" style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '24px' }}>
                              No support tickets raised yet.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* ── SETTINGS ── */}
              {activeTab === 'settings' && (
                <div style={{ maxWidth: '800px' }}>
                  <form onSubmit={handleSaveSettings} className="glass-card" style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
                    <div style={{ borderBottom: '1px solid var(--border)', paddingBottom: '16px', marginBottom: '8px' }}>
                      <h2 className="section-title" style={{ fontSize: '18px' }}>Configure Application Settings</h2>
                      <p style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '4px' }}>Update platform parameters, delivery thresholds, and driver earning schemes globally.</p>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '24px' }}>
                      <div className="form-group">
                        <label className="form-label">App Name</label>
                        <input
                          type="text"
                          className="input-field"
                          value={settingsForm.appName}
                          onChange={e => setSettingsForm({ ...settingsForm, appName: e.target.value })}
                          required
                        />
                      </div>
                      <div className="form-group">
                        <label className="form-label">App Version</label>
                        <input
                          type="text"
                          className="input-field"
                          value={settingsForm.appVersion}
                          onChange={e => setSettingsForm({ ...settingsForm, appVersion: e.target.value })}
                          required
                        />
                      </div>
                      <div className="form-group">
                        <label className="form-label">Support Number</label>
                        <input
                          type="text"
                          className="input-field"
                          value={settingsForm.supportNumber}
                          onChange={e => setSettingsForm({ ...settingsForm, supportNumber: e.target.value })}
                          required
                        />
                      </div>
                      <div className="form-group">
                        <label className="form-label">Delivery Partner Radius (km)</label>
                        <input
                          type="number"
                          step="0.1"
                          className="input-field"
                          value={settingsForm.deliveryPartnerRadius}
                          onChange={e => setSettingsForm({ ...settingsForm, deliveryPartnerRadius: parseFloat(e.target.value) || 0 })}
                          required
                        />
                      </div>
                    </div>

                    <div style={{ borderTop: '1px solid var(--border)', paddingTop: '20px' }}>
                      <h3 className="form-label" style={{ color: 'var(--primary)', fontSize: '14px', marginBottom: '16px' }}>Order & Tax Structures</h3>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' }}>
                        <div className="form-group">
                          <label className="form-label">Default Customer Delivery Charge (₹)</label>
                          <input
                            type="number"
                            className="input-field"
                            value={settingsForm.deliveryCharge}
                            onChange={e => setSettingsForm({ ...settingsForm, deliveryCharge: parseFloat(e.target.value) || 0 })}
                            required
                          />
                        </div>
                        <div className="form-group">
                          <label className="form-label">Tax Rate (%)</label>
                          <input
                            type="number"
                            className="input-field"
                            value={settingsForm.taxPercent}
                            onChange={e => setSettingsForm({ ...settingsForm, taxPercent: parseFloat(e.target.value) || 0 })}
                            required
                          />
                        </div>
                        <div className="form-group">
                          <label className="form-label">Minimum Order Value (₹)</label>
                          <input
                            type="number"
                            className="input-field"
                            value={settingsForm.minimumOrder}
                            onChange={e => setSettingsForm({ ...settingsForm, minimumOrder: parseFloat(e.target.value) || 0 })}
                            required
                          />
                        </div>
                      </div>
                    </div>

                    <div style={{ borderTop: '1px solid var(--border)', paddingTop: '20px' }}>
                      <h3 className="form-label" style={{ color: 'var(--primary)', fontSize: '14px', marginBottom: '16px' }}>Delivery Partner Earnings Configuration</h3>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '20px' }}>
                        <div className="form-group">
                          <label className="form-label">Base Delivery Earning (₹)</label>
                          <input
                            type="number"
                            className="input-field"
                            style={{ borderColor: 'rgba(16, 185, 129, 0.3)' }}
                            value={settingsForm.deliveryBaseFare}
                            onChange={e => setSettingsForm({ ...settingsForm, deliveryBaseFare: parseFloat(e.target.value) || 0 })}
                            required
                          />
                          <p style={{ color: 'var(--text-secondary)', fontSize: '11px', marginTop: '6px' }}>Flat rate paid to driver for any delivery regardless of distance.</p>
                        </div>
                        <div className="form-group">
                          <label className="form-label">Per Kilometer Earning Rate (₹/km)</label>
                          <input
                            type="number"
                            className="input-field"
                            style={{ borderColor: 'rgba(16, 185, 129, 0.3)' }}
                            value={settingsForm.deliveryPerKmRate}
                            onChange={e => setSettingsForm({ ...settingsForm, deliveryPerKmRate: parseFloat(e.target.value) || 0 })}
                            required
                          />
                          <p style={{ color: 'var(--text-secondary)', fontSize: '11px', marginTop: '6px' }}>Incremental earnings paid for every kilometer of distance computed from vendor to customer.</p>
                        </div>
                      </div>
                    </div>

                    <div style={{ borderTop: '1px solid var(--border)', paddingTop: '20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                        <span className="form-label" style={{ margin: 0 }}>System Maintenance Mode</span>
                        <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Restrict customer apps during system updates.</span>
                      </div>
                      <label className="switch" style={{ position: 'relative', display: 'inline-block', width: '50px', height: '26px' }}>
                        <input
                          type="checkbox"
                          style={{ opacity: 0, width: 0, height: 0 }}
                          checked={settingsForm.isMaintenanceMode}
                          onChange={e => setSettingsForm({ ...settingsForm, isMaintenanceMode: e.target.checked })}
                        />
                        <span className="slider" style={{
                          position: 'absolute', cursor: 'pointer', top: 0, left: 0, right: 0, bottom: 0,
                          backgroundColor: settingsForm.isMaintenanceMode ? 'var(--danger)' : '#2e3344',
                          transition: '0.4s', borderRadius: '34px'
                        }}>
                          <span style={{
                            position: 'absolute', content: '""', height: '18px', width: '18px', left: '4px', bottom: '4px',
                            backgroundColor: 'white', transition: '0.4s', borderRadius: '50%',
                            transform: settingsForm.isMaintenanceMode ? 'translateX(24px)' : 'translateX(0)'
                          }}></span>
                        </span>
                      </label>
                    </div>

                    <button type="submit" className="btn btn-primary" style={{ marginTop: '12px' }}>
                      Save Application Settings
                    </button>
                  </form>
                </div>
              )}
            </>
          )}
        </div>
      </main>

      {/* REJECTION MODAL */}
      {rejectionModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 10000
        }}>
          <div className="glass-panel" style={{ width: '100%', maxWidth: '450px', padding: '24px' }}>
            <h3 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '16px', color: 'white' }}>Reject Payout Request</h3>
            <form onSubmit={handleRejectWithdrawalSubmit}>
              <div className="form-group" style={{ marginBottom: '20px' }}>
                <label className="form-label">Reason for Rejection</label>
                <textarea
                  className="input-field"
                  rows="4"
                  placeholder="Provide reason (e.g. Invalid bank details or incorrect UPI ID)..."
                  value={rejectionReason}
                  onChange={e => setRejectionReason(e.target.value)}
                  style={{ resize: 'none', background: '#12141c' }}
                  required
                />
              </div>
              <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                <button
                  type="button"
                  onClick={() => setRejectionModalOpen(false)}
                  className="btn btn-outline"
                  style={{ width: 'auto', padding: '8px 16px', fontSize: '13px' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-danger"
                  style={{ width: 'auto', padding: '8px 16px', fontSize: '13px' }}
                >
                  Confirm Rejection & Refund
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* DRIVER KYC INSPECTOR MODAL */}
      {driverKycModalOpen && selectedDriver && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0,0,0,0.85)', backdropFilter: 'blur(8px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999,
          overflowY: 'auto', padding: '20px'
        }}>
          <div className="glass-panel" style={{
            width: '100%', maxWidth: '800px', padding: '28px',
            maxHeight: '90vh', overflowY: 'auto', position: 'relative',
            border: '1px solid rgba(16, 185, 129, 0.2)'
          }}>
            {/* Close Button */}
            <button
              onClick={() => {
                setDriverKycModalOpen(false);
                setSelectedDriver(null);
              }}
              style={{
                position: 'absolute', top: '16px', right: '16px',
                background: 'rgba(255,255,255,0.05)', border: 'none',
                color: 'white', cursor: 'pointer', padding: '8px',
                borderRadius: '50%', display: 'flex', alignItems: 'center',
                justifyContent: 'center', transition: 'all 0.3s'
              }}
              onMouseEnter={e => e.currentTarget.style.background = 'rgba(239, 68, 68, 0.2)'}
              onMouseLeave={e => e.currentTarget.style.background = 'rgba(255,255,255,0.05)'}
            >
              <X size={18} />
            </button>

            {/* Header: Driver Info */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '20px', borderBottom: '1px solid var(--border)', paddingBottom: '20px', marginBottom: '24px' }}>
              <div style={{ position: 'relative' }}>
                {selectedDriver.profileImage || selectedDriver.userId?.profileImage ? (
                  <img
                    src={(selectedDriver.profileImage || selectedDriver.userId?.profileImage).startsWith('http') 
                      ? (selectedDriver.profileImage || selectedDriver.userId?.profileImage) 
                      : `http://localhost:5000/${selectedDriver.profileImage || selectedDriver.userId?.profileImage}`}
                    alt="Driver Profile"
                    style={{ width: '70px', height: '70px', borderRadius: '50%', objectFit: 'cover', border: '2px solid var(--primary)' }}
                  />
                ) : (
                  <div className="avatar" style={{ width: '70px', height: '70px', fontSize: '24px', background: 'var(--primary-gradient)' }}>
                    {(selectedDriver.userId?.name || selectedDriver.name || 'D').charAt(0).toUpperCase()}
                  </div>
                )}
                <span style={{
                  position: 'absolute', bottom: 0, right: 0,
                  width: '16px', height: '16px', borderRadius: '50%',
                  backgroundColor: selectedDriver.isOnline ? 'var(--primary)' : 'var(--danger)',
                  border: '2px solid #1a1e2e'
                }} title={selectedDriver.isOnline ? 'Online' : 'Offline'}></span>
              </div>

              <div>
                <h3 style={{ fontSize: '22px', fontWeight: 700, color: 'white', margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
                  {selectedDriver.userId?.name || selectedDriver.name || 'Unnamed Driver'}
                  <span className={`badge ${selectedDriver.kycStatus === 'approved' ? 'badge-success' : selectedDriver.kycStatus === 'rejected' ? 'badge-danger' : 'badge-warning'}`} style={{ fontSize: '11px', padding: '2px 8px' }}>
                    {selectedDriver.kycStatus?.toUpperCase()}
                  </span>
                </h3>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '12px', marginTop: '6px', fontSize: '13px', color: 'var(--text-secondary)' }}>
                  <span>📧 {selectedDriver.userId?.email || selectedDriver.email || 'No Email'}</span>
                  <span>📞 {selectedDriver.userId?.phone || selectedDriver.phone || 'No Phone'}</span>
                  {selectedDriver.userId?.isVerified && (
                    <span style={{ color: 'var(--primary)', display: 'flex', alignItems: 'center', gap: '3px' }}>
                      <Check size={14} /> Verified User Account
                    </span>
                  )}
                </div>
              </div>
            </div>

            {/* Main Content Sections */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
              {/* Section 1: Vehicle & Account Info */}
              <div style={{ background: 'rgba(255,255,255,0.02)', padding: '16px', borderRadius: '12px', border: '1px solid var(--border)' }}>
                <h4 style={{ color: 'var(--primary)', fontSize: '14px', fontWeight: 600, marginBottom: '12px', textTransform: 'uppercase', letterSpacing: '0.5px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Bike size={16} /> Vehicle & Fleet Metadata
                </h4>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px' }}>
                  <div>
                    <span style={{ fontSize: '11px', color: 'var(--text-secondary)', display: 'block' }}>VEHICLE TYPE</span>
                    <strong style={{ color: 'white', fontSize: '14px' }}>
                      {(selectedDriver.vehicleInfo?.vehicleType || selectedDriver.vehicleType || '—').toUpperCase()}
                    </strong>
                  </div>
                  <div>
                    <span style={{ fontSize: '11px', color: 'var(--text-secondary)', display: 'block' }}>VEHICLE MODEL</span>
                    <strong style={{ color: 'white', fontSize: '14px' }}>
                      {selectedDriver.vehicleInfo?.model || '—'}
                    </strong>
                  </div>
                  <div>
                    <span style={{ fontSize: '11px', color: 'var(--text-secondary)', display: 'block' }}>PLATE / REGISTRATION NO.</span>
                    <code style={{ color: 'var(--primary)', fontSize: '13px', fontWeight: 'bold' }}>
                      {selectedDriver.vehicleInfo?.plateNumber || selectedDriver.vehicleNumber || '—'}
                    </code>
                  </div>
                  <div>
                    <span style={{ fontSize: '11px', color: 'var(--text-secondary)', display: 'block' }}>WALLET BALANCE</span>
                    <strong style={{ color: 'white', fontSize: '14px' }}>₹{(selectedDriver.earnings || 0).toFixed(2)}</strong>
                  </div>
                </div>
              </div>

              {/* Section 2: KYC Identity Documents */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                <h4 style={{ color: 'var(--primary)', fontSize: '14px', fontWeight: 600, marginBottom: '4px', textTransform: 'uppercase', letterSpacing: '0.5px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <FileText size={16} /> Identity Verification Documents
                </h4>

                {/* Aadhar Card Documents */}
                <div style={{ background: 'rgba(255,255,255,0.01)', padding: '16px', borderRadius: '12px', border: '1px solid var(--border)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px', flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 600, color: 'white', fontSize: '13px' }}>Aadhar Card Details</span>
                    <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                      Number: <strong style={{ color: 'white' }}>{selectedDriver.kyc?.aadharNumber || 'Not Provided'}</strong>
                    </span>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                    <div>
                      <span style={{ fontSize: '11px', color: 'var(--text-secondary)', display: 'block', marginBottom: '6px' }}>Aadhar Card Front</span>
                      {selectedDriver.kyc?.aadharFront ? (
                        <div style={{ position: 'relative', borderRadius: '8px', overflow: 'hidden', border: '1px solid var(--border)', background: '#12141c' }}>
                          <img
                            src={selectedDriver.kyc.aadharFront.startsWith('http') ? selectedDriver.kyc.aadharFront : `http://localhost:5000/${selectedDriver.kyc.aadharFront}`}
                            alt="Aadhar Front"
                            style={{ width: '100%', height: '140px', objectFit: 'contain' }}
                          />
                          <a
                            href={selectedDriver.kyc.aadharFront.startsWith('http') ? selectedDriver.kyc.aadharFront : `http://localhost:5000/${selectedDriver.kyc.aadharFront}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            style={{ position: 'absolute', bottom: '8px', right: '8px', background: 'rgba(0,0,0,0.7)', color: 'white', fontSize: '10px', padding: '4px 8px', borderRadius: '4px', textDecoration: 'none' }}
                          >
                            View Full
                          </a>
                        </div>
                      ) : (
                        <div style={{ height: '140px', background: 'rgba(255,255,255,0.02)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px dashed var(--border)', borderRadius: '8px', color: 'var(--text-secondary)', fontSize: '12px' }}>
                          No image uploaded
                        </div>
                      )}
                    </div>

                    <div>
                      <span style={{ fontSize: '11px', color: 'var(--text-secondary)', display: 'block', marginBottom: '6px' }}>Aadhar Card Back</span>
                      {selectedDriver.kyc?.aadharBack ? (
                        <div style={{ position: 'relative', borderRadius: '8px', overflow: 'hidden', border: '1px solid var(--border)', background: '#12141c' }}>
                          <img
                            src={selectedDriver.kyc.aadharBack.startsWith('http') ? selectedDriver.kyc.aadharBack : `http://localhost:5000/${selectedDriver.kyc.aadharBack}`}
                            alt="Aadhar Back"
                            style={{ width: '100%', height: '140px', objectFit: 'contain' }}
                          />
                          <a
                            href={selectedDriver.kyc.aadharBack.startsWith('http') ? selectedDriver.kyc.aadharBack : `http://localhost:5000/${selectedDriver.kyc.aadharBack}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            style={{ position: 'absolute', bottom: '8px', right: '8px', background: 'rgba(0,0,0,0.7)', color: 'white', fontSize: '10px', padding: '4px 8px', borderRadius: '4px', textDecoration: 'none' }}
                          >
                            View Full
                          </a>
                        </div>
                      ) : (
                        <div style={{ height: '140px', background: 'rgba(255,255,255,0.02)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px dashed var(--border)', borderRadius: '8px', color: 'var(--text-secondary)', fontSize: '12px' }}>
                          No image uploaded
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Driving License Documents */}
                <div style={{ background: 'rgba(255,255,255,0.01)', padding: '16px', borderRadius: '12px', border: '1px solid var(--border)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px', flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 600, color: 'white', fontSize: '13px' }}>Driving License Details</span>
                    <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                      License No: <strong style={{ color: 'white' }}>{selectedDriver.kyc?.dlNumber || 'Not Provided'}</strong>
                    </span>
                  </div>

                  <div>
                    <span style={{ fontSize: '11px', color: 'var(--text-secondary)', display: 'block', marginBottom: '6px' }}>Driving License Image</span>
                    {selectedDriver.kyc?.dlImage ? (
                      <div style={{ position: 'relative', borderRadius: '8px', overflow: 'hidden', border: '1px solid var(--border)', background: '#12141c', maxWidth: '380px' }}>
                        <img
                          src={selectedDriver.kyc.dlImage.startsWith('http') ? selectedDriver.kyc.dlImage : `http://localhost:5000/${selectedDriver.kyc.dlImage}`}
                          alt="Driving License"
                          style={{ width: '100%', height: '180px', objectFit: 'contain' }}
                        />
                        <a
                          href={selectedDriver.kyc.dlImage.startsWith('http') ? selectedDriver.kyc.dlImage : `http://localhost:5000/${selectedDriver.kyc.dlImage}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          style={{ position: 'absolute', bottom: '8px', right: '8px', background: 'rgba(0,0,0,0.7)', color: 'white', fontSize: '10px', padding: '4px 8px', borderRadius: '4px', textDecoration: 'none' }}
                        >
                          View Full
                        </a>
                      </div>
                    ) : (
                      <div style={{ height: '140px', background: 'rgba(255,255,255,0.02)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px dashed var(--border)', borderRadius: '8px', color: 'var(--text-secondary)', fontSize: '12px' }}>
                        No image uploaded
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>

            {/* KYC Status Rejection Details */}
            {selectedDriver.kycStatus === 'rejected' && selectedDriver.kycRejectionReason && (
              <div style={{ marginTop: '20px', background: 'rgba(239, 68, 68, 0.08)', border: '1px solid rgba(239, 68, 68, 0.2)', padding: '12px 16px', borderRadius: '8px' }}>
                <span style={{ fontSize: '12px', fontWeight: 600, color: 'var(--danger)', display: 'block' }}>KYC REJECTION RECORD:</span>
                <span style={{ fontSize: '13px', color: 'white' }}>{selectedDriver.kycRejectionReason}</span>
              </div>
            )}

            {/* Footer: Interactive Decision Actions */}
            <div style={{ display: 'flex', gap: '12px', marginTop: '28px', borderTop: '1px solid var(--border)', paddingTop: '20px', width: '100%', justifyContent: 'flex-end' }}>
              <button
                type="button"
                onClick={() => {
                  setDriverKycModalOpen(false);
                  setSelectedDriver(null);
                }}
                className="btn btn-outline"
                style={{ width: 'auto', padding: '8px 20px', fontSize: '13px' }}
              >
                Close Inspector
              </button>

              {selectedDriver.kycStatus !== 'rejected' && (
                <button
                  type="button"
                  onClick={() => handleRejectKycClick(selectedDriver._id)}
                  className="btn btn-danger"
                  style={{ width: 'auto', padding: '8px 20px', fontSize: '13px' }}
                >
                  Reject Credentials
                </button>
              )}

              {selectedDriver.kycStatus !== 'approved' && (
                <button
                  type="button"
                  onClick={() => handleApproveKyc(selectedDriver._id)}
                  className="btn btn-primary"
                  style={{ width: 'auto', padding: '8px 20px', fontSize: '13px' }}
                >
                  Approve KYC & Activate
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* DRIVER KYC REJECTION MODAL */}
      {driverRejectionModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 10000
        }}>
          <div className="glass-panel" style={{ width: '100%', maxWidth: '450px', padding: '24px' }}>
            <h3 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '16px', color: 'white', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <X size={18} style={{ color: 'var(--danger)' }} /> Reject Driver KYC Application
            </h3>
            <form onSubmit={handleRejectKycSubmit}>
              <div className="form-group" style={{ marginBottom: '20px' }}>
                <label className="form-label">Suspension / Rejection Grounds</label>
                <textarea
                  className="input-field"
                  rows="4"
                  placeholder="Specify details for the driver (e.g. Blurry DL photo, Aadhar number mismatch)..."
                  value={driverRejectionReason}
                  onChange={e => setDriverRejectionReason(e.target.value)}
                  style={{ resize: 'none', background: '#12141c' }}
                  required
                />
              </div>
              <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                <button
                  type="button"
                  onClick={() => setDriverRejectionModalOpen(false)}
                  className="btn btn-outline"
                  style={{ width: 'auto', padding: '8px 16px', fontSize: '13px' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-danger"
                  style={{ width: 'auto', padding: '8px 16px', fontSize: '13px' }}
                >
                  Confirm Rejection
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
