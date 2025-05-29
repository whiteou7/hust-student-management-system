<template>
    <UModal title="Teacher Information">
        <template #body>
            <div class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <h3 class="text-sm font-medium text-white">Teacher ID</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ teacherInfo.teacher_id }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Full Name</h3>
                        <p class="mt-1 text-sm text-gray-400">
                            {{ teacherInfo.full_name }}<span v-if="teacherInfo.qualification">, {{ teacherInfo.qualification }}</span>
                        </p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Email</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ teacherInfo.email }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">School Name</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ teacherInfo.school_name }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Hired Year</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ teacherInfo.hired_year }}</p>
                    </div>
                </div>
            </div>
        </template>
    </UModal>
</template>

<script setup>
const props = defineProps({
    teacherInfo: {
        type: Object,
        required: true,
        default: () => ({
            teacher_id: "",
            full_name: "",
            email: "",
            school_name: "",
            hired_year: "",
            qualification: ""
        })
    }
})
</script>