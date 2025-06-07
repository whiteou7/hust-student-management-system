import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"
export default defineEventHandler (async (event) => {
  const query = await getQuery(event)

  if (query.studentId == null) {
    return {
      success: false,
      err: "Invalid studentId. Try signing in again.",
      courses: null
    }
  }

  const courses = await db.execute(
    sql.raw(`
      SELECT 
        pr.course_id
      FROM 
        program_requirements pr
      JOIN 
        students_view s on s.program_id = pr.program_id
      WHERE 
        s.student_id = ${query.studentId}    
    `)
  )

  return {
    success: true,
    err: null,
    courses
  }
})