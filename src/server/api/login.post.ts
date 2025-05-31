import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"
import process from 'process'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (
    body.email === process.env.ADMIN_USER &&
    body.password === process.env.ADMIN_PASS
  ) {
    return {
      success: true,
      error: null,
      role: "admin",
      userId: null
    }
  }

  const [user] = await db.execute(
    sql.raw(`select * from users where email = '${body.email}';`)
  )
  
  if (user == undefined) return { success: false, sessionId: '0', error: "Wrong email or password.", role: null, userId: '0'}

  if (body.password === user.password) {
    return { success: true, error: "None", role: user.role, userId: user.user_id}
  }

  return { success: false, error: "Wrong email or password.", role: null, userId: '0'}

});
