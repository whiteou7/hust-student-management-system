# HUST Student Management System

A full-stack student management system for Hanoi University of Science and Technology (HUST), built with Nuxt 3, Vue, and PostgreSQL.

## Features

- **Student Management:** Add, update, delete, and view student information.
- **Teacher Management:** Manage teacher records and assignments.
- **Course & Class Management:** Create, edit, and remove courses and classes.
- **Enrollment:** Register students for classes, manage enrollments, and track grades.
- **Authentication:** Admin and user login.
- **Program Requirements:** Track required courses for student programs.
- **Semester Management:** Configure current and next semesters.
- **API:** RESTful endpoints for all major resources.

## Tech Stack

- **Frontend:** Nuxt 3 (Vue 3), Tailwind CSS, UI components
- **Backend:** Nuxt 3 server API routes
- **Database:** PostgreSQL (via drizzle-orm)
- **ORM:** drizzle-orm
- **Other:** TypeScript, Node.js

## Getting Started

### Prerequisites

- Node.js (v18+ recommended)
- PostgreSQL database
- [pnpm](https://pnpm.io/) or npm/yarn

### Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/your-username/hust-student-management-system.git
   cd hust-student-management-system
   ```

2. **Install dependencies:**

   ```bash
   pnpm install
   # or
   npm install
   ```

3. **Configure environment variables:**

   Create a `.env` file in the root directory with the following:

   ```
   DATABASE_URL=postgres://user:password@localhost:5432/your_db
   ADMIN_USER=admin@example.com
   ADMIN_PASS=your_admin_password
   ```

4. **Set up the database:**

   - Ensure your PostgreSQL server is running.
   - Create the necessary tables and views as expected by the queries in `src/server/api/`.
   - (Optional) Use drizzle-kit or your preferred migration tool.

5. **Run the development server:**

   ```bash
   pnpm dev
   # or
   npm run dev
   ```

   The app will be available at [http://localhost:3000](http://localhost:3000).

## Project Structure

