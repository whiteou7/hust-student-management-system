import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async () => {
  try {
    const teachers = await db.execute(
      sql.raw(`
        SELECT 
          t.teacher_id,
          CONCAT(u.first_name, ' ', u.last_name) AS full_name
        FROM 
          teachers t
        JOIN 
          users u ON u.user_id = t.teacher_id
        ORDER BY
          t.teacher_id
      `)
    )

    return {
      success: true,
      err: null,
      teachers: teachers
    }
  } catch (error) {
    return {
      success: false,
      err: error,
      teachers: null
    }
  }
}) 