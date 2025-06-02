import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.classId) {
    return {
      success: false,
      err: "Class ID is required",
      classInfo: null
    }
  }

  try {
    const classInfo = await db.execute(
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
          u.first_name,
          u.last_name
        FROM 
          classes c
        JOIN 
          courses co ON c.course_id = co.course_id
        JOIN 
          teachers t ON c.teacher_id = t.teacher_id
        JOIN 
          users u ON t.teacher_id = u.user_id
        WHERE 
          c.class_id = ${body.classId};
      `)
    )

    if (!classInfo.length) {
      return {
        success: false,
        err: "Class not found",
        classInfo: null
      }
    }

    return {
      success: true,
      err: null,
      classInfo: classInfo[0]
    }
  } catch (error) {
    console.error("Error fetching class info:", error)
    return {
      success: false,
      err: "Internal server error",
      classInfo: null
    }
  }
}) 