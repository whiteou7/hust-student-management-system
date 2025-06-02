<template>
    <UModal title="Class Information">
        <template #body>
            <div class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <h3 class="text-sm font-medium text-white">Course Name</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ classInfo.course_name }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Class ID</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ classInfo.class_id }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Instructor</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ classInfo.first_name }} {{ classInfo.last_name }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Schedule</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ classInfo.day_of_week }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Location</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ classInfo.location }}</p>
                    </div>
                    <div>
                        <h3 class="text-sm font-medium text-white">Credits</h3>
                        <p class="mt-1 text-sm text-gray-400">{{ classInfo.credit }}</p>
                    </div>
                </div>
                
                <div>
                    <h3 class="text-sm font-medium text-white">Enrollment</h3>
                    <p class="mt-1 text-sm text-gray-400">{{ classInfo.enrolled_count }} / {{ classInfo.capacity }} students</p>
                </div>

                <div>
                    <h3 class="text-sm font-medium text-white">Status</h3>
                    <p class="mt-1 text-sm text-gray-400">{{ classInfo.status }}</p>
                </div>

                <div>
                    <h3 class="text-sm font-medium text-white">Description</h3>
                    <p class="mt-1 text-sm text-gray-400">{{ classInfo.course_description }}</p>
                </div>
            </div>
        </template>
    </UModal>
</template>

<script setup>
const props = defineProps({
    classInfo: {
        type: Object,
        required: true,
        default: () => ({
            class_id: "",
            course_id: "",
            course_name: "",
            course_description: "",
            location: "",
            capacity: 0,
            enrolled_count: 0,
            status: "",
            day_of_week: "",
            credit: 0,
            first_name: "",
            last_name: ""
        })
    }
})
</script>