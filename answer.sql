-- STEP 1: New Function to Increment/Decrement debt
CREATE OR REPLACE FUNCTION adjust_student_debt() RETURNS TRIGGER AS $$
DECLARE
    old_debt NUMERIC := 0;
    new_debt NUMERIC := 0;
BEGIN
    IF (TG_OP = 'INSERT') THEN
        SELECT c.credit * c.tuition_per_credit
        INTO new_debt
        FROM classes cl
        JOIN courses c ON cl.course_id = c.course_id
        WHERE cl.class_id = NEW.class_id;

        UPDATE students
        SET debt = debt + new_debt
        WHERE student_id = NEW.student_id;

    ELSIF (TG_OP = 'DELETE') THEN
        SELECT c.credit * c.tuition_per_credit
        INTO old_debt
        FROM classes cl
        JOIN courses c ON cl.course_id = c.course_id
        WHERE cl.class_id = OLD.class_id;

        UPDATE students
        SET debt = debt - old_debt
        WHERE student_id = OLD.student_id;

    ELSIF (TG_OP = 'UPDATE') THEN
        -- Only act if class_id actually changed
        IF (NEW.class_id <> OLD.class_id) THEN
            SELECT c.credit * c.tuition_per_credit
            INTO old_debt
            FROM classes cl
            JOIN courses c ON cl.course_id = c.course_id
            WHERE cl.class_id = OLD.class_id;

            SELECT c.credit * c.tuition_per_credit
            INTO new_debt
            FROM classes cl
            JOIN courses c ON cl.course_id = c.course_id
            WHERE cl.class_id = NEW.class_id;

            UPDATE students
            SET debt = debt - old_debt + new_debt
            WHERE student_id = NEW.student_id;
        END IF;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- STEP 2: Create Trigger
DROP TRIGGER IF EXISTS trg_adjust_student_debt ON enrollments;

CREATE TRIGGER trg_adjust_student_debt
AFTER INSERT OR UPDATE OR DELETE ON enrollments
FOR EACH ROW
EXECUTE FUNCTION adjust_student_debt();
