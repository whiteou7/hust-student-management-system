<template>
  <div class="p-8">
    <div class="flex flex-col md:flex-row gap-8">
      <div class="flex-1">
        <UCard>
          <template #header>
            <h1 class="text-2xl font-bold mb-4">
              Class Details: {{ classId }} - {{ classInfo.course_id }} {{ classInfo.course_name }}
            </h1>
          </template>
          <div class="flex items-center mb-4 gap-2">
            <label class="font-medium">Sort by:</label>
            <USelect
              v-model="sortKey"
              :items="[{label: 'Student ID', value: 'student_id'}, {label: 'Result', value: 'result'}]"
              class="w-40"
            />
          </div>
          <UTable
            sticky
            :columns="columns"
            :data="sortedStudents"
            class="w-full"
          />
        </UCard>
      </div>
      <div v-if="Object.keys(selectedStudent).length > 0" class="flex-1">
        <UCard>
          <template #header>
            <h1 class="text-2xl font-bold mb-4">
              Student Grading
            </h1>
          </template>
          <div v-if="selectedStudent">
            <div class="mb-4">
              <div class="font-semibold">Student: {{ selectedStudent.full_name }} ({{ selectedStudent.student_id }})</div>
            </div>
            <UForm :state="gradeForm" @submit="onSubmitGrade">
              <div class="mb-4">
                <label class="block mb-1 font-medium">Mid Term</label>
                <UInput
                  v-model="gradeForm.midTerm"
                  type="number"
                  min="0"
                  max="10"
                  step="0.25"
                  class="w-full"
                />
              </div>
              <div class="mb-4">
                <label class="block mb-1 font-medium">Final Term</label>
                <UInput
                  v-model="gradeForm.finalTerm"
                  type="number"
                  min="0"
                  max="10"
                  step="0.25"
                  class="w-full"
                />
              </div>
              <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">Update Grade</button>
            </UForm>
          </div>
        </UCard>
      </div>
    </div>
  </div>
</template>

<script setup>
import { h, ref, onMounted, watch, computed } from "vue"
import { useRoute } from "vue-router"

const UButton = resolveComponent("UButton")
const route = useRoute()
const selectedStudent = ref({})
const toast = useToast()
const classId = route.params.id
const classInfo = ref({})
const students = ref([])
const gradeForm = ref({ midTerm: "", finalTerm: "" })
const sortKey = ref('student_id')

// Function to update grade and return api response
const updateGrade = async (studentId, midTerm, finalTerm) => {
  const { data: responseData } = await useFetch("/api/class-students", {
    method: "PUT",
    body: {
      studentId,
      midTerm,
      finalTerm
    }
  })

  return responseData.value
}

// Table column config
const columns = [
  { accessorKey: "student_id", header: "Student ID" },
  { accessorKey: "full_name", header: "Full Name" },
  { accessorKey: "mid_term", header: "Mid Term" },
  { accessorKey: "final_term", header: "Final Term" },
  { accessorKey: "result", header: "Result" },
  { id: "grade",
    cell: ({ row }) => {
      return h(UButton, {
        icon: "i-lucide-book-open-text",
        color: "neutral",
        variant: "ghost",
        onClick: () => {
          selectedStudent.value = row.original
        }
      })
    }
  }
]

const sortedStudents = computed(() => {
  const arr = [...students.value]
  arr.sort((a, b) => {
    let aVal = a[sortKey.value]
    let bVal = b[sortKey.value]
    // For result, handle 'Ungraded' as lowest
    if (sortKey.value === 'result') {
      aVal = aVal === 'Ungraded' ? -Infinity : Number(aVal)
      bVal = bVal === 'Ungraded' ? -Infinity : Number(bVal)
    }
    if (aVal < bVal) return -1
    if (aVal > bVal) return 1
    return 0
  })
  return arr
})

onMounted(async () => {
  // Fetch basic class info
  const { data: classData } = await useFetch("/api/class-info", {
    method: "POST",
    body: { classId }
  })

  if (!classData.value || !classData.value.success) {
    toast.add({
        title: "Error",
        description: classData.value.err,
        color: "error"
    })
    return
  }

  classInfo.value = classData.value.classInfo

  // Fetch student list
  const { data: studentData } = await useFetch("/api/class-students", {
    method: "POST",
    body: { classId }
  })
  if (!studentData.value || !studentData.value.success) {
    toast.add({
        title: "Error",
        description: studentData.value.err,
        color: "error"
    })
    return
  }

  students.value = studentData.value.students

  // Handle null value
  students.value = students.value.map(item => {
    return {
      ...item,
      mid_term: item.mid_term === null ? "Ungraded" : item.mid_term,
      final_term: item.final_term === null ? "Ungraded" : item.final_term,
      result: item.result === null ? "Ungraded" : item.result
    }
  })
})

// Update form object
watch(selectedStudent, (val) => {
  if (val && val.mid_term !== undefined && val.final_term !== undefined) {
    gradeForm.value.midTerm = val.mid_term === "Ungraded" ? "" : val.mid_term
    gradeForm.value.finalTerm = val.final_term === "Ungraded" ? "" : val.final_term
  }
})

// On grade submit
const onSubmitGrade = async () => {
  const { success, err } = await updateGrade(selectedStudent.value.student_id, gradeForm.value.midTerm, gradeForm.value.finalTerm)
  if (!success) {
    toast.add({
      title: "Error",
      description: err,
      color: "error"
    })
  } else {
    toast.add({
      title: "Success",
      description: "Grades updated successfully",
      color: "success"
    })
  }

  // Refresh students list after updating grade
  const { data: studentData } = await useFetch("/api/class-students", {
    method: "POST",
    body: { classId }
  })
  if (studentData.value && studentData.value.success) {
    students.value = studentData.value.students.map(item => {
      return {
        ...item,
        mid_term: item.mid_term === null ? "Ungraded" : item.mid_term,
        final_term: item.final_term === null ? "Ungraded" : item.final_term,
        result: item.result === null ? "Ungraded" : item.result
      }
    })
  }
}
</script>
