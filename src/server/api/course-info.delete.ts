import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.courseId) {
    return {
      success: false,
      err: "course ID is required"
    }
  }

  try {
    await db.execute(
      sql.raw(`
        DELETE FROM courses WHERE course_id = '${body.courseId}';
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
