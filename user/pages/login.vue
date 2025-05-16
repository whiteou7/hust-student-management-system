<script setup lang="ts">
import type { FormSubmitEvent } from '@nuxt/ui'


interface FormData {
  email: string
  password: string
}

const schema = {
  email: {
    required: true,
    pattern: /^\S+@\S+$/,
    message: 'Enter a valid email'
  },
  password: {
    required: true,
    min: 6,
    message: 'Password must be at least 6 characters'
  }
}

const state = reactive<FormData>({
  email: '',
  password: ''
})

async function onSubmit(event: FormSubmitEvent<unknown>) {
  const data = event.data as FormData;
  console.log(data.email + ' submitted.');

  const res = await useFetch('/api/login.ts', {
      method: 'POST',
      body: {
        email: data.email,
        password: data.password
      }
    });

}
</script>

<template>
  <UForm :schema="schema" :state="state" class="space-y-4" @submit = "onSubmit">
    <UFormField label="Email" name="email">
      <UInput v-model="state.email" />
    </UFormField>

    <UFormField label="Password" name="password">
      <UInput v-model="state.password" type="password" />
    </UFormField>

    <UButton type="submit">
      Submit
    </UButton>
  </UForm>
</template>

