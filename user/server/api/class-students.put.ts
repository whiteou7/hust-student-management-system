import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.studentId) {
    return {
      success: false,
      err: "Student ID is required"
    }
  }

  try {
    const students = await db.execute(
      sql.raw(`
        UPDATE
          enrollments e
        SET
          e.mid_term = ${body.midTerm},
          e.final_term = ${body.finalTerm}
        WHERE 
          e.student_id = ${body.studentId};
      `)
    )

    return {
      success: true,
      err: null
    }
    
  } catch (error) {
    console.error("Error:", error)
    return {
      success: false,
      err: "Internal server error"
    }
  }
}) 