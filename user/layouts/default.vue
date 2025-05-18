<template>
  <div class="layout-container">
    <header class="header">
      <h1>Hust Student Management System</h1>
    </header>
    
    <main class="main-content">
      <slot />
    </main>
  </div>
</template>

<script setup lang="ts">
// Component logic can be added here
</script>

<style scoped>
.layout-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  padding-top: 64px; /* Height of the header */
}

.header {
  background-color: rgb(102, 123, 153); /* primary-500 */
  color: white;
  padding: 1rem 2rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 1000;
  height: 64px;
  display: flex;
  align-items: center;
}

.header h1 {
  margin: 0;
  font-size: 1.5rem;
  font-weight: 600;
}

.main-content {
  flex: 1;
  padding: 2rem;
}
</style> 