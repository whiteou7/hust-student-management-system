CREATE TYPE "public"."class_status" AS ENUM('open', 'closed');--> statement-breakpoint
CREATE TYPE "public"."day_of_week" AS ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');--> statement-breakpoint
CREATE TYPE "public"."graduation_status" AS ENUM('graduated', 'enrolled', 'expelled');--> statement-breakpoint
CREATE TYPE "public"."role" AS ENUM('student', 'teacher');--> statement-breakpoint
CREATE TABLE "classes" (
	"class_id" serial PRIMARY KEY NOT NULL,
	"teacher_id" integer NOT NULL,
	"course_id" varchar(6) NOT NULL,
	"capacity" integer DEFAULT 0 NOT NULL,
	"semester" varchar NOT NULL,
	"enrolled_count" integer DEFAULT 0 NOT NULL,
	"status" "class_status" NOT NULL,
	"day_of_week" "day_of_week" NOT NULL,
	"location" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "courses" (
	"course_id" varchar(6) PRIMARY KEY NOT NULL,
	"course_name" varchar NOT NULL,
	"course_description" varchar NOT NULL,
	"credit" integer NOT NULL,
	"tuition_per_credit" integer NOT NULL,
	"school_id" integer NOT NULL,
	CONSTRAINT "courses_course_id_unique" UNIQUE("course_id")
);
--> statement-breakpoint
CREATE TABLE "enrollments" (
	"student_id" integer NOT NULL,
	"class_id" integer NOT NULL,
	"mid_term" numeric(3, 2),
	"final_term" numeric(3, 2),
	"result" numeric(3, 2) DEFAULT '0.00',
	"pass" boolean DEFAULT false NOT NULL,
	CONSTRAINT "unique_student_class" UNIQUE("student_id","class_id"),
	CONSTRAINT "check_mid_term" CHECK ("enrollments"."mid_term" >= 0.00 AND "enrollments"."mid_term" <= 10.00),
	CONSTRAINT "check_final_term" CHECK ("enrollments"."final_term" >= 0.00 AND "enrollments"."final_term" <= 10.00)
);
--> statement-breakpoint
CREATE TABLE "programs" (
	"program_id" serial PRIMARY KEY NOT NULL,
	"program_name" varchar NOT NULL,
	"total_credit" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "schools" (
	"school_id" serial PRIMARY KEY NOT NULL,
	"school_name" varchar NOT NULL
);
--> statement-breakpoint
CREATE TABLE "sessions" (
	"session_id" serial PRIMARY KEY NOT NULL,
	"user_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "students" (
	"student_id" integer PRIMARY KEY NOT NULL,
	"program_id" integer NOT NULL,
	"enrolled_year" integer NOT NULL,
	"warning_level" integer DEFAULT 0,
	"accumulated_credit" integer DEFAULT 0,
	"graduated" "graduation_status" DEFAULT 'enrolled',
	"debt" integer DEFAULT 0,
	"cpa" numeric(3, 2) DEFAULT '0.00'
);
--> statement-breakpoint
CREATE TABLE "teachers" (
	"teacher_id" integer PRIMARY KEY NOT NULL,
	"school_id" integer NOT NULL,
	"hired_year" integer,
	"qualification" varchar
);
--> statement-breakpoint
CREATE TABLE "users" (
	"user_id" serial PRIMARY KEY NOT NULL,
	"first_name" varchar NOT NULL,
	"last_name" varchar NOT NULL,
	"date_of_birth" date,
	"address" varchar,
	"email" varchar,
	"password" varchar,
	"role" "role" NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "classes" ADD CONSTRAINT "classes_teacher_id_teachers_teacher_id_fk" FOREIGN KEY ("teacher_id") REFERENCES "public"."teachers"("teacher_id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "classes" ADD CONSTRAINT "classes_course_id_courses_course_id_fk" FOREIGN KEY ("course_id") REFERENCES "public"."courses"("course_id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "courses" ADD CONSTRAINT "courses_school_id_schools_school_id_fk" FOREIGN KEY ("school_id") REFERENCES "public"."schools"("school_id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "enrollments" ADD CONSTRAINT "enrollments_student_id_students_student_id_fk" FOREIGN KEY ("student_id") REFERENCES "public"."students"("student_id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "enrollments" ADD CONSTRAINT "enrollments_class_id_classes_class_id_fk" FOREIGN KEY ("class_id") REFERENCES "public"."classes"("class_id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_users_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("user_id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "students" ADD CONSTRAINT "students_student_id_users_user_id_fk" FOREIGN KEY ("student_id") REFERENCES "public"."users"("user_id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "students" ADD CONSTRAINT "students_program_id_programs_program_id_fk" FOREIGN KEY ("program_id") REFERENCES "public"."programs"("program_id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "teachers" ADD CONSTRAINT "teachers_teacher_id_users_user_id_fk" FOREIGN KEY ("teacher_id") REFERENCES "public"."users"("user_id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "teachers" ADD CONSTRAINT "teachers_school_id_schools_school_id_fk" FOREIGN KEY ("school_id") REFERENCES "public"."schools"("school_id") ON DELETE cascade ON UPDATE cascade;