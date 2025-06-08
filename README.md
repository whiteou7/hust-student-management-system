# HUST Student Management System

Final term project for IT3290 Database Lab (HUST)

## Prerequisites

- Node.js 
- PostgreSQL database

### Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/your-username/hust-student-management-system.git
   cd hust-student-management-system
   ```

2. **Install dependencies:**

   ```bash
   cd src
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

   ```bash
   psql -U user -f db.sql
   ```

5. **Run the development server:**

   ```bash
   npm run dev
   ```

   The app will be available at [http://localhost:3000](http://localhost:3000).


