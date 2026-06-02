// State Variables
let token = localStorage.getItem('vendor_token') || null;
let currentVendor = null;
let currentTab = 'dashboard-tab';
let allCategories = [];
let allProducts = [];
let allOrders = [];
let tempPhone = '';

const API_BASE = '/api';

// On Document Load
document.addEventListener('DOMContentLoaded', () => {
  lucide.createIcons();
  
  if (token) {
    loadVendorDashboard();
  } else {
    showScreen('landing-screen');
  }

  // Load Categories on startup
  fetchCategories();
});

// Screen management
function showScreen(screenId) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  document.getElementById(screenId).classList.add('active');
}

function switchTab(tabId, el) {
  document.querySelectorAll('.tab-view').forEach(t => t.classList.remove('active'));
  document.getElementById(tabId).classList.add('active');
  
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  el.classList.add('active');
  
  currentTab = tabId;
  
  // Set Page Title
  const titleText = el.textContent.trim();
  document.getElementById('tab-title').textContent = titleText;

  if (tabId === 'products-tab') {
    fetchProducts();
  } else if (tabId === 'orders-tab') {
    fetchOrders();
  } else if (tabId === 'profile-tab') {
    fillProfileForm();
  }
}

// ----------------------------------------------------
// AUTHENTICATION & LOGIN FLOW
// ----------------------------------------------------
async function handleSendOTP(event) {
  event.preventDefault();
  const phone = document.getElementById('login-phone').value;
  tempPhone = phone;

  try {
    const res = await fetch(`${API_BASE}/auth/send-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone })
    });
    const data = await res.json();
    
    if (data.success) {
      alert(`OTP Sent! Use: ${data.otp}`); // Convenient alert showing hardcoded OTP
      document.getElementById('login-form').classList.add('hidden');
      document.getElementById('otp-form').classList.remove('hidden');
    } else {
      alert(data.message || 'Failed to send OTP');
    }
  } catch (err) {
    alert('Error sending OTP. Make sure backend is running.');
  }
}

async function handleVerifyOTP(event) {
  event.preventDefault();
  const o1 = document.getElementById('otp-1').value;
  const o2 = document.getElementById('otp-2').value;
  const o3 = document.getElementById('otp-3').value;
  const o4 = document.getElementById('otp-4').value;
  const otp = `${o1}${o2}${o3}${o4}`;

  try {
    const res = await fetch(`${API_BASE}/auth/verify-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: tempPhone, otp })
    });
    const data = await res.json();

    if (data.success) {
      token = data.token;
      localStorage.setItem('vendor_token', token);
      
      // If user role is not vendor, prompt them to onboard
      if (data.user.role !== 'vendor') {
        alert('You do not have a vendor store profile. Let\'s onboard you!');
        showScreen('register-screen');
        // Pre-fill email, phone, name in step 3 directly
        document.getElementById('register-step-1').classList.add('hidden');
        document.getElementById('register-step-2').classList.remove('hidden');
        document.getElementById('store-owner').value = data.user.name || '';
        document.getElementById('store-name').value = data.user.name ? `${data.user.name}'s Farm` : '';
      } else {
        loadVendorDashboard();
      }
    } else {
      alert(data.message || 'Invalid OTP');
    }
  } catch (err) {
    alert('Error verifying OTP.');
  }
}

// Focus movement helper
function moveFocus(current, nextId) {
  if (current.value.length === 1) {
    document.getElementById(nextId).focus();
  }
}

function fetchLiveCoordinates(latId, lngId) {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        document.getElementById(latId).value = position.coords.latitude.toFixed(6);
        document.getElementById(lngId).value = position.coords.longitude.toFixed(6);
        alert('Location detected successfully! 📍');
      },
      (error) => {
        alert('Failed to detect location. Please type coordinates manually or allow browser location permission.');
      }
    );
  } else {
    alert('Geolocation is not supported by this browser.');
  }
}

