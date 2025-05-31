<script setup lang="ts">
import type { FormSubmitEvent } from "@nuxt/ui"
import { z } from "zod"
import Cookies from "js-cookie"
import { useRouter } from "vue-router"
import { ref } from "vue"

const router = useRouter()
const errorMsg = ref("")

const state = reactive({
  email: "",
  password: ""
})

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(6)
})

type Schema = z.output<typeof schema>

async function onSubmit(event: FormSubmitEvent<Schema>) {
  const loginData = event.data
  console.log(loginData.email + " submitted.")

  const { data } = await useFetch("/api/login", {
    method: "POST",
    body: {
      email: loginData.email,
      password: loginData.password
    }
  })

  if (!data.value) {
    errorMsg.value = "Failed to fetch user info."
    return
  }

  if (data.value.success) {
    if (data.value?.userId != null) {
      localStorage.setItem("userId", data.value?.userId)
    }
    
    // Fetch current semester
    const { data: semesterData } = await useFetch("/api/semester")
    if (semesterData.value) {
      localStorage.setItem("currentSemester", semesterData.value.currentSemester)
    }

    // Fetch current class registration status
    const { data: statusData } = await useFetch("/api/class-reg-status")
    if (statusData.value) {
      localStorage.setItem("classRegStatus", statusData.value.classRegStatus)
    }
    
    if (data.value.role === "student") {
      localStorage.setItem("role", "student")
      router.push("/student/dashboard")
    } else if (data.value.role === "teacher") {
      localStorage.setItem("role", "teacher")
      router.push("/teacher/dashboard")
    } else {
      localStorage.setItem("role", "admin")
      router.push("/admin/dashboard")
    }
  } else {
    errorMsg.value = "Wrong credentials. Please try again."
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-900 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900 dark:text-white">
        Sign in to your account
      </h2>
      <p class="mt-2 text-center text-sm text-gray-600 dark:text-gray-400">
        Welcome to hell! Please enter your details.
      </p>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="bg-white dark:bg-gray-800 py-8 px-4 shadow sm:rounded-lg sm:px-10">
        <UForm :schema="schema" :state="state" class="space-y-6" @submit="onSubmit">
          <UFormField label="Email address" name="email">
            <UInput 
              v-model="state.email" 
              type="email"
              autocomplete="email"
              placeholder="Enter your email"
              class="block w-full dark:bg-gray-700 dark:text-white dark:border-gray-600"
            />
          </UFormField>

          <UFormField label="Password" name="password">
            <UInput 
              v-model="state.password" 
              type="password"
              autocomplete="current-password"
              placeholder="Enter your password"
              class="block w-full dark:bg-gray-700 dark:text-white dark:border-gray-600"
            />
          </UFormField>

          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <UCheckbox name="remember-me" label="Remember me" class="dark:text-gray-300" />
            </div>
          </div>

          <div v-if="errorMsg" class="text-red-500 text-center">
            {{ errorMsg }}
          </div>

          <div>
            <UButton
              type="submit"
              block
              color="primary"
              class="flex w-full justify-center"
            >
              Sign in
            </UButton>
          </div>
        </UForm>

        <div class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300 dark:border-gray-600"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="bg-white dark:bg-gray-800 px-2 text-gray-500 dark:text-gray-400">Don't have an account?</span>
            </div>
          </div>

          <div class="mt-6">
            <NuxtLink
              to="/register"
              class="flex w-full justify-center rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 shadow-sm hover:bg-gray-50 dark:hover:bg-gray-600"
            >
              Create an account
            </NuxtLink>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

