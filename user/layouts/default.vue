<template>
  <div class="layout-container">
    <header v-if="!isAuthPage" class="header">
      <h1>Hust Student Management System</h1>
      <div class="header-buttons">
        <button class="btn profile-btn">View Profile</button>
        <button class="btn signout-btn" @click="handleSignOut">Sign Out</button>
      </div>
    </header>

    <main class="main-content" :class="{ 'no-header': isAuthPage }">
      <slot />
    </main>
  </div>
</template>


<script setup lang="ts">
import { useRouter, useRoute } from 'vue-router';

const router = useRouter();
const route = useRoute();

const isAuthPage = computed(() => {
  return ['/login', '/register'].includes(route.path);
});

const handleSignOut = () => {
  // Clear all data from localStorage
  localStorage.clear();
  
  // Redirect to login page
  router.push('/login');
};
</script>

<style scoped>
.header {
  background-color: transparent;
  color: rgb(255, 255, 255);
  padding: 1rem 2rem;
  box-shadow: none;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1000;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
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

.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  color: white;
}

.profile-btn {
  background-color: #2c3e50; /* Darker blue/grey */
}

.signout-btn {
  background-color: #e74c3c; /* Red */
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