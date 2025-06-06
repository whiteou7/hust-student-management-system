import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const method = event.method

  if (method === "GET") {
    const [row] = await db.execute(sql.raw("SELECT class_reg_status FROM configs LIMIT 1"))
    return { classRegStatus: typeof row?.class_reg_status === "boolean" ? row.class_reg_status : null }
  }

  if (method === "PUT") {
    const body = await readBody(event)
    if (typeof body.classRegStatus !== "boolean") {
      throw createError({ statusCode: 400, statusMessage: "Invalid classRegStatus" })
    }
    await db.execute(sql.raw(`UPDATE configs SET class_reg_status = ${body.classRegStatus}`))
    return { success: true }
  }

  throw createError({ statusCode: 405, statusMessage: "Method Not Allowed" })
})
