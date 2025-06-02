import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.classId) {
    return {
      success: false,
      err: "class ID is required"
    }
  }

  try {
    await db.execute(
      sql.raw(`
        DELETE FROM classes WHERE class_id = ${body.classId};
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
      err: "Internal server error"
    }
  }
})
