import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.courseId || !body.courseName || !body.schoolId || !body.credit || !body.tuitionPerCredit || !body.courseDescription) {
    return {
      success: false,
      err: "Missing required fields"
    }
  }

  try {
    await db.execute(
      sql.raw(`
        INSERT INTO courses (
          course_id, course_name, school_id, credit, tuition_per_credit, course_description
        ) VALUES (
          '${body.courseId}',
          '${body.courseName}',
          ${body.schoolId},
          ${body.credit},
          ${body.tuitionPerCredit},
          '${body.courseDescription}'
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
