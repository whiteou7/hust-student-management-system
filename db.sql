-- 1. Cập nhật danh sách schools
INSERT INTO "schools" ("school_id", "school_name") VALUES
(2, 'School of Engineering'),
(3, 'School of Business'),
(4, 'School of Language'),  
(5, 'School of Physics');

-- 2. Courses cho Computer Science (school_id=1)
INSERT INTO "courses" ("course_id", "course_name", "credit", "tuition_per_credit", "school_id") VALUES
('CS0101', 'Introduction to Programming', 3, 100, 1),
('CS0102', 'Data Structures', 4, 120, 1),
('CS0103', 'Algorithms', 4, 130, 1),
('CS0104', 'Database Systems', 3, 110, 1),
('CS0105', 'Computer Networks', 4, 140, 1),
('CS0106', 'Operating Systems', 4, 130, 1),
('CS0107', 'AI Fundamentals', 3, 150, 1),
('CS0108', 'Web Development', 3, 115, 1),
('CS0109', 'Software Engineering', 4, 125, 1),
('CS0110', 'Cybersecurity', 3, 145, 1);

-- 3. Courses cho Engineering (school_id=2)
INSERT INTO "courses" ("course_id", "course_name", "credit", "tuition_per_credit", "school_id") VALUES
('EN0201', 'Thermodynamics', 4, 90, 2),
('EN0202', 'Circuit Analysis', 4, 110, 2),
('EN0203', 'Fluid Mechanics', 4, 120, 2),
('EN0204', 'Materials Science', 3, 95, 2),
('EN0205', 'Structural Design', 4, 115, 2),
('EN0206', 'Control Systems', 3, 105, 2),
('EN0207', 'Robotics', 4, 130, 2),
('EN0208', 'Renewable Energy', 3, 100, 2),
('EN0209', 'CAD Modeling', 3, 110, 2),
('EN0210', 'Engineering Math', 4, 100, 2);

-- 4. Courses cho Business (school_id=3)
INSERT INTO "courses" ("course_id", "course_name", "credit", "tuition_per_credit", "school_id") VALUES
('BU0301', 'Financial Accounting', 4, 150, 3),
('BU0302', 'Marketing Principles', 3, 130, 3),
('BU0303', 'Business Statistics', 3, 120, 3),
('BU0304', 'Operations Management', 4, 140, 3),
('BU0305', 'Organizational Behavior', 3, 110, 3),
('BU0306', 'Business Law', 3, 125, 3),
('BU0307', 'Strategic Management', 4, 160, 3),
('BU0308', 'Entrepreneurship', 3, 130, 3),
('BU0309', 'International Business', 3, 135, 3),
('BU0310', 'Digital Marketing', 3, 140, 3);

-- 5. Courses cho Language (school_id=4)
INSERT INTO "courses" ("course_id", "course_name", "credit", "tuition_per_credit", "school_id") VALUES
('LA0401', 'English Linguistics', 3, 90, 4),
('LA0402', 'French Literature', 3, 95, 4),
('LA0403', 'Spanish Grammar', 3, 85, 4),
('LA0404', 'Chinese Characters', 4, 100, 4),
('LA0405', 'Translation Studies', 3, 110, 4),
('LA0406', 'Phonetics', 2, 80, 4),
('LA0407', 'Comparative Literature', 3, 105, 4),
('LA0408', 'Academic Writing', 2, 75, 4),
('LA0409', 'Japanese Culture', 3, 95, 4),
('LA0410', 'German Conversation', 3, 90, 4);

-- 6. Courses cho Physics (school_id=5)
INSERT INTO "courses" ("course_id", "course_name", "credit", "tuition_per_credit", "school_id") VALUES
('PH0501', 'Classical Mechanics', 4, 110, 5),
('PH0502', 'Electromagnetism', 4, 120, 5),
('PH0503', 'Quantum Physics', 4, 130, 5),
('PH0504', 'Thermodynamics', 3, 100, 5),
('PH0505', 'Nuclear Physics', 4, 140, 5),
('PH0506', 'Astrophysics', 3, 125, 5),
('PH0507', 'Optics', 3, 115, 5),
('PH0508', 'Particle Physics', 4, 150, 5),
('PH0509', 'Solid State Physics', 4, 135, 5),
('PH0510', 'Computational Physics', 3, 120, 5);
