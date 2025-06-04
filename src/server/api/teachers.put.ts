import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body.teacherId) return { success: false, err: "teacherId is required" }
  try {
    await db.execute(sql.raw(`
      UPDATE users SET first_name='${body.firstName}', last_name='${body.lastName}', email='${body.email}', password='${body.password}' WHERE user_id=${body.teacherId}
    `))
    await db.execute(sql.raw(`
      UPDATE teachers SET school_id=${body.schoolId}, hired_year=${body.hiredYear}, qualification='${body.qualification}', profession='${body.profession}', position='${body.position}' WHERE teacher_id=${body.teacherId}
    `))
    return { success: true }
  } catch (err) {
    return { success: false, err: err }
  }
})
