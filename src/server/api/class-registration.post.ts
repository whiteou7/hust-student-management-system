import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.classId || !body.studentId) {
    return {
      success: false,
      err: "Missing required fields"
    }
  }

  try {
    await db.execute(
      sql.raw(`
        CALL 
          enroll_student_in_class(${body.studentId}, ${body.classId});
      `)
    )

    return {
      success: true,
      err: null
    }
  } catch (error) {
    console.error(error)
    return {
      success: false,
      err: typeof error === "object" && error !== null && "message" in error ? (error as { message: string }).message : String(error)
    }
  }
})