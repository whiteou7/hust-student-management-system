--2 Vũ
--Hàm Trigger chứa logic mã lệnh
CREATE OR REPLACE FUNCTION public.update_enrollment_pass_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Kiểm tra nếu một trong hai điểm là NULL
    IF NEW.mid_term IS NULL OR NEW.final_term IS NULL THEN
        NEW.pass := NULL;
    -- Kiểm tra điều kiện rớt (điểm giữa kỳ < 3 hoặc điểm cuối kỳ < 4)
    ELSIF NEW.mid_term < 3 OR NEW.final_term < 4 THEN
        NEW.pass := FALSE;
    -- Nếu không thuộc các trường hợp trên, sinh viên đậu
    ELSE
        NEW.pass := TRUE;
    END IF;
    RETURN NEW;
END;
$$;
ALTER FUNCTION public.update_enrollment_pass_status() OWNER TO postgres;

--Khai báo trigger
CREATE TRIGGER trg_update_enrollment_pass
BEFORE INSERT OR UPDATE ON public.enrollments
FOR EACH ROW
EXECUTE FUNCTION public.update_enrollment_pass_status();