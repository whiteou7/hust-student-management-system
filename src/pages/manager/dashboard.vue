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
        <h2 class="text-2xl font-bold">Edit/Add Course</h2>
      </template>
      <UForm :state="editCourseForm" @submit="handleEditCourse">
        <div class="max-w-md mx-auto flex flex-col space-y-4">
          <UFormField class="block w-full mb-2" label="Course ID" required>
            <UInput v-model="editCourseForm.courseId" class="w-full" />
          </UFormField>
          
          <UFormField class="block w-full mb-2" label="Course Name" required>
            <UInput v-model="editCourseForm.courseName" class="w-full" />
          </UFormField>
          
          <UFormField class="block w-full mb-2" label="Description" required>
            <UTextarea v-model="editCourseForm.courseDescription" class="w-full" />
          </UFormField>
          
          <UFormField class="block w-full mb-2" label="Credits" required>
            <UInput v-model="editCourseForm.credit" type="number" class="w-full" />
          </UFormField>
          
          <UFormField class="block w-full mb-2" label="Tuition per Credit" required>
            <UInput v-model="editCourseForm.tuitionPerCredit" type="number" class="w-full" />
          </UFormField>
          
          <UFormField class="block w-full mb-2" label="School" required>
            <USelect 
              v-model="editCourseForm.schoolId" 
              :items="schoolOptions"
              class="w-full"
            />
          </UFormField>

          <div class="flex justify-end space-x-2">
            <UButton color="gray" @click="cancelEdit">Cancel</UButton>
            <UButton v-if="editCourseForm.courseId" type="button" color="error" @click="handleDeleteCourse">Delete</UButton>
            <UButton type="submit" color="primary">Save Changes</UButton>
          </div>
        </div>
      </UForm>
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

    <UCard>
      <template #header>
        <h2 class="text-2xl font-bold">Edit/Add Class</h2>
      </template>
      <UForm :state="editClassForm" @submit="handleEditClass">
        <div class="max-w-md mx-auto flex flex-col space-y-4">
          <UFormField class="block w-full mb-2" label="Teacher">
            <USelect
              v-model="editClassForm.teacherId"
              :items="teacherOptions"
              class="w-full"
            />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Course ID" required>
            <UInput v-model="editClassForm.courseId" class="w-full" />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Capacity" required>
            <UInput v-model="editClassForm.capacity" type="number" class="w-full" />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Semester" required>
            <UInput v-model="editClassForm.semester" class="w-full" />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Status" required>
            <USelect
              v-model="editClassForm.status"
              :items="classStatusOptions"
              class="w-full"
            />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Day of Week" required>
            <UInput v-model="editClassForm.dayOfWeek" class="w-full" />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Location" required>
            <UInput v-model="editClassForm.location" class="w-full" />
          </UFormField>
          <div class="flex justify-end space-x-2">
            <UButton color="gray" @click="cancelEditClass">Cancel</UButton>
            <UButton v-if="editClassForm.classId" type="button" color="red" @click="handleDeleteClass">Delete</UButton>
            <UButton type="submit" color="primary">Save Changes</UButton>
          </div>
        </div>
      </UForm>
    </UCard>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "manager"
})

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
const editClassForm = ref({})
const schools = ref([])
const teachers = ref([])
const schoolOptions = computed(() => 
  schools.value.map(school => ({
    label: school.school_name,
    value: school.school_id
  }))
)
const teacherOptions = computed(() =>
  teachers.value.map(teacher => ({
    label: teacher.full_name,
    value: teacher.teacher_id
  }))
)
const classStatusOptions = [
  { label: "Open", value: "open" },
  { label: "Closed", value: "closed" }
]

// Watch selectedCourse to update form
watch(selectedCourse, (newValue) => {
  if (newValue) {
    editCourseForm.value = {
      courseId: newValue.course_id,
      courseName: newValue.course_name,
      courseDescription: newValue.course_description,
      credit: newValue.credit,
      tuitionPerCredit: newValue.tuition_per_credit,
      schoolId: schools.value.find(s => s.school_name === newValue.school_name)?.school_id || ""
    }

  } else {
    editCourseForm.value = {}
  }
})

// Watch selectedClass to update form
watch(selectedClass, (newValue) => {
  if (newValue) {
    editClassForm.value = {
      classId: newValue.class_id,
      teacherId: teachers.value.find(t => t.full_name === newValue.full_name)?.teacher_id || "",
      courseId: newValue.course_id,
      capacity: newValue.capacity,
      semester: newValue.semester,
      enrolledCount: newValue.enrolled_count,
      status: newValue.status,
      dayOfWeek: newValue.day_of_week,
      location: newValue.location
    }
  } else {
    editClassForm.value = {}
  }
})

