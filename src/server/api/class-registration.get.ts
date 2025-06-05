import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  try {
    const unregisteredNewClasses = await db.execute(
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
          classes_view c
        JOIN 
          courses co ON c.course_id = co.course_id
        LEFT JOIN 
          teachers t ON c.teacher_id = t.teacher_id
        LEFT JOIN 
          users u ON t.teacher_id = u.user_id
        LEFT JOIN 
          enrollments e ON c.class_id = e.class_id
        WHERE 
          c.semester = '${query.nextSemester}'
        AND
          e.student_id is null
      `)
    )

    const registeredNewClasses = await db.execute(
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
          classes_view c
        JOIN 
          courses co ON c.course_id = co.course_id
        LEFT JOIN 
          teachers t ON c.teacher_id = t.teacher_id
        LEFT JOIN 
          users u ON t.teacher_id = u.user_id
        JOIN 
          enrollments e ON c.class_id = e.class_id
        WHERE 
          c.semester = '${query.nextSemester}'
        AND
          e.student_id = ${query.studentId}
      `)
    )

    return {
      success: true,
      err: null,
      unregisteredNewClasses,
      registeredNewClasses
    }
  } catch (error) {
    console.error(error)
    return {
      success: false,
      err: "Internal server error",
      unregisteredNewClasses: null,
      registeredNewClasses: null
    }
  }
})
