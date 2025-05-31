import TeacherInfoModal from "~/components/TeacherInfoModal.vue"

interface UseTeacherInfoModalOptions {
  searchQuery: string
  overlay: any
  toast: any
}

export async function useTeacherInfoModal({ searchQuery, overlay, toast }: UseTeacherInfoModalOptions) {
  const { data: teacherData } = await useFetch("/api/teacher-info", {
    method: "POST",
    body: {
      teacherId: searchQuery
    }
  })

  const modal = overlay.create(TeacherInfoModal)

  if (!teacherData.value) return
  if (!teacherData.value.success || !teacherData.value.teacherInfo) {
    toast.add({
      title: "Error",
      description: teacherData.value.err ?? "",
      color: "error"
    })
    return
  }

  modal.open({
    teacherInfo: {
      teacher_id: searchQuery,
      full_name: teacherData.value.teacherInfo.full_name,
      email: teacherData.value.teacherInfo.email,
      school_name: teacherData.value.teacherInfo.school_name,
      hired_year: teacherData.value.teacherInfo.hired_year,
      qualification: teacherData.value.teacherInfo.qualification,
      profession: teacherData.value.teacherInfo.profession,
      position: teacherData.value.teacherInfo.position
    }
  })
}
