import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.courseId) {
    return {
      success: false,
      err: "Course ID is required"
    }
  }

  try {
    await db.execute(
      sql.raw(`
        UPDATE
          courses co
        SET
          co.course_id = ${body.course_id},
          co.course_name = '${body.course_name}',
          co.course_description = '${body.course_description}',
          co.tuition_per_credit = ${body.tuition_per_credit},
          co.credit = ${body.credit},
          co.school_id = ${body.school_id}
        WHERE 
          co.course_id = '${body.courseId}';
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