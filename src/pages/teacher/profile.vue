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
          <div class="text-white font-bold">{{ teacher.full_name }}</div>
          <div class="teacher-id">Teacher ID: {{ teacher.teacher_id }} - {{ teacher.school_name }}</div>
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
            <div>{{ teacher.full_name }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">Email</label>
            <div>{{ teacher.email }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">Date of Birth</label>
            <div>{{ teacher.date_of_birth }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">Address</label>
            <div>{{ teacher.address }}</div>
          </div>
        </div>
      </UCard>

      <!-- Professional Information -->
      <UCard>
        <template #header>
          <div class="flex items-center gap-2">
            <UIcon name="i-heroicons-briefcase" />
            <h2>Professional Information</h2>
          </div>
        </template>
        <div class="info-grid">
          <div class="form-group">
            <label class="text-sm text-gray-500">Qualification</label>
            <div>{{ teacher.qualification }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">Position</label>
            <div>{{ teacher.position }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">Profession</label>
            <div>{{ teacher.profession }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">Hired Year</label>
            <div>{{ teacher.hired_year }}</div>
          </div>
          <div class="form-group">
            <label class="text-sm text-gray-500">School Name</label>
            <div>{{ teacher.school_name }}</div>
          </div>
        </div>
      </UCard>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue"

const teacherId = localStorage.getItem("userId")
const teacher = ref({})
const toast = useToast()

// Fetch teacher info
const { data: teacherData } = await useFetch("/api/teacher-info", {
  method: "GET",
  query: {
    teacherId: parseInt(teacherId ?? "0")
  }
})

if (!teacherData.value) {
  toast.add({
    title: "Error",
    description: "Failed to fetch teacher info.",
    color: "error"
  })
}

if (teacherData.value.success) {
  teacher.value = teacherData.value.teacherInfo
} else {
  toast.add({
    title: "Error",
    description: teacherData.value.err,
    color: "error"
  })
}

const editForm = ref({
  first_name: "",
  last_name: "",
  email: "",
  date_of_birth: "",
  address: ""
})

// Handle edit profile button
async function onEditProfile() {
  // Initialize form with current values
  editForm.value = {
    first_name: teacher.value.first_name,
    last_name: teacher.value.last_name,
    email: teacher.value.email,
    date_of_birth: teacher.value.date_of_birth,
    address: teacher.value.address
  }
}

// Edit teacher profile after submitting
async function submitEdit() {
  const { data: editData } = await useFetch("/api/teacher-info", {
    method: "PUT",
    body: {
      teacherId: parseInt(teacherId ?? "0"),
      ...editForm.value
    }
  })

  if (!editData.value) {
    toast.add({
      title: "Error",
      description: "Failed to update teacher info.",
      color: "error"
    })
    return
  }

  if (editData.value.success) {
    // Update teacher info locally (only editable fields)
    teacher.value.email = editForm.value.email
    teacher.value.date_of_birth = editForm.value.date_of_birth
    teacher.value.address = editForm.value.address
    // Update full_name
    teacher.value.full_name = `${editForm.value.first_name} ${editForm.value.last_name}`
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

.teacher-id {
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
