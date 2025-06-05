<template>
  <div class="p-6">
    <div v-if="!classRegStatus" class="text-center text-xl text-red-600 font-bold py-20">
      This is not the period for class registration
    </div>
    <template v-else>
      <!-- Available Classes Table -->
      <UCard class="mb-8">
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-semibold">Available Classes for Registration</h2>
          </div>
        </template>
        <div class="mb-4 flex items-center gap-4">
          <UInput
            v-model="searchAvailable"
            variant="subtle"
            placeholder="Search classes..."
            icon="i-heroicons-magnifying-glass"
            class="w-64"
          />
          <USelect
            v-model="filterAvailable"
            variant="subtle"
            :items="filterItems"
            placeholder="Filter by day"
            class="w-40"
          />
        </div>
        <UTable
          sticky
          :columns="columns"
          :data="filteredAvailableClasses"
        />
      </UCard>

      <!-- Enrolled Classes Table -->
      <UCard>
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-semibold">Enrolled Classes</h2>
          </div>
        </template>
        <div class="mb-4 flex items-center gap-4">
          <UInput
            v-model="searchEnrolled"
            variant="subtle"
            placeholder="Search classes..."
            icon="i-heroicons-magnifying-glass"
            class="w-64"
          />
          <USelect
            v-model="filterEnrolled"
            variant="subtle"
            :items="filterItems"
            placeholder="Filter by day"
            class="w-40"
          />
        </div>
        <UTable
          sticky
          :columns="enrolledColumns"
          :data="filteredEnrolledClasses"
        />
      </UCard>

      <div v-if="errorMsg" class="text-red-500 text-center mt-4">
        {{ errorMsg }}
      </div>
    </template>
  </div>
</template>

<script setup lang="js">
import ClassInfoModal from "~/components/ClassInfoModal.vue"
import { ref, computed, h } from "vue"
const UButton = resolveComponent("UButton")
const UDropdownMenu = resolveComponent("UDropdownMenu")

