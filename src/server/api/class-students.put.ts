import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (body.studentId == null || body.studentId === "") {
    return {
      success: false,
      err: "Missing body parameters."
    }
  }
  if (body.midTerm == null || body.midTerm === "") {body.midTerm = "NULL"} 
  if (body.finalTerm == null || body.finalTerm === "") {body.finalTerm = "NULL"} 

  try {
    await db.execute(
      sql.raw(`
        UPDATE
          enrollments
        SET
          mid_term = ${body.midTerm},
          final_term = ${body.finalTerm}
        WHERE 
          student_id = ${body.studentId};
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