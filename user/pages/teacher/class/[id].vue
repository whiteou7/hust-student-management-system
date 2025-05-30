<template>
  <div class="p-8">
    <UCard>
      <template #header>
        <h1 class="text-2xl font-bold mb-4">
          Class Details: {{ classId }} - {{ classInfo.course_id }} {{ classInfo.course_name }}
        </h1>
      </template>
      <UTable
        sticky
        :columns="columns"
        :data="students"
        class="w-full"
      />
    </UCard>
  </div>
</template>

<script setup>
import { h, ref, onMounted } from "vue"
import { useRoute } from "vue-router"

const UInput = resolveComponent("UInput")
const route = useRoute()
const toast = useToast()
const classId = route.params.id
const classInfo = ref({})
const students = ref([])
const updateGrade = async (studentId, midTerm, finalTerm) => {
  await useFetch("/api/class-students", {
    method: "PUT",
    body: {
      studentId,
      midTerm,
      finalTerm
    }
  })
}

const columns = [
  { accessorKey: "student_id", header: "Student ID" },
  { accessorKey: "full_name", header: "Full Name" },
  { accessorKey: "mid_term", header: "Mid Term" },
  { accessorKey: "final_term", header: "Final Term" },
  { accessorKey: "result", header: "Result" }
]

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
</script>
