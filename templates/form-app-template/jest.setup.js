import '@testing-library/jest-dom'

// Mock the environment variables
window.process = {
  ...window.process,
};

Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});

// Mock environment variables
vi.mock('import.meta.env', () => ({
  VITE_API_URL: 'http://localhost:8000/api',
  VITE_API_KEY: 'test-api-key',
  VITE_AZURE_ENABLED: 'false',
  VITE_ENABLE_ANALYTICS: 'false',
}));
