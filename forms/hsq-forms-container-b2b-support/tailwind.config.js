/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        husqvarna: {
          orange: '#FF8100',
          'orange-dark': '#E6740A',
          blue: '#0071ce',
          'blue-dark': '#005bb5',
          gray: '#374151',
          'gray-light': '#F9FAFB',
        }
      }
    },
  },
  plugins: [],
}