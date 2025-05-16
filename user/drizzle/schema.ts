import { sql } from "drizzle-orm";
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
} from "drizzle-orm/pg-core";

export const roles = pgEnum('roles', ['student', 'teacher']);

export const graduation_status = pgEnum('graduation_status', ['true', 'false', 'expelled']);

export const class_status = pgEnum('class_status', ['open', 'closes']);

export const users = pgTable("users", {
  user_id: serial().primaryKey().notNull(),
  first_name: varchar().notNull(),
  last_name: varchar().notNull(),
  email: varchar().notNull().unique(),
  password: varchar().notNull(),
  role: roles().notNull()
});

export const programs = pgTable("programs", {
  program_id: serial().primaryKey().notNull(),
  program_name: varchar().notNull(),
  total_credit: integer().notNull()
});

export const schools = pgTable("schools", {
  school_id: serial().primaryKey().notNull(),
  school_name: varchar().notNull()
});

export const students = pgTable("students", {
  student_id: integer().primaryKey().notNull().references(() => users.user_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  program_id: integer().notNull().references(() => programs.program_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  enrolled_year: integer(),
  warning_level: integer(),
  accumulated_credit: integer(),
  graduated: graduation_status(),
  debt: integer(),
  cpa: numeric({
    precision: 3,
    scale: 2
  })
});

export const teachers = pgTable("teachers", {
  teacher_id: integer().primaryKey().notNull().references(() => users.user_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  school_id: integer().notNull().references(() => schools.school_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  hired_year: integer(),
  qualification: varchar()
});

export const courses = pgTable("courses", {
  course_id: serial().primaryKey().notNull(),
  course_name: varchar().notNull(),
  credit: integer().notNull(),
  tuition_per_credit: integer().notNull(),
  school_id: integer().notNull().references(() => schools.school_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  })
});

export const classes = pgTable("classes", {
  class_id: serial().primaryKey().notNull(),
  teacher_id: integer().notNull().references(() => teachers.teacher_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  course_id: integer().notNull().references(() => courses.course_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  capacity: integer().notNull(),
  semester: varchar().notNull(),
  enrolled_count: integer().notNull().default(0),
  status: class_status().notNull(),
  day_of_week: varchar().notNull(),
  location: text().notNull()
});

export const sessions = pgTable("sessions", {
  session_id: serial().primaryKey(),
  user_id: integer("user_id").notNull().references(() => users.user_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
});

export const enrollments = pgTable("enrollments", {
  student_id: integer().notNull().references(() => students.student_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  class_id: integer().notNull().references(() => classes.class_id, {
    onDelete: "cascade",
    onUpdate: "cascade"
  }),
  mid_term: numeric({
    precision: 3,
    scale: 2
  }),
  final_term: numeric({
    precision: 3,
    scale: 2
  }),
  pass: boolean()
});
