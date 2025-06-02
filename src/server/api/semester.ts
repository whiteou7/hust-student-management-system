import { readFileSync, writeFileSync } from "fs"
import { join } from "path"

const configPath = join(process.cwd(), "configs", "currentSemester.json")

export default defineEventHandler(async (event) => {
  const method = event.method

  if (method === "GET") {
    const file = readFileSync(configPath, "utf-8")
    const json = JSON.parse(file)
    return json
  }

  if (method === "POST") {
    const body = await readBody(event)

    if (!body.currentSemester || typeof body.currentSemester !== "string") {
      throw createError({ statusCode: 400, statusMessage: "Invalid currentSemester" })
    }

    writeFileSync(configPath, JSON.stringify({ currentSemester: body.currentSemester }, null, 2))
    return { success: true }
  }

  throw createError({ statusCode: 405, statusMessage: "Method Not Allowed" })
})