// Fetch logic
async function fetchCourses() {
  try {
    const { data: coursesData } = await useFetch("/api/all-courses")
    if (coursesData.value?.success) {
      courses.value = coursesData.value.courses || []
    }
  } catch (error) {
    console.error("Error fetching courses:", error)
  }
}

async function fetchClasses() {
  try {
    const { data: classesData } = await useFetch("/api/all-classes")
    if (classesData.value?.success) {
      classes.value = classesData.value.classes || []
    }
  } catch (error) {
    console.error("Error fetching classes:", error)
  }
}

async function fetchSchools() {
  try {
    const { data: schoolsData } = await useFetch("/api/all-schools")
    if (schoolsData.value?.success) {
      schools.value = schoolsData.value.schools || []
    }
  } catch (error) {
    console.error("Error fetching schools:", error)
  }
}

async function fetchTeachers() {
  try {
    const { data: teachersData } = await useFetch("/api/all-teachers")
    if (teachersData.value?.success) {
      teachers.value = teachersData.value.teachers || []
    }
  } catch (error) {
    console.error("Error fetching teachers:", error)
  }
}

onMounted(async () => {
  await Promise.all([
    fetchCourses(),
    fetchClasses(),
    fetchSchools(),
    fetchTeachers()
  ])
})

function cancelEdit() {
  selectedCourse.value = {}
  editCourseForm.value = {}
}

function cancelEditClass() {
  selectedClass.value = {}
  editClassForm.value = {}
}

async function refetchAll() {
  await Promise.all([
    fetchCourses(),
    fetchClasses(),
    fetchSchools(),
    fetchTeachers()
  ])
}

async function handleEditCourse() {
  try {
    const isEdit = !!selectedCourse.value && !!selectedCourse.value.course_id
    const response = await useFetch(isEdit ? "/api/course-info" : "/api/course-info", {
      method: isEdit ? "PUT" : "POST",
      body: editCourseForm.value
    })
    if (response.data.value?.success) {
      await refetchAll()
      toast.add({
        title: "Success",
        description: isEdit ? "Course updated successfully" : "Course added successfully",
        color: "success"
      })
      cancelEdit()
    } else {
      toast.add({
        title: "Error",
        description: response.data.value?.err || (isEdit ? "Failed to update course" : "Failed to add course"),
        color: "error"
      })
      console.error(isEdit ? "Failed to update course:" : "Failed to add course:", response.data.value?.err)
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: isEdit ? "Error updating course" : "Error adding course",
      color: "error"
    })
    console.error(isEdit ? "Error updating course:" : "Error adding course:", error)
  }
}

async function handleEditClass() {
  try {
    const isEdit = !!selectedClass.value && !!selectedClass.value.class_id
    const response = await useFetch(isEdit ? "/api/class-info" : "/api/class-info", {
      method: isEdit ? "PUT" : "POST",
      body: editClassForm.value
    })
    if (response.data.value?.success) {
      await refetchAll()
      toast.add({
        title: "Success",
        description: isEdit ? "Class updated successfully" : "Class added successfully",
        color: "success"
      })
      cancelEditClass()
    } else {
      toast.add({
        title: "Error",
        description: response.data.value?.err || (isEdit ? "Failed to update class" : "Failed to add class"),
        color: "error"
      })
      console.error(isEdit ? "Failed to update class:" : "Failed to add class:", response.data.value?.err)
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: isEdit ? "Error updating class" : "Error adding class",
      color: "error"
    })
    console.error(isEdit ? "Error updating class:" : "Error adding class:", error)
  }
}

async function handleDeleteCourse() {
  try {
    const response = await useFetch("/api/course-info", {
      method: "DELETE",
      body: { courseId: editCourseForm.value.courseId }
    })
    if (response.data.value?.success) {
      await refetchAll()
      toast.add({
        title: "Success",
        description: "Course deleted successfully",
        color: "success"
      })
      cancelEdit()
    } else {
      toast.add({
        title: "Error",
        description: response.data.value?.err || "Failed to delete course",
        color: "error"
      })
      console.error("Failed to delete course:", response.data.value?.err)
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: "Error deleting course",
      color: "error"
    })
    console.error("Error deleting course:", error)
  }
}

async function handleDeleteClass() {
  try {
    const response = await useFetch("/api/class-info", {
      method: "DELETE",
      body: { classId: editClassForm.value.classId }
    })
    if (response.data.value?.success) {
      await refetchAll()
      toast.add({
        title: "Success",
        description: "Class deleted successfully",
        color: "success"
      })
      cancelEditClass()
    } else {
      toast.add({
        title: "Error",
        description: response.data.value?.err || "Failed to delete class",
        color: "error"
      })
      console.error("Failed to delete class:", response.data.value?.err)
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: "Error deleting class",
      color: "error"
    })
    console.error("Error deleting class:", error)
  }
}
</script>