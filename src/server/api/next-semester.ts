import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const method = event.method

  if (method === "GET") {
    const [row] = await db.execute(sql.raw("SELECT next_semester FROM configs LIMIT 1"))
    return { nextSemester: row?.next_semester || null }
  }

  if (method === "PUT") {
    const body = await readBody(event)
    if (!body.nextSemester || typeof body.nextSemester !== "string") {
      throw createError({ statusCode: 400, statusMessage: "Invalid nextSemester" })
    }
    await db.execute(sql.raw(`UPDATE configs SET next_semester = '${body.nextSemester}'`))
    return { success: true }
  }

  throw createError({ statusCode: 405, statusMessage: "Method Not Allowed" })
})
