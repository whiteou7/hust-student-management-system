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
    const success = await db.execute(
      sql.raw(`
        
      `)
    )
  }
  catch (error) {
    console.error("Error updating student info:", error)
    return {
      success: false,
      err: "Internal server error"
    }
  }

})