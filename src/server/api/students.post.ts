import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  try {
    // Insert into users first
    const userRes = await db.execute(sql.raw(`
      INSERT INTO users (first_name, last_name, role)
      VALUES ('${body.firstName}', '${body.lastName}', 'student')
      RETURNING user_id
    `))
    const userId = userRes[0]?.user_id
    // Insert into students
    await db.execute(sql.raw(`
      INSERT INTO students (student_id, program_id, enrolled_year, graduated, debt)
      VALUES (${userId}, ${body.programId}, ${body.enrolledYear}, 'enrolled', 0)
    `))
    return { success: true, studentId: userId }
  } catch (err) {
    return { success: false, err: err }
  }
})
