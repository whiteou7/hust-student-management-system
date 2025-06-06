-- Indexes for common query patterns in your APIs

-- 1. For filtering/joining on teacher_id, course_id, semester in classes_view/classes
CREATE INDEX idx_classes_teacher_id ON classes(teacher_id);
CREATE INDEX idx_classes_course_id ON classes(course_id);
CREATE INDEX idx_classes_semester ON classes(semester);

-- 2. For filtering/joining on course_id, school_id in courses
CREATE INDEX idx_courses_school_id ON courses(school_id);

-- 3. For filtering/joining on student_id, class_id in enrollments
CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_enrollments_class_id ON enrollments(class_id);

-- 4. For filtering/joining on program_id in students and program_requirements
CREATE INDEX idx_students_program_id ON students(program_id);
CREATE INDEX idx_program_requirements_program_id ON program_requirements(program_id);
CREATE INDEX idx_program_requirements_course_id ON program_requirements(course_id);

-- 5. For filtering/joining on school_id in teachers
CREATE INDEX idx_teachers_school_id ON teachers(school_id);

-- 6. For filtering/joining on user_id and role in users
CREATE INDEX idx_users_role ON users(role);

-- 7. For filtering on graduated in students (if you often filter by graduation status)
CREATE INDEX idx_students_graduated ON students(graduated);

-- 8. For filtering on email in users (for login)
CREATE INDEX idx_users_email ON users(email);