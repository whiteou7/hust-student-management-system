import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async () => {
  const teachers = await db.execute(
    sql.raw(`
      SELECT t.teacher_id, u.first_name, u.last_name, u.email, u.password, u.date_of_birth, u.address, t.school_id, t.hired_year, t.qualification, t.profession, t.position
      FROM teachers t
      JOIN users u ON u.user_id = t.teacher_id
      WHERE u.role = 'teacher';
    `)
  )
  return { success: true, teachers }
})
