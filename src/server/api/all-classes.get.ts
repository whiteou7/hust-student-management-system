import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async () => {
  try {
    const classes = await db.execute(
      sql.raw(`
        SELECT 
          c.class_id,
          c.course_id,
          c.location,
          c.capacity,
          c.enrolled_count,
          co.course_description,
          c.status,
          c.day_of_week,
          co.course_name,
          co.credit,
          CONCAT(u.first_name, ' ', u.last_name) as full_name,
          u.user_id,
          c.semester
        FROM 
          classes c
        JOIN 
          courses co ON c.course_id = co.course_id
        JOIN 
          teachers t ON c.teacher_id = t.teacher_id
        JOIN 
          users u ON t.teacher_id = u.user_id
      `)
    )

    if (!classes.length) {
      return {
        success: false,
        err: "Class not found",
        classes: null
      }
    }

    return {
      success: true,
      err: null,
      classes: classes
    }
  } catch (error) {
    console.error("Error fetching class info:", error)
    return {
      success: false,
      err: "Internal server error",
      classes: null
    }
  }
}) 