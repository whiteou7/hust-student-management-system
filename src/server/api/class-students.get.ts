import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const query = await getQuery(event)

  if (!query.classId) {
    return {
      success: false,
      err: "Class ID is required",
      students: null
    }
  }

  try {
    const students = await db.execute(
      sql.raw(`
        SELECT 
          e.student_id,
          CONCAT(u.first_name, ' ', u.last_name) AS full_name,
          e.mid_term,
          e.final_term,
          e.result,
          e.pass
        FROM 
          classes c
        JOIN 
          enrollments e ON e.class_id = c.class_id
        JOIN
          students s ON e.student_id = s.student_id
        JOIN
          users u ON u.user_id = s.student_id
        WHERE 
          c.class_id = ${query.classId};
      `)
    )

    if (!students.length) {
      return {
        success: false,
        err: "Class not found",
        students: null
      }
    }

    return {
      success: true,
      err: null,
      students: students
    }
  } catch (error) {
    console.error("Error fetching class info:", error)
    return {
      success: false,
      err: "Internal server error",
      students: null
    }
  }
}) 