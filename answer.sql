---4
DELIMITER //

CREATE TRIGGER increase_student_debt
AFTER INSERT ON enrollments
FOR EACH ROW
BEGIN
    DECLARE class_fee DECIMAL(10, 2);

    -- Lấy học phí của lớp vừa đăng ký
    SELECT fee INTO class_fee
    FROM classes
    WHERE class_id = NEW.class_id;

    -- Tăng tổng học phí (debt) của học sinh
    UPDATE students
    SET debt = debt + class_fee
    WHERE student_id = NEW.student_id;
END;
//

DELIMITER ;

---8
DELIMITER $$

CREATE PROCEDURE CheckGraduation()
BEGIN
    -- Cập nhật trạng thái tốt nghiệp
    UPDATE students
    SET graduated = 'graduated'
    WHERE credits_completed >= total_credits_required AND debt = 0;

    -- Cập nhật trạng thái chưa tốt nghiệp
    UPDATE students
    SET graduated = 'enrolled'
    WHERE credits_completed < total_credits_required OR debt > 0;
END $$

DELIMITER ;
