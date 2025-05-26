import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"
export default defineEventHandler (async (event) => {
  const body = await readBody(event)

  if (body.userId == 0) {
    return {
      success: false,
      err: "Invalid userId. Try signing in again.",
      courses: null
    }
  }

  const courses = await db.execute(
    sql.raw(`
      SELECT 
        co.course_id,
        co.course_name,
        co.course_description,
        c.semester,
        e.result,
        e.pass,
        co.credit
      FROM 
        enrollments e
      JOIN 
        classes c ON e.class_id = c.class_id
      JOIN 
        courses co ON c.course_id = co.course_id
      WHERE 
        e.student_id = ${body.studentId};  
    `)
  )

  return {
    success: true,
    err: null,
    courses: courses
  }
})