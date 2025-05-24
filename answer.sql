
-- 1. Tạo hàm trigger cho thao tác INSERT (đăng ký lớp mới)
CREATE OR REPLACE FUNCTION update_enrolled_count_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE classes 
    SET enrolled_count = enrolled_count + 1 
    WHERE class_id = NEW.class_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Tạo hàm trigger cho thao tác DELETE (hủy đăng ký)
CREATE OR REPLACE FUNCTION update_enrolled_count_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE classes 
    SET enrolled_count = enrolled_count - 1 
    WHERE class_id = OLD.class_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 3. Tạo hàm trigger cho thao tác UPDATE (chuyển lớp)
CREATE OR REPLACE FUNCTION update_enrolled_count_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Giảm enrolled_count của lớp cũ đi 1
    IF OLD.class_id IS DISTINCT FROM NEW.class_id THEN
        UPDATE classes 
        SET enrolled_count = enrolled_count - 1 
        WHERE class_id = OLD.class_id;
        
        -- Tăng enrolled_count của lớp mới lên 1
        UPDATE classes 
        SET enrolled_count = enrolled_count + 1 
        WHERE class_id = NEW.class_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Tạo các trigger
-- Trigger cho INSERT
CREATE TRIGGER trg_enrollments_insert
AFTER INSERT ON enrollments
FOR EACH ROW
EXECUTE FUNCTION update_enrolled_count_insert();

-- Trigger cho DELETE
CREATE TRIGGER trg_enrollments_delete
AFTER DELETE ON enrollments
FOR EACH ROW
EXECUTE FUNCTION update_enrolled_count_delete();

-- Trigger cho UPDATE
CREATE TRIGGER trg_enrollments_update
AFTER UPDATE OF class_id ON enrollments
FOR EACH ROW
WHEN (OLD.class_id IS DISTINCT FROM NEW.class_id)
EXECUTE FUNCTION update_enrolled_count_update();

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

