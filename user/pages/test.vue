<script setup lang="ts">
const props = defineProps<{
  title: string
}>()

const toast = useToast()

function showToast() {
  toast.add({
  title: props.title,
  description: 'This is an additional message'
})

}
</script>

<template>
  <UButton label="Show toast" color="neutral" variant="outline" @click="showToast" />
</template>