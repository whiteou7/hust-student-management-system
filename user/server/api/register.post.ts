import { sql } from "drizzle-orm";
import { db_user as db } from "../../drizzle/db";
export default defineEventHandler(async (event) => {
  const body = await readBody(event);

  // console.log(body.email + " " + body.password);

  const [user] = await db.execute(
    sql.raw(`select * from users where user_id = '${body.user_id}';`)
  );

  // console.log(user);
  
  if (user === undefined) return { success: false, error: "User does not exist." };

  if (user.role === "teacher") return { success: false, error: "Cannot create account for teacher." };

  await db.execute(
    sql.raw(`update users set password = ${user.password} where user_id = ${user.user_id}`)
  );
  await db.execute(
    sql.raw(`update users set email = '${user.email}' where user_id = ${user.user_id}`)
  );

  console.log("Account created.");
  return { success: true, error: null };

});
