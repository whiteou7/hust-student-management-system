<template>
  <div class="profile-container">
    <!-- Profile Header -->
    <UCard class="profile-header">
      <div class="profile-cover"/>
      <div class="profile-info">
        <UAvatar
          size="2xl"
          class="avatar"
        />
        <div style="display: flex; flex-direction: column;">
          <div class="text-white font-bold">{{ student.full_name }}</div>
          <div class="student-id">Student ID: {{ student.student_id }} - {{ student.program_name }}</div>
        </div>
      </div>
    </UCard>

    <!-- Profile Content -->
    <div class="profile-content">
      <!-- Personal Information -->
      <UCard>
        <template #header>
          <div class="flex items-center justify-between w-full">
            <div class="flex items-center gap-2">
              <UIcon name="i-heroicons-user" />
              <h2>Personal Information</h2>
            </div>
            <UModal>
              <UButton
                variant="subtle"
                icon="i-heroicons-pencil-square"
                label="Edit"
                @click="onEditProfile"
              />

              <template #content>
                <UCard>
                  <template #header>
                    <div class="flex items-center gap-2">
                      <UIcon name="i-heroicons-pencil-square" />
                      <h2>Edit Basic Information</h2>
                    </div>
                  </template>

                  <UForm :state="editForm" @submit="submitEdit">
                    <div class="space-y-4">
                      <UFormField label="First Name" required>
                        <UInput v-model="editForm.first_name" placeholder="Enter first name" />
                      </UFormField>
                      
                      <UFormField label="Last Name" required>
                        <UInput v-model="editForm.last_name" placeholder="Enter last name" />
                      </UFormField>
                      
                      <UFormField label="Email" required>
                        <UInput v-model="editForm.email" type="email" placeholder="Enter email" />
                      </UFormField>

                      <UFormField label="Date of Birth" required>
                        <UInput v-model="editForm.date_of_birth" type="date" placeholder="Enter date of birth" />
                      </UFormField>

                      <UFormField label="Address" required>
                        <UInput v-model="editForm.address" placeholder="Enter address" />
                      </UFormField>
                      
                      <UFormField label="Enrolled Year" required>
                        <UInput v-model="editForm.enrolled_year" type="number" placeholder="Enter enrolled year" />
                      </UFormField>

                      <UButton type="submit">
                        Submit
                      </UButton>
                    </div>

                    <template #footer>
                      <div class="flex justify-end gap-2">
                        <UButton
                          variant="subtle"
                          label="Cancel"
                        />
                        <UButton
                          label="Save changes"
                        />
                      </div>
                    </template>
                  </UForm>
                </UCard>
              </template>
            </UModal>
          </div>
        </template>
        
        <div class="info-grid">
        <div class="form-group">
            <label class="text-sm text-gray-500">Full Name</label>
            <div>{{ student.full_name }}</div>
        </div>
        <div class="form-group">
            <label class="text-sm text-gray-500">Email</label>
            <div>{{ student.email }}</div>
        </div>
        <div class="form-group">
            <label class="text-sm text-gray-500">Date of Birth</label>
            <div>{{ student.date_of_birth }}</div>
        </div>
        <div class="form-group">
            <label class="text-sm text-gray-500">Address</label>
            <div>{{ student.address }}</div>
        </div>
        <div class="form-group">
            <label class="text-sm text-gray-500">Enrolled Year</label>
            <div>{{ student.enrolled_year }}</div>
        </div>
        </div>
    
      </UCard>

      <!-- Academic Information -->
      <UCard>
        <template #header>
          <div class="flex items-center gap-2">
            <UIcon name="i-heroicons-academic-cap" />
            <h2>Academic Information</h2>
          </div>
        </template>

        <div class="info-grid">
          <div class="form-group">
            <label class="text-sm text-gray-500">Program</label>
            <div>{{ student.program_name }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">Warning Level</label>
            <div>{{ student.warning_level }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">Debt</label>
            <div class="flex items-center space-x-2">
              <span>{{ student.debt }}</span>
              <span class="text-blue-600 hover:underline cursor-pointer text-sm" @click="payTuition">
                Pay Tuition
              </span>
            </div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">CPA</label>
            <div>{{ student.cpa }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">GPA (semester {{ currentSemester }})</label>
            <div>{{ student.gpa }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">Accumulated Credit</label>
            <div>{{ student.accumulated_credit }}/{{ student.total_credit }}</div>
          </div>
        </div>

      </UCard>

      <!-- All Enrolled Courses -->
      <UCard>
        <template #header>
          <div class="flex items-center justify-between w-full">
            <div class="flex items-center gap-2">
              <UIcon name="i-heroicons-book-open" />
              <h2>All Enrolled Courses</h2>
            </div>

            <UButton
              variant="subtle"
              color="neutral"
              icon="i-heroicons-arrow-up-right"
              label="View all courses"
              @click="onViewCourses"
            />
          </div>
        </template>

        <div class="mb-4 flex items-center gap-4">
          <UInput
            v-model="search"
            variant="subtle"
            placeholder="Search courses..."
            icon="i-heroicons-magnifying-glass"
            class="w-64"
          />
        </div>
        
        <UTable
          sticky
          :columns="columns"
          :data="filteredCourses"/>

      </UCard>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue"
import CourseInfoModal from "~/components/CourseInfoModal.vue"
import { useRouter } from "vue-router"

const courses = ref([])
const studentId = localStorage.getItem("userId")
const student = ref({})
const toast = useToast()
const router = useRouter()
const currentSemester = ref(localStorage.getItem("currentSemester"))
const search = ref("")
const UButton = resolveComponent("UButton")
const UDropdownMenu = resolveComponent("UDropdownMenu")
const overlay = useOverlay()

// Fetch all courses
const { data: courseData } = await useFetch("/api/student-courses", {
  method: "POST",
  body: {
    studentId: parseInt(studentId ?? "0")
  }
})

if (!courseData.value) {
  toast.add({
    title: "Error",
    description: "Failed to fetch course info.",
    color: "error"
  })
}

if (courseData.value.success) {
  courses.value = courseData.value.courses

  // Handle pass status
  courses.value = courses.value.map(item => {
    return {
      ...item,
      pass: item.pass === true
        ? "Passed"
        : item.pass === null
          ? "Ungraded"
          : "Failed",
      result: item.result === null ? "Ungraded" : item.result
    }
  })

} else {
  toast.add({
    title: "Error",
    description: courseData.value.err,
    color: "error"
  })
}

// Apply filter to courses
const filteredCourses = computed(() => {
  const searchTerm = search.value.trim().toLowerCase()
  
  return courses.value.filter(item => {
    return (
      searchTerm === "" ||
      item.course_name.toLowerCase().includes(searchTerm) ||
      item.course_id.toLowerCase().includes(searchTerm)
    )
  })
})

// Column display config
const columns = [
  {
    accessorKey: "course_id",
    header: "ID"
  },
  {
    accessorKey: "course_name",
    header: "Course Name"
  },
  {
    accessorKey: "semester",
    header: "Semester"
  },
  {
    accessorKey: "credit",
    header: "Credit"
  },
  {
    accessorKey: "result",
    header: "Result"
  },
  {
    accessorKey: "pass",
    header: "Status"
  },
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

// Display course info on selected row
function getRowItems(row) {
  return [
    {
      label: "View course information",
      async onSelect() {
        const modal = overlay.create(CourseInfoModal)
        const courseId = row.original.course_id

        const { data: courseInfoData } = await useFetch("/api/course-info", {
          method: "POST",
          body: {
            courseId: courseId
          }
        })

        if (!courseInfoData.value) {
          toast.add({
            title: "Error",
            description: "Failed to fetch course information.",
            color: "error"
          })
          return
        }

        if (courseInfoData.value.success) {
          console.log(courseInfoData.value.courseInfo)
          modal.open({ courseInfo: courseInfoData.value.courseInfo })
        } else {
          toast.add({
            title: "Error",
            description: courseInfoData.value?.err || "Failed to fetch course information",
            color: "error"
          })
          return
        }
      }
    }
  ]
}

const editForm = ref({
  first_name: "",
  last_name: "",
  email: "",
  date_of_birth: "",
  address: "",
  enrolled_year: ""
})

// Handle view all courses button
function onViewCourses() {
  router.push("/courses")
}

// Handle pay tuition
async function payTuition() {
  const { data: editData } = await useFetch("/api/student-info", {
    method: "PUT",
    body: {
      studentId: parseInt(studentId ?? "0"),
      debt: 0
    }
  })

  if (!editData.value || !editData.value.success) {
    toast.add({
      title: "Error",
      description: "Transaction failed. Please try again.",
      color: "error"
    })
    return
  }

  toast.add({
    title: "Success",
    description: "Tuition paid successfully.",
    color: "success"
  })
}

// Fetch student info
const { data: studentData } = await useFetch("/api/student-info", {
  method: "POST",
  body: {
    studentId: parseInt(studentId ?? "0"),
    currentSemester: currentSemester.value ?? "0"
  }
})

if (!studentData.value) {
  toast.add({
    title: "Error",
    description: "Failed to fetch student info.",
    color: "error"
  })
}

if (studentData.value.success) {
  student.value = studentData.value.studentInfo
} else {
  toast.add({
    title: "Error",
    description: studentData.value.err,
    color: "error"
  })
}

// Handle edit profile button
async function onEditProfile() {
  // Initialize form with current values
  editForm.value = {
    first_name: student.value.first_name,
    last_name: student.value.last_name,
    email: student.value.email,
    date_of_birth: student.value.date_of_birth,
    address: student.value.address,
    enrolled_year: student.value.enrolled_year
  }
}

// Edit student profile after submitting
async function submitEdit() {
  const { data: editData } = await useFetch("/api/student-info", {
    method: "PUT",
    body: {
      studentId: parseInt(studentId ?? "0"),
      ...editForm.value
    }
  })

  if (!editData.value) {
    toast.add({
      title: "Error",
      description: "Failed to update student info.",
      color: "red"
    })
    return
  }

  if (editData.value.success) {
    Object.assign(student.value, editForm.value)
    toast.add({
      title: "Success",
      description: "Information updated successfully",
      color: "success"
    })
  } else {
    toast.add({
      title: "Error",
      description: editData.value.err,
      color: "error"
    })
  }
}

</script>

<style scoped>
.profile-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.profile-header {
  position: relative;
  margin-bottom: 100px;
}

.profile-cover {
  height: 200px;
  background-image: url('https://navi.edu.vn/blog/wp-content/uploads/2025/02/tuyen-sinh-2025-thong-tin-tuyen-sinh-dai-hoc-bach-khoa-ha-noi-hust.jpg'); /* Replace with actual image path */
  background-size: cover;
  background-position: center;
  border-radius: 12px;
}

.profile-info {
  position: absolute;
  bottom: -75px;
  left: 40px;
  display: flex;
  align-items: flex-end;
  gap: 24px;
}

.avatar {
  border: 4px solid white;
}

.edit-avatar-btn {
  position: absolute;
  bottom: 10px;
  right: 10px;
}

.student-id {
  color: var(--color-gray-500);
}

.profile-content {
  display: grid;
  gap: 32px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.courses-list {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.course-card {
  background: var(--color-gray-50);
  border-left: 4px solid var(--color-green-500);
}

.course-card h3 {
  margin: 0 0 8px 0;
  color: var(--color-gray-900);
}

@media (max-width: 768px) {
  .profile-info {
    flex-direction: column;
    align-items: center;
    text-align: center;
    left: 50%;
    transform: translateX(-50%);
  }
}
</style>
