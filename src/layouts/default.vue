<template>
  <div class="layout-container">
    <header v-if="!isAuthPage && !isAdmin" class="header">
      <h1 class="clickable-header" @click="dashboardNavigate">Hust Student Management System</h1>
      
      <div class="flex items-center gap-4 ml-auto">
        <UInput
          v-model="searchQuery"
          placeholder="Search..."
          icon="i-heroicons-magnifying-glass-20-solid"
          size="md"
          @keydown.enter="openModal"
        />

        <UDropdownMenu
          :items="items"
          :content="{
            align: 'start',
            side: 'bottom',
            sideOffset: 8
          }"
          :ui="{
            content: 'w-48'
          }"
          size="xl"
        >
          <UButton label="Navigation" icon="i-lucide-menu" color="neutral" variant="outline" />
        </UDropdownMenu>
      </div>
    </header>

    <main class="main-content" :class="{ 'no-header': isAuthPage }">
      <slot />
    </main>
  </div>
</template>


<script setup lang="ts">
import { useRouter, useRoute } from "vue-router"
import type { DropdownMenuItem } from "@nuxt/ui"

const toast = useToast()
const router = useRouter()
const route = useRoute()
const overlay = useOverlay()
const UButton = resolveComponent("UButton")
const UDropdownMenu = resolveComponent("UDropdownMenu")
const isAdmin = ref(localStorage.getItem("role") === "admin")

const searchQuery = ref("")

const openModal = async () => {
  const query = searchQuery.value.trim()
  if (!query.includes(":")) {
    toast.add({ title: "Invalid search format", description: "Please use 'student:{id}' or 'teacher:{id}'." })
    return
  }
  const [type, id] = query.split(":")
  if (!id) {
    toast.add({ title: "Invalid search format", description: "ID is missing after ':'." })
    return
  }
  if (type === "student") {
    await useStudentInfoModal({
      searchQuery: id,
      overlay,
      toast
    })
  } else if (type === "teacher") {
    await useTeacherInfoModal({
      searchQuery: id,
      overlay,
      toast
    })
  } else {
    toast.add({ title: "Unknown type", description: "Please use 'student:{id}' or 'teacher:{id}'." })
  }
}

const items: DropdownMenuItem[][] = [
[
  {
    label: "Profile",
    icon: "i-lucide-user",
    onSelect() {
      viewProfile()
    }
  },
  {
    label: "Class Registration",
    icon: "i-lucide-book-open-text"
  },
  {
    label: "View All Courses",
    icon: "i-lucide-school",
    onSelect() {
      router.push("/courses")
    }
  }
], [
  {
    label: "Sign out",
    icon: "i-lucide-log-out",
    color: "error",
    onSelect() {
      signOut()
    }
  }
]]

const isAuthPage = computed(() => {
  return ["/login", "/register"].includes(route.path)
})

const dashboardNavigate = () => {
  const role = localStorage.getItem("role")
  if (role === "student") {
    router.push("/student/dashboard")
  } else router.push("/teacher/dashboard")
}

const viewProfile = () => {
  const role = localStorage.getItem("role")
  if (role === "student") {
    router.push("/student/profile")
  } else router.push("/teacher/profile")
}

const signOut = () => {
  // Clear all data from localStorage
  localStorage.clear()
  
  // Redirect to login page
  router.push("/login")
}
</script>

<style scoped>
.header {
  background-color: transparent;
  backdrop-filter: blur(10px); /* Apply blur effect */
  -webkit-backdrop-filter: blur(10px); /* Safari support */
  color: rgb(255, 255, 255); /* Better contrast with lighter bg */
  padding: 1rem 2rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1); /* Optional: soft shadow */
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1000;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  backdrop-filter: blur(10px);
}

.clickable-header {
  cursor: pointer;
  color: #ffffff;
  transition: color 0.2s;
}
.clickable-header:hover {
  color: #3cff7a;
}

.header h1 {
  margin: 0;
  font-size: 1.5rem;
  font-weight: 600;
}

.header-buttons {
  display: flex;
  gap: 1rem;
}

.main-content {
  flex: 1;
  padding: 2rem;
  padding-top: 64px;
}

.main-content.no-header {
  padding-top: 0;
}

</style>