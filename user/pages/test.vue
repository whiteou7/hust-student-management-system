<script setup lang="js">
import ClassInfoModal from '~/components/ClassInfoModal.vue'

const overlay = useOverlay()

const modal = overlay.create(ClassInfoModal)

const classData = ref({
    name: 'Introduction to Computer Science',
    code: 'CS101',
    instructor: 'Dr. Smith',
    schedule: 'Mon/Wed 10:00 AM - 11:30 AM',
    description: 'An introductory course covering fundamental concepts of computer science...',
    enrolledStudents: 45
})

const openModalA = () => {
  modal.open({classInfo: classData})
}

</script>

<template>
  <div>
    <UButton @click="openModalA">Open Modal</UButton>
  </div>
  <div>
    <UModal title="Modal with title">
    <UButton label="Open" color="neutral" variant="subtle" />

    <template #body>
      <Placeholder class="h-48" />
    </template>
  </UModal>
  </div>
</template>
