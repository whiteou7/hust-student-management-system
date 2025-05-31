import { sql } from "drizzle-orm"
import {
  pgTable,
  unique,
  pgEnum,
  serial,
  varchar,
  foreignKey,
  integer,
  boolean,
  time,
  numeric,
  text,
  index,
  date,
  primaryKey,
  uuid,
  uniqueIndex,
  check
} from "drizzle-orm/pg-core"

export const role = pgEnum("role", ["student", "teacher"])

export const graduation_status = pgEnum("graduation_status", ["graduated", "enrolled", "expelled"])

export const class_status = pgEnum("class_status", ["open", "closed"])

export const day_of_week = pgEnum("day_of_week", [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday"
])

export const users = pgTable("users", {
  user_id: serial().primaryKey().notNull(),
  first_name: varchar().notNull(),
  last_name: varchar().notNull(),
  email: varchar().unique(),
  password: varchar(),
  role: role().notNull()
})

export const programs = pgTable("programs", {
  program_id: serial().primaryKey().notNull(),
  program_name: varchar().notNull(),
  total_credit: integer().notNull()
})

export const schools = pgTable("schools", {
  school_id: serial().primaryKey().notNull(),
  school_name: varchar().notNull()
})

export const students = pgTable("students", {
  student_id: integer().primaryKey().references(() => users.user_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  program_id: integer().notNull().references(() => programs.program_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  enrolled_year: integer().notNull(),
  warning_level: integer().default(0),
  accumulated_credit: integer().default(0),
  graduated: graduation_status().default("enrolled"),
  debt: integer().default(0),
  cpa: numeric({
    precision: 3,
    scale: 2
  }).default('0.00')
})

export const teachers = pgTable("teachers", {
  teacher_id: integer().primaryKey().references(() => users.user_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  school_id: integer().notNull().references(() => schools.school_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  hired_year: integer(),
  qualification: varchar()
})

export const courses = pgTable("courses", {
  course_id: varchar("course_id", { length: 6 }).primaryKey().unique(),
  course_name: varchar().notNull(),
  credit: integer().notNull(),
  tuition_per_credit: integer().notNull(),
  school_id: integer().notNull().references(() => schools.school_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  })
})

export const classes = pgTable("classes", {
  class_id: serial().primaryKey(),
  teacher_id: integer().notNull().references(() => teachers.teacher_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  course_id: varchar("course_id", { length: 6 }).notNull().references(() => courses.course_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  capacity: integer().notNull().default(0),
  semester: varchar().notNull(),
  enrolled_count: integer().notNull().default(0),
  status: class_status().notNull(),
  day_of_week: day_of_week().notNull(),
  location: text().notNull()
})

export const sessions = pgTable("sessions", {
  session_id: serial().primaryKey(),
  user_id: integer("user_id").notNull().references(() => users.user_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
})

export const enrollments = pgTable(
  "enrollments",
  {
    student_id: integer("student_id")
      .notNull()
      .references(() => students.student_id, {
        onDelete: "cascade",
        onUpdate: "cascade",
      }),
    class_id: integer("class_id")
      .notNull()
      .references(() => classes.class_id, {
        onDelete: "cascade",
        onUpdate: "cascade",
      }),
    mid_term: numeric("mid_term", { precision: 3, scale: 2 })
      .default("0.00")
      .notNull(),
    final_term: numeric("final_term", { precision: 3, scale: 2 })
      .default("0.00")
      .notNull(),
    pass: boolean("pass").default(false).notNull(),
  },
  (table) => [
    unique("unique_student_class").on(table.student_id, table.class_id),
    check("check_mid_term", sql`${table.mid_term} >= 0.00 AND ${table.mid_term} <= 10.00`),
    check("check_final_term", sql`${table.final_term} >= 0.00 AND ${table.final_term} <= 10.00`),
  ]
)

