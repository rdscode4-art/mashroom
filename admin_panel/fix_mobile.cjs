const fs = require('fs');

try {
  let code = fs.readFileSync('src/App.jsx', 'utf8');

  // 1. Add state for mobileMenuOpen
  if (!code.includes('const [mobileMenuOpen')) {
    code = code.replace(
      "const [activeTab, setActiveTab] = useState('dashboard');",
      "const [activeTab, setActiveTab] = useState('dashboard');\n  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);"
    );
  }

  // 2. Add lucide icon Menu
  if (!code.includes('Menu,')) {
    code = code.replace('LayoutDashboard,', 'Menu,\n  LayoutDashboard,');
  }

  // 3. Update sidebar to accept dynamic class
  if (code.includes('<aside className="sidebar">')) {
    code = code.replace(
      '<aside className="sidebar">',
      '<aside className={`sidebar ${mobileMenuOpen ? "mobile-open" : ""}`}>'
    );
  }

  // 4. Update sidebar-menu to close mobile menu on click
  code = code.replace(
    /onClick=\{\(\) => \{ setActiveTab\(item\.id\); setSearchQuery\(''\); \}\}/g,
    "onClick={() => { setActiveTab(item.id); setSearchQuery(''); setMobileMenuOpen(false); }}"
  );

  // 5. Update top-bar header to include hamburger menu
  const regexTopBar = /<header className="top-bar">\s*<h1 className="page-title"(.*?)>([\s\S]*?)<\/h1>/;
  if (code.match(regexTopBar)) {
    code = code.replace(regexTopBar, (match, p1, p2) => {
      if(match.includes('mobile-menu-btn')) return match;
      return `<header className="top-bar">
            <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
              <button className="mobile-menu-btn" onClick={() => setMobileMenuOpen(true)}>
                <Menu size={24} />
              </button>
              <h1 className="page-title"${p1}>
  ${p2}
              </h1>
            </div>`;
    });
  }

  // 6. Add a mobile overlay
  if (!code.includes('mobile-overlay')) {
    code = code.replace(
      '{/* SIDEBAR */}',
      `{/* SIDEBAR OVERLAY */}
        {mobileMenuOpen && (
          <div className="mobile-overlay" onClick={() => setMobileMenuOpen(false)}></div>
        )}
        {/* SIDEBAR */}`
    );
  }

  fs.writeFileSync('src/App.jsx', code);
  console.log('App.jsx updated successfully.');
} catch(e) {
  console.error(e);
}

try {
  let css = fs.readFileSync('src/index.css', 'utf8');
  
  // Replace the entire /* --- Mobile Responsiveness --- */ block with the offcanvas sidebar CSS
  const responsiveBlockStart = css.indexOf('/* --- Mobile Responsiveness --- */');
  if (responsiveBlockStart !== -1) {
    css = css.substring(0, responsiveBlockStart);
  }

  const newCss = `
/* --- Mobile Responsiveness --- */
.mobile-menu-btn {
  display: none;
  background: none;
  border: none;
  color: var(--text-primary);
  cursor: pointer;
  padding: 4px;
}
.mobile-menu-btn:hover {
  color: var(--primary);
}

.mobile-overlay {
  display: none;
}

@media (max-width: 900px) {
  .app-container {
    flex-direction: column;
  }
  
  .mobile-menu-btn {
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .mobile-overlay {
    display: block;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.6);
    backdrop-filter: blur(4px);
    z-index: 1050;
  }

  .sidebar {
    position: fixed;
    top: 0;
    left: -300px;
    height: 100vh;
    width: 280px;
    z-index: 1100;
    transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    background-color: var(--bg-sidebar);
    box-shadow: 4px 0 24px rgba(0, 0, 0, 0.5);
  }
  
  .sidebar.mobile-open {
    transform: translateX(300px);
  }
  
  .main-wrapper {
    width: 100%;
    margin-bottom: 0;
  }
  
  .top-bar {
    padding: 0 16px;
    height: 60px;
  }
  
  .content-container {
    padding: 16px;
  }
  
  .stats-grid {
    grid-template-columns: 1fr 1fr;
    gap: 16px;
  }
  
  .page-title {
    font-size: 16px; /* slightly smaller on mobile */
  }
  
  .login-card {
    padding: 24px;
  }
  
  .dashboard-grid {
    grid-template-columns: 1fr;
  }

  .category-manager-layout {
    grid-template-columns: 1fr;
  }
  
  .order-details-block {
    grid-template-columns: 1fr;
    gap: 16px;
  }
  
  /* Make tables horizontally scrollable */
  .data-table-container {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }
  
  .catalog-grid {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: 16px;
  }
  
  .product-img-wrapper {
    height: 130px; /* shorter image */
  }

  .top-actions {
    gap: 8px;
  }

  .live-indicator {
    padding: 4px 8px;
    font-size: 11px;
  }
  
  .btn {
    font-size: 13px;
    padding: 10px 14px;
  }

  /* Form spacing improvements on mobile */
  .form-group {
    margin-bottom: 16px;
  }
}

/* Extra small devices */
@media (max-width: 480px) {
  .stats-grid {
    grid-template-columns: 1fr; /* 1 col on very small screens */
  }
  .catalog-grid {
    grid-template-columns: 1fr 1fr; /* force 2 cols on mobile products */
  }
}
`;

  fs.writeFileSync('src/index.css', css + newCss);
  console.log('index.css updated successfully.');
} catch(e) {
  console.error(e);
}
