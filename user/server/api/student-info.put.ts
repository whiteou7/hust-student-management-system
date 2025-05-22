import { sql } from "drizzle-orm"
import { db_user as db } from "../../drizzle/db"

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (body.studentId == 0) {
    return {
      success: false,
      err: "Student ID is required.",
      studentInfo: null
    }
  }

  try {
    await db.execute(
      sql.raw(`
        UPDATE
          students s
        SET
          enrolled_year = ${body.enrolled_year}
        WHERE
          student_id = ${body.studentId};
      `)
    )

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
          user_id = ${body.studentId};
      `)
    );

    console.log("updated info")
    return {
      success: true,
      err: null
    }
  }
  catch (error) {
    console.error("Error updating student info:", error)
    return {
      success: false,
      err: "Internal server error"
    }
  }

})