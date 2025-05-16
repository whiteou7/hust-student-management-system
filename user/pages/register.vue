<script setup lang="ts">
import type { FormSubmitEvent } from '@nuxt/ui'
import { z } from 'zod';
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const errorMsg = ref('')

interface FormState {
  email: string
  password: string
  confirmPassword: string
  fullName: string
  role: 'student'
}

const state = reactive<FormState>({
  email: '',
  password: '',
  confirmPassword: '',
  fullName: '',
  role: 'student'
})

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  confirmPassword: z.string().min(6),
  fullName: z.string().min(2),
  role: z.literal('student')
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"]
});

type Schema = z.output<typeof schema>;

async function onSubmit(event: FormSubmitEvent<Schema>) {
  const data = event.data;
  // Here you would implement the actual registration logic
  router.push('/login')
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-900 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900 dark:text-white">
        Create your account
      </h2>
      <p class="mt-2 text-center text-sm text-gray-600 dark:text-gray-400">
        Join us today and start your journey!
      </p>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="bg-white dark:bg-gray-800 py-8 px-4 shadow sm:rounded-lg sm:px-10">
        <UForm :schema="schema" :state="state" class="space-y-6" @submit="onSubmit">
          <UFormField label="Full Name" name="fullName">
            <UInput 
              v-model="state.fullName" 
              type="text"
              autocomplete="name"
              placeholder="Enter your full name"
              class="block w-full dark:bg-gray-700 dark:text-white dark:border-gray-600"
            />
          </UFormField>

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
              autocomplete="new-password"
              placeholder="Create a password"
              class="block w-full dark:bg-gray-700 dark:text-white dark:border-gray-600"
            />
          </UFormField>

          <UFormField label="Confirm Password" name="confirmPassword">
            <UInput 
              v-model="state.confirmPassword" 
              type="password"
              autocomplete="new-password"
              placeholder="Confirm your password"
              class="block w-full dark:bg-gray-700 dark:text-white dark:border-gray-600"
            />
          </UFormField>

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
              Create account
            </UButton>
          </div>
        </UForm>

        <div class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300 dark:border-gray-600"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="bg-white dark:bg-gray-800 px-2 text-gray-500 dark:text-gray-400">Already have an account?</span>
            </div>
          </div>

          <div class="mt-6">
            <NuxtLink
              to="/login"
              class="flex w-full justify-center rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 shadow-sm hover:bg-gray-50 dark:hover:bg-gray-600"
            >
              Sign in instead
            </NuxtLink>
          </div>
        </div>
      </div>
    </div>
  </div>
</template> 