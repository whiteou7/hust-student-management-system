import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const method = event.method

  if (method === "GET") {
    const [row] = await db.execute(sql.raw("SELECT current_semester FROM configs LIMIT 1"))
    return { currentSemester: row?.current_semester || null }
  }

  if (method === "PUT") {
    const body = await readBody(event)
    if (!body.currentSemester || typeof body.currentSemester !== "string") {
      throw createError({ statusCode: 400, statusMessage: "Invalid currentSemester" })
    }
    await db.execute(sql.raw(`UPDATE configs SET current_semester = '${body.currentSemester}'`))
    return { success: true }
  }

  throw createError({ statusCode: 405, statusMessage: "Method Not Allowed" })
})
