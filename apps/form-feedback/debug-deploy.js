// Lägg till detta script i index.html för att visa felsökningsinformation
console.log('DEBUG: Script loaded');

// Globalt error-hantering för att fånga alla fel på sidan
window.addEventListener('error', function(event) {
  console.error('GLOBAL ERROR:', event.error || event.message);
  showErrorOverlay('JavaScript Error: ' + (event.error?.message || event.message));
});

// Fånga löften som inte hanteras
window.addEventListener('unhandledrejection', function(event) {
  console.error('UNHANDLED PROMISE REJECTION:', event.reason);
  showErrorOverlay('Promise Error: ' + (event.reason?.message || event.reason));
});

// Visa synlig error-overlay på sidan
function showErrorOverlay(errorMessage) {
  const existingOverlay = document.getElementById('error-diagnostic-overlay');
  if (existingOverlay) {
    existingOverlay.remove();
  }
  
  const overlay = document.createElement('div');
  overlay.id = 'error-diagnostic-overlay';
  overlay.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(255, 0, 0, 0.8);
    color: white;
    padding: 20px;
    font-family: monospace;
    z-index: 10000;
    overflow: auto;
  `;
  
  const content = document.createElement('div');
  content.innerHTML = `
    <h2>Error Detected</h2>
    <p>${errorMessage}</p>
    <h3>Debug Info:</h3>
    <p>URL: ${window.location.href}</p>
    <p>User Agent: ${navigator.userAgent}</p>
    <p>Timestamp: ${new Date().toISOString()}</p>
    <button id="close-error-overlay" style="padding: 10px; background: white; color: red; border: none; margin-top: 20px; cursor: pointer;">Close</button>
  `;
  
  overlay.appendChild(content);
  document.body.appendChild(overlay);
  
  document.getElementById('close-error-overlay').addEventListener('click', function() {
    overlay.remove();
  });
}

// Kolla om React renderas korrekt
function checkReactRendering() {
  console.log('DEBUG: Checking React rendering');
  const rootElement = document.getElementById('root');
  
  if (!rootElement) {
    console.error('DEBUG: Root element missing!');
    return;
  }
  
  console.log('DEBUG: Root element found');
  console.log('DEBUG: Root element content:', rootElement.innerHTML);
  
  // Timeout för att kolla om React har renderat något
  setTimeout(() => {
    const hasContent = rootElement.children.length > 0 || 
                      (rootElement.innerHTML && rootElement.innerHTML.trim() !== '');
                      
    console.log('DEBUG: After timeout, root has content:', hasContent);
    
    if (!hasContent) {
      console.error('DEBUG: React did not render anything');
      showErrorOverlay('React did not render any content');
    }
  }, 3000);
}

// Vänta på att DOM:en laddas
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', checkReactRendering);
} else {
  checkReactRendering();
}
