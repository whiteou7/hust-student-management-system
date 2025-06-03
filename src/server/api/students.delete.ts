import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const query = await getQuery(event)
  if (!query.studentId) return { success: false, err: "studentId is required" }
  try {
    await db.execute(sql.raw(`
      DELETE FROM users WHERE user_id=${query.studentId}
    `))
    return { success: true }
  } catch (err) {
    return { success: false, err: err }
  }
})
