import { defineConfig } from 'vite'

export default defineConfig({
  base: process.env.NODE_ENV === 'production'
    ? '/NCICS-2026/zarr-layer-demo/'
    : '/',

  build: {
    outDir: 'dist/zarr-layer-demo',
  },

  server: {
    host: '0.0.0.0',
    port: 5173,
  },
  optimizeDeps: {
    include: ['maplibre-gl', '@carbonplan/zarr-layer', '@carbonplan/icechunk-js'],
  },
})
