CREATE OR REPLACE FUNCTION check_graduation_status(p_student_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_program_id INT;
    v_completed_course INT;
    v_total_course INT;
    v_completed_credit INT;
    v_total_credit INT;
BEGIN
    -- Get the student's program ID
    SELECT program_id INTO v_program_id
    FROM students
    WHERE student_id = p_student_id;
    RAISE NOTICE 'program_id = %', v_program_id;

    -- Count distinct completed courses that are part of program requirements
    SELECT COUNT(DISTINCT c.course_id) INTO v_completed_course
    FROM enrollments e
    JOIN classes c ON e.class_id = c.class_id
    RIGHT JOIN program_requirements pr ON pr.course_id = c.course_id
    WHERE e.student_id = p_student_id
      AND e.pass = TRUE;
    RAISE NOTICE 'completed_course = %', v_completed_course;

    -- Get total required courses in the program
    SELECT COUNT(course_id) INTO v_total_course
    FROM program_requirements
    WHERE program_id = v_program_id;
    RAISE NOTICE 'total_course = %', v_total_course;

    -- Get total completed credits, avoiding duplicate course_ids
    SELECT SUM(DISTINCT co.credit) INTO v_completed_credit
    FROM enrollments e
    JOIN classes c ON e.class_id = c.class_id
    JOIN courses co ON co.course_id = c.course_id
    WHERE e.student_id = p_student_id
      AND e.pass = TRUE;
    RAISE NOTICE 'completed_credit = %', v_completed_credit;

    -- Get the required total credit for the program
    SELECT total_credit INTO v_total_credit
    FROM programs
    WHERE program_id = v_program_id;
    RAISE NOTICE 'total_credit = %', v_total_credit;

    -- Return graduation status
    RETURN v_completed_course = v_total_course
           AND v_completed_credit >= v_total_credit;
END;
$$ LANGUAGE plpgsql;
