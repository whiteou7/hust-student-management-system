
CREATE OR REPLACE FUNCTION trg_update_cpa_accumulated_credit()
RETURNS TRIGGER AS $$
DECLARE
  total_weighted_score NUMERIC := 0;
  total_credits INTEGER := 0;
BEGIN
  -- Recalculate accumulated_credit and cpa for the student

  SELECT 
    COALESCE(SUM(c.credit), 0),
    COALESCE(SUM(c.credit * ((e.mid_term + e.final_term)/2.0)), 0)
  INTO total_credits, total_weighted_score
  FROM enrollments e
  JOIN classes cl ON e.class_id = cl.class_id
  JOIN courses c ON cl.course_id = c.course_id
  WHERE e.student_id = NEW.student_id AND e.pass = TRUE;

  -- Update accumulated_credit and cpa in students
  UPDATE students
  SET 
    accumulated_credit = total_credits,
    cpa = CASE WHEN total_credits = 0 THEN NULL ELSE total_weighted_score / total_credits END
  WHERE student_id = NEW.student_id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_cpa
AFTER INSERT OR UPDATE OF mid_term, final_term, pass ON enrollments
FOR EACH ROW EXECUTE FUNCTION trg_update_cpa_accumulated_credit();