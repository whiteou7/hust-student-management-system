import StudentInfoModal from "~/components/StudentInfoModal.vue"

interface UseStudentInfoModalOptions {
  searchQuery: string
  overlay: any
  toast: any
}

export async function useStudentInfoModal({ searchQuery, overlay, toast }: UseStudentInfoModalOptions) {
  const { data: studentData } = await useFetch("/api/student-info", {
    method: "POST",
    body: {
      studentId: searchQuery,
      currentSemester: localStorage.getItem("currentSemester")
    }
  })

  const modal = overlay.create(StudentInfoModal)

  if (!studentData.value) return
  if (!studentData.value.success || !studentData.value.studentInfo) {
    toast.add({
      title: "Error",
      description: studentData.value.err ?? "",
      color: "error"
    })
    return
  }

  modal.open({ 
    studentInfo: {
      student_id: searchQuery,
      full_name: studentData.value.studentInfo.full_name,
      email: studentData.value.studentInfo.email,
      date_of_birth: studentData.value.studentInfo.date_of_birth,
      enrolled_year: studentData.value.studentInfo.enrolled_year,
      program: studentData.value.studentInfo.program_name
    }
  })
}
