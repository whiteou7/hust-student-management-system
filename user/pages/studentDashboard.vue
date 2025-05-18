<template>
  <div class="p-6">
    <UCard class="mb-4">
      <template #header>
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-semibold">My Enrolled Classes</h2>
          <p class="text-sm text-gray-500">Current Semester: {{ currentSemester }}</p>
        </div>
      </template>

      <!-- Search and Filter Section -->
      <div class="mb-4 flex items-center gap-4">
        <UInput
          
          placeholder="Search classes..."
          icon="i-heroicons-magnifying-glass"
          class="w-64"
        />
        <USelect
         
          :options="['All Days', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']"
          placeholder="Filter by day"
          class="w-40"
        />
      </div>

      <!-- Classes Table -->
      <UTable
        :data="data"
      />
    </UCard>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
      <UCard>
        <div class="text-center">
          <div class="text-2xl font-bold">15</div>
          <div class="text-sm text-gray-500">Total Credits This Semester</div>
        </div>
      </UCard>
      
      <UCard>
        <div class="text-center">
          <div class="text-2xl font-bold">3.75</div>
          <div class="text-sm text-gray-500">Current GPA</div>
        </div>
      </UCard>

      <UCard>
        <div class="text-center">
          <div class="text-2xl font-bold">5</div>
          <div class="text-sm text-gray-500">Enrolled Classes</div>
        </div>
      </UCard>
    </div>
  </div>
</template>

<script setup lang = "ts">
import { ref, computed, onMounted } from "vue"

const data = ref([])
const currentSemester = ref(localStorage.getItem("currentSemester") || "")
const errorMsg = ref("")

onMounted(async () => {
  await fetchClasses()
})

async function fetchClasses() {
    const userId = localStorage.getItem("userId")
    const currentSemester = localStorage.getItem("currentSemester")

    const res = await useFetch("/api/student-classes", {
      method: "POST",
      body: {
        userId: parseInt(userId ?? "0"),
        semester: currentSemester
      }
    })

    

    if (res.data.value && res.data.value.success) {
      data.value = res.data.value?.classes
    } else {

    }
}


</script>