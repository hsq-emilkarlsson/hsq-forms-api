// Fallback index.js file for browsers that may struggle with .tsx files
import './main.tsx';

// Add global error handler for uncaught exceptions
window.addEventListener('error', function(event) {
  console.error('Global error caught:', event.error || event.message);
  
  // Only show the error message if we're not already showing an error page
  if (window.location.pathname !== '/fallback.html' && 
      !document.body.innerHTML.includes('error-message')) {
    
    // Create error message element
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.innerHTML = `
      <h2>Something went wrong</h2>
      <p>An error occurred while loading the application.</p>
      <button onclick="window.location.reload()">Reload Page</button>
      <p><small>If the problem persists, please try using a different browser.</small></p>
    `;
    
    // Add some basic styling
    errorDiv.style.cssText = `
      position: fixed; 
      top: 50%; 
      left: 50%; 
      transform: translate(-50%, -50%);
      background: white; 
      padding: 20px; 
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      text-align: center;
      font-family: Arial, sans-serif;
      z-index: 9999;
    `;
    
    // Style the button
    setTimeout(() => {
      const button = errorDiv.querySelector('button');
      if (button) {
        button.style.cssText = `
          background-color: #002F6C;
          color: white;
          border: none;
          padding: 10px 20px;
          border-radius: 4px;
          margin-top: 16px;
          cursor: pointer;
        `;
      }
    }, 0);
    
    // Add to page
    document.body.appendChild(errorDiv);
  }
  
  return false; // Let other error handlers run
});
