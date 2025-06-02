import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (body.teacherId == 0 || body.teacherId == null) {
    return {
      success: false,
      err: "Teacher ID is required."
    }
  }

  try {
    await db.execute(
      sql.raw(`
        UPDATE 
          users u
        SET
          first_name = '${body.first_name}',
          last_name = '${body.last_name}',
          email = '${body.email}',
          date_of_birth = '${body.date_of_birth}',
          address = '${body.address}'
        WHERE
          user_id = ${body.teacherId};
      `)
    );

    return {
      success: true,
      err: null
    }
  }
  catch (error) {
    console.error("Error updating teacher info:", error)
    return {
      success: false,
      err: "Internal server error"
    }
  }

})