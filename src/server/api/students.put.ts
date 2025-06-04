import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body.studentId) return { success: false, err: "studentId is required" }
  try {
    await db.execute(sql.raw(`
      UPDATE users SET first_name='${body.firstName}', last_name='${body.lastName}' WHERE user_id=${body.studentId}
    `))
    await db.execute(sql.raw(`
      UPDATE students SET program_id=${body.programId}, enrolled_year=${body.enrolledYear} WHERE student_id=${body.studentId}
    `))
    return { success: true }
  } catch (err) {
    return { success: false, err: err }
  }
})
