<template>
    <UModal title="Class Information">
        <template #body>
            <div class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <h3 class="text-sm font-medium text-white">Course ID</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ courseInfo.course_id }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Course Name</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ courseInfo.course_name }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">School</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ courseInfo.school_name }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Tuition per credit</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ courseInfo.tuition_per_credit }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Credit</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ courseInfo.credit }}</p>
                    </div>
                </div>
                <div>
                    <h3 class="text-sm font-medium text-white">Description</h3>
                    <p class="mt-1 text-sm text-gray-400">{{ courseInfo.course_description }}</p>
                </div>
            </div>
        </template>
    </UModal>
</template>

<script setup>
const props = defineProps({
    courseInfo: {
        type: Object,
        required: true,
        default: () => ({
            course_id: "",
            course_name: "",
            course_description: "",
            credit: 0,
            school_name: "",
            tuition_per_credit: 0
        })
    }
})
</script>