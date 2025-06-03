import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const query = await getQuery(event)

  if (query.studentId == 0) {
    return {
      success: false,
      err: "Student ID is required.",
      studentInfo: null
    }
  }

  try {
    const studentInfo = await db.execute(
      sql.raw(`
        SELECT 
          s.student_id,
          u.first_name,
          u.last_name,
          CONCAT(u.first_name, ' ', u.last_name) AS full_name,
          u.email,
          u.date_of_birth,
          u.address,
          s.enrolled_year,
          s.warning_level,
          s.accumulated_credit,
          s.graduated,
          s.debt,
          ROUND(s.cpa, 2) as cpa,
          p.program_name,
          p.total_credit,
          ROUND(calculate_gpa(${query.studentId}, '${query.currentSemester}'), 2) as gpa
        FROM 
          users u
        JOIN 
          students_view s ON u.user_id = s.student_id
        JOIN
          programs p ON s.program_id = p.program_id
        JOIN
          enrollments_view e ON e.student_id = s.student_id
        JOIN 
          classes_view c ON c.class_id = e.class_id
        WHERE 
          u.user_id = ${query.studentId};
      `)
    )

    // console.log(studentInfo[0] + query.currentSemester + query.studentId)

    if (!studentInfo.length) {
      return {
        success: false,
        err: "Student not found.",
        studentInfo: null
      }
    }

    return {
      success: true,
      err: null,
      studentInfo: studentInfo[0]
    }
  } catch (error) {
    console.error("Error fetching student info:", error)
    return {
      success: false,
      err: "Internal server error",
      studentInfo: null
    }
  }
})