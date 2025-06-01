<script setup lang="js">
import { useRouter } from "vue-router"
import { onMounted } from "vue"

const router = useRouter()

onMounted(() => {
  const role = localStorage.getItem("role")
  switch (role) {
    case "student":
      router.push("/student/dashboard")
      break
    case "teacher":
      router.push("/teacher/dashboard")
      break
    default:
      router.push("/login")
      break
  }
})
</script>
