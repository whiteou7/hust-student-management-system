import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.classId) {
    return {
      success: false,
      err: "class ID is required"
    }
  }

  try {
    await db.execute(
      sql.raw(`
        UPDATE
          classes
        SET
          class_id = ${body.classId},
          teacher_id = ${body.teacherId},
          course_id = '${body.courseId}',
          capacity = ${body.capacity},
          semester = '${body.semester}',
          enrolled_count = ${body.enrolledCount},
          status = '${body.status}',
          day_of_week = '${body.dayOfWeek}',
          location = '${body.location}'
        WHERE 
          class_id = ${body.classId};
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