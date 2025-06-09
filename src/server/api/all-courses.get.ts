import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async () => {
  try {
    const courses = await db.execute(
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
        ORDER BY
          co.course_id;
      `)
    )

    return {
      success: true,
      err: null,
      courses: courses
    }
  } catch (error) {
    return {
      success: false,
      err: error,
      courses: null
    }
  }
}) 