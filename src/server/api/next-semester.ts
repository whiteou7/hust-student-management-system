import { readFileSync, writeFileSync } from "fs"
import { join } from "path"

const configPath = join(process.cwd(), "configs", "nextSemester.json")

export default defineEventHandler(async (event) => {
  const method = event.method

  if (method === "GET") {
    const file = readFileSync(configPath, "utf-8")
    const json = JSON.parse(file)
    return json
  }

  if (method === "PUT") {
    const body = await readBody(event)

    if (!body.nextSemester || typeof body.nextSemester !== "string") {
      throw createError({ statusCode: 400, statusMessage: "Invalid nextSemester" })
    }

    writeFileSync(configPath, JSON.stringify({ nextSemester: body.nextSemester }, null, 2))
    return { success: true }
  }

  throw createError({ statusCode: 405, statusMessage: "Method Not Allowed" })
})
