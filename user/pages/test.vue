<script setup lang = "ts">
import { ref, computed, onMounted } from "vue"

const data = ref([])
const currentSemester = ref(localStorage.getItem("currentSemester") || "")

onMounted(async () => {
  await fetchClasses()
})

async function fetchClasses() {
    const userId = localStorage.getItem("userId")
    const currentSemester = localStorage.getItem("currentSemester")

    const res = await useFetch("/api/student-classes", {
      method: "POST",
      body: {
        userId: parseInt(userId ?? "0"),
        semester: currentSemester
      }
    })

    if (res.data.value && res.data.value.success) {
      data.value = res.data.value.classes;
    }
}


</script>