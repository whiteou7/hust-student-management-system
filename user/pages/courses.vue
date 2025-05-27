<template>
  <div>
    <h1 class="text-2xl font-bold mb-4">All Courses</h1>
    <div class="flex flex-wrap gap-4 mb-4">
      <UInput
          v-model="search"
          variant="subtle"
          placeholder="Search courses..."
          icon="i-heroicons-magnifying-glass"
          class="w-64"
        />
        <USelect
          v-model="selectedSchool"
          variant="subtle"
          :items="allSchools"
          placeholder="Filter by school"
          class="w-40"
        />
    </div>
    <UTable :columns="columns" :data="filteredCourses" />
    <div v-if="error" class="text-red-500 mt-4">{{ error }}</div>
  </div>
</template>

<script setup lang="js">
import { ref, computed, onMounted } from "vue"

const columns = [
  { accessorKey: "course_id", header: "ID" },
  { accessorKey: "course_name", header: "Name" },
  { accessorKey: "course_description", header: "Description" },
  { accessorKey: "credit", header: "Credit" },
  { accessorKey: "school_name", header: "School" },
  { accessorKey: "tuition_per_credit", header: "Tuition/Credit" }
]

const toast = useToast()
const courses = ref([])
const error = ref("")
const search = ref("")
const selectedSchool = ref("")
const allSchools = ref("")

const { data: schoolsData } = await useFetch('/api/all-schools');
allSchools.value = schoolsData.value.schools.map(obj => Object.values(obj)[0]);

onMounted(async () => {
  try {
    const { data } = await useFetch("/api/all-courses")
    if (data.value.success || data.value) {
      courses.value = data.value.courses || []
    } else {
      toast.add({
        title: "Error",
        description: data.value.err,
        color: "error"
      })
    }
  } catch (e) {
    toast.add({
      title: "Error",
      description: "Failed to fetch course list.",
      color: "error"
    })
  }
})

const filteredCourses = computed(() => {
  let filtered = courses.value
  if (search.value) {
    const s = search.value.toLowerCase()
    filtered = filtered.filter(
      c =>
        String(c.course_id).toLowerCase().includes(s) ||
        (c.course_name && c.course_name.toLowerCase().includes(s))
    )
  }
  if (selectedSchool.value) {
    filtered = filtered.filter(c => c.school_name === selectedSchool.value)
  }
  return filtered
})
</script>
