import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { 
  LayoutDashboard, 
  ShoppingBag, 
  Tags, 
  User, 
  MapPin, 
  Plus, 
  Trash2, 
  LogOut, 
  Send, 
  ShieldCheck, 
  FolderPlus, 
  DollarSign, 
  Boxes, 
  AlertCircle, 
  CheckCircle2, 
  Loader2, 
  Settings, 
  Navigation,
  Image as ImageIcon
} from 'lucide-react';

function App() {
  // Config & API Settings
  const [apiBaseUrl, setApiBaseUrl] = useState(() => {
    return localStorage.getItem('vendor_api_url') || 'http://localhost:5000/api';
  });
  const [showSettings, setShowSettings] = useState(false);

  // Authentication State
  const [token, setToken] = useState(() => localStorage.getItem('vendor_token') || '');
  const [user, setUser] = useState(null);
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [registrationRequired, setRegistrationRequired] = useState(false);

  // Onboarding Form
  const [regForm, setRegForm] = useState({
    name: '',
    email: '',
    role: 'vendor', // Explicitly vendor for this panel
    pincode: '',
    fullAddress: '',
    city: '',
    state: ''
  });

  // App Dashboard State
  const [activeTab, setActiveTab] = useState('dashboard');
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [statusMessage, setStatusMessage] = useState({ type: '', text: '' });

  // Add Product Form
  const [newProduct, setNewProduct] = useState({
    categoryId: '',
    productName: '',
    description: '',
    mrpPrice: '',
    sellingPrice: '',
    stock: '',
    unit: 'kg',
    weight: '',
    tags: ''
  });
  const [productImages, setProductImages] = useState([]);
  const [imagePreviews, setImagePreviews] = useState([]);

  // Add Category State
  const [newCategoryName, setNewCategoryName] = useState('');

  // Fetch initial profile & dashboard data on token load
  useEffect(() => {
    if (token) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      fetchProfile();
      fetchProducts();
      fetchCategories();
    } else {
      setUser(null);
    }
  }, [token, apiBaseUrl]);

  // Alert handler
  const showAlert = (type, text) => {
    setStatusMessage({ type, text });
    setTimeout(() => {
      setStatusMessage({ type: '', text: '' });
    }, 5000);
  };

  // API Call: Send OTP
  const handleSendOtp = async (e) => {
    e.preventDefault();
    if (!phone || phone.length < 10) {
      showAlert('error', 'Please enter a valid 10-digit phone number');
      return;
    }
    setIsLoading(true);
    try {
      const response = await axios.post(`${apiBaseUrl}/auth/send-otp`, { phone });
      if (response.data.success) {
        setOtpSent(true);
        showAlert('success', `OTP Sent Successfully (Code: ${response.data.otp || '1234'})`);
      } else {
        showAlert('error', response.data.message || 'Failed to send OTP');
      }
    } catch (err) {
      showAlert('error', err.response?.data?.message || 'Server connection error');
    } finally {
      setIsLoading(false);
    }
  };

  // API Call: Verify OTP
  const handleVerifyOtp = async (e) => {
    e.preventDefault();
    if (!otp) {
      showAlert('error', 'Please enter the verification code');
      return;
    }
    setIsLoading(true);
    try {
      const response = await axios.post(`${apiBaseUrl}/auth/verify-otp`, { phone, otp });
      if (response.data.success) {
        const receivedToken = response.data.token;
        const receivedUser = response.data.user;

        // Check if profile registration is required or incomplete
        if (!receivedUser.name || !receivedUser.isVerified) {
          setToken(receivedToken);
          axios.defaults.headers.common['Authorization'] = `Bearer ${receivedToken}`;
          setUser(receivedUser);
          setRegistrationRequired(true);
          showAlert('success', 'OTP Verified! Please complete your registration');
        } else {
          localStorage.setItem('vendor_token', receivedToken);
          setToken(receivedToken);
          axios.defaults.headers.common['Authorization'] = `Bearer ${receivedToken}`;
          setUser(receivedUser);
          setRegistrationRequired(false);
          showAlert('success', 'Logged in successfully!');
        }
      } else {
        showAlert('error', response.data.message || 'OTP verification failed');
      }
    } catch (err) {
      showAlert('error', err.response?.data?.message || 'Verification failed');
    } finally {
      setIsLoading(false);
    }
  };

  // API Call: Register Profile Onboarding
  const handleRegister = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      const response = await axios.post(`${apiBaseUrl}/auth/register`, {
        ...regForm,
        phone
      });
      if (response.data.success) {
        localStorage.setItem('vendor_token', token);
        setUser(response.data.user);
        setRegistrationRequired(false);
        showAlert('success', 'Profile Registered Successfully! Welcome aboard.');
      } else {
        showAlert('error', response.data.message || 'Registration failed');
      }
    } catch (err) {
      showAlert('error', err.response?.data?.message || 'Registration failed');
    } finally {
      setIsLoading(false);
    }
  };

  // API Call: Fetch Profile
  const fetchProfile = async () => {
    try {
      const response = await axios.get(`${apiBaseUrl}/auth/profile`);
      if (response.data.success) {
        setUser(response.data.user);
      }
    } catch (err) {
      if (err.response?.status === 401) {
        handleLogout();
      }
    }
  };

  // API Call: Fetch Products
  const fetchProducts = async () => {
    try {
      const response = await axios.get(`${apiBaseUrl}/products`);
      if (response.data.success) {
        setProducts(response.data.products);
      }
    } catch (err) {
      console.error('Failed to load products');
    }
  };

  // API Call: Fetch Categories
  const fetchCategories = async () => {
    try {
      const response = await axios.get(`${apiBaseUrl}/categories`);
      if (response.data.success) {
        setCategories(response.data.categories);
      }
    } catch (err) {
      console.error('Failed to load categories');
    }
  };

  // API Call: Add Category
  const handleAddCategory = async (e) => {
    e.preventDefault();
    if (!newCategoryName.trim()) return;
    setIsLoading(true);
    try {
      const response = await axios.post(`${apiBaseUrl}/categories/add`, { name: newCategoryName });
      if (response.data.success) {
        showAlert('success', 'Category Created Successfully!');
        setNewCategoryName('');
        fetchCategories();
      }
    } catch (err) {
      showAlert('error', err.response?.data?.message || 'Failed to create category');
    } finally {
      setIsLoading(false);
    }
  };

  // API Call: Add Product
  const handleAddProduct = async (e) => {
    e.preventDefault();
    if (!newProduct.categoryId || !newProduct.productName || !newProduct.sellingPrice) {
      showAlert('error', 'Product Name, Category and Selling Price are required!');
      return;
    }

    setIsLoading(true);
    const formData = new FormData();
    formData.append('categoryId', newProduct.categoryId);
    formData.append('productName', newProduct.productName);
    formData.append('description', newProduct.description);
    formData.append('mrpPrice', newProduct.mrpPrice);
    formData.append('sellingPrice', newProduct.sellingPrice);
    formData.append('stock', newProduct.stock);
    formData.append('unit', newProduct.unit);
    formData.append('weight', newProduct.weight);
    formData.append('tags', newProduct.tags);

    // Append multiple files to "images" field matching multer backend key!
    for (let i = 0; i < productImages.length; i++) {
      formData.append('images', productImages[i]);
    }

    try {
      const response = await axios.post(`${apiBaseUrl}/products/add`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      if (response.data.success) {
        showAlert('success', 'Product listed successfully!');
        setNewProduct({
          categoryId: '',
          productName: '',
          description: '',
          mrpPrice: '',
          sellingPrice: '',
          stock: '',
          unit: 'kg',
          weight: '',
          tags: ''
        });
        setProductImages([]);
        setImagePreviews([]);
        fetchProducts();
        setActiveTab('products');
      }
    } catch (err) {
      showAlert('error', err.response?.data?.message || 'Failed to list product');
    } finally {
      setIsLoading(false);
    }
  };

  // API Call: Delete Product
  const handleDeleteProduct = async (productId) => {
    if (!window.confirm('Are you sure you want to delete this product?')) return;
    setIsLoading(true);
    try {
      const response = await axios.delete(`${apiBaseUrl}/products/${productId}`);
      if (response.data.success) {
        showAlert('success', 'Product deleted successfully');
        fetchProducts();
      }
    } catch (err) {
      showAlert('error', 'Failed to delete product');
    } finally {
      setIsLoading(false);
    }
  };

  // Geolocation trigger: update coordinates in backend
  const handleUpdateLocation = () => {
    if (!navigator.geolocation) {
      showAlert('error', 'Geolocation is not supported by your browser');
      return;
    }
    setIsLoading(true);
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const { latitude, longitude } = pos.coords;
        try {
          const response = await axios.put(`${apiBaseUrl}/auth/location`, {
            latitude,
            longitude,
            fullAddress: user?.address?.fullAddress || 'Updated via Web Panel',
            city: user?.address?.city || 'Browser City',
            state: user?.address?.state || 'Browser State',
            pincode: user?.address?.pincode || '000000'
          });
          if (response.data.success) {
            showAlert('success', 'Coordinates updated successfully in backend database!');
            fetchProfile();
          }
        } catch (err) {
          showAlert('error', 'Failed to update coordinates on backend');
        } finally {
          setIsLoading(false);
        }
      },
      (err) => {
        showAlert('error', 'Permission denied or location not acquired');
        setIsLoading(false);
      }
    );
  };

  // Handle image files selection
  const handleFileChange = (e) => {
    const files = Array.from(e.target.files);
    setProductImages(files);

    const previews = files.map(file => URL.createObjectURL(file));
    setImagePreviews(previews);
  };

  // API base URL configuration save
  const handleSaveSettings = (e) => {
    e.preventDefault();
    localStorage.setItem('vendor_api_url', apiBaseUrl);
    setShowSettings(false);
    showAlert('success', `API URL set to ${apiBaseUrl}`);
  };

  // Logout handler
  const handleLogout = () => {
    localStorage.removeItem('vendor_token');
    setToken('');
    setUser(null);
    setOtpSent(false);
    showAlert('success', 'Logged out successfully');
  };

  // Filter products listing belonging to current logged-in vendor only
  const myProducts = products.filter(p => p.vendorId === user?._id);

  // Authenticated State Layout
  const renderDashboard = () => (
    <div className="animate-fade-in">
      <div className="stats-grid">
        <div className="glass-card stat-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ color: 'var(--text-secondary)' }}>My Active Listings</span>
            <ShoppingBag color="var(--primary)" size={20} />
          </div>
          <div className="stat-value">{myProducts.length}</div>
        </div>
        <div className="glass-card stat-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ color: 'var(--text-secondary)' }}>Total System Products</span>
            <Boxes color="#60a5fa" size={20} />
          </div>
          <div className="stat-value">{products.length}</div>
        </div>
        <div className="glass-card stat-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ color: 'var(--text-secondary)' }}>Product Categories</span>
            <Tags color="#fb7185" size={20} />
          </div>
          <div className="stat-value">{categories.length}</div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '30px', marginTop: '30px' }}>
        {/* Quick Location card */}
        <div className="glass-card" style={{ padding: '30px', textAlign: 'left' }}>
          <h3 style={{ fontSize: '20px', marginBottom: '15px', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <MapPin color="var(--primary)" /> Store Geo-Coordinates
          </h3>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '20px', lineHeight: '1.6' }}>
            RiFresh INDIA demands precise location tracking for dynamic delivery route allocation. Bind your shop's active GPS coordinates using your browser location detector.
          </p>
          <div style={{ background: 'rgba(0, 0, 0, 0.2)', padding: '15px', borderRadius: '10px', marginBottom: '20px', fontSize: '14px' }}>
            <div style={{ marginBottom: '8px' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Latitude: </span>
              <strong style={{ color: 'var(--primary)' }}>{user?.address?.location?.latitude || '0.0'}</strong>
            </div>
            <div>
              <span style={{ color: 'var(--text-secondary)' }}>Longitude: </span>
              <strong style={{ color: 'var(--primary)' }}>{user?.address?.location?.longitude || '0.0'}</strong>
            </div>
          </div>
          <button className="btn btn-primary" onClick={handleUpdateLocation} style={{ width: '100%' }}>
            <Navigation size={18} /> Update Store Coordinates
          </button>
        </div>

        {/* Dynamic Category Summary */}
        <div className="glass-card" style={{ padding: '30px', textAlign: 'left' }}>
          <h3 style={{ fontSize: '20px', marginBottom: '15px', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Tags color="var(--primary)" /> Categories Overview
          </h3>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '20px' }}>
            Add new categories or view existing departments matching the Organic Growers catalog.
          </p>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
            {categories.map((c) => (
              <span key={c._id} style={{ background: 'rgba(255, 255, 255, 0.05)', border: '1px solid rgba(255, 255, 255, 0.1)', padding: '6px 14px', borderRadius: '20px', fontSize: '13px' }}>
                {c.name}
              </span>
            ))}
            {categories.length === 0 && <div style={{ color: 'var(--text-muted)' }}>No categories listed yet.</div>}
          </div>
        </div>
      </div>
    </div>
  );

  const renderProducts = () => (
    <div className="animate-fade-in" style={{ textAlign: 'left' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' }}>
        <div>
          <h2 style={{ fontSize: '26px', color: 'var(--text-primary)' }}>Listed Products ({myProducts.length})</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>Add and manage your inventory here.</p>
        </div>
        <button className="btn btn-primary" onClick={() => setActiveTab('addProduct')}>
          <Plus size={18} /> Add New Product
        </button>
      </div>

      <div className="products-grid">
        {myProducts.map((p) => {
          const mainImage = p.images && p.images.length > 0 ? `${apiBaseUrl.replace('/api', '')}/${p.images[0].replace(/\\/g, '/')}` : '';
          return (
            <div className="glass-card product-card" key={p._id}>
              <div className="product-image-container">
                {mainImage ? (
                  <img src={mainImage} className="product-img" alt={p.productName} />
                ) : (
                  <ImageIcon className="product-placeholder-img" size={48} />
                )}
                <span className="product-category-tag">{p.categoryId?.name || 'Uncategorized'}</span>
              </div>
              <div className="product-info">
                <h4 className="product-title">{p.productName}</h4>
                <p style={{ color: 'var(--text-secondary)', fontSize: '13px', display: '-webkit-box', WebkitLineClamp: '2', WebkitBoxOrient: 'vertical', overflow: 'hidden', height: '36px', marginBottom: '10px' }}>
                  {p.description || 'No description listed.'}
                </p>
                <div className="product-prices">
                  <span className="selling-price">₹{p.sellingPrice}</span>
                  {p.mrpPrice > p.sellingPrice && <span className="mrp-price">₹{p.mrpPrice}</span>}
                </div>
                <div className="product-meta-row">
                  <div className="meta-item">Stock: <span className="meta-value" style={{ color: p.stock > 0 ? 'var(--primary)' : 'var(--danger)' }}>{p.stock > 0 ? `${p.stock} units` : 'Out of Stock'}</span></div>
                  <div className="meta-item">Weight: <span className="meta-value">{p.weight} {p.unit}</span></div>
                </div>
                <button className="btn btn-danger" onClick={() => handleDeleteProduct(p._id)} style={{ marginTop: '15px', width: '100%', padding: '8px' }}>
                  <Trash2 size={15} /> Delete Listing
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {myProducts.length === 0 && (
        <div className="glass-card" style={{ padding: '80px 20px', textAlign: 'center' }}>
          <ShoppingBag size={48} color="var(--text-muted)" style={{ marginBottom: '20px' }} />
          <h3 style={{ fontSize: '20px', marginBottom: '10px' }}>No Products Listed</h3>
          <p style={{ color: 'var(--text-secondary)', marginBottom: '20px' }}>You haven't listed any organic items yet.</p>
          <button className="btn btn-primary" onClick={() => setActiveTab('addProduct')}>
            <Plus size={18} /> Add Your First Product
          </button>
        </div>
      )}
    </div>
  );

  const renderAddProduct = () => (
    <div className="animate-fade-in" style={{ textAlign: 'left', maxWidth: '800px', margin: '0 auto' }}>
      <h2 style={{ fontSize: '26px', color: 'var(--text-primary)', marginBottom: '10px' }}>Add Product Details</h2>
      <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '30px' }}>Provide accurate information for your organic product listing.</p>

      <form onSubmit={handleAddProduct} className="glass-card" style={{ padding: '40px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
          <div className="input-group">
            <label className="input-label">Product Name *</label>
            <input 
              type="text" 
              className="input-field" 
              placeholder="e.g. Fresh Organic Mushroom"
              value={newProduct.productName} 
              onChange={e => setNewProduct({...newProduct, productName: e.target.value})}
              required 
            />
          </div>

          <div className="input-group">
            <label className="input-label">Product Category *</label>
            <select 
              className="input-field"
              value={newProduct.categoryId}
              onChange={e => setNewProduct({...newProduct, categoryId: e.target.value})}
              required
            >
              <option value="">-- Choose Category --</option>
              {categories.map((c) => (
                <option key={c._id} value={c._id}>{c.name}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="input-group">
          <label className="input-label">Product Description</label>
          <textarea 
            className="input-field" 
            placeholder="Tell customers about the quality, origin and health benefits..." 
            rows="4"
            value={newProduct.description}
            onChange={e => setNewProduct({...newProduct, description: e.target.value})}
            style={{ resize: 'none' }}
          ></textarea>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '20px' }}>
          <div className="input-group">
            <label className="input-label">MRP Price (₹) *</label>
            <input 
              type="number" 
              className="input-field" 
              placeholder="e.g. 150"
              value={newProduct.mrpPrice} 
              onChange={e => setNewProduct({...newProduct, mrpPrice: e.target.value})}
              required 
            />
          </div>

          <div className="input-group">
            <label className="input-label">Selling Price (₹) *</label>
            <input 
              type="number" 
              className="input-field" 
              placeholder="e.g. 120"
              value={newProduct.sellingPrice} 
              onChange={e => setNewProduct({...newProduct, sellingPrice: e.target.value})}
              required 
            />
          </div>

          <div className="input-group">
            <label className="input-label">Available Stock *</label>
            <input 
              type="number" 
              className="input-field" 
              placeholder="e.g. 50"
              value={newProduct.stock} 
              onChange={e => setNewProduct({...newProduct, stock: e.target.value})}
              required 
            />
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '20px' }}>
          <div className="input-group">
            <label className="input-label">Unit *</label>
            <select 
              className="input-field"
              value={newProduct.unit}
              onChange={e => setNewProduct({...newProduct, unit: e.target.value})}
              required
            >
              <option value="kg">kg</option>
              <option value="gm">gm</option>
              <option value="packet">packet</option>
              <option value="piece">piece</option>
            </select>
          </div>

          <div className="input-group">
            <label className="input-label">Weight per Unit *</label>
            <input 
              type="number" 
              className="input-field" 
              placeholder="e.g. 1"
              value={newProduct.weight} 
              onChange={e => setNewProduct({...newProduct, weight: e.target.value})}
              required 
            />
          </div>

          <div className="input-group">
            <label className="input-label">Tags (comma separated)</label>
            <input 
              type="text" 
              className="input-field" 
              placeholder="e.g. organic, fresh, direct"
              value={newProduct.tags} 
              onChange={e => setNewProduct({...newProduct, tags: e.target.value})} 
            />
          </div>
        </div>

        {/* File upload section */}
        <div className="input-group" style={{ marginTop: '10px', marginBottom: '30px' }}>
          <label className="input-label">Product Images (Up to 5)</label>
          <div style={{ display: 'flex', gap: '15px', alignItems: 'center' }}>
            <label className="btn btn-secondary" style={{ display: 'inline-flex', cursor: 'pointer' }}>
              <ImageIcon size={18} /> Select Images
              <input 
                type="file" 
                multiple 
                accept="image/*" 
                onChange={handleFileChange} 
                style={{ display: 'none' }} 
              />
            </label>
            <span style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>
              {productImages.length} file(s) selected
            </span>
          </div>

          {imagePreviews.length > 0 && (
            <div style={{ display: 'flex', gap: '10px', marginTop: '15px', overflowX: 'auto', padding: '10px 0' }}>
              {imagePreviews.map((preview, i) => (
                <div key={i} style={{ width: '80px', height: '80px', borderRadius: '8px', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.1)' }}>
                  <img src={preview} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="Preview" />
                </div>
              ))}
            </div>
          )}
        </div>

        <div style={{ display: 'flex', gap: '15px', justifyContent: 'flex-end' }}>
          <button type="button" className="btn btn-secondary" onClick={() => setActiveTab('products')}>Cancel</button>
          <button type="submit" className="btn btn-primary">
            {isLoading ? <Loader2 className="animate-spin" size={18} /> : 'List Product'}
          </button>
        </div>
      </form>
    </div>
  );

  const renderCategories = () => (
    <div className="animate-fade-in" style={{ textAlign: 'left', maxWidth: '700px', margin: '0 auto' }}>
      <h2 style={{ fontSize: '26px', color: 'var(--text-primary)', marginBottom: '10px' }}>Product Categories</h2>
      <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '30px' }}>View all categories in the system or register a new organic category.</p>

      <form onSubmit={handleAddCategory} className="glass-card" style={{ padding: '30px', marginBottom: '40px', display: 'flex', gap: '15px', alignItems: 'flex-end' }}>
        <div className="input-group" style={{ flex: 1, marginBottom: 0 }}>
          <label className="input-label">New Category Name</label>
          <input 
            type="text" 
            className="input-field" 
            placeholder="e.g. Leafy Greens" 
            value={newCategoryName}
            onChange={e => setNewCategoryName(e.target.value)}
            required
          />
        </div>
        <button type="submit" className="btn btn-primary" style={{ padding: '14px 24px' }}>
          <FolderPlus size={18} /> Create Category
        </button>
      </form>

      <div className="glass-card" style={{ padding: '30px' }}>
        <h3 style={{ fontSize: '18px', marginBottom: '20px' }}>System Categories catalog</h3>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
          {categories.map((c, i) => (
            <div key={c._id} style={{ background: 'rgba(255, 255, 255, 0.03)', border: '1px solid rgba(255, 255, 255, 0.05)', padding: '14px 20px', borderRadius: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: '500' }}>{c.name}</span>
              <span style={{ color: 'var(--text-muted)', fontSize: '12px' }}>ID: #{c._id.slice(-6)}</span>
            </div>
          ))}
          {categories.length === 0 && <div style={{ color: 'var(--text-muted)', gridColumn: 'span 2', textAlign: 'center' }}>No categories registered.</div>}
        </div>
      </div>
    </div>
  );

  const renderProfile = () => (
    <div className="animate-fade-in" style={{ textAlign: 'left', maxWidth: '700px', margin: '0 auto' }}>
      <h2 style={{ fontSize: '26px', color: 'var(--text-primary)', marginBottom: '10px' }}>Vendor Account Profile</h2>
      <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '30px' }}>Manage your shop's address and dynamic platform configurations.</p>

      <div className="glass-card" style={{ padding: '40px' }}>
        <div style={{ display: 'flex', gap: '20px', alignItems: 'center', marginBottom: '30px', borderBottom: '1px solid rgba(255, 255, 255, 0.05)', paddingBottom: '20px' }}>
          <div style={{ width: '80px', height: '80px', borderRadius: '50%', background: 'var(--primary-glow)', border: '2px solid var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)' }}>
            <User size={38} />
          </div>
          <div>
            <h3 style={{ fontSize: '22px', fontWeight: '700' }}>{user?.name || 'Organic Vendor'}</h3>
            <span style={{ background: 'rgba(16, 185, 129, 0.15)', border: '1px solid var(--primary)', color: 'var(--primary)', padding: '3px 12px', borderRadius: '20px', fontSize: '12px', fontWeight: '700', textTransform: 'uppercase', marginTop: '6px', display: 'inline-block' }}>
              {user?.role}
            </span>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '25px', marginBottom: '30px' }}>
          <div>
            <span style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>Registered Phone</span>
            <div style={{ fontSize: '16px', fontWeight: '600', marginTop: '4px' }}>{user?.phone || 'Not Available'}</div>
          </div>
          <div>
            <span style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>Email Address</span>
            <div style={{ fontSize: '16px', fontWeight: '600', marginTop: '4px' }}>{user?.email || 'Not Available'}</div>
          </div>
        </div>

        <div style={{ borderTop: '1px solid rgba(255,255,255,0.05)', paddingTop: '20px' }}>
          <span style={{ color: 'var(--text-secondary)', fontSize: '13px', display: 'block', marginBottom: '8px' }}>Store Address</span>
          <div style={{ background: 'rgba(0, 0, 0, 0.15)', padding: '20px', borderRadius: '10px' }}>
            <div style={{ fontSize: '15px', fontWeight: '500', lineHeight: '1.6' }}>{user?.address?.fullAddress || 'No Address registered'}</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '15px', marginTop: '15px', fontSize: '13px', borderTop: '1px solid rgba(255,255,255,0.05)', paddingTop: '15px' }}>
              <div><span style={{ color: 'var(--text-secondary)' }}>City: </span><strong>{user?.address?.city || '-'}</strong></div>
              <div><span style={{ color: 'var(--text-secondary)' }}>State: </span><strong>{user?.address?.state || '-'}</strong></div>
              <div><span style={{ color: 'var(--text-secondary)' }}>Pincode: </span><strong>{user?.address?.pincode || '-'}</strong></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  // Core Login Screen View
  const renderLogin = () => (
    <div style={{ minHeight: '80vh', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '100%' }}>
      <div className="glass-card animate-fade-in" style={{ padding: '40px', width: '100%', maxWidth: '440px', textAlign: 'center' }}>
        <h2 style={{ fontSize: '32px', fontWeight: '800', marginBottom: '8px' }}>
          RiFresh <span className="logo-highlight">INDIA</span>
        </h2>
        <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '30px' }}>
          Premium Vendor Panel for Organic Growers App
        </p>

        {!otpSent ? (
          <form onSubmit={handleSendOtp}>
            <div className="input-group">
              <label className="input-label">Enter Registered Phone Number</label>
              <input 
                type="text" 
                className="input-field" 
                placeholder="Phone Number (e.g. 9548621727)" 
                value={phone}
                onChange={e => setPhone(e.target.value)}
                maxLength={10}
                required
              />
            </div>
            <button type="submit" className="btn btn-primary" style={{ width: '100%', padding: '14px' }}>
              {isLoading ? <Loader2 className="animate-spin" size={18} /> : 'Send Verification OTP'}
            </button>
          </form>
        ) : (
          <form onSubmit={handleVerifyOtp}>
            <div className="input-group">
              <label className="input-label">Verification Code (OTP)</label>
              <input 
                type="text" 
                className="input-field" 
                placeholder="Enter 4-Digit OTP (e.g. 1234)" 
                value={otp}
                onChange={e => setOtp(e.target.value)}
                maxLength={4}
                required
              />
            </div>
            <button type="submit" className="btn btn-primary" style={{ width: '100%', padding: '14px', marginBottom: '15px' }}>
              {isLoading ? <Loader2 className="animate-spin" size={18} /> : 'Verify & Continue'}
            </button>
            <button type="button" className="btn btn-secondary" onClick={() => setOtpSent(false)} style={{ width: '100%' }}>
              Back
            </button>
          </form>
        )}
      </div>
    </div>
  );

  // New Vendor Onboarding Profile Registration Form
  const renderOnboarding = () => (
    <div style={{ minHeight: '90vh', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '100%', padding: '40px 0' }}>
      <div className="glass-card animate-fade-in" style={{ padding: '40px', width: '100%', maxWidth: '640px' }}>
        <h2 style={{ fontSize: '28px', fontWeight: '800', marginBottom: '8px', textAlign: 'center' }}>
          Vendor Onboarding
        </h2>
        <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '35px', textAlign: 'center' }}>
          Complete your profile registration to open your online organic store catalog.
        </p>

        <form onSubmit={handleRegister}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
            <div className="input-group">
              <label className="input-label">Full Name *</label>
              <input 
                type="text" 
                className="input-field" 
                placeholder="e.g. Udit Pal"
                value={regForm.name} 
                onChange={e => setRegForm({...regForm, name: e.target.value})}
                required 
              />
            </div>
            <div className="input-group">
              <label className="input-label">Email Address *</label>
              <input 
                type="email" 
                className="input-field" 
                placeholder="e.g. paludit@gmail.com"
                value={regForm.email} 
                onChange={e => setRegForm({...regForm, email: e.target.value})}
                required 
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
            <div className="input-group">
              <label className="input-label">Postal Pincode *</label>
              <input 
                type="text" 
                className="input-field" 
                placeholder="6-digit pincode"
                value={regForm.pincode} 
                onChange={e => setRegForm({...regForm, pincode: e.target.value})}
                required 
              />
            </div>
            <div className="input-group">
              <label className="input-label">City *</label>
              <input 
                type="text" 
                className="input-field" 
                placeholder="e.g. Bhubaneswar"
                value={regForm.city} 
                onChange={e => setRegForm({...regForm, city: e.target.value})}
                required 
              />
            </div>
          </div>

          <div className="input-group">
            <label className="input-label">State *</label>
            <input 
              type="text" 
              className="input-field" 
              placeholder="e.g. Odisha"
              value={regForm.state} 
              onChange={e => setRegForm({...regForm, state: e.target.value})}
              required 
            />
          </div>

          <div className="input-group" style={{ marginBottom: '30px' }}>
            <label className="input-label">Shop Full Address *</label>
            <input 
              type="text" 
              className="input-field" 
              placeholder="e.g. Unit 3, Organic Market, Bhubaneswar"
              value={regForm.fullAddress} 
              onChange={e => setRegForm({...regForm, fullAddress: e.target.value})}
              required 
            />
          </div>

          <button type="submit" className="btn btn-primary" style={{ width: '100%', padding: '14px' }}>
            {isLoading ? <Loader2 className="animate-spin" size={18} /> : 'Complete Registration'}
          </button>
        </form>
      </div>
    </div>
  );

  return (
    <div className="App">
      {/* Dynamic Status Alert banners at top */}
      {statusMessage.text && (
        <div style={{ 
          position: 'fixed', 
          top: '20px', 
          left: '50%', 
          transform: 'translateX(-50%)', 
          zIndex: 9999, 
          display: 'flex', 
          alignItems: 'center', 
          gap: '10px', 
          padding: '14px 24px', 
          borderRadius: '12px', 
          border: '1px solid',
          background: 'rgba(11, 22, 17, 0.95)',
          backdropFilter: 'blur(8px)',
          boxShadow: '0 10px 30px rgba(0,0,0,0.5)',
          color: statusMessage.type === 'success' ? '#6ee7b7' : '#fca5a5',
          borderColor: statusMessage.type === 'success' ? 'rgba(16, 185, 129, 0.4)' : 'rgba(239, 68, 68, 0.4)',
          animation: 'fadeIn 0.25s ease'
        }}>
          {statusMessage.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
          <span style={{ fontSize: '14px', fontWeight: '600' }}>{statusMessage.text}</span>
        </div>
      )}

      {/* Global Navbar Header */}
      <header className="navbar">
        <div className="container navbar-content">
          <div className="logo">
            <span>RiFresh</span><span className="logo-highlight">INDIA</span>
            <span style={{ fontSize: '11px', background: 'var(--primary-glow)', border: '1px solid rgba(16,185,129,0.3)', padding: '2px 8px', borderRadius: '4px', textTransform: 'uppercase', color: 'var(--primary)', marginLeft: '10px' }}>
              Vendor Panel
            </span>
          </div>

          <div style={{ display: 'flex', gap: '15px', alignItems: 'center' }}>
            <button className="btn btn-secondary" style={{ padding: '8px' }} onClick={() => setShowSettings(!showSettings)}>
              <Settings size={18} />
            </button>
            {token && user && !registrationRequired && (
              <>
                <div className="user-badge">
                  <User size={14} color="var(--primary)" />
                  <span style={{ fontSize: '13px', fontWeight: '600' }}>{user.name}</span>
                </div>
                <button className="btn btn-secondary" onClick={handleLogout} style={{ padding: '8px 12px' }}>
                  <LogOut size={16} /> Logout
                </button>
              </>
            )}
          </div>
        </div>
      </header>

      {/* Settings Modal (Config Base API URL) */}
      {showSettings && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.8)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <form onSubmit={handleSaveSettings} className="glass-card animate-fade-in" style={{ padding: '30px', width: '90%', maxWidth: '440px', textAlign: 'left' }}>
            <h3 style={{ fontSize: '20px', marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '10px' }}><Settings /> Configure Server URL</h3>
            <div className="input-group">
              <label className="input-label">Backend API Base Endpoint</label>
              <input 
                type="text" 
                className="input-field" 
                placeholder="e.g. http://localhost:5000/api" 
                value={apiBaseUrl}
                onChange={e => setApiBaseUrl(e.target.value)}
                required
              />
            </div>
            <p style={{ color: 'var(--text-secondary)', fontSize: '12px', marginBottom: '25px', lineHeight: '1.5' }}>
              Make sure this matches the network address of your running Express backend. If testing on local computer, use <code>http://localhost:5000/api</code>.
            </p>
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
              <button type="button" className="btn btn-secondary" onClick={() => setShowSettings(false)}>Close</button>
              <button type="submit" className="btn btn-primary">Save Settings</button>
            </div>
          </form>
        </div>
      )}

      {/* Primary Application Page router */}
      <main className="container" style={{ flex: 1, paddingBottom: '80px' }}>
        {!token ? (
          renderLogin()
        ) : registrationRequired ? (
          renderOnboarding()
        ) : (
          <div className="dashboard-grid">
            {/* Sidebar navigation */}
            <aside>
              <div className="glass-card" style={{ padding: '24px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <button 
                  className={`btn ${activeTab === 'dashboard' ? 'btn-primary' : 'btn-secondary'}`}
                  style={{ justifyContent: 'flex-start', width: '100%', padding: '14px 20px' }}
                  onClick={() => setActiveTab('dashboard')}
                >
                  <LayoutDashboard size={18} /> Overview Dashboard
                </button>
                <button 
                  className={`btn ${activeTab === 'products' || activeTab === 'addProduct' ? 'btn-primary' : 'btn-secondary'}`}
                  style={{ justifyContent: 'flex-start', width: '100%', padding: '14px 20px' }}
                  onClick={() => setActiveTab('products')}
                >
                  <ShoppingBag size={18} /> Manage Products
                </button>
                <button 
                  className={`btn ${activeTab === 'categories' ? 'btn-primary' : 'btn-secondary'}`}
                  style={{ justifyContent: 'flex-start', width: '100%', padding: '14px 20px' }}
                  onClick={() => setActiveTab('categories')}
                >
                  <Tags size={18} /> Product Categories
                </button>
                <button 
                  className={`btn ${activeTab === 'profile' ? 'btn-primary' : 'btn-secondary'}`}
                  style={{ justifyContent: 'flex-start', width: '100%', padding: '14px 20px' }}
                  onClick={() => setActiveTab('profile')}
                >
                  <User size={18} /> Store Profile
                </button>

                <div style={{ marginTop: '30px', paddingTop: '20px', borderTop: '1px solid rgba(255,255,255,0.05)', textAlign: 'left' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: 'var(--text-secondary)' }}>
                    <ShieldCheck size={14} color="var(--primary)" /> Secure JWT Session
                  </div>
                </div>
              </div>
            </aside>

            {/* Dynamic Dashboard views */}
            <section style={{ minWidth: 0 }}>
              {activeTab === 'dashboard' && renderDashboard()}
              {activeTab === 'products' && renderProducts()}
              {activeTab === 'addProduct' && renderAddProduct()}
              {activeTab === 'categories' && renderCategories()}
              {activeTab === 'profile' && renderProfile()}
            </section>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
