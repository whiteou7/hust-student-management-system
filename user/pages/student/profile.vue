<template>
  <div class="profile-container">
    <!-- Profile Header -->
    <UCard class="profile-header">
      <div class="profile-cover"></div>
      <div class="profile-info">
        <div class="profile-avatar">
          <UAvatar
            size="xl"
            class="avatar"
          />
        </div>
        <div class="profile-details">
          <div><UText class="text-white font-bold">{{ student.first_name }} {{ student.last_name }}</UText></div>
          <UText class="student-id">Student ID: {{ student.student_id }} - </UText>
          <UText class="department">{{ student.program_name }}</UText>
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
                label="Edit Basic Info"
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

                  <UForm @submit="submitEdit">
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
                      
                      <UFormField label="Enrolled Year">
                        <UInput v-model="editForm.enrolled_year" type="number" placeholder="Enter enrolled year" />
                      </UFormField>
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
            <UText>{{ student.first_name }} {{ student.last_name }}</UText>
        </div>
        <div class="form-group">
            <label class="text-sm text-gray-500">Email</label>
            <UText>{{ student.email }}</UText>
        </div>
        <div class="form-group">
            <label class="text-sm text-gray-500">Enrolled Year</label>
            <UText>{{ student.enrolled_year }}</UText>
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
        <UForm>
          <div class="info-grid">
            <div class="form-group">
              <label class="text-sm text-gray-500">Program</label>
              <UText>{{ student.program_name }}</UText>
            </div>
            <div class="form-group">
              <label class="text-sm text-gray-500">Warning Level</label>
              <UText>{{ student.warning_level }}</UText>
            </div>
            <div class="form-group">
              <label class="text-sm text-gray-500">Debt</label>
              <UText>{{ student.debt }}</UText>
            </div>
            <div class="form-group">
              <label class="text-sm text-gray-500">CPA</label>
              <UText>{{ student.cpa }}</UText>
            </div>
            <div class="form-group">
              <label class="text-sm text-gray-500">Accumulated Credit</label>
              <UText>{{ student.accumulated_credit }}/{{ student.total_credit }}</UText>
            </div>
          </div>
        </UForm>
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
            <UText class="text-gray-500">{{ course.code }}</UText>
            <div class="mt-2 space-y-1">
              <UText class="flex items-center gap-1">
                <UIcon name="i-heroicons-clock" class="w-4 h-4" />
                {{ course.schedule }}
              </UText>
              <UText class="flex items-center gap-1">
                <UIcon name="i-heroicons-user" class="w-4 h-4" />
                {{ course.instructor }}
              </UText>
            </div>
          </UCard>
        </div>
      </UCard>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const student = ref({})
const studentId = localStorage.getItem("userId")
const toast = useToast()
const editForm = ref({
  first_name: '',
  last_name: '',
  email: '',
  enrolled_year: ''
})

const res = await useFetch("/api/student-info", {
  method: "POST",
  body: {
    studentId: parseInt(studentId ?? "0"),
  }
})

if (!res.data.value) {
  errorMsg.value = "Failed to fetch student info."
}

if (res.data.value.success) {
  student.value = res.data.value.studentInfo
} else {
  errorMsg.value = res.data.value.err
}

async function onClick() {
  // Initialize form with current values
  editForm.value = {
    first_name: student.value.first_name,
    last_name: student.value.last_name,
    email: student.value.email,
    enrolled_year: student.value.enrolled_year
  }
}

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
      title: 'Error',
      description: 'Failed to update student info.',
      color: 'red'
    })
    return
  }

  if (res.data.value.success) {
    student.value = res.data.value.studentInfo
    toast.add({
      title: 'Success',
      description: 'Information updated successfully',
      color: 'green'
    })
  } else {
    toast.add({
      title: 'Error',
      description: res.data.value.err,
      color: 'red'
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
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
}

.profile-info {
  position: absolute;
  bottom: -80px;
  left: 40px;
  display: flex;
  align-items: flex-end;
  gap: 24px;
}

.profile-avatar {
  position: relative;
}

.avatar {
  border: 4px solid white;
}

.edit-avatar-btn {
  position: absolute;
  bottom: 10px;
  right: 10px;
}

.profile-details {
  color: var(--color-gray-900);
}

.student-id, .department {
  margin: 5px 0;
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
