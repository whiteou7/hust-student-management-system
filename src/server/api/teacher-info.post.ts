import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (body.teacherId == 0) {
    return {
      success: false,
      err: "Teacher ID is required.",
      teacherInfo: null
    }
  }

  try {
    const teacherInfo = await db.execute(
      sql.raw(`
        SELECT 
          t.teacher_id,
          u.first_name,
          u.last_name,
          CONCAT(u.first_name, ' ', u.last_name) AS full_name,
          u.email,
          u.address,
          u.date_of_birth,
          t.qualification,
          t.position,
          t.profession,
          t.hired_year,
          s.school_name
        FROM 
          users u
        JOIN 
          teachers t ON u.user_id = t.teacher_id
        JOIN 
          schools s ON s.school_id = t.school_id
        WHERE 
          u.user_id = ${body.teacherId};
      `)
    )

    if (!teacherInfo.length) {
      return {
        success: false,
        err: "Teacher not found.",
        teacherInfo: null
      }
    }

    return {
      success: true,
      err: null,
      teacherInfo: teacherInfo[0]
    }
  } catch (error) {
    console.error("Error fetching teacher info:", error)
    return {
      success: false,
      err: "Internal server error",
      teacherInfo: null
    }
  }
}) 