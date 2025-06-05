import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.classId || !body.studentId) {
    return {
      success: false,
      err: "Missing required fields"
    }
  }

  try {
    await db.execute(
      sql.raw(`
        DELETE FROM enrollments WHERE class_id = ${body.classId} AND student_id = ${body.studentId};
      `)
    )

    return {
      success: true,
      err: null
    }
  } catch (error) {
    console.error(error)
    return {
      success: false,
      err: "Internal server error"
    }
  }
})