// ----------------------------------------------------
// REGISTRATION & ONBOARDING
// ----------------------------------------------------
async function handleRegisterStep1(event) {
  event.preventDefault();
  const name = document.getElementById('reg-name').value;
  const email = document.getElementById('reg-email').value;
  const phone = document.getElementById('reg-phone').value;
  tempPhone = phone;

  try {
    const res = await fetch(`${API_BASE}/auth/send-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone })
    });
    const data = await res.json();

    if (data.success) {
      alert(`OTP Sent! Use: ${data.otp}`);
      document.getElementById('register-step-1').classList.add('hidden');
      document.getElementById('register-step-otp').classList.remove('hidden');
    } else {
      alert(data.message);
    }
  } catch (err) {
    alert('Error registering vendor step 1.');
  }
}

async function handleRegisterVerifyOTP(event) {
  event.preventDefault();
  const o1 = document.getElementById('reg-otp-1').value;
  const o2 = document.getElementById('reg-otp-2').value;
  const o3 = document.getElementById('reg-otp-3').value;
  const o4 = document.getElementById('reg-otp-4').value;
  const otp = `${o1}${o2}${o3}${o4}`;

  try {
    const res = await fetch(`${API_BASE}/auth/verify-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: tempPhone, otp })
    });
    const data = await res.json();

    if (data.success) {
      token = data.token;
      localStorage.setItem('vendor_token', token);

      // Now register basic user profile first
      const regName = document.getElementById('reg-name').value;
      const regEmail = document.getElementById('reg-email').value;
      
      await fetch(`${API_BASE}/auth/register`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          name: regName,
          email: regEmail,
          phone: tempPhone,
          role: 'vendor',
          fullAddress: 'Pending Onboarding',
          city: 'Bhubaneswar',
          state: 'Odisha',
          pincode: '751024'
        })
      });

      // Move to step 3 (Store details)
      document.getElementById('register-step-otp').classList.add('hidden');
      document.getElementById('register-step-2').classList.remove('hidden');
      document.getElementById('store-owner').value = regName;
      document.getElementById('store-name').value = `${regName}'s Store`;
    } else {
      alert(data.message || 'Verification Failed');
    }
  } catch (err) {
    alert('Error registering OTP.');
  }
}

async function handleOnboardStore(event) {
  event.preventDefault();
  const formData = new FormData();
  
  formData.append('shopName', document.getElementById('store-name').value);
  formData.append('ownerName', document.getElementById('store-owner').value);
  formData.append('phone', tempPhone);
  formData.append('description', document.getElementById('store-desc').value);
  formData.append('deliveryTime', document.getElementById('store-delivery-time').value);
  formData.append('minimumOrder', document.getElementById('store-min-order').value);
  
  const tagsStr = document.getElementById('store-tags').value;
  const tagsArr = tagsStr.split(',').map(t => t.trim()).filter(Boolean);
  formData.append('cuisineTags', JSON.stringify(tagsArr));
  
  formData.append('fullAddress', document.getElementById('store-address').value);
  formData.append('city', document.getElementById('store-city').value);
  formData.append('state', document.getElementById('store-state').value);
  formData.append('pincode', document.getElementById('store-pincode').value);
  formData.append('latitude', document.getElementById('store-lat').value);
  formData.append('longitude', document.getElementById('store-lng').value);
  formData.append('serviceRadius', document.getElementById('store-service-radius').value);
  
  const fileInput = document.getElementById('store-image');
  if (fileInput.files.length > 0) {
    formData.append('shopImage', fileInput.files[0]);
  }

  try {
    const res = await fetch(`${API_BASE}/vendors/onboard`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      },
      body: formData
    });
    const data = await res.json();

    if (data.success) {
      alert('Congratulations! Your store is onboarded and live! 🎉');
      loadVendorDashboard();
    } else {
      alert(data.message || 'Onboarding failed');
    }
  } catch (err) {
    alert('Error creating store profile.');
  }
}

