<template>
  <div class="p-6">
    <UCard class="mb-4">
      <template #header>
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-semibold">My Enrolled Classes</h2>
          <p class="text-sm text-gray-500">Current Semester: Spring 2024</p>
        </div>
      </template>

      <!-- Search and Filter Section -->
      <div class="mb-4 flex items-center gap-4">
        <UInput
          v-model="search"
          placeholder="Search classes..."
          icon="i-heroicons-magnifying-glass"
          class="w-64"
        />
        <USelect
          v-model="dayFilter"
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
          <div class="text-2xl font-bold">{{ data.length }}</div>
          <div class="text-sm text-gray-500">Enrolled Classes</div>
        </div>
      </UCard>
    </div>
  </div>
</template>

<script setup lang = "ts">
import { ref, computed } from 'vue'

const search = ref('')
const dayFilter = ref('All Days')

// Mock data for demonstration
const data = ref([
  {
    course_id: 'CS101',
    course_name: 'Introduction to Programming',
    day_of_week: 'Monday',
    location: 'Room A101',
    status: 'open',
    mid_term: '8.5',
    final_term: '9.0'
  },
  {
    course_id: 'MATH201',
    course_name: 'Linear Algebra',
    day_of_week: 'Tuesday',
    location: 'Room B205',
    status: 'open',
    mid_term: '7.5',
    final_term: '8.0'
  },
  {
    course_id: 'PHY102',
    course_name: 'Physics II',
    day_of_week: 'Wednesday',
    location: 'Room C303',
    status: 'open',
    mid_term: '9.0',
    final_term: '8.5'
  },
  {
    course_id: 'ENG201',
    course_name: 'Technical Writing',
    day_of_week: 'Thursday',
    location: 'Room D104',
    status: 'closed',
    mid_term: '8.0',
    final_term: '8.5'
  },
  {
    course_id: 'BIO101',
    course_name: 'Introduction to Biology',
    day_of_week: 'Friday',
    location: 'Room E210',
    status: 'open',
    mid_term: '7.0',
    final_term: '7.5'
  }
])


</script>