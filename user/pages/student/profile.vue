<template>
  <div class="profile-container">
    <!-- Profile Header -->
    <UCard class="profile-header">
      <div class="profile-cover"></div>
      <div class="profile-info">
        <UAvatar
          size="2xl"
          class="avatar"
        />
        <div style="display: flex; flex-direction: column;">
          <div class="text-white font-bold">{{ student.first_name }} {{ student.last_name }}</div>
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
                @click="onClick"
              >
              </UButton>

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
                      <UFormField label="First Name">
                        <UInput v-model="editForm.first_name" placeholder="Enter first name" />
                      </UFormField>
                      
                      <UFormField label="Last Name">
                        <UInput v-model="editForm.last_name" placeholder="Enter last name" />
                      </UFormField>
                      
                      <UFormField label="Email">
                        <UInput v-model="editForm.email" type="email" placeholder="Enter email" />
                      </UFormField>

                      <UFormField label="Date of Birth">
                        <UInput v-model="editForm.date_of_birth" type="date" placeholder="Enter date of birth" />
                      </UFormField>

                      <UFormField label="Address">
                        <UInput v-model="editForm.address" placeholder="Enter address" />
                      </UFormField>
                      
                      <UFormField label="Enrolled Year">
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
                        >
                        </UButton>
                        <UButton
                          label="Save changes"
                        >
                        </UButton>
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
            <div>{{ student.first_name }} {{ student.last_name }}</div>
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
            <div>{{ student.debt }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">CPA</label>
            <div>{{ student.cpa }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">Accumulated Credit</label>
            <div>{{ student.accumulated_credit }}/{{ student.total_credit }}</div>
          </div>
        </div>

      </UCard>

      <!-- Current Courses -->
      <UCard>
        <template #header>
          <div class="flex items-center gap-2">
            <UIcon name="i-heroicons-book-open" />
            <h2>Current Courses</h2>
          </div>
        </template>
        <div class="courses-list">
          <UCard
            v-for="course in student.courses"
            :key="course.id"
            class="course-card"
          >
            <h3>{{ course.name }}</h3>
            <div class="text-gray-500">{{ course.code }}</div>
            <div class="mt-2 space-y-1">
              <div class="flex items-center gap-1">
                <UIcon name="i-heroicons-clock" class="w-4 h-4" />
                {{ course.schedule }}
              </div>
              <div class="flex items-center gap-1">
                <UIcon name="i-heroicons-user" class="w-4 h-4" />
                {{ course.instructor }}
              </div>
            </div>
          </UCard>
        </div>
      </UCard>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue"

const student = ref({})
const studentId = localStorage.getItem("userId")
const toast = useToast()
const editForm = ref({
  first_name: "",
  last_name: "",
  email: "",
  date_of_birth: "",
  address: "",
  enrolled_year: ""
})

// Fetch student info
const res = await useFetch("/api/student-info", {
  method: "POST",
  body: {
    studentId: parseInt(studentId ?? "0"),
  }
})

if (!res.data.value) {
  toast.add({
    title: "Error",
    description: "Failed to fetch student info.",
    color: "error"
  })
}

if (res.data.value.success) {
  student.value = res.data.value.studentInfo
} else {
  toast.add({
    title: "Error",
    description: res.data.value.err,
    color: "error"
  })
}

async function onClick() {
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
  const res = await useFetch("/api/student-info", {
    method: "PUT",
    body: {
      studentId: parseInt(studentId ?? "0"),
      ...editForm.value
    }
  })

  if (!res.data.value) {
    toast.add({
      title: "Error",
      description: "Failed to update student info.",
      color: "red"
    })
    return
  }

  if (res.data.value.success) {
    Object.assign(student.value, editForm.value)
    toast.add({
      title: "Success",
      description: "Information updated successfully",
      color: "success"
    })
  } else {
    toast.add({
      title: "Error",
      description: res.data.value.err,
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
