<template>
  <div class="p-4 space-y-6">
    <UCard>
      <template #header>
        <h2 class="text-2xl font-bold">All Students</h2>
      </template>
      <UTable
        :data="students"
        :columns="studentColumns"
        sticky
        class="flex-1 max-h-[312px]"
      />
    </UCard>

    <UCard>
      <template #header>
        <h2 class="text-2xl font-bold">Edit/Add Student</h2>
      </template>
      <UForm :state="editStudentForm" @submit="handleEditStudent">
        <div class="max-w-md mx-auto flex flex-col space-y-4">
          <UFormField class="block w-full mb-2" label="First Name" required>
            <UInput v-model="editStudentForm.firstName" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Last Name" required>
            <UInput v-model="editStudentForm.lastName" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Program ID" required>
            <UInput v-model="editStudentForm.programId" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Enrolled Year" required>
            <UInput v-model="editStudentForm.enrolledYear" class="w-full" required />
          </UFormField>
          <div class="flex justify-end space-x-2">
            <UButton color="gray" @click="cancelEditStudent">Cancel</UButton>
            <UButton v-if="editStudentForm.studentId" type="button" color="error" @click="handleDeleteStudent">Delete</UButton>
            <UButton type="submit" color="primary">Save Changes</UButton>
          </div>
        </div>
      </UForm>
    </UCard>

    <UCard>
      <template #header>
        <h2 class="text-2xl font-bold">All Teachers</h2>
      </template>
      <UTable
        :data="teachers"
        :columns="teacherColumns"
        sticky
        class="flex-1 max-h-[312px]"
      />
    </UCard>

    <UCard>
      <template #header>
        <h2 class="text-2xl font-bold">Edit/Add Teacher</h2>
      </template>
      <UForm :state="editTeacherForm" @submit="handleEditTeacher">
        <div class="max-w-md mx-auto flex flex-col space-y-4">
          <UFormField class="block w-full mb-2" label="First Name" required>
            <UInput v-model="editTeacherForm.firstName" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Last Name" required>
            <UInput v-model="editTeacherForm.lastName" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Email" required>
            <UInput v-model="editTeacherForm.email" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Password" required>
            <UInput v-model="editTeacherForm.password" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="School ID" required>
            <UInput v-model="editTeacherForm.schoolId" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Hired Year" required>
            <UInput v-model="editTeacherForm.hiredYear" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Qualification" required>
            <UInput v-model="editTeacherForm.qualification" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Profession" required>
            <UInput v-model="editTeacherForm.profession" class="w-full" required />
          </UFormField>
          <UFormField class="block w-full mb-2" label="Position" required>
            <UInput v-model="editTeacherForm.position" class="w-full" required />
          </UFormField>
          <div class="flex justify-end space-x-2">
            <UButton color="gray" @click="cancelEditTeacher">Cancel</UButton>
            <UButton v-if="editTeacherForm.teacherId" type="button" color="error" @click="handleDeleteTeacher">Delete</UButton>
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
const selectedStudent = ref({})
const selectedTeacher = ref({})
const toast = useToast()

const studentColumns = [
  { accessorKey: "student_id", header: "Student ID" },
  { accessorKey: "first_name", header: "First Name" },
  { accessorKey: "last_name", header: "Last Name" },
  { accessorKey: "email", header: "Email" },
  { accessorKey: "date_of_birth", header: "Date of Birth" },
  { accessorKey: "address", header: "Address" },
  { accessorKey: "enrolled_year", header: "Enrolled Year" },
  { accessorKey: "graduated", header: "Graduated" },
  { accessorKey: "debt", header: "Debt" },
  { accessorKey: "program_id", header: "Program ID" },
  {
    id: "selectStudent",
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
              selectedStudent.value = row.original
            }
          })
      )
    }
  }
]

const teacherColumns = [
  { accessorKey: "teacher_id", header: "Teacher ID" },
  { accessorKey: "first_name", header: "First Name" },
  { accessorKey: "last_name", header: "Last Name" },
  { accessorKey: "email", header: "Email" },
  { accessorKey: "school_id", header: "School ID" },
  { accessorKey: "hired_year", header: "Hired Year" },
  { accessorKey: "qualification", header: "Qualification" },
  { accessorKey: "profession", header: "Profession" },
  { accessorKey: "position", header: "Position" },
  {
    id: "selectTeacher",
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
              selectedTeacher.value = row.original
            }
          })
      )
    }
  }
]

const students = ref([])
const teachers = ref([])
const editStudentForm = ref({})
const editTeacherForm = ref({})

// Watch selectedStudent to update form
watch(selectedStudent, (newValue) => {
  if (newValue && newValue.student_id) {
    editStudentForm.value = {
      studentId: newValue.student_id,
      firstName: newValue.first_name,
      lastName: newValue.last_name,
      programId: newValue.program_id,
      enrolledYear: newValue.enrolled_year
    }
  } else {
    editStudentForm.value = {}
  }
})

