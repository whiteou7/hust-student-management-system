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
