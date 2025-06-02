<template>
    <UModal title="Student Information">
        <template #body>
            <div class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <h3 class="text-sm font-medium text-white">Student ID</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ studentInfo.student_id }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Full Name</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ studentInfo.full_name }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Email</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ studentInfo.email }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Date of Birth</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ studentInfo.date_of_birth }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Enrolled Year</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ studentInfo.enrolled_year }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Program</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ studentInfo.program }}</p>
                    </div>
                </div>
            </div>
        </template>
    </UModal>
</template>

<script setup>
const props = defineProps({
    studentInfo: {
        type: Object,
        required: true,
        default: () => ({
            student_id: "",
            full_name: "",
            email: "",
            date_of_birth: "",
            enrolled_year: "",
            program: ""
        })
    }
})
</script>