// Columns for available classes (with Register)
const columns = [
  { accessorKey: "class_id", header: "Class ID" },
  { accessorKey: "course_id", header: "Course ID" },
  { accessorKey: "day_of_week", header: "Day of Week" },
  { accessorKey: "location", header: "Location" },
  { accessorKey: "capacity", header: "Capacity" },
  {
    id: "actions",
    cell: ({ row }) => {
      return h(
        "div",
        { class: "text-right" },
        h(
          UDropdownMenu,
          {
            content: { align: "end" },
            items: [
              {
                label: "View class information",
                onSelect() {
                  onView(row.original)
                }
              },
              {
                label: "Register",
                onSelect() {
                  onRegister(row.original)
                }
              }
            ],
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

// Columns for enrolled classes (with Unregister)
const enrolledColumns = [
  { accessorKey: "class_id", header: "Class ID" },
  { accessorKey: "course_id", header: "Course ID" },
  { accessorKey: "day_of_week", header: "Day of Week" },
  { accessorKey: "location", header: "Location" },
  { accessorKey: "capacity", header: "Capacity" },
  {
    id: "actions",
    cell: ({ row }) => {
      return h(
        "div",
        { class: "text-right" },
        h(
          UDropdownMenu,
          {
            content: { align: "end" },
            items: [
              {
                label: "View class information",
                onSelect() {
                  onView(row.original)
                }
              },
              {
                label: "Unregister",
                onSelect() {
                  onUnregister(row.original)
                }
              }
            ],
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

const toast = useToast()
const availableClasses = ref([])
const enrolledClasses = ref([])
const errorMsg = ref("")
const overlay = useOverlay()
const searchAvailable = ref("")
const filterAvailable = ref("All Days")
const searchEnrolled = ref("")
const filterEnrolled = ref("All Days")
const filterItems = ref([
  "All Days", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
])

const userId = localStorage.getItem("userId")
const classRegStatus = ref(true)

// Fetch next semester
const { data: semesterData } = await useFetch("/api/next-semester", {
  method: "GET"
})

const nextSemester = semesterData.value.nextSemester

// Fetch class registration status
try {
  const { data: regStatusData } = await useFetch("/api/class-reg-status", { method: "GET" })
  classRegStatus.value = !!regStatusData.value?.classRegStatus
} catch (e) {
  console.log(e)
  classRegStatus.value = false
}

// Fetch available and enrolled classes for registration
const res = await useFetch("/api/class-registration", {
  method: "GET",
  query: {
    studentId: userId,
    nextSemester
  }
})

if (!res.data.value) {
  errorMsg.value = "Failed to fetch class registration info."
} else if (res.data.value.success) {
  availableClasses.value = res.data.value.unregisteredNewClasses
  enrolledClasses.value = res.data.value.registeredNewClasses
} else {
  errorMsg.value = res.data.value.err
}

// Filter and search for available classes
const filteredAvailableClasses = computed(() => {
  return (availableClasses.value || []).filter(item => {
    const matchesSearch =
      searchAvailable.value.trim() === "" ||
      item.course_id?.toString().toLowerCase().includes(searchAvailable.value.toLowerCase()) ||
      item.class_id?.toString().toLowerCase().includes(searchAvailable.value.toLowerCase())
    const matchesFilter =
      filterAvailable.value === "All Days" ||
      item.day_of_week === filterAvailable.value
    return matchesSearch && matchesFilter
  })
})

// Filter and search for enrolled classes
const filteredEnrolledClasses = computed(() => {
  return (enrolledClasses.value || []).filter(item => {
    const matchesSearch =
      searchEnrolled.value.trim() === "" ||
      item.course_id?.toString().toLowerCase().includes(searchEnrolled.value.toLowerCase()) ||
      item.class_id?.toString().toLowerCase().includes(searchEnrolled.value.toLowerCase())
    const matchesFilter =
      filterEnrolled.value === "All Days" ||
      item.day_of_week === filterEnrolled.value
    return matchesSearch && matchesFilter
  })
})

async function onRegister(selectedClass) {
  if (!userId) {
    toast.add({
      title: "Error",
      description: "User not logged in.",
      color: "error"
    })
    return
  }

  const { data: registerRes } = await useFetch("/api/class-registration", {
    method: "POST",
    body: {
      studentId: userId,
      classId: selectedClass.class_id
    }
  })

  if (!registerRes.value) {
    toast.add({
      title: "Error",
      description: "Failed to register for class.",
      color: "error"
    })
    return
  }

  if (registerRes.value.success) {
    toast.add({
      title: "Success",
      description: "Successfully registered for the class.",
      color: "primary"
    })
    // Refresh class lists
    const res = await useFetch("/api/class-registration", {
      method: "GET",
      query: {
        studentId: userId,
        nextSemester
      }
    })
    if (res.data.value && res.data.value.success) {
      availableClasses.value = res.data.value.unregisteredNewClasses
      enrolledClasses.value = res.data.value.registeredNewClasses
    }
  } else {
    toast.add({
      title: "Error",
      description: registerRes.value.err || "Registration failed.",
      color: "error"
    })
  }
}

async function onUnregister(selectedClass) {
  if (!userId) {
    toast.add({
      title: "Error",
      description: "User not logged in.",
      color: "error"
    })
    return
  }

  const { data: unregisterRes } = await useFetch("/api/class-registration", {
    method: "DELETE",
    body: {
      studentId: userId,
      classId: selectedClass.class_id
    }
  })

  if (!unregisterRes.value) {
    toast.add({
      title: "Error",
      description: "Failed to unregister from class.",
      color: "error"
    })
    return
  }

  if (unregisterRes.value.success) {
    toast.add({
      title: "Success",
      description: "Successfully unregistered from the class.",
      color: "primary"
    })
    // Refresh class lists
    const res = await useFetch("/api/class-registration", {
      method: "GET",
      query: {
        studentId: userId,
        nextSemester
      }
    })
    if (res.data.value && res.data.value.success) {
      availableClasses.value = res.data.value.unregisteredNewClasses
      enrolledClasses.value = res.data.value.registeredNewClasses
    }
  } else {
    toast.add({
      title: "Error",
      description: unregisterRes.value.err || "Unregistration failed.",
      color: "error"
    })
  }
}

// View selected class's information
async function onView(selectedClass) {
  const modal = overlay.create(ClassInfoModal)

  const { data: classInfoData } = await useFetch("/api/class-info", {
    method: "GET",
    query: {
      classId: selectedClass.class_id
    }
  })

  if (!classInfoData.value) {
    toast.add({ 
      title: "Error", 
      description: "Failed fetching class info",
      color: "error"
    })
    return
  }

  if (classInfoData.value.success) {
    modal.open({ classInfo: classInfoData.value.classInfo })
  } else {
    toast.add({ 
      title: "Error", 
      description: classInfoData.err,
      color: "error"
    })
    return
  }
}
</script>
