INSERT INTO "schools" ("school_id", "school_name") VALUES
(2, 'School of Engineering'),
(3, 'School of Business'),
(4, 'School of Medicine'),
(5, 'School of Arts');

-- 1. School of Computer Science (school_id = 1)
INSERT INTO "courses" ("course_id", "course_name", "credit", "tuition_per_credit", "school_id") VALUES
('CS101', 'Introduction to Programming', 3, 100, 1),
('CS102', 'Object-Oriented Programming', 4, 120, 1),
('CS103', 'Data Structures', 3, 110, 1),
('CS104', 'Algorithms', 4, 130, 1),
('CS105', 'Database Systems', 3, 120, 1),
('CS106', 'Computer Networks', 4, 140, 1),
('CS107', 'Operating Systems', 4, 130, 1),
('CS108', 'Software Engineering', 3, 125, 1),
('CS109', 'Artificial Intelligence', 3, 150, 1),
('CS110', 'Web Development', 3, 115, 1);

-- 2. School of Engineering (school_id = 2)
INSERT INTO "courses" ("course_id", "course_name", "credit", "tuition_per_credit", "school_id") VALUES
('EN201', 'Engineering Mechanics', 4, 90, 2),
('EN202', 'Thermodynamics', 3, 100, 2),
('EN203', 'Electrical Circuits', 4, 110, 2),
('EN204', 'Materials Science', 3, 95, 2),
('EN205', 'Fluid Mechanics', 4, 120, 2),
('EN206', 'Structural Analysis', 4, 115, 2),
('EN207', 'Control Systems', 3, 105, 2),
('EN208', 'Robotics', 4, 130, 2),
('EN209', 'Renewable Energy', 3, 100, 2),
('EN210', 'Engineering Design', 3, 110, 2);

-- 3. School of Business (school_id = 3)
INSERT INTO "courses" ("course_id", "course_name", "credit", "tuition_per_credit", "school_id") VALUES
('BU301', 'Principles of Marketing', 3, 130, 3),
('BU302', 'Financial Accounting', 4, 150, 3),
('BU303', 'Business Statistics', 3, 120, 3),
('BU304', 'Organizational Behavior', 3, 110, 3),
('BU305', 'Operations Management', 4, 140, 3),
('BU306', 'Business Law', 3, 125, 3),
('BU307', 'International Business', 3, 135, 3),
('BU308', 'Strategic Management', 4, 160, 3),
('BU309', 'Entrepreneurship', 3, 130, 3),
('BU310', 'Digital Marketing', 3, 140, 3);

-- 4. School of Medicine (school_id = 4)
INSERT INTO "courses" ("course_id", "course_name", "credit", "tuition_per_credit", "school_id") VALUES
('MD401', 'Human Anatomy', 5, 200, 4),
('MD402', 'Biochemistry', 4, 180, 4),
('MD403', 'Medical Ethics', 2, 90, 4),
('MD404', 'Pharmacology', 4, 190, 4),
('MD405', 'Pathology', 5, 210, 4),
('MD406', 'Microbiology', 4, 185, 4),
('MD407', 'Clinical Skills', 3, 170, 4),
('MD408', 'Immunology', 4, 195, 4),
('MD409', 'Neuroscience', 5, 220, 4),
('MD410', 'Public Health', 3, 150, 4);

-- 5. School of Arts (school_id = 5)
INSERT INTO "courses" ("course_id", "course_name", "credit", "tuition_per_credit", "school_id") VALUES
('AR501', 'Art History', 3, 80, 5),
('AR502', 'Drawing Fundamentals', 2, 70, 5),
('AR503', 'Modern Painting', 3, 90, 5),
('AR504', 'Sculpture', 4, 100, 5),
('AR505', 'Digital Art', 3, 110, 5),
('AR506', 'Photography', 3, 95, 5),
('AR507', 'Graphic Design', 4, 120, 5),
('AR508', 'Art Theory', 3, 85, 5),
('AR509', 'Ceramics', 4, 105, 5),
('AR510', 'Animation', 4, 130, 5);
