import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const query = await getQuery(event)

  if (!query.courseId) {
    return {
      success: false,
      err: "Course ID is required",
      courseInfo: null
    }
  }

  try {
    const courseInfo = await db.execute(
      sql.raw(`
        SELECT 
          co.course_id,
          co.course_name,
          co.course_description,
          co.credit,
          s.school_name,
          co.tuition_per_credit
        FROM 
          courses co
        JOIN 
          schools s on s.school_id = co.school_id
        WHERE 
          co.course_id = '${query.courseId}';
      `)
    )

    if (!courseInfo.length) {
      return {
        success: false,
        err: "Course not found",
        courseInfo: null
      }
    }
    return {
      success: true,
      err: null,
      courseInfo: courseInfo[0]
    }
  } catch (error) {
    console.error("Error fetching course info:", error)
    return {
      success: false,
      err: "Internal server error",
      courseInfo: null
    }
  }
}) 