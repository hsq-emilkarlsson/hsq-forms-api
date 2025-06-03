// Browser-friendly script to diagnose Static Web App deployment issues
// Save in public/ as debug-client.js to be available in production

(function() {
  console.log('Debug script loaded!');
  
  // Create debug UI
  function createDebugUI() {
    const debugContainer = document.createElement('div');
    debugContainer.id = 'swa-debug-container';
    debugContainer.style.cssText = `
      position: fixed;
      bottom: 0;
      right: 0;
      background: rgba(255,255,255,0.95);
      border: 1px solid #ccc;
      border-radius: 5px 0 0 0;
      box-shadow: 0 0 10px rgba(0,0,0,0.1);
      padding: 10px;
      max-width: 400px;
      max-height: 400px;
      overflow-y: auto;
      font-family: monospace;
      font-size: 12px;
      z-index: 10000;
      display: none;
    `;
    
    const header = document.createElement('h4');
    header.textContent = 'Azure SWA Debug';
    header.style.margin = '0 0 10px 0';
    
    const output = document.createElement('pre');
    output.id = 'swa-debug-output';
    output.style.margin = '0';
    output.style.whiteSpace = 'pre-wrap';
    output.style.maxHeight = '300px';
    output.style.overflow = 'auto';
    
    const closeBtn = document.createElement('button');
    closeBtn.textContent = 'Close';
    closeBtn.style.cssText = 'float: right; margin-top: -30px;';
    closeBtn.onclick = function() {
      debugContainer.style.display = 'none';
    };
    
    const refreshBtn = document.createElement('button');
    refreshBtn.textContent = 'Refresh Info';
    refreshBtn.style.cssText = 'margin-top: 10px;';
    refreshBtn.onclick = collectDebugInfo;
    
    debugContainer.appendChild(header);
    debugContainer.appendChild(closeBtn);
    debugContainer.appendChild(output);
    debugContainer.appendChild(refreshBtn);
    document.body.appendChild(debugContainer);
    
    return {
      container: debugContainer,
      output: output
    };
  }
  
  // Collect all relevant debug information
  function collectDebugInfo() {
    if (!window.swaDebugUI) {
      window.swaDebugUI = createDebugUI();
    }
    
    const output = window.swaDebugUI.output;
    const container = window.swaDebugUI.container;
    
    // Show the debug panel
    container.style.display = 'block';
    
    // Gather information
    const debugInfo = {
      timestamp: new Date().toISOString(),
      url: window.location.href,
      hostname: window.location.hostname,
      pathname: window.location.pathname,
      userAgent: navigator.userAgent,
      networkType: navigator.connection ? navigator.connection.effectiveType : 'unknown',
      scripts: Array.from(document.querySelectorAll('script')).map(s => ({
        src: s.src || '(inline)',
        type: s.type,
        crossOrigin: s.crossOrigin
      })),
      links: Array.from(document.querySelectorAll('link')).map(l => ({
        href: l.href,
        rel: l.rel,
        type: l.type
      })),
      rootChildren: document.getElementById('root') ? document.getElementById('root').childNodes.length : 'no root element',
      errors: window.swaDebugErrors || [],
      localStorage: Object.keys(localStorage).filter(k => k.startsWith('swa-')).reduce((obj, key) => {
        obj[key] = localStorage.getItem(key);
        return obj;
      }, {})
    };
    
    // Output the info
    output.textContent = JSON.stringify(debugInfo, null, 2);
    
    // Also log to console
    console.log('SWA Debug Info:', debugInfo);
    
    return debugInfo;
  }
  
  // Track errors
  window.swaDebugErrors = [];
  const originalConsoleError = console.error;
  console.error = function() {
    window.swaDebugErrors.push({
      timestamp: new Date().toISOString(),
      args: Array.from(arguments).map(arg => {
        try {
          return arg instanceof Error ? arg.message + '\n' + arg.stack : String(arg);
        } catch (e) {
          return 'Cannot stringify error';
        }
      })
    });
    originalConsoleError.apply(console, arguments);
  };
  
  // Add global accessor
  window.showSWADebug = function() {
    collectDebugInfo();
  };
  
  // Instructions
  console.log('To show debug panel, run window.showSWADebug() in the console');
  
  // Register keyboard shortcut: Ctrl+Alt+D
  document.addEventListener('keydown', function(e) {
    if (e.ctrlKey && e.altKey && e.key === 'd') {
      collectDebugInfo();
    }
  });
})();
