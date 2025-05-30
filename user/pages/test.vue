<template>
  <div class="p-4">
    <h1 class="text-2xl font-bold mb-4">Available Courses</h1>
    
    <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
      <UCard
        v-for="course in courses"
        :key="course.id"
        class="hover:shadow-lg transition"
      >
        <template #header>
          <div class="text-lg font-semibold">{{ course.title }}</div>
        </template>

        <p class="text-sm text-gray-600">
          {{ course.description }}
        </p>

        <template #footer>
          <UButton :to="`/courses/${course.id}`" variant="outline">View</UButton>
        </template>
      </UCard>
    </div>
  </div>
</template>

<script setup>
const courses = reactive([
  { id: 1, title: "Intro to C", description: "Learn the basics of C programming." },
  { id: 2, title: "Web Dev with Vue", description: "Vue 3 and composition API crash course." },
  { id: 3, title: "Embedded Systems", description: "Intro to microcontrollers and hardware." },
  { id: 4, title: "Cybersecurity 101", description: "Foundations of ethical hacking and defense." },
  // Add more...
])
</script>