// Watch selectedTeacher to update form
watch(selectedTeacher, (newValue) => {
  if (newValue && newValue.teacher_id) {
    editTeacherForm.value = {
      teacherId: newValue.teacher_id,
      firstName: newValue.first_name,
      lastName: newValue.last_name,
      email: newValue.email,
      password: newValue.password || "",
      schoolId: newValue.school_id,
      hiredYear: newValue.hired_year,
      qualification: newValue.qualification,
      profession: newValue.profession,
      position: newValue.position
    }
  } else {
    editTeacherForm.value = {}
  }
})

async function fetchStudents() {
  try {
    const { data: studentsData } = await useFetch("/api/students")
    if (studentsData.value?.success) {
      students.value = studentsData.value.students || []
    }
  } catch (error) {
    console.error("Error fetching students:", error)
  }
}

async function fetchTeachers() {
  try {
    const { data: teachersData } = await useFetch("/api/teachers")
    if (teachersData.value?.success) {
      teachers.value = teachersData.value.teachers || []
    }
  } catch (error) {
    console.error("Error fetching teachers:", error)
  }
}

onMounted(async () => {
  await Promise.all([
    fetchStudents(),
    fetchTeachers()
  ])
})

function cancelEditStudent() {
  selectedStudent.value = {}
  editStudentForm.value = {}
}

function cancelEditTeacher() {
  selectedTeacher.value = {}
  editTeacherForm.value = {}
}

async function handleEditStudent() {
  try {
    const isEdit = !!selectedStudent.value && !!selectedStudent.value.student_id
    const response = await useFetch("/api/students", {
      method: isEdit ? "PUT" : "POST",
      body: editStudentForm.value
    })
    if (response.data.value?.success) {
      await fetchStudents()
      toast.add({
        title: "Success",
        description: isEdit ? "Student updated successfully" : "Student added successfully",
        color: "success"
      })
      cancelEditStudent()
    } else {
      toast.add({
        title: "Error",
        description: response.data.value?.err || (isEdit ? "Failed to update student" : "Failed to add student"),
        color: "error"
      })
      console.error(isEdit ? "Failed to update student:" : "Failed to add student:", response.data.value?.err)
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: isEdit ? "Error updating student" : "Error adding student",
      color: "error"
    })
    console.error(isEdit ? "Error updating student:" : "Error adding student:", error)
  }
}

async function handleEditTeacher() {
  try {
    const isEdit = !!selectedTeacher.value && !!selectedTeacher.value.teacher_id
    const response = await useFetch("/api/teachers", {
      method: isEdit ? "PUT" : "POST",
      body: editTeacherForm.value
    })
    if (response.data.value?.success) {
      await fetchTeachers()
      toast.add({
        title: "Success",
        description: isEdit ? "Teacher updated successfully" : "Teacher added successfully",
        color: "success"
      })
      cancelEditTeacher()
    } else {
      toast.add({
        title: "Error",
        description: response.data.value?.err || (isEdit ? "Failed to update teacher" : "Failed to add teacher"),
        color: "error"
      })
      console.error(isEdit ? "Failed to update teacher:" : "Failed to add teacher:", response.data.value?.err)
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: isEdit ? "Error updating teacher" : "Error adding teacher",
      color: "error"
    })
    console.error(isEdit ? "Error updating teacher:" : "Error adding teacher:", error)
  }
}

async function handleDeleteStudent() {
  try {
    const response = await useFetch(`/api/students?studentId=${editStudentForm.value.studentId}`, {
      method: "DELETE"
    })
    if (response.data.value?.success) {
      await fetchStudents()
      toast.add({
        title: "Success",
        description: "Student deleted successfully",
        color: "success"
      })
      cancelEditStudent()
    } else {
      toast.add({
        title: "Error",
        description: response.data.value?.err || "Failed to delete student",
        color: "error"
      })
      console.error("Failed to delete student:", response.data.value?.err)
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: "Error deleting student",
      color: "error"
    })
    console.error("Error deleting student:", error)
  }
}

async function handleDeleteTeacher() {
  try {
    const response = await useFetch(`/api/teachers?teacherId=${editTeacherForm.value.teacherId}`, {
      method: "DELETE"
    })
    if (response.data.value?.success) {
      await fetchTeachers()
      toast.add({
        title: "Success",
        description: "Teacher deleted successfully",
        color: "success"
      })
      cancelEditTeacher()
    } else {
      toast.add({
        title: "Error",
        description: response.data.value?.err || "Failed to delete teacher",
        color: "error"
      })
      console.error("Failed to delete teacher:", response.data.value?.err)
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: "Error deleting teacher",
      color: "error"
    })
    console.error("Error deleting teacher:", error)
  }
}
</script>