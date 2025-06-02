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
          courses
        SET
          course_id = '${body.courseId}',
          course_name = '${body.courseName}',
          course_description = '${body.courseDescription}',
          tuition_per_credit = ${body.tuitionPerCredit},
          credit = ${body.credit},
          school_id = ${body.schoolId}
        WHERE 
          course_id = '${body.courseId}';
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