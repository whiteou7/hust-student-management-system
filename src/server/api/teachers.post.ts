import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  try {
    // Insert into users first
    const userRes = await db.execute(sql.raw(`
      INSERT INTO users (first_name, last_name, email, password, role)
      VALUES ('${body.firstName}', '${body.lastName}', '${body.email}', '${body.password}', 'teacher')
      RETURNING user_id
    `))
    const userId = userRes[0]?.user_id
    // Insert into teachers
    await db.execute(sql.raw(`
      INSERT INTO teachers (teacher_id, school_id, hired_year, qualification, profession, position)
      VALUES (${userId}, ${body.schoolId}, ${body.hiredYear}, '${body.qualification}', '${body.profession}', '${body.position}')
    `))
    return { success: true, teacherId: userId }
  } catch (err) {
    return { success: false, err: err }
  }
})
