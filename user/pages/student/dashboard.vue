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
          v-model="search"
          variant="subtle"
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

      <!-- Classes Table -->
    <UTable
      sticky
      :columns="columns"
      :data="filteredClasses"
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
          <div class="text-2xl font-bold"> {{ classCount }}</div>
          <div class="text-sm text-gray-500">Enrolled Classes</div>
        </div>
      </UCard>
    </div>

    <div v-if="errorMsg" class="text-red-500 text-center">
      {{ errorMsg }}
    </div>
  </div>
</template>

<script setup lang = "js">
import { ref, computed } from "vue"
import ClassInfoModal from "~/components/ClassInfoModal.vue"
const UButton = resolveComponent("UButton")
const UDropdownMenu = resolveComponent("UDropdownMenu")
const overlay = useOverlay()

// Column display config
const columns = [
  {
    accessorKey: "class_id",
    header: "#"
  },
  {
    accessorKey: "course_name",
    header: "Course Name"
  },
  {
    accessorKey: "day_of_week",
    header: "Day of Week"
  },
  {
    accessorKey: "mid_term",
    header: "Midterm Score"
  },
  {
    accessorKey: "final_term",
    header: "Final Score"
  },
  {
    accessorKey: "result",
    header: "Result"
  },
  // Dropdown menu to show class info
  {
  id: "actions",
  cell: ({ row }) => {
    return h(
      "div",
      { class: "text-right" },
      h(
        UDropdownMenu,
        {
          content: {
            align: "end"
          },
          items: getRowItems(row),
          "aria-label": "Actions dropdown"
        },
        () =>
          h(UButton, {
            icon: "i-lucide-ellipsis-vertical",
            color: "neutral",
            variant: "ghost",
            class: "ml-auto",
            "aria-label": "Actions dropdown"
          })
        )
      )
    }
  }
]

// Fetch and display class info on selected row
function getRowItems(row) {
  return [
    {
      label: "View class information",
      async onSelect() {
        const modal = overlay.create(ClassInfoModal)
        const classId = row.original.class_id

        const { data: classInfoRes } = await useFetch("/api/class-info", {
          method: "GET",
          body: {
            classId: classId
          }
        })

        if (!classInfoRes.value ) {
          errorMsg.value = "Failed to fetch class information"
          return
        }

        if (classInfoRes.value.success) {
          modal.open({ classInfo: classInfoRes.value.classInfo })
        } else {
          errorMsg.value = classInfoRes.value?.err || "Failed to fetch class information"
          return
        }
      }
    }
  ]
}

const classData = ref([])
const classCount = ref(0)
const currentSemester = ref(localStorage.getItem("currentSemester") || "")
const errorMsg = ref("")
const search = ref("")
const filter = ref("All Days")
const filterItems = ref([
  "All Days", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
])

const userId = localStorage.getItem("userId")

// Fetch basic enrollment info 
const res = await useFetch("/api/student-classes", {
  method: "POST",
  body: {
    userId: parseInt(userId ?? "0"),
    semester: currentSemester.value
  }
})

if (!res.data.value) {
  errorMsg.value = "Failed to fetch enrollment info."
}

if (res.data.value.success) {
  classData.value = res.data.value.classes

  // Handle null value
  classData.value = classData.value.map(item => {
    return {
      ...item,
      mid_term: item.mid_term === null ? "Ungraded" : item.mid_term,
      final_term: item.final_term === null ? "Ungraded" : item.final_term,
      result: item.result === null ? "Ungraded" : item.result
    }
  })

  classCount.value = classData.value.length
} else {
  errorMsg.value = res.data.value.err
}

// Filter and search classes
const filteredClasses = computed(() => {
  return classData.value.filter(item => {
    const matchesSearch = search.value.trim() === "" || 
      item.course_name.toLowerCase().includes(search.value.toLowerCase())

    const matchesFilter = filter.value === "All Days" || 
      item.day_of_week === filter.value

    return matchesSearch && matchesFilter
  })
})
</script>