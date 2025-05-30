<template>
  <div class="p-6">
    <UCard class="mb-4">
      <template #header>
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-semibold">My Teaching Classes</h2>
          <p class="text-sm text-gray-500">Current Semester: {{ semester }}</p>
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
          v-model="filter"
          variant="subtle"
          :items="filterItems"
          placeholder="Filter by day"
          class="w-40"
        />
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        <UCard
          v-for="class_ in filteredClasses"
          :key="class_.class_id"
          class="h-[150px] flex flex-col justify-between h-full hover:shadow-lg transition"
        >
          <template #header>
            <NuxtLink
              :to="`/teacher/class/${class_.class_id}`"
              class="text-lg font-semibold hover:underline focus:outline-none"
              style="display: block;"
            >
              {{ class_.class_id }} - {{ class_.course_id }} {{ class_.course_name }}
            </NuxtLink>
          </template>

          <div>
            <p class="h-[50px] text-sm text-gray-600">
              {{ class_.course_description }}
            </p>
          </div>

          <template #footer>
            <div>
              {{ class_.enrolled_count }} enrolled - {{ class_.location }} - {{ class_.day_of_week }}
            </div>
          </template>
        </UCard>
      </div>

      
    </UCard>

    <!-- Summary Cards -->
    <div class="grid grid-cols-2 gap-4 mt-6">
      <UCard>
        <div class="text-center">
          <div class="text-2xl font-bold"> {{ miscInfo.total_class_count }} </div>
          <div class="text-sm text-gray-500">Total Classes</div>
        </div>
      </UCard>

      <UCard>
        <div class="text-center">
          <div class="text-2xl font-bold"> {{ miscInfo.today_class_count }}</div>
          <div class="text-sm text-gray-500">Active Classes Today</div>
        </div>
      </UCard>

    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const semester = ref(localStorage.getItem("currentSemester"))
const classes = ref([])
const toast = useToast()
const miscInfo = ref({})
const search = ref("")
const filter = ref("All Days")
const filterItems = ref([
  "All Days", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
])

// Fetch class list
onMounted(async () => {
  const { data: classData } = await useFetch("/api/teacher-classes", {
    method: "POST",
    body: {
      semester: semester.value,
      userId: localStorage.getItem("userId")
    }
  })

  if (!classData.value || !classData.value.success) {
    toast.add({
      title: "Error",
      description: classData.value.err ?? "Failed fetching class information.",
      color: "error"
    })
    return
  }

  classes.value = classData.value.classes
  miscInfo.value = classData.value.miscInfo
})

// Search by class id, course id, course name and filter by days
const filteredClasses = computed(() => {
  return classes.value.filter(item => {
    const searchTerm = search.value.trim().toLowerCase()
    const matchesSearch = searchTerm === "" ||
      item.course_name.toLowerCase().includes(searchTerm) ||
      item.class_id.toLowerCase().includes(searchTerm) ||
      item.course_id.toLowerCase().includes(searchTerm)

    const matchesFilter = filter.value === "All Days" ||
      item.day_of_week === filter.value

    return matchesSearch && matchesFilter
  })
})

</script>