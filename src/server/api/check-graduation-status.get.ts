import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const query = await getQuery(event)

  if (!query.studentId) {
    return null
  }

  try {
    const isGraduated = await db.execute(
      sql.raw(`
        SELECT check_graduation_status(${query.studentId})
      `)
    )

    return isGraduated[0].check_graduation_status

  } catch (error) {
    console.log(error)
    return null
  }
}) 