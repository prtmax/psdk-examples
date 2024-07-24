import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import basicSsl from '@vitejs/plugin-basic-ssl'
import vue from '@vitejs/plugin-vue'
import vuetify from "vite-plugin-vuetify";
// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    basicSsl(),
    vuetify({
      autoImport: true,
      styles: {
        configFile: 'src/styles/variables/_vuetify.scss',
      },
    }),
  ],
  server: {
    host: '0.0.0.0'
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  }
})

