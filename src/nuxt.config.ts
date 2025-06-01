// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: true },
  eslint: {
    config: {
      stylistic: true // <---
    }
  },
  modules: ["@nuxt/ui", "@nuxt/eslint"],
  css: ["~/assets/css/main.css"],
  compatibilityDate: '2025-05-30',
  nitro: {
    routeRules: {
      "/_nuxt/**": {
        headers: {
          "Content-Type": "text/css"
        }
      }
    }
  },
  ssr: false
})