import React from 'react';

// Error boundary component for catching React errors
class ErrorBoundary extends React.Component<{ children: React.ReactNode }, { hasError: boolean }> {
  constructor(props: { children: React.ReactNode }) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(): { hasError: boolean } {
    return { hasError: true };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
    console.error("Error caught by boundary:", error, errorInfo);
  }

  render(): React.ReactNode {
    if (this.state.hasError) {
      return (
        <div style={{ padding: '20px', color: 'red', textAlign: 'center' }}>
          <h2>Error loading application</h2>
          <p>Something went wrong when rendering the application.</p>
          <p>Try refreshing the page or check your browser console for errors.</p>
          <button 
            onClick={() => window.location.reload()} 
            style={{ backgroundColor: '#002F6C', color: 'white', padding: '10px 20px', border: 'none', borderRadius: '4px', marginTop: '20px' }}
          >
            Reload Page
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

export default ErrorBoundary;
