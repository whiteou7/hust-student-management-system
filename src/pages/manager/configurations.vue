<template>
  <div class="p-6 max-w-xl mx-auto space-y-6">
    <UCard>
      <template #header>
        <h2 class="text-xl font-bold">System Configuration</h2>
      </template>
      <UForm :state="form" @submit="onSubmit">
        <div class="space-y-4">
          <UFormField label="Current Semester" required>
            <UInput v-model="form.currentSemester" placeholder="e.g. 20242" class="w-full" />
          </UFormField>
          <UFormField label="Next Semester" required>
            <UInput v-model="form.nextSemester" placeholder="e.g. 20243" class="w-full" />
          </UFormField>
          <UFormField label="Class Registration Status" required>
            <USelect
              v-model="form.classRegStatus"
              :items="statusOptions"
              class="w-full"
            />
          </UFormField>
        </div>
        <div class="flex justify-end mt-6 gap-2">
          <UButton type="submit" color="primary">Save Changes</UButton>
        </div>
      </UForm>
      <div v-if="successMsg" class="text-green-600 mt-2">{{ successMsg }}</div>
      <div v-if="errorMsg" class="text-red-600 mt-2">{{ errorMsg }}</div>
    </UCard>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue"

definePageMeta({
  layout: "manager"
})
const form = ref({
  currentSemester: "",
  nextSemester: "",
  classRegStatus: false
})

const successMsg = ref("")
const errorMsg = ref("")
const statusOptions = [
  { label: "Open", value: true },
  { label: "Closed", value: false }
]

async function fetchConfig() {
  try {
    const [{ data: semesterData }, { data: regStatusData }, { data: nextSemesterData }] = await Promise.all([
      useFetch("/api/semester"),
      useFetch("/api/class-reg-status"),
      useFetch("/api/next-semester")
    ])
    if (semesterData.value?.currentSemester) {
      form.value.currentSemester = semesterData.value.currentSemester
    }
    if (typeof regStatusData.value?.classRegStatus === "boolean") {
      form.value.classRegStatus = regStatusData.value.classRegStatus
    }
    if (nextSemesterData.value?.nextSemester) {
      form.value.nextSemester = nextSemesterData.value.nextSemester
    }
  } catch {
    errorMsg.value = "Failed to fetch configuration."
  }
}

onMounted(fetchConfig)

async function onSubmit() {
  errorMsg.value = ""
  successMsg.value = ""
  try {
    const [semesterRes, regStatusRes, nextSemesterRes] = await Promise.all([
      useFetch("/api/semester", {
        method: "PUT",
        body: { currentSemester: form.value.currentSemester }
      }),
      useFetch("/api/class-reg-status", {
        method: "PUT",
        body: { classRegStatus: form.value.classRegStatus }
      }),
      useFetch("/api/next-semester", {
        method: "PUT",
        body: { nextSemester: form.value.nextSemester }
      })
    ])
    if (semesterRes.data.value?.success && regStatusRes.data.value?.success && nextSemesterRes.data.value?.success) {
      successMsg.value = "Configuration updated successfully."
    } else {
      errorMsg.value = "Failed to update configuration."
    }
  } catch {
    errorMsg.value = "Failed to update configuration."
  }
}
</script>
