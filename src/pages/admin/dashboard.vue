<template>  <div class="p-4 space-y-6">
    <UCard>
      <template #header>
        <h2 class="text-2xl font-bold">All Courses</h2>
      </template>
        <UTable 
          :data="courses" 
          :columns="courseColumns"
          sticky
          class="flex-1 max-h-[312px]"
        />
    </UCard>

    <UCard>
      <template #header>
        <h2 class="text-2xl font-bold">All Classes</h2>
      </template>
        <UTable 
          :data="classes" 
          :columns="classColumns"
          sticky
          class="flex-1 max-h-[312px]"
        />
    </UCard>

    <UCard v-if="Object.keys(selectedCourse).length > 0">
      <template #header>
        <h2 class="text-2xl font-bold">Edit Course</h2>
      </template>
      <UForm :state="editCourseForm" @submit="handleEditCourse">
        <div class="space-y-4">
          <UFormField label="Course ID" required>
            <UInput v-model="editCourseForm.course_id" />
          </UFormField>
          
          <UFormField label="Course Name" required>
            <UInput v-model="editCourseForm.course_name" />
          </UFormField>
          
          <UFormField label="Description" required>
            <UTextarea v-model="editCourseForm.course_description" />
          </UFormField>
          
          <UFormField label="Credits" required>
            <UInput v-model="editCourseForm.credit" type="number" />
          </UFormField>
          
          <UFormField label="Tuition per Credit" required>
            <UInput v-model="editCourseForm.tuition_per_credit" type="number" />
          </UFormField>
          
          <UFormField label="School" required>
            <USelect 
              v-model="editCourseForm.school_id" 
              :items="schoolOptions"
            />
          </UFormField>

          <div class="flex justify-end space-x-2">
            <UButton color="gray" @click="cancelEdit">Cancel</UButton>
            <UButton type="submit" color="primary">Save Changes</UButton>
          </div>
        </div>
      </UForm>
    </UCard>
  </div>
</template>

<script setup>
const UButton = resolveComponent("UButton")
const selectedCourse = ref({})
const selectedClass = ref({})
const toast = useToast()

const courseColumns = [
  {
    accessorKey: "course_id",
    header: "Course ID"
  },
  {
    accessorKey: "course_name",
    header: "Course Name"
  },
  {
    accessorKey: "credit",
    header: "Credits"
  },
  {
    accessorKey: "course_description",
    header: "Description"
  },
  {
    accessorKey: "school_name",
    header: "School"
  },
  {
    accessorKey: "tuition_per_credit",
    header: "Tuition/Credit"
  },  
  {    
    id: "selectCourse",
    class: "w-[100px] flex justify-end",
    cell: ({ row }) => {
      return h(
        "div",
        { class: "text-right" },
        h(
          UButton, {
            icon: "i-lucide-pencil",
            color: "neutral",
            variant: "ghost",
            onClick: () => {
              selectedCourse.value = row.original
            }
          })
      )
    }
  }
]

const classColumns = [
  {
    accessorKey: "class_id",
    header: "Class ID"
  },
  {
    accessorKey: "course_id",
    header: "Course ID"
  },
  {
    accessorKey: "location",
    header: "Location"
  },
  {
    accessorKey: "capacity",
    header: "Capacity"
  },
  {
    accessorKey: "enrolled_count",
    header: "Enrolled"
  },
  {
    accessorKey: "semester",
    header: "Semester"
  },
  {
    accessorKey: "day_of_week",
    header: "Day"
  },
  {
    accessorKey: "full_name",
    header: "Teacher",
  },  
  {
    id: "selectClass",
    cell: ({ row }) => {
      return h(
        "div",
        { class: "text-right" },
        h(
          UButton, {
            icon: "i-lucide-pencil",
            color: "neutral",
            variant: "ghost",
            onClick: () => {
              selectedClass.value = row.original
            }
          })
      )
    }
  }
]

// State
const courses = ref([])
const classes = ref([])
const editCourseForm = ref({})
const schools = ref([])
const schoolOptions = computed(() => 
  schools.value.map(school => ({
    label: school.school_name,
    value: school.school_id
  }))
)

// Watch selectedCourse to update form
watch(selectedCourse, (newValue) => {
  if (newValue) {
    editCourseForm.value = { ...newValue }
  } else {
    editCourseForm.value = {}
  }
})

// Fetch data
onMounted(async () => {
  try {
    const { data: coursesData } = await useFetch("/api/all-courses")
    const { data: classesData } = await useFetch("/api/all-classes")
    const { data: schoolsData } = await useFetch("/api/all-schools")
    
    if (coursesData.value?.success) {
      courses.value = coursesData.value.courses || []
    }
    
    if (classesData.value?.success) {
      classes.value = classesData.value.classes || []
    }

    if (schoolsData.value?.success) {
      schools.value = schoolsData.value.schools || []
    }
  } catch (error) {
    console.error("Error fetching data:", error)
  }
})

function cancelEdit() {
  selectedCourse.value = {}
  editCourseForm.value = {}
}

async function handleEditCourse() {
  try {
    const response = await useFetch("/api/course-info.put", {
      method: "PUT",
      body: editCourseForm.value
    })
    
    if (response.data.value?.success) {
      const index = courses.value.findIndex(course => course.course_id === editCourseForm.value.course_id)
      if (index !== -1) {
        courses.value[index] = { ...courses.value[index], ...editCourseForm.value }
      } toast.add({
        title: "Success",
        description: "Course updated successfully",
        color: "success"
      })
      cancelEdit()
    } else {
      toast.add({
        title: "Error",
        description: response.data.value?.message || "Failed to update course",
        color: "error"
      })
      console.error("Failed to update course:", response.data.value?.message)
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: "Error updating course",
      color: "error"
    })
    console.error("Error updating course:", error)
  }
}
</script>