import { readFileSync, writeFileSync } from "fs"
import { join } from "path"

const configPath = join(process.cwd(), "config", "classRegStatus.json")

export default defineEventHandler(async (event) => {
  const method = event.method

  if (method === "GET") {
    const file = readFileSync(configPath, "utf-8")
    const json = JSON.parse(file)
    return json
  }

  if (method === "POST") {
    const body = await readBody(event)

    if (typeof body.classRegStatus !== "boolean") {
      throw createError({ statusCode: 400, statusMessage: "Invalid classRegStatus" })
    }

    writeFileSync(configPath, JSON.stringify({ classRegStatus: body.classRegStatus }, null, 2))
    return { success: true }
  }

  throw createError({ statusCode: 405, statusMessage: "Method Not Allowed" })
})
