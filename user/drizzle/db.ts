import postgres from "postgres";
import { drizzle } from "drizzle-orm/postgres-js";
import "dotenv/config";

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL environment variable is not defined");
}
const db_user = drizzle(postgres(process.env.DATABASE_URL));

export { db_user };
