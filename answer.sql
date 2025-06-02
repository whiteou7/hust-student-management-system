--CÂU 6
CREATE OR REPLACE FUNCTION check_enrollment_eligibility(
    p_student_id INTEGER,
    p_class_id INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_warning_level INTEGER;
    v_current_credits INTEGER;
    v_class_capacity INTEGER;
    v_enrolled_count INTEGER;
    v_class_status TEXT;
    v_course_credit INTEGER;
    v_max_allowed_credits INTEGER;
    v_total_program_credits INTEGER;
BEGIN
    /* 
    Lấy mức cảnh báo của sinh viên
    0: Không cảnh báo
    1: Cảnh báo nhẹ (giới hạn 75% tín chỉ)
    2: Cảnh báo nặng (giới hạn 50% tín chỉ)
    */
    SELECT warning_level INTO v_warning_level
    FROM students
    WHERE student_id = p_student_id;
    
    -- Lấy thông tin sức chứa, số lượng đã đăng ký, trạng thái và số tín chỉ của lớp
    SELECT c.capacity, c.enrolled_count, c.status, cr.credit
    INTO v_class_capacity, v_enrolled_count, v_class_status, v_course_credit
    FROM classes c
    JOIN courses cr ON c.course_id = cr.course_id
    WHERE c.class_id = p_class_id;
    
    -- Kiểm tra điều kiện cơ bản: lớp còn chỗ và đang mở đăng ký
    IF v_enrolled_count >= v_class_capacity OR v_class_status != 'open' THEN
        RETURN FALSE;
    END IF;
    
    -- Tính tổng số tín chỉ sinh viên đã đăng ký trong học kỳ hiện tại
    SELECT COALESCE(SUM(cr.credit), 0) INTO v_current_credits
    FROM enrollments e
    JOIN classes cl ON e.class_id = cl.class_id
    JOIN courses cr ON cl.course_id = cr.course_id
    WHERE e.student_id = p_student_id AND cl.semester = (
        SELECT semester FROM classes WHERE class_id = p_class_id
    );
    
    -- Lấy tổng số tín chỉ yêu cầu của chương trình học
    SELECT total_credit INTO v_total_program_credits
    FROM programs
    WHERE program_id = (SELECT program_id FROM students WHERE student_id = p_student_id);
    
    -- Xác định số tín chỉ tối đa được đăng ký dựa trên mức cảnh báo
    CASE v_warning_level
        WHEN 0 THEN v_max_allowed_credits := v_total_program_credits; -- Không giới hạn
        WHEN 1 THEN v_max_allowed_credits := CEIL(v_total_program_credits * 0.75); -- Giới hạn 75%
        WHEN 2 THEN v_max_allowed_credits := CEIL(v_total_program_credits * 0.5); -- Giới hạn 50%
        ELSE RETURN FALSE; -- Mức cảnh báo không hợp lệ
    END CASE;
    
    -- Kiểm tra nếu đăng ký thêm sẽ vượt quá giới hạn tín chỉ
    IF (v_current_credits + v_course_credit) > v_max_allowed_credits THEN
        RETURN FALSE;
    END IF;
    
    -- Nếu tất cả điều kiện đều thỏa mãn
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


--CÂU 7
CREATE OR REPLACE PROCEDURE enroll_student_in_class(
    p_student_id INTEGER,
    p_class_id INTEGER
) AS $$
DECLARE
    v_eligible BOOLEAN;
BEGIN
    /* 
    Kiểm tra sinh viên có đủ điều kiện đăng ký không
    Sử dụng function check_enrollment_eligibility đã tạo ở trên
    */
    v_eligible := check_enrollment_eligibility(p_student_id, p_class_id);
    
    -- Nếu không đủ điều kiện, báo lỗi
    IF NOT v_eligible THEN
        RAISE EXCEPTION 'Student does not meet enrollment requirements for this class';
    END IF;
    
    -- Bắt đầu transaction để đảm bảo tính toàn vẹn dữ liệu
    BEGIN
        -- Thêm bản ghi đăng ký vào bảng enrollments
        INSERT INTO enrollments (student_id, class_id, mid_term, final_term, pass)
        VALUES (p_student_id, p_class_id, NULL, NULL, NULL);
        
        -- Xác nhận transaction nếu thành công
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback nếu có lỗi xảy ra
            ROLLBACK;
            RAISE EXCEPTION 'Enrollment failed: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;
