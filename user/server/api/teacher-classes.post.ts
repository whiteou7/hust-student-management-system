import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"
export default defineEventHandler (async (event) => {
  const body = await readBody(event)

  if (body.userId == 0) {
    return {
      success: false,
      err: "Invalid userId. Try signing in again.",
      classes: null
    }
  }

  const classArr = await db.execute(
    sql.raw(`
      SELECT 
        c.class_id,
        co.course_name,
        c.day_of_week,
        c.location,
        CONCAT(c.enrolled_count::text, '/', c.capacity::text) as enrolled_count
      FROM 
        classes c
      JOIN 
        courses co ON c.course_id = co.course_id
      WHERE 
        c.teacher_id = ${body.userId}  
        AND c.semester = '${body.semester}';  
    `)
  )

  return {
    success: true,
    err: null,
    classes: classArr
  }
})