// ----------------------------------------------------
// DASHBOARD & STATE LOADER
// ----------------------------------------------------
async function loadVendorDashboard() {
  try {
    const res = await fetch(`${API_BASE}/vendors/panel/dashboard`, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await res.json();

    if (data.success) {
      currentVendor = data.vendor;
      showScreen('dashboard-screen');
      
      // Update UI elements
      document.getElementById('side-shop-name').textContent = currentVendor.shopName;
      document.getElementById('header-owner-name').textContent = currentVendor.ownerName;
      document.getElementById('header-avatar').textContent = currentVendor.ownerName.charAt(0).toUpperCase();
      
      // Update Stats
      document.getElementById('stat-earnings').textContent = `₹${data.stats.totalEarnings.toFixed(2)}`;
      document.getElementById('stat-orders').textContent = data.stats.totalOrders;
      document.getElementById('stat-active-orders').textContent = data.stats.activeOrders;
      document.getElementById('stat-products').textContent = data.stats.totalProducts;
      
      // Shop Open Toggle UI
      const shopToggle = document.getElementById('shop-toggle');
      const label = document.getElementById('shop-status-label');
      shopToggle.checked = currentVendor.isOpen;
      if (currentVendor.isOpen) {
        label.textContent = "Shop is Open";
        label.className = "status-open";
      } else {
        label.textContent = "Shop is Closed";
        label.className = "status-closed";
      }

      // Load Recent Orders
      fetchRecentOrders();
    } else {
      // Token expired or invalid
      handleLogout();
    }
  } catch (err) {
    alert('Failed to load dashboard.');
    handleLogout();
  }
}

async function toggleShopStatus() {
  try {
    const res = await fetch(`${API_BASE}/vendors/panel/toggle-shop`, {
      method: 'PUT',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await res.json();
    
    if (data.success) {
      currentVendor.isOpen = data.isOpen;
      const label = document.getElementById('shop-status-label');
      if (data.isOpen) {
        label.textContent = "Shop is Open";
        label.className = "status-open";
      } else {
        label.textContent = "Shop is Closed";
        label.className = "status-closed";
      }
      alert(data.message);
    }
  } catch (err) {
    alert('Failed to toggle status');
  }
}

// ----------------------------------------------------
// PRODUCT MANAGEMENT
// ----------------------------------------------------
async function fetchProducts() {
  try {
    const res = await fetch(`${API_BASE}/vendors/panel/products`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await res.json();
    if (data.success) {
      allProducts = data.products;
      renderProducts(allProducts);
    }
  } catch (err) {
    console.error('Failed to load products');
  }
}

function renderProducts(productsList) {
  const container = document.getElementById('vendor-products-grid');
  container.innerHTML = '';

  if (productsList.length === 0) {
    container.innerHTML = `
      <div class="col-span-2 text-center" style="grid-column: 1/-1; padding: 40px 0;">
        <i data-lucide="package-search" style="width: 48px; height: 48px; color: var(--text-secondary);"></i>
        <p style="margin-top: 12px; color: var(--text-secondary);">No products added yet. Click "Add New Product" to start!</p>
      </div>
    `;
    lucide.createIcons();
    return;
  }

  productsList.forEach(prod => {
    const imgUrl = prod.images && prod.images.length > 0 ? `/${prod.images[0]}` : 'https://cdn-icons-png.flaticon.com/512/3062/3062634.png';
    const card = document.createElement('div');
    card.className = 'product-card card hover-scale';
    card.innerHTML = `
      <div class="product-img-container">
        <img class="product-img" src="${imgUrl}" alt="${prod.productName}" onerror="this.src='https://cdn-icons-png.flaticon.com/512/3062/3062634.png'">
        <div class="product-badges">
          <span class="badge ${prod.isAvailable ? 'badge-success' : 'badge-danger'}">${prod.isAvailable ? 'Available' : 'Unavailable'}</span>
        </div>
        <div class="product-actions-overlay">
          <button class="action-icon-btn edit" onclick="editProduct('${prod._id}')" title="Edit">
            <i data-lucide="edit"></i>
          </button>
          <button class="action-icon-btn delete" onclick="deleteProduct('${prod._id}')" title="Delete">
            <i data-lucide="trash-2"></i>
          </button>
        </div>
      </div>
      <div class="product-body">
        <h3 class="product-title">${prod.productName}</h3>
        <p class="product-desc">${prod.description || 'No description provided.'}</p>
        <div class="product-footer">
          <div class="price-box">
            <span class="selling-price">₹${prod.sellingPrice}</span>
            <span class="mrp-price">₹${prod.mrpPrice}</span>
          </div>
          <span class="badge badge-success" style="background: rgba(255,255,255,0.05); text-transform:none; border: 1px solid var(--border-color); color: var(--text-primary); font-size: 0.75rem;">
            ${prod.weight} ${prod.unit}
          </span>
        </div>
      </div>
    `;
    container.appendChild(card);
  });
  lucide.createIcons();
}

function filterProducts(query) {
  const filtered = allProducts.filter(p => p.productName.toLowerCase().includes(query.toLowerCase()));
  renderProducts(filtered);
}

// Category lists fetching
async function fetchCategories() {
  try {
    const res = await fetch(`${API_BASE}/categories`);
    const data = await res.json();
    if (data.success) {
      allCategories = data.categories;
      const select = document.getElementById('prod-category');
      select.innerHTML = allCategories.map(cat => `<option value="${cat._id}">${cat.name}</option>`).join('');
    }
  } catch (err) {
    console.error('Failed to fetch categories');
  }
}

// Modal Products Add/Edit
function openAddProductModal() {
  document.getElementById('modal-title').textContent = 'Add New Product';
  document.getElementById('product-form').reset();
  document.getElementById('prod-id').value = '';
  document.getElementById('product-modal').classList.add('active');
  document.getElementById('prod-images').required = true;

  // Clear the image preview container
  const previewContainer = document.getElementById('product-images-preview');
  if (previewContainer) {
    previewContainer.innerHTML = '';
  }
}

function closeProductModal() {
  document.getElementById('product-modal').classList.remove('active');
}

async function handleSubmitProduct(event) {
  event.preventDefault();
  const prodId = document.getElementById('prod-id').value;
  const isEditing = !!prodId;

  const formData = new FormData();
  formData.append('productName', document.getElementById('prod-name').value);
  formData.append('categoryId', document.getElementById('prod-category').value);
  formData.append('unit', document.getElementById('prod-unit').value);
  formData.append('weight', document.getElementById('prod-weight').value);
  formData.append('mrpPrice', document.getElementById('prod-mrp').value);
  formData.append('sellingPrice', document.getElementById('prod-price').value);
  formData.append('stock', document.getElementById('prod-stock').value);
  formData.append('description', document.getElementById('prod-desc').value);

  const imagesInput = document.getElementById('prod-images');
  if (imagesInput.files.length > 0) {
    for (let i = 0; i < imagesInput.files.length; i++) {
      formData.append('images', imagesInput.files[i]);
    }
  }

  const url = isEditing ? `${API_BASE}/products/${prodId}` : `${API_BASE}/products/add`;
  const method = isEditing ? 'PUT' : 'POST';

  try {
    const res = await fetch(url, {
      method: method,
      headers: { 'Authorization': `Bearer ${token}` },
      body: formData
    });
    const data = await res.json();

    if (data.success) {
      alert(data.message);
      closeProductModal();
      fetchProducts();
    } else {
      alert(data.message);
    }
  } catch (err) {
    alert('Failed to save product');
  }
}

function editProduct(productId) {
  const prod = allProducts.find(p => p._id === productId);
  if (!prod) return;

  document.getElementById('modal-title').textContent = 'Edit Product';
  document.getElementById('prod-id').value = prod._id;
  document.getElementById('prod-name').value = prod.productName;
  document.getElementById('prod-category').value = prod.categoryId?._id || prod.categoryId;
  document.getElementById('prod-unit').value = prod.unit;
  document.getElementById('prod-weight').value = prod.weight;
  document.getElementById('prod-mrp').value = prod.mrpPrice;
  document.getElementById('prod-price').value = prod.sellingPrice;
  document.getElementById('prod-stock').value = prod.stock;
  document.getElementById('prod-desc').value = prod.description || '';
  
  // Images are optional when editing
  document.getElementById('prod-images').required = false;

  // Render existing images in the preview container
  const previewContainer = document.getElementById('product-images-preview');
  if (previewContainer) {
    previewContainer.innerHTML = '';
    if (prod.images && prod.images.length > 0) {
      prod.images.forEach(img => {
        const wrapper = document.createElement('div');
        wrapper.style = "width: 70px; height: 70px; border-radius: 8px; overflow: hidden; border: 1px solid rgba(255,255,255,0.1); flex-shrink: 0; position: relative;";
        const src = img.startsWith('/') ? img : '/' + img;
        wrapper.innerHTML = `<img src="${src}" style="width:100%; height:100%; object-fit:cover;" onerror="this.src='https://cdn-icons-png.flaticon.com/512/3062/3062634.png'">`;
        previewContainer.appendChild(wrapper);
      });
    }
  }

  document.getElementById('product-modal').classList.add('active');
}

async function deleteProduct(productId) {
  if (!confirm('Are you sure you want to delete this product?')) return;
  try {
    const res = await fetch(`${API_BASE}/products/${productId}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await res.json();
    if (data.success) {
      alert('Product deleted successfully');
      fetchProducts();
    }
  } catch (err) {
    alert('Failed to delete product');
  }
}

// ----------------------------------------------------
// ORDERS MANAGEMENT
// ----------------------------------------------------
async function fetchOrders() {
  try {
    const res = await fetch(`${API_BASE}/vendors/panel/orders`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await res.json();
    if (data.success) {
      allOrders = data.orders;
      renderOrders(allOrders);
    }
  } catch (err) {
    console.error('Failed to load orders');
  }
}

async function fetchRecentOrders() {
  try {
    const res = await fetch(`${API_BASE}/vendors/panel/orders?status=pending`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await res.json();
    if (data.success) {
      const container = document.getElementById('recent-orders-list');
      container.innerHTML = '';
      
      const pend = data.orders.slice(0, 5);
      
      // Update badge
      const pendingBadge = document.getElementById('pending-orders-count');
      if (data.orders.length > 0) {
        pendingBadge.textContent = data.orders.length;
        pendingBadge.classList.remove('hidden');
      } else {
        pendingBadge.classList.add('hidden');
      }

      if (pend.length === 0) {
        container.innerHTML = '<tr><td colspan="5" class="text-center">No pending orders.</td></tr>';
        return;
      }

      pend.forEach(ord => {
        const row = document.createElement('tr');
        row.innerHTML = `
          <td>#${ord._id.slice(-8).toUpperCase()}</td>
          <td>${ord.customerId?.name || 'Customer'}</td>
          <td>₹${ord.totalAmount}</td>
          <td><span class="badge badge-danger" style="background:var(--orange-light); color:var(--orange);">Pending</span></td>
          <td>
            <button class="btn btn-primary btn-sm" onclick="updateStatus('${ord._id}', 'accepted')">Accept</button>
          </td>
        `;
        container.appendChild(row);
      });
    }
  } catch (err) {
    console.error('Failed to load recent orders');
  }
}

function renderOrders(ordersList) {
  const container = document.getElementById('vendor-orders-list');
  container.innerHTML = '';

  if (ordersList.length === 0) {
    container.innerHTML = `
      <div class="text-center" style="padding: 40px 0;">
        <i data-lucide="receipt" style="width: 48px; height: 48px; color: var(--text-secondary);"></i>
        <p style="margin-top: 12px; color: var(--text-secondary);">No orders found matching this filter.</p>
      </div>
    `;
    lucide.createIcons();
    return;
  }

  ordersList.forEach(ord => {
    const card = document.createElement('div');
    card.className = `order-card card status-${ord.orderStatus} hover-scale`;
    
    const statusMap = {
      pending: { text: 'Pending', cls: 'badge-danger' },
      accepted: { text: 'Accepted', cls: 'badge-success' },
      packed: { text: 'Packed — Awaiting Rider', cls: 'badge-warning' },
      ready_for_pickup: { text: 'Ready for Pickup 🛵', cls: 'badge-info' },
      out_for_delivery: { text: 'Out for Delivery', cls: 'badge-success' },
      delivered: { text: 'Delivered ✓', cls: 'badge-success' },
      cancelled: { text: 'Cancelled', cls: 'badge-danger' },
    };
    const { text: statusText, cls: badgeClass } = statusMap[ord.orderStatus] || { text: ord.orderStatus, cls: 'badge-success' };

    // Vendor action buttons — vendor can only accept, pack, or cancel
    let actionBtn = '';
    if (ord.orderStatus === 'pending') {
      actionBtn = `
        <button class="btn btn-primary w-100" onclick="updateStatus('${ord._id}', 'accepted')">✅ Accept Order</button>
        <button class="btn btn-secondary w-100" style="margin-top:8px; color:var(--red);" onclick="updateStatus('${ord._id}', 'cancelled')">✗ Reject</button>
      `;
    } else if (ord.orderStatus === 'accepted') {
      actionBtn = `<button class="btn btn-primary w-100" style="background:var(--purple); box-shadow:none;" onclick="updateStatus('${ord._id}', 'packed')">📦 Mark Packed & Assign Rider</button>`;
    } else if (ord.orderStatus === 'packed') {
      if (ord.deliveryPartnerId) {
        actionBtn = `<div style="font-size:0.85rem; color:var(--green); text-align:center; padding:8px;">🛵 Rider assigned — waiting for pickup</div>`;
      } else {
        actionBtn = `<div style="font-size:0.85rem; color:var(--text-secondary); text-align:center; padding:8px;">⏳ Waiting for delivery partner to accept...</div>`;
      }
    } else if (ord.orderStatus === 'ready_for_pickup') {
      actionBtn = `<div style="font-size:0.85rem; color:var(--green); text-align:center; padding:8px;">🛵 Rider assigned — waiting for pickup</div>`;
    } else if (ord.orderStatus === 'out_for_delivery') {
      actionBtn = `<div style="font-size:0.85rem; color:var(--blue); text-align:center; padding:8px;">🚴 Order is on the way to customer</div>`;
    } else if (ord.orderStatus === 'delivered') {
      actionBtn = `<div style="font-size:0.85rem; color:var(--green); text-align:center; padding:8px;">✅ Delivered successfully</div>`;
    }

    // Delivery partner info (shown when assigned)
    const dp = ord.deliveryPartnerId;
    const partnerHtml = dp ? `
      <div class="delivery-partner-info">
        <i data-lucide="bike" style="width:14px; height:14px;"></i>
        <strong>${dp.name}</strong> &nbsp;·&nbsp; ${dp.phone}
        ${dp.vehicleType ? `&nbsp;·&nbsp; <span style="text-transform:capitalize;">${dp.vehicleType}</span>` : ''}
        ${dp.vehicleNumber ? `&nbsp;·&nbsp; ${dp.vehicleNumber}` : ''}
      </div>
    ` : '';

    card.innerHTML = `
      <div class="order-header">
        <div class="order-info">
          <h3>Order #${ord._id.slice(-8).toUpperCase()}</h3>
          <span>Placed: ${new Date(ord.createdAt).toLocaleString()}</span>
        </div>
        <div class="order-meta-info">
          <span class="badge ${badgeClass}">${statusText}</span>
          <span style="font-weight:700; font-size:1.1rem; color:var(--accent-color);">₹${ord.totalAmount}</span>
        </div>
      </div>
      <div class="order-body-grid">
        <div class="customer-details">
          <h4>Customer</h4>
          <p><strong>${ord.customerId?.name || 'Customer'}</strong></p>
          <p><i data-lucide="phone" style="width:14px;"></i> ${ord.customerId?.phone || '—'}</p>
          <p style="margin-top:8px; font-size:0.8rem; color:var(--text-secondary);">
            <i data-lucide="map-pin" style="width:12px;"></i> ${ord.deliveryAddress?.fullAddress || '—'}
          </p>
          ${partnerHtml}
        </div>
        <div class="order-items-box">
          <h4>Items</h4>
          <div class="ordered-items-list">
            ${ord.products.map(p => `
              <div class="order-item-row">
                <span>${p.productId?.productName || 'Product'} × ${p.quantity} ${p.productId?.unit || ''}</span>
                <strong>₹${p.price * p.quantity}</strong>
              </div>
            `).join('')}
          </div>
          <div style="margin-top:10px; font-size:0.8rem; color:var(--text-secondary);">
            Delivery: ₹${ord.deliveryCharge || 0} &nbsp;|&nbsp; Tax: ₹${ord.tax || 0}
          </div>
        </div>
        <div class="order-actions-box">
          ${['ready_for_pickup', 'packed'].includes(ord.orderStatus) && ord.deliveryPartnerId ? `
            <div style="margin-bottom:10px; padding:12px; border:1px solid var(--border); border-radius:12px; text-align:center;">
              <div style="font-size:0.75rem; color:var(--text-secondary); text-transform:uppercase; font-weight:700;">Pickup OTP</div>
              <div style="font-size:1.5rem; letter-spacing:4px; color:var(--accent-color); font-weight:800;">${ord.pickupOTP || '----'}</div>
              <div style="font-size:0.75rem; color:var(--text-secondary);">Share this OTP with the driver after handing over the order.</div>
            </div>
          ` : ''}
          ${actionBtn}
        </div>
      </div>
    `;
    container.appendChild(card);
  });
  lucide.createIcons();
}

async function updateStatus(orderId, status) {
  try {
    const res = await fetch(`${API_BASE}/vendors/panel/orders/${orderId}/status`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ orderStatus: status })
    });
    const data = await res.json();
    if (data.success) {
      // Show richer message when delivery partner was auto-assigned
      const msg = data.assignedPartner
        ? `✅ ${data.message}`
        : `Order updated: ${data.order?.orderStatus || status}`;
      alert(msg);
      if (currentTab === 'dashboard-tab') {
        loadVendorDashboard();
      } else {
        fetchOrders();
      }
    } else {
      alert(data.message || 'Failed to update status');
    }
  } catch (err) {
    alert('Failed to update status');
  }
}

function filterOrders(status, el) {
  document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
  el.classList.add('active');

  if (status === 'all') {
    renderOrders(allOrders);
  } else {
    const filtered = allOrders.filter(o => o.orderStatus === status);
    renderOrders(filtered);
  }
}

// ----------------------------------------------------
// PROFILE MANAGEMENT
// ----------------------------------------------------
function fillProfileForm() {
  if (!currentVendor) return;
  document.getElementById('prof-store-name').value = currentVendor.shopName;
  document.getElementById('prof-store-desc').value = currentVendor.description || '';
  document.getElementById('prof-delivery-time').value = currentVendor.deliveryTime;
  document.getElementById('prof-min-order').value = currentVendor.minimumOrder;
  document.getElementById('prof-tags').value = currentVendor.cuisineTags ? currentVendor.cuisineTags.join(', ') : '';
  document.getElementById('prof-lat').value = currentVendor.address?.location?.latitude || '';
  document.getElementById('prof-lng').value = currentVendor.address?.location?.longitude || '';
  document.getElementById('prof-service-radius').value = currentVendor.serviceRadius || 10;
}

async function handleUpdateProfile(event) {
  event.preventDefault();
  const formData = new FormData();
  
  formData.append('shopName', document.getElementById('prof-store-name').value);
  formData.append('description', document.getElementById('prof-store-desc').value);
  formData.append('deliveryTime', document.getElementById('prof-delivery-time').value);
  formData.append('minimumOrder', document.getElementById('prof-min-order').value);
  
  const tagsStr = document.getElementById('prof-tags').value;
  const tagsArr = tagsStr.split(',').map(t => t.trim()).filter(Boolean);
  formData.append('cuisineTags', JSON.stringify(tagsArr));

  formData.append('latitude', document.getElementById('prof-lat').value);
  formData.append('longitude', document.getElementById('prof-lng').value);
  formData.append('serviceRadius', document.getElementById('prof-service-radius').value);

  const imageInput = document.getElementById('prof-image');
  if (imageInput.files.length > 0) {
    formData.append('shopImage', imageInput.files[0]);
  }

  try {
    const res = await fetch(`${API_BASE}/vendors/panel/profile`, {
      method: 'PUT',
      headers: { 'Authorization': `Bearer ${token}` },
      body: formData
    });
    const data = await res.json();
    if (data.success) {
      alert('Profile updated successfully!');
      loadVendorDashboard();
    } else {
      alert(data.message || 'Update failed');
    }
  } catch (err) {
    alert('Failed to update profile settings.');
  }
}

// LOGOUT
function handleLogout() {
  token = null;
  localStorage.removeItem('vendor_token');
  currentVendor = null;
  showScreen('landing-screen');
  document.getElementById('login-form').classList.remove('hidden');
  document.getElementById('otp-form').classList.add('hidden');
  document.getElementById('login-phone').value = '';
}

// ----------------------------------------------------
// PRODUCT IMAGE PREVIEW
// ----------------------------------------------------
function handleProductImagePreviews(input) {
  const container = document.getElementById('product-images-preview');
  if (!container) return;
  container.innerHTML = '';
  if (input.files && input.files.length > 0) {
    Array.from(input.files).forEach(file => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const wrapper = document.createElement('div');
        wrapper.style = "width: 70px; height: 70px; border-radius: 8px; overflow: hidden; border: 1px solid rgba(255,255,255,0.1); flex-shrink: 0;";
        wrapper.innerHTML = `<img src="${e.target.result}" style="width:100%; height:100%; object-fit:cover;" />`;
        container.appendChild(wrapper);
      };
      reader.readAsDataURL(file);
    });
  }
}
