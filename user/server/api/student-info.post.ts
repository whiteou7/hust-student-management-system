import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (body.studentId == 0) {
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
          u.email,
          u.date_of_birth,
          u.address,
          s.enrolled_year,
          s.warning_level,
          s.accumulated_credit,
          s.graduated,
          s.debt,
          s.cpa,
          p.program_name,
          p.total_credit,
          ROUND(AVG(e.result), 2) as gpa
        FROM 
          users u
        JOIN 
          students s ON u.user_id = s.student_id
        JOIN
          programs p ON s.program_id = p.program_id
        JOIN
          enrollments e ON e.student_id = s.student_id
        JOIN 
          classes c ON c.class_id = e.class_id
        WHERE 
          u.user_id = ${body.studentId}
          AND c.semester = '${body.currentSemester}'
        GROUP BY
          s.student_id,
          u.first_name,
          u.last_name,
          u.email,
          u.date_of_birth,
          u.address,
          s.enrolled_year,
          s.warning_level,
          s.accumulated_credit,
          s.graduated,
          s.debt,
          s.cpa,
          p.program_name,
          p.total_credit;
      `)
    )

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