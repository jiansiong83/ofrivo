import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        tealbrand: '#0B4F55',
        page: '#F5F7F8',
      },
    },
  },
  plugins: [],
};

export default config;

