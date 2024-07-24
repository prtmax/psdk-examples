import './assets/main.css'

import { createApp } from 'vue'
import { createVuetify } from 'vuetify'
import VuetifyUseDialog from 'vuetify-use-dialog'
import App from './App.vue'
const app = createApp(App)
const vuetify = createVuetify()
app.use(vuetify)
app.use(VuetifyUseDialog)
app.mount('#app')
