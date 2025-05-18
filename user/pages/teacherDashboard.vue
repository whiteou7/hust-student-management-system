<template>
  <div class="p-6">
    <UCard class="mb-4">
      <template #header>
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-semibold">My Teaching Classes</h2>
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
          v-model="statusFilter"
          :options="['All Status', 'Open', 'Closed']"
          placeholder="Filter by status"
          class="w-40"
        />
      </div>

      <!-- Classes Table -->
      <UTable
        :rows="teachingClasses"
        :columns="columns"
        :search="search"
        :sort="{ column: 'course_id', direction: 'asc' }"
      >
        <template #course-name-data="{ row }">
          <div>
            <p class="font-medium">{{ row.course_name }}</p>
            <p class="text-sm text-gray-500">{{ row.course_id }}</p>
          </div>
        </template>

        <template #enrollment-data="{ row }">
          <div class="flex items-center gap-2">
            <span class="font-medium">{{ row.enrolled_count }}/{{ row.capacity }}</span>
            <UProgress
              :value="(row.enrolled_count / row.capacity) * 100"
              :color="row.enrolled_count >= row.capacity ? 'red' : 'blue'"
              class="w-20"
            />
          </div>
        </template>

        <template #status-data="{ row }">
          <UBadge :color="row.status === 'open' ? 'green' : 'red'">
            {{ row.status }}
          </UBadge>
        </template>

        <template #actions-data="{ row }">
          <div class="flex gap-2">
            <UButton
              color="primary"
              variant="soft"
              icon="i-heroicons-users"
              @click="showStudentList(row)"
            >
              Students
            </UButton>
            <UButton
              color="gray"
              variant="ghost"
              icon="i-heroicons-pencil-square"
              @click="manageGrades(row)"
            >
              Grades
            </UButton>
          </div>
        </template>
      </UTable>
    </UCard>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mt-6">
      <UCard>
        <div class="text-center">
          <div class="text-2xl font-bold">5</div>
          <div class="text-sm text-gray-500">Total Classes</div>
        </div>
      </UCard>
      
      <UCard>
        <div class="text-center">
          <div class="text-2xl font-bold">150</div>
          <div class="text-sm text-gray-500">Total Students</div>
        </div>
      </UCard>

      <UCard>
        <div class="text-center">
          <div class="text-2xl font-bold">4</div>
          <div class="text-sm text-gray-500">Active Classes</div>
        </div>
      </UCard>

      <UCard>
        <div class="text-center">
          <div class="text-2xl font-bold">15</div>
          <div class="text-sm text-gray-500">Teaching Hours/Week</div>
        </div>
      </UCard>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const search = ref('')
const statusFilter = ref('All Status')

// Table columns configuration
const columns = [
  {
    key: 'course_name',
    label: 'Course',
    sortable: true,
    id: 'course_name'
  },
  {
    key: 'day_of_week',
    label: 'Day',
    sortable: true,
    id: 'day_of_week'
  },
  {
    key: 'location',
    label: 'Location',
    id: 'location'
  },
  {
    key: 'enrollment',
    label: 'Enrollment',
    id: 'enrollment'
  },
  {
    key: 'status',
    label: 'Status',
    id: 'status'
  },
  {
    key: 'actions',
    label: 'Actions',
    id: 'actions'
  }
]

// Mock data for demonstration
const teachingClasses = ref([
  {
    course_id: 'CS101',
    course_name: 'Introduction to Programming',
    day_of_week: 'Monday',
    location: 'Room A101',
    status: 'open',
    enrolled_count: 35,
    capacity: 40
  },
  {
    course_id: 'CS202',
    course_name: 'Data Structures',
    day_of_week: 'Tuesday',
    location: 'Room B202',
    status: 'open',
    enrolled_count: 40,
    capacity: 40
  },
  {
    course_id: 'CS301',
    course_name: 'Database Systems',
    day_of_week: 'Wednesday',
    location: 'Room C103',
    status: 'open',
    enrolled_count: 28,
    capacity: 35
  },
  {
    course_id: 'CS401',
    course_name: 'Software Engineering',
    day_of_week: 'Thursday',
    location: 'Room A205',
    status: 'closed',
    enrolled_count: 25,
    capacity: 30
  }
])

const showStudentList = (classData) => {
  // Implement student list modal or navigation
  console.log('Show students for:', classData)
}

const manageGrades = (classData) => {
  // Implement grade management modal or navigation
  console.log('Manage grades for:', classData)
}
</script> 