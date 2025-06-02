
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

--5 Viết function để tính warning level của học sinh
-- warning level = 0 nếu trượt < 3 môn
-- warning level = 1 nếu trượt < 6 môn
-- warning level = 2 nếu trượt < 9 môn
-- (Chú ý: tính tổng môn trượt, không phải lớp trượt. Nếu 1 môn có 2 lớp, 1 trượt 1 đạt thì môn đó đạt)
CREATE OR REPLACE FUNCTION calculate_student_warning_level(p_student_id INT)
RETURNS INT AS $$
DECLARE
    v_failed_courses_count INT;
    v_warning_level INT;
BEGIN
    -- Tính số lượng môn học (course_id) mà sinh viên đã trượt.
    -- Một môn học được coi là trượt nếu sinh viên KHÔNG có bất kỳ bản ghi đăng ký nào
    -- cho môn học đó với trạng thái 'pass = TRUE'
    -- VÀ có ÍT NHẤT MỘT bản ghi đăng ký cho môn học đó với trạng thái 'pass = FALSE'.
    WITH StudentDistinctCourses AS (
        -- Lấy tất cả các mã môn học (course_id) riêng biệt mà sinh viên đã đăng ký
        SELECT DISTINCT cls.course_id
        FROM public.enrollments enr
        JOIN public.classes cls ON enr.class_id = cls.class_id
        WHERE enr.student_id = p_student_id
    )
    SELECT COUNT(sdc.course_id)
    INTO v_failed_courses_count
    FROM StudentDistinctCourses sdc
    WHERE
        -- Điều kiện 1: Sinh viên không có bản ghi nào là 'pass = TRUE' cho môn học này
        NOT EXISTS (
            SELECT 1
            FROM public.enrollments e_pass
            JOIN public.classes c_pass ON e_pass.class_id = c_pass.class_id
            WHERE e_pass.student_id = p_student_id
              AND c_pass.course_id = sdc.course_id
              AND e_pass.pass = TRUE
        )
        -- Điều kiện 2: Sinh viên có ít nhất một bản ghi là 'pass = FALSE' cho môn học này
        -- Điều này để phân biệt với trường hợp môn học chưa có điểm hoặc đang học (pass vẫn là default false)
        -- mà thực sự đã có kết quả là trượt.
        AND EXISTS (
            SELECT 1
            FROM public.enrollments e_fail
            JOIN public.classes c_fail ON e_fail.class_id = c_fail.class_id
            WHERE e_fail.student_id = p_student_id
              AND c_fail.course_id = sdc.course_id
              AND e_fail.pass = FALSE
        );

    -- Xác định warning level dựa trên số môn trượt
    IF v_failed_courses_count < 3 THEN
        v_warning_level := 0; -- 0, 1, 2 môn trượt
    ELSIF v_failed_courses_count < 6 THEN
        v_warning_level := 1; -- 3, 4, 5 môn trượt
    ELSIF v_failed_courses_count < 9 THEN
        v_warning_level := 2; -- 6, 7, 8 môn trượt
    ELSE
        v_warning_level := 2; -- Từ 9 môn trượt trở lên, vẫn là mức 2 (theo cách hiểu đề bài "<9 môn" cho mức 2)
    END IF;

    RETURN v_warning_level;
END;



--9 Câu 9: Viết trigger để gọi function 5 mỗi khi nhập điểm.
-- "Nhập điểm" được hiểu là có sự thay đổi (INSERT hoặc UPDATE) trong bảng enrollments
-- mà có thể ảnh hưởng đến trạng thái 'pass' của sinh viên, từ đó ảnh hưởng đến warning_level.
-- Trigger sẽ cập nhật cột warning_level trong bảng students.
CREATE OR REPLACE FUNCTION update_student_warning_level_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
    v_student_id_affected INT;
    v_new_warning_level INT;
BEGIN
    -- Xác định student_id bị ảnh hưởng
    IF TG_OP = 'DELETE' THEN
        -- Nếu là DELETE, student_id lấy từ OLD record
        v_student_id_affected := OLD.student_id;
    ELSE
        -- Nếu là INSERT hoặc UPDATE, student_id lấy từ NEW record
        v_student_id_affected := NEW.student_id;
    END IF;

    -- Tính toán warning level mới cho sinh viên bị ảnh hưởng
    v_new_warning_level := calculate_student_warning_level(v_student_id_affected);

    -- Cập nhật cột warning_level trong bảng students
    -- Chỉ cập nhật nếu warning_level thực sự thay đổi để tránh ghi không cần thiết
    -- và các vòng lặp trigger tiềm ẩn nếu có trigger khác trên bảng students.
    UPDATE public.students
    SET warning_level = v_new_warning_level
    WHERE student_id = v_student_id_affected
      AND warning_level IS DISTINCT FROM v_new_warning_level; -- Chỉ UPDATE nếu giá trị thay đổi

    -- Đối với AFTER trigger, giá trị trả về thường được bỏ qua.
    -- Trả về NULL cho AFTER trigger là phổ biến.
    RETURN NULL; -- Hoặc RETURN NEW; cho INSERT/UPDATE, RETURN OLD; cho DELETE nếu cần.
END;

