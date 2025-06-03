CREATE TABLE public.classes (
	class_id serial4 NOT NULL,
	teacher_id int4 NULL,
	course_id varchar(6) NOT NULL,
	capacity int4 DEFAULT 0 NOT NULL,
	semester varchar NOT NULL,
	status public.class_status NOT NULL,
	day_of_week public.day_of_week NOT NULL,
	"location" text NOT NULL,
	CONSTRAINT classes_pkey PRIMARY KEY (class_id),
	CONSTRAINT classes_course_id_courses_course_id_fk FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT classes_teacher_id_teachers_teacher_id_fk FOREIGN KEY (teacher_id) REFERENCES public.teachers(teacher_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE public.courses (
	course_id varchar(6) NOT NULL,
	course_name varchar NOT NULL,
	credit int4 NOT NULL,
	tuition_per_credit int4 NOT NULL,
	school_id int4 NOT NULL,
	course_description varchar NULL,
	CONSTRAINT courses_course_id_unique PRIMARY KEY (course_id),
	CONSTRAINT courses_school_id_schools_school_id_fk FOREIGN KEY (school_id) REFERENCES public.schools(school_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE public.enrollments (
	student_id int4 NOT NULL,
	class_id int4 NOT NULL,
	mid_term numeric(4, 2) NULL,
	final_term numeric(4, 2) NULL,
	CONSTRAINT check_final_term CHECK (((final_term IS NULL) OR ((final_term >= 0.00) AND (final_term <= 10.00)))),
	CONSTRAINT check_mid_term CHECK (((mid_term IS NULL) OR ((mid_term >= 0.00) AND (mid_term <= 10.00)))),
	CONSTRAINT unique_student_class UNIQUE (student_id, class_id),
	CONSTRAINT enrollments_class_id_classes_class_id_fk FOREIGN KEY (class_id) REFERENCES public.classes(class_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT enrollments_student_id_students_student_id_fk FOREIGN KEY (student_id) REFERENCES public.students(student_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE public.program_requirements (
	program_id int4 NULL,
	course_id varchar(6) NULL,
	CONSTRAINT program_course_unique UNIQUE (program_id, course_id),
	CONSTRAINT program_requirements_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id),
	CONSTRAINT program_requirements_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id)
);

CREATE TABLE public.programs (
	program_id serial4 NOT NULL,
	program_name varchar NOT NULL,
	total_credit int4 NOT NULL,
	CONSTRAINT programs_pkey PRIMARY KEY (program_id)
);

CREATE TABLE public.schools (
	school_id serial4 NOT NULL,
	school_name varchar NOT NULL,
	CONSTRAINT schools_pkey PRIMARY KEY (school_id)
);

CREATE TABLE public.students (
	student_id int4 NOT NULL,
	program_id int4 NOT NULL,
	enrolled_year int4 NOT NULL,
	graduated public.graduation_status DEFAULT 'enrolled'::graduation_status NULL,
	debt int4 DEFAULT 0 NULL,
	CONSTRAINT students_pkey PRIMARY KEY (student_id),
	CONSTRAINT students_program_id_programs_program_id_fk FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT students_student_id_users_user_id_fk FOREIGN KEY (student_id) REFERENCES public.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE public.teachers (
	teacher_id int4 NOT NULL,
	school_id int4 NOT NULL,
	hired_year int4 NULL,
	qualification varchar NULL,
	profession varchar NULL,
	"position" varchar NULL,
	CONSTRAINT teachers_pkey PRIMARY KEY (teacher_id),
	CONSTRAINT teachers_school_id_schools_school_id_fk FOREIGN KEY (school_id) REFERENCES public.schools(school_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT teachers_teacher_id_users_user_id_fk FOREIGN KEY (teacher_id) REFERENCES public.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE public.users (
	user_id serial4 NOT NULL,
	first_name varchar NOT NULL,
	last_name varchar NOT NULL,
	email varchar NULL,
	"password" varchar NULL,
	"role" public."role" NOT NULL,
	date_of_birth date NULL,
	address varchar NULL,
	CONSTRAINT users_email_unique UNIQUE (email),
	CONSTRAINT users_pkey PRIMARY KEY (user_id)
);