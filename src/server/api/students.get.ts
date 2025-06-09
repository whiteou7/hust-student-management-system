import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async () => {
  const students = await db.execute(
    sql.raw(`
      SELECT s.student_id, u.first_name, u.last_name, u.email, u.date_of_birth, u.address, s.enrolled_year, s.graduated, s.debt, s.program_id
      FROM students s
      JOIN users u ON u.user_id = s.student_id
      WHERE u.role = 'student'
      ORDER BY s.student_id;
    `)
  )
  return { success: true, students }
})
