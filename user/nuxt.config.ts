// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: true },

  modules: ["@nuxt/ui"],
  css: ["~/assets/css/main.css"],
  
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