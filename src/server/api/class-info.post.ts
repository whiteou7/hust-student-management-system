import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.teacherId || !body.courseId || !body.capacity || !body.semester || !body.status || !body.dayOfWeek || !body.location) {
    return {
      success: false,
      err: "Missing required fields"
    }
  }

  try {
    await db.execute(
      sql.raw(`
        INSERT INTO classes (
          teacher_id, course_id, capacity, semester, status, day_of_week, location
        ) VALUES (
          ${body.teacherId},
          '${body.courseId}',
          ${body.capacity},
          '${body.semester}',
          '${body.status}',
          '${body.dayOfWeek}',
          '${body.location}'
        );
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
