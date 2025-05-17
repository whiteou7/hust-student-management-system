import { sql } from "drizzle-orm";
import { db_user as db } from "../../drizzle/db";
export default defineEventHandler(async (event) => {
  const body = await readBody(event);

  // console.log(body.email + " " + body.password);

  const [user] = await db.execute(
    sql.raw(`select * from users where email = '${body.email}';`)
  );

  // console.log(user);
  
  if (user === undefined) return { success: false, sessionId: '0', error: "Wrong email or password.", role: null};

  if (body.password === user.password) {
    const [session] = await db.execute(
        sql.raw(`INSERT INTO sessions (user_id) VALUES (${user.user_id}) RETURNING session_id;`)
    );
    console.log("api called successfully");
    return { success: true, sessionId: session.session_id, error: "None", role: user.role, userId: user.user_id};
  }

  return { success: false, sessionId: '0', error: "Wrong email or password.", role: null};

});
