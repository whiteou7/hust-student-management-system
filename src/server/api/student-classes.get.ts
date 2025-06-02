import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"
export default defineEventHandler (async (event) => {
  const query = await getQuery(event)

  if (query.userId == 0 || query.userId == null) {
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
        e.mid_term,
        e.final_term,
        e.result
      FROM 
        enrollments e
      JOIN 
        classes c ON e.class_id = c.class_id
      JOIN 
        courses co ON c.course_id = co.course_id
      WHERE 
        e.student_id = ${query.userId}  
        AND c.semester = '${query.semester}';  
    `)
  )

  const miscInfo = await db.execute(
    sql.raw(`
      SELECT
        ROUND(AVG(e.result), 2) as gpa,
        SUM(co.credit) as total_credit,
        COUNT(c.class_id) as class_count
      FROM
        enrollments e
      JOIN
        classes c ON c.class_id = e.class_id
      JOIN
        courses co ON co.course_id = c.course_id
      WHERE
        e.student_id = ${query.userId}  
        AND c.semester = '${query.semester}';
    `)
  )

  return {
    success: true,
    err: null,
    classes: classArr,
    miscInfo: miscInfo[0]
  }
})