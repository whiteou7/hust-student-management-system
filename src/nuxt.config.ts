// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: true },
  eslint: {
    config: {
      stylistic: false // <---
    }
  },
  modules: ["@nuxt/ui", "@nuxt/eslint"],
  css: ["~/assets/css/main.css"],
  compatibilityDate: "2025-05-30",
  ssr: false
})