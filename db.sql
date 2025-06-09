--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: class_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.class_status AS ENUM (
    'open',
    'closed'
);


ALTER TYPE public.class_status OWNER TO postgres;

--
-- Name: day_of_week; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.day_of_week AS ENUM (
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
);


ALTER TYPE public.day_of_week OWNER TO postgres;

--
-- Name: graduation_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.graduation_status AS ENUM (
    'graduated',
    'enrolled',
    'expelled'
);


ALTER TYPE public.graduation_status OWNER TO postgres;

--
-- Name: role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.role AS ENUM (
    'student',
    'teacher'
);


ALTER TYPE public.role OWNER TO postgres;

--
-- Name: adjust_student_debt(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.adjust_student_debt() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.adjust_student_debt() OWNER TO postgres;

--
-- Name: calculate_accumulated_credit(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_accumulated_credit(student_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  total_credits INTEGER := 0;
BEGIN
  SELECT 
    COALESCE(SUM(c.credit), 0)
  INTO total_credits
  FROM enrollments_view e
  JOIN classes cl ON e.class_id = cl.class_id
  JOIN courses c ON cl.course_id = c.course_id
  WHERE e.student_id = calculate_accumulated_credit.student_id AND e.pass = TRUE;

  RETURN total_credits;
END;
$$;


ALTER FUNCTION public.calculate_accumulated_credit(student_id integer) OWNER TO postgres;

--
-- Name: calculate_cpa(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_cpa(student_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
  total_weighted_score NUMERIC := 0;
  total_credits INTEGER := 0;
  result NUMERIC := NULL;
BEGIN
  WITH best_attempts AS (
    SELECT DISTINCT ON (c.course_id)
      c.course_id,
      c.credit,
      e.result
    FROM enrollments_view e
    JOIN classes cl ON e.class_id = cl.class_id
    JOIN courses c ON cl.course_id = c.course_id
    WHERE e.student_id = calculate_cpa.student_id
    ORDER BY c.course_id, ((e.mid_term + e.final_term) / 2.0) DESC
  )
  SELECT 
    COALESCE(SUM(credit), 0),
    COALESCE(SUM(credit * best_attempts.result), 0)
  INTO total_credits, total_weighted_score
  FROM best_attempts;

  IF total_credits > 0 THEN
    result := total_weighted_score / total_credits;
  END IF;

  RETURN result;
END;
$$;


ALTER FUNCTION public.calculate_cpa(student_id integer) OWNER TO postgres;

--
-- Name: calculate_gpa(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_gpa(student_id integer, semester character varying) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
  total_weighted_score NUMERIC := 0;
  total_credits INTEGER := 0;
  result NUMERIC := NULL;
BEGIN
  WITH best_attempts AS (
    SELECT DISTINCT ON (c.course_id)
      c.course_id,
      c.credit,
      e.result
    FROM enrollments_view e
    JOIN classes cl ON e.class_id = cl.class_id
    JOIN courses c ON cl.course_id = c.course_id
    WHERE e.student_id = calculate_gpa.student_id
      AND cl.semester = calculate_gpa.semester
    ORDER BY c.course_id, ((e.mid_term + e.final_term) / 2.0) DESC
  )
  SELECT 
    COALESCE(SUM(credit), 0),
    COALESCE(SUM(credit * best_attempts.result), 0)
  INTO total_credits, total_weighted_score
  FROM best_attempts;

  IF total_credits > 0 THEN
    result := total_weighted_score / total_credits;
  END IF;

  RETURN result;
END;
$$;


ALTER FUNCTION public.calculate_gpa(student_id integer, semester character varying) OWNER TO postgres;

--
-- Name: calculate_pass_status(numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_pass_status(mid_term numeric, final_term numeric) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    pass_status BOOLEAN;
BEGIN
    IF mid_term IS NULL OR final_term IS NULL THEN
        pass_status := NULL;
    ELSIF mid_term < 3 OR final_term < 4 THEN
        pass_status := FALSE;
    ELSE
        pass_status := TRUE;
    END IF;
    
    RETURN pass_status;
END;
$$;


ALTER FUNCTION public.calculate_pass_status(mid_term numeric, final_term numeric) OWNER TO postgres;

--
-- Name: calculate_result(numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_result(mid_term numeric, final_term numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    result NUMERIC;
BEGIN
    IF mid_term IS NULL OR final_term IS NULL THEN
        result := NULL;
    ELSE
        result := ROUND((mid_term + final_term) / 2.0, 2);
    END IF;
    RETURN result;
END;
$$;


ALTER FUNCTION public.calculate_result(mid_term numeric, final_term numeric) OWNER TO postgres;

--
-- Name: calculate_student_warning_level(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_student_warning_level(p_student_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
            FROM public.enrollments_view e_pass
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
            FROM public.enrollments_view e_fail
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
$$;


ALTER FUNCTION public.calculate_student_warning_level(p_student_id integer) OWNER TO postgres;

--
-- Name: check_enrollment_eligibility(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_enrollment_eligibility(p_student_id integer, p_class_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
    FROM students_view
    WHERE student_id = p_student_id;
    
    -- Lấy thông tin sức chứa, số lượng đã đăng ký, trạng thái và số tín chỉ của lớp
    SELECT c.capacity, c.enrolled_count, c.status, cr.credit
    INTO v_class_capacity, v_enrolled_count, v_class_status, v_course_credit
    FROM classes_view c
    JOIN courses cr ON c.course_id = cr.course_id
    WHERE c.class_id = p_class_id;
    
    -- Kiểm tra điều kiện cơ bản: lớp còn chỗ và đang mở đăng ký
    IF v_enrolled_count >= v_class_capacity OR v_class_status != 'open' THEN
        RETURN FALSE;
    END IF;
    
    -- Tính tổng số tín chỉ sinh viên đã đăng ký trong học kỳ hiện tại
    SELECT COALESCE(SUM(cr.credit), 0) INTO v_current_credits
    FROM enrollments_view e
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
$$;


ALTER FUNCTION public.check_enrollment_eligibility(p_student_id integer, p_class_id integer) OWNER TO postgres;

--
-- Name: check_graduation_status(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_graduation_status(p_student_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_program_id INT;
    v_completed_course INT;
    v_total_course INT;
    v_completed_credit INT;
    v_total_credit INT;
BEGIN
    -- Get the student's program ID
    SELECT program_id INTO v_program_id
    FROM students_view
    WHERE student_id = p_student_id;
    RAISE NOTICE 'program_id = %', v_program_id;

    -- Count distinct completed courses that are part of program requirements
    SELECT COUNT(DISTINCT c.course_id) INTO v_completed_course
    FROM enrollments_view e
    JOIN classes c ON e.class_id = c.class_id
    RIGHT JOIN program_requirements pr ON pr.course_id = c.course_id
    WHERE e.student_id = p_student_id
	  AND pr.program_id = v_program_id
      AND e.pass = TRUE;
    RAISE NOTICE 'completed_course = %', v_completed_course;

    -- Get total required courses in the program
    SELECT COUNT(course_id) INTO v_total_course
    FROM program_requirements
    WHERE program_id = v_program_id;
    RAISE NOTICE 'total_course = %', v_total_course;

    -- Get total completed credits, avoiding duplicate course_ids
    SELECT accumulated_credit INTO v_completed_credit
    FROM students_view 
	WHERE student_id = p_student_id;
    RAISE NOTICE 'completed_credit = %', v_completed_credit;

    -- Get the required total credit for the program
    SELECT total_credit INTO v_total_credit
    FROM programs
    WHERE program_id = v_program_id;
    RAISE NOTICE 'total_credit = %', v_total_credit;

    -- Return graduation status
    RETURN v_completed_course >= v_total_course
           AND v_completed_credit >= v_total_credit;
END;
$$;


ALTER FUNCTION public.check_graduation_status(p_student_id integer) OWNER TO postgres;

--
-- Name: enroll_student_in_class(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.enroll_student_in_class(IN p_student_id integer, IN p_class_id integer)
    LANGUAGE plpgsql
    AS $$
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
        INSERT INTO enrollments (student_id, class_id, mid_term, final_term)
        VALUES (p_student_id, p_class_id, NULL, NULL);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Enrollment failed: %', SQLERRM;
    END;
END;
$$;


ALTER PROCEDURE public.enroll_student_in_class(IN p_student_id integer, IN p_class_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: classes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.classes (
    class_id integer NOT NULL,
    teacher_id integer,
    course_id character varying(6) NOT NULL,
    capacity integer DEFAULT 0 NOT NULL,
    semester character varying NOT NULL,
    status public.class_status NOT NULL,
    day_of_week public.day_of_week NOT NULL,
    location text NOT NULL
);


ALTER TABLE public.classes OWNER TO postgres;

--
-- Name: classes_class_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.classes_class_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.classes_class_id_seq OWNER TO postgres;

--
-- Name: classes_class_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.classes_class_id_seq OWNED BY public.classes.class_id;


--
-- Name: classes_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.classes_view AS
SELECT
    NULL::integer AS class_id,
    NULL::integer AS teacher_id,
    NULL::character varying(6) AS course_id,
    NULL::integer AS capacity,
    NULL::character varying AS semester,
    NULL::public.class_status AS status,
    NULL::public.day_of_week AS day_of_week,
    NULL::text AS location,
    NULL::bigint AS enrolled_count;


ALTER VIEW public.classes_view OWNER TO postgres;

--
-- Name: configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configs (
    current_semester character varying(255),
    next_semester character varying(255),
    class_reg_status boolean
);


ALTER TABLE public.configs OWNER TO postgres;

--
-- Name: courses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.courses (
    course_id character varying(6) NOT NULL,
    course_name character varying NOT NULL,
    credit integer NOT NULL,
    tuition_per_credit integer NOT NULL,
    school_id integer NOT NULL,
    course_description character varying
);


ALTER TABLE public.courses OWNER TO postgres;

--
-- Name: enrollments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.enrollments (
    student_id integer NOT NULL,
    class_id integer NOT NULL,
    mid_term numeric(4,2),
    final_term numeric(4,2),
    CONSTRAINT check_final_term CHECK (((final_term IS NULL) OR ((final_term >= 0.00) AND (final_term <= 10.00)))),
    CONSTRAINT check_mid_term CHECK (((mid_term IS NULL) OR ((mid_term >= 0.00) AND (mid_term <= 10.00))))
);


ALTER TABLE public.enrollments OWNER TO postgres;

--
-- Name: enrollments_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.enrollments_view AS
 SELECT student_id,
    class_id,
    mid_term,
    final_term,
    public.calculate_result(mid_term, final_term) AS result,
    public.calculate_pass_status(mid_term, final_term) AS pass
   FROM public.enrollments;


ALTER VIEW public.enrollments_view OWNER TO postgres;

--
-- Name: program_requirements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.program_requirements (
    program_id integer NOT NULL,
    course_id character varying(6) NOT NULL
);


ALTER TABLE public.program_requirements OWNER TO postgres;

--
-- Name: programs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.programs (
    program_id integer NOT NULL,
    program_name character varying NOT NULL,
    total_credit integer NOT NULL
);


ALTER TABLE public.programs OWNER TO postgres;

--
-- Name: programs_program_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.programs_program_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.programs_program_id_seq OWNER TO postgres;

--
-- Name: programs_program_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.programs_program_id_seq OWNED BY public.programs.program_id;


--
-- Name: schools; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schools (
    school_id integer NOT NULL,
    school_name character varying NOT NULL
);


ALTER TABLE public.schools OWNER TO postgres;

--
-- Name: schools_school_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.schools_school_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.schools_school_id_seq OWNER TO postgres;

--
-- Name: schools_school_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.schools_school_id_seq OWNED BY public.schools.school_id;


--
-- Name: students; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.students (
    student_id integer NOT NULL,
    program_id integer NOT NULL,
    enrolled_year integer NOT NULL,
    graduated public.graduation_status DEFAULT 'enrolled'::public.graduation_status,
    debt integer DEFAULT 0
);


ALTER TABLE public.students OWNER TO postgres;

--
-- Name: students_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.students_view AS
 SELECT student_id,
    program_id,
    enrolled_year,
    graduated,
    debt,
    public.calculate_student_warning_level(student_id) AS warning_level,
    public.calculate_accumulated_credit(student_id) AS accumulated_credit,
    public.calculate_cpa(student_id) AS cpa
   FROM public.students;


ALTER VIEW public.students_view OWNER TO postgres;

--
-- Name: teachers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teachers (
    teacher_id integer NOT NULL,
    school_id integer NOT NULL,
    hired_year integer,
    qualification character varying,
    profession character varying,
    "position" character varying
);


ALTER TABLE public.teachers OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    email character varying,
    password character varying,
    role public.role NOT NULL,
    date_of_birth date,
    address character varying
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: classes class_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classes ALTER COLUMN class_id SET DEFAULT nextval('public.classes_class_id_seq'::regclass);


--
-- Name: programs program_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programs ALTER COLUMN program_id SET DEFAULT nextval('public.programs_program_id_seq'::regclass);


--
-- Name: schools school_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schools ALTER COLUMN school_id SET DEFAULT nextval('public.schools_school_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Data for Name: classes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.classes (class_id, teacher_id, course_id, capacity, semester, status, day_of_week, location) FROM stdin;
1	240	LA0403	30	2022.2	closed	Thursday	Room 008
2	207	LA0401	40	2024.2	closed	Thursday	Room 009
3	226	BU0305	50	2024.2	closed	Wednesday	Room 025
4	221	LA0406	60	2021.2	closed	Tuesday	Room 029
5	217	CS0105	39	2024.1	closed	Saturday	Room 010
6	230	CS0104	49	2024.2	closed	Monday	Room 012
7	214	CS0107	59	2022.2	closed	Tuesday	Room 029
8	216	EN0204	38	2023.1	closed	Wednesday	Room 005
9	225	CS0104	48	2024.2	closed	Saturday	Room 003
10	236	LA0410	58	2021.1	closed	Monday	Room 008
11	222	BU0306	37	2024.1	closed	Thursday	Room 027
12	218	LA0401	47	2021.2	closed	Tuesday	Room 018
13	242	CS0107	57	2021.1	closed	Saturday	Room 003
14	230	PH0509	36	2023.1	closed	Tuesday	Room 017
15	232	CS0104	46	2023.1	closed	Thursday	Room 011
16	203	PH0501	56	2023.1	closed	Thursday	Room 006
17	233	BU0305	35	2022.2	closed	Wednesday	Room 003
18	207	PH0506	45	2023.2	closed	Saturday	Room 007
19	201	CS0105	55	2024.2	closed	Friday	Room 012
20	222	EN0206	34	2022.1	closed	Monday	Room 003
21	244	LA0403	44	2021.2	closed	Saturday	Room 014
22	209	BU0304	54	2023.2	closed	Saturday	Room 009
23	225	BU0305	33	2022.1	closed	Monday	Room 018
24	225	LA0404	43	2021.1	closed	Monday	Room 029
25	221	EN0202	53	2023.2	closed	Thursday	Room 001
26	210	PH0502	32	2021.2	closed	Wednesday	Room 025
27	249	LA0403	42	2021.1	closed	Wednesday	Room 020
28	234	EN0202	52	2022.1	closed	Tuesday	Room 006
29	237	EN0201	31	2022.1	closed	Monday	Room 007
30	212	LA0409	41	2022.1	closed	Tuesday	Room 008
31	206	PH0506	51	2022.1	closed	Saturday	Room 007
32	230	EN0207	30	2023.1	closed	Thursday	Room 001
33	234	CS0105	40	2022.2	closed	Monday	Room 001
34	230	PH0504	50	2021.2	closed	Tuesday	Room 004
35	249	CS0110	60	2021.1	closed	Tuesday	Room 025
36	225	EN0205	39	2022.1	closed	Thursday	Room 010
37	212	CS0104	49	2021.1	closed	Monday	Room 029
38	218	PH0508	59	2022.2	closed	Monday	Room 020
39	217	EN0205	38	2023.2	closed	Wednesday	Room 004
40	208	CS0106	48	2023.2	closed	Friday	Room 024
41	238	EN0204	58	2021.1	closed	Saturday	Room 020
42	241	BU0308	37	2024.2	closed	Friday	Room 021
43	231	CS0110	47	2023.1	closed	Thursday	Room 027
44	222	EN0206	57	2023.1	closed	Tuesday	Room 017
45	215	PH0501	36	2022.1	closed	Monday	Room 003
46	236	EN0203	46	2022.1	closed	Wednesday	Room 004
47	243	PH0506	56	2021.2	closed	Wednesday	Room 026
48	240	BU0306	35	2022.1	closed	Saturday	Room 003
49	225	BU0305	45	2022.1	closed	Friday	Room 005
50	228	PH0504	55	2024.1	closed	Wednesday	Room 006
51	245	BU0304	34	2023.1	closed	Friday	Room 007
52	221	LA0405	44	2021.2	closed	Saturday	Room 009
53	225	LA0406	54	2021.1	closed	Thursday	Room 008
54	204	CS0109	33	2023.2	closed	Thursday	Room 007
55	243	BU0303	43	2021.2	closed	Thursday	Room 021
56	223	BU0308	53	2022.2	closed	Monday	Room 001
57	205	BU0310	32	2022.2	closed	Saturday	Room 024
58	225	EN0203	42	2023.2	closed	Saturday	Room 024
59	228	LA0409	52	2021.1	closed	Wednesday	Room 001
60	226	EN0203	31	2022.2	closed	Tuesday	Room 009
61	230	CS0104	41	2023.2	closed	Monday	Room 027
62	236	BU0302	51	2022.1	closed	Monday	Room 015
63	219	CS0109	30	2024.2	closed	Friday	Room 020
64	203	LA0407	40	2022.1	closed	Saturday	Room 014
65	242	PH0504	50	2022.1	closed	Wednesday	Room 027
66	247	LA0410	60	2023.2	closed	Friday	Room 001
67	250	CS0103	39	2024.2	closed	Thursday	Room 006
68	250	PH0510	49	2021.2	closed	Monday	Room 009
69	247	BU0309	59	2022.2	closed	Monday	Room 021
70	222	CS0101	38	2022.2	closed	Thursday	Room 021
71	201	EN0204	48	2022.1	closed	Wednesday	Room 017
72	205	EN0204	58	2023.2	closed	Wednesday	Room 026
73	227	EN0206	37	2023.2	closed	Monday	Room 013
74	207	LA0401	47	2021.2	closed	Saturday	Room 006
75	243	CS0105	57	2021.1	closed	Monday	Room 005
76	220	PH0502	36	2024.2	closed	Wednesday	Room 011
77	202	CS0101	46	2021.2	closed	Wednesday	Room 030
78	247	BU0306	56	2021.2	closed	Monday	Room 010
79	224	EN0209	35	2022.2	closed	Thursday	Room 011
80	217	BU0305	45	2021.2	closed	Saturday	Room 029
81	242	EN0209	55	2022.2	closed	Friday	Room 028
82	219	PH0510	34	2024.2	closed	Tuesday	Room 026
83	246	PH0506	44	2022.2	closed	Thursday	Room 025
84	208	CS0106	54	2024.1	closed	Thursday	Room 026
85	205	PH0503	33	2021.1	closed	Thursday	Room 027
86	218	LA0403	43	2022.1	closed	Tuesday	Room 010
87	239	EN0207	53	2022.1	closed	Wednesday	Room 026
88	208	PH0506	32	2023.1	closed	Friday	Room 026
89	232	PH0506	42	2022.2	closed	Friday	Room 024
90	247	BU0309	52	2024.2	closed	Tuesday	Room 025
91	210	EN0209	31	2024.2	closed	Wednesday	Room 029
92	210	LA0401	41	2022.2	closed	Saturday	Room 009
93	240	EN0209	51	2021.1	closed	Monday	Room 023
94	208	BU0310	30	2022.2	closed	Tuesday	Room 002
95	216	LA0407	40	2021.1	closed	Wednesday	Room 012
96	228	EN0208	50	2021.2	closed	Saturday	Room 010
97	211	BU0303	60	2022.1	closed	Wednesday	Room 012
98	230	CS0102	39	2021.2	closed	Saturday	Room 002
99	221	LA0409	49	2023.2	closed	Saturday	Room 014
100	206	BU0305	59	2023.2	closed	Wednesday	Room 022
101	230	EN0210	38	2024.1	closed	Friday	Room 026
102	239	PH0506	48	2024.1	closed	Wednesday	Room 006
103	208	PH0508	58	2023.1	closed	Saturday	Room 027
104	231	LA0408	37	2021.1	closed	Thursday	Room 017
105	235	CS0108	47	2024.2	closed	Friday	Room 013
106	245	CS0105	57	2024.2	closed	Saturday	Room 001
107	213	EN0202	36	2021.2	closed	Wednesday	Room 026
108	234	PH0501	46	2024.1	closed	Tuesday	Room 006
109	232	PH0505	56	2023.2	closed	Wednesday	Room 015
110	237	LA0406	35	2021.1	closed	Tuesday	Room 006
111	235	BU0305	45	2021.2	closed	Thursday	Room 017
112	219	BU0302	55	2022.1	closed	Tuesday	Room 020
113	235	PH0502	34	2023.1	closed	Wednesday	Room 018
114	213	CS0107	44	2021.1	closed	Thursday	Room 006
115	221	PH0505	54	2022.2	closed	Tuesday	Room 006
116	245	BU0303	33	2024.2	closed	Thursday	Room 015
117	201	BU0308	43	2024.1	closed	Thursday	Room 022
118	246	BU0304	53	2021.1	closed	Tuesday	Room 030
119	207	PH0510	32	2022.1	closed	Friday	Room 017
120	208	LA0403	42	2021.2	closed	Friday	Room 003
121	239	EN0205	52	2021.1	closed	Saturday	Room 023
122	213	BU0308	31	2022.1	closed	Monday	Room 018
123	250	CS0108	41	2024.2	closed	Thursday	Room 014
124	213	BU0306	51	2022.2	closed	Monday	Room 029
125	230	PH0506	30	2023.1	closed	Saturday	Room 009
126	215	PH0504	40	2022.1	closed	Friday	Room 020
127	227	LA0407	50	2024.2	closed	Wednesday	Room 019
128	219	CS0100	60	2024.1	closed	Wednesday	Room 023
129	228	BU0309	39	2024.2	closed	Thursday	Room 023
130	221	LA0402	49	2021.2	closed	Thursday	Room 017
131	215	CS0105	59	2022.2	closed	Friday	Room 019
132	236	PH0504	38	2024.1	closed	Thursday	Room 005
133	232	CS0106	48	2022.1	closed	Wednesday	Room 020
134	224	CS0109	58	2022.2	closed	Saturday	Room 022
135	239	LA0401	37	2022.1	closed	Saturday	Room 017
136	231	BU0304	47	2024.1	closed	Monday	Room 011
137	250	CS0101	57	2024.2	closed	Friday	Room 004
138	228	EN0205	36	2024.1	closed	Monday	Room 024
139	206	EN0210	46	2021.2	closed	Thursday	Room 029
140	214	CS0106	56	2021.2	closed	Friday	Room 019
141	238	EN0209	35	2024.1	closed	Monday	Room 002
142	241	CS0100	45	2023.2	closed	Monday	Room 003
143	242	EN0209	55	2021.1	closed	Friday	Room 001
144	204	BU0302	34	2021.1	closed	Thursday	Room 019
145	214	EN0209	44	2022.2	closed	Wednesday	Room 018
146	238	EN0202	54	2024.2	closed	Saturday	Room 019
147	231	CS0107	33	2021.2	closed	Wednesday	Room 010
148	238	EN0208	43	2021.1	closed	Thursday	Room 028
149	242	LA0407	53	2022.2	closed	Tuesday	Room 021
150	212	BU0306	32	2023.1	closed	Monday	Room 007
151	207	BU0307	42	2021.1	closed	Monday	Room 029
152	217	CS0104	52	2023.2	closed	Saturday	Room 020
153	207	EN0209	31	2022.1	closed	Thursday	Room 016
154	244	LA0407	41	2024.1	closed	Monday	Room 023
155	212	CS0108	51	2021.1	closed	Thursday	Room 028
156	242	LA0405	30	2022.1	closed	Thursday	Room 014
157	210	LA0403	40	2022.2	closed	Wednesday	Room 015
158	229	PH0510	50	2022.2	closed	Friday	Room 017
159	225	BU0310	60	2022.1	closed	Wednesday	Room 005
160	207	CS0103	39	2021.2	closed	Monday	Room 024
161	210	EN0203	49	2024.1	closed	Wednesday	Room 028
162	206	PH0505	59	2024.1	closed	Wednesday	Room 023
163	223	PH0501	38	2024.2	closed	Wednesday	Room 029
164	229	BU0308	48	2021.2	closed	Saturday	Room 003
165	225	PH0504	58	2024.2	closed	Monday	Room 028
166	239	CS0106	37	2023.2	closed	Thursday	Room 015
167	234	LA0402	47	2022.2	closed	Wednesday	Room 015
168	234	BU0302	57	2021.2	closed	Tuesday	Room 022
169	207	LA0402	36	2021.2	closed	Thursday	Room 026
170	217	PH0510	46	2022.2	closed	Saturday	Room 007
171	207	CS0100	56	2022.2	closed	Monday	Room 030
172	235	PH0501	35	2024.1	closed	Tuesday	Room 012
173	237	LA0408	45	2024.1	closed	Thursday	Room 023
174	248	EN0209	55	2024.2	closed	Tuesday	Room 009
175	210	EN0205	34	2024.2	closed	Saturday	Room 030
176	221	BU0305	44	2023.1	closed	Thursday	Room 009
177	208	PH0507	54	2021.2	closed	Wednesday	Room 019
178	233	EN0206	33	2021.1	closed	Thursday	Room 008
179	228	LA0403	43	2022.1	closed	Monday	Room 012
180	214	LA0408	53	2023.2	closed	Friday	Room 030
181	249	CS0106	32	2022.2	closed	Wednesday	Room 023
182	206	BU0304	42	2021.1	closed	Friday	Room 012
183	201	LA0405	52	2023.2	closed	Tuesday	Room 009
184	240	LA0404	31	2023.1	closed	Monday	Room 019
185	217	LA0405	41	2024.1	closed	Monday	Room 012
186	217	PH0507	51	2021.2	closed	Thursday	Room 018
187	237	LA0402	30	2021.2	closed	Tuesday	Room 015
188	221	LA0407	40	2024.1	closed	Monday	Room 010
189	202	LA0403	50	2022.2	closed	Saturday	Room 023
190	225	CS0104	60	2024.1	closed	Friday	Room 016
191	242	LA0406	39	2021.2	closed	Monday	Room 004
192	241	EN0206	49	2021.1	closed	Monday	Room 023
193	215	EN0210	59	2021.2	closed	Monday	Room 005
194	215	CS0100	38	2021.1	closed	Monday	Room 013
195	246	PH0508	48	2021.1	closed	Tuesday	Room 004
196	220	PH0501	58	2022.2	closed	Saturday	Room 011
197	202	BU0307	37	2022.2	closed	Tuesday	Room 029
198	250	CS0103	47	2024.2	closed	Wednesday	Room 015
199	202	BU0306	57	2024.2	closed	Wednesday	Room 005
200	212	BU0305	36	2021.2	closed	Saturday	Room 023
201	218	PH0509	46	2023.2	closed	Wednesday	Room 005
202	202	LA0409	56	2022.1	closed	Monday	Room 007
203	243	BU0308	35	2022.2	closed	Saturday	Room 002
204	204	EN0207	45	2024.2	closed	Saturday	Room 005
205	234	EN0206	55	2022.1	closed	Tuesday	Room 013
206	206	CS0107	34	2022.2	closed	Friday	Room 011
207	203	BU0304	44	2023.2	closed	Saturday	Room 015
208	210	LA0403	54	2023.2	closed	Thursday	Room 022
209	205	EN0205	33	2022.1	closed	Wednesday	Room 010
210	215	EN0205	43	2021.1	closed	Friday	Room 009
211	230	EN0209	53	2023.1	closed	Saturday	Room 003
212	225	PH0507	32	2024.1	closed	Friday	Room 029
213	211	EN0206	42	2024.2	closed	Tuesday	Room 023
214	208	LA0409	52	2024.2	closed	Tuesday	Room 002
215	219	CS0100	31	2021.1	closed	Saturday	Room 019
216	247	BU0304	41	2023.2	closed	Monday	Room 020
217	240	LA0406	51	2021.1	closed	Monday	Room 020
218	217	LA0408	30	2022.1	closed	Thursday	Room 009
219	215	PH0504	40	2024.2	closed	Friday	Room 006
220	229	BU0304	50	2021.1	closed	Wednesday	Room 017
221	224	BU0302	60	2021.2	closed	Saturday	Room 025
222	229	BU0302	39	2023.2	closed	Wednesday	Room 019
223	234	PH0509	49	2021.1	closed	Monday	Room 011
224	248	PH0508	59	2021.2	closed	Monday	Room 005
225	243	EN0201	38	2024.1	closed	Friday	Room 020
226	233	PH0504	48	2024.2	closed	Friday	Room 003
227	238	LA0401	58	2023.1	closed	Thursday	Room 029
228	220	BU0309	37	2023.2	closed	Wednesday	Room 024
229	219	BU0307	47	2021.1	closed	Saturday	Room 004
230	232	CS0107	57	2022.2	closed	Friday	Room 003
231	221	LA0403	36	2024.1	closed	Monday	Room 027
232	225	BU0306	46	2024.2	closed	Tuesday	Room 018
233	238	LA0410	56	2023.1	closed	Wednesday	Room 011
234	235	EN0205	35	2024.2	closed	Thursday	Room 005
235	228	PH0509	45	2021.1	closed	Monday	Room 010
236	226	EN0208	55	2023.2	closed	Tuesday	Room 015
237	220	PH0503	34	2023.2	closed	Saturday	Room 030
238	222	EN0205	44	2023.2	closed	Thursday	Room 011
239	248	BU0302	54	2024.2	closed	Friday	Room 008
240	208	PH0502	33	2023.2	closed	Thursday	Room 011
241	209	EN0202	43	2024.1	closed	Friday	Room 014
242	215	EN0205	53	2024.2	closed	Friday	Room 025
243	248	CS0103	32	2022.1	closed	Monday	Room 029
244	222	CS0101	42	2021.1	closed	Thursday	Room 027
245	214	CS0105	52	2024.2	closed	Friday	Room 001
246	208	EN0201	31	2022.1	closed	Monday	Room 022
247	219	PH0507	41	2022.2	closed	Wednesday	Room 003
248	210	PH0510	51	2023.1	closed	Saturday	Room 025
249	235	LA0410	30	2023.1	closed	Saturday	Room 019
250	239	BU0306	40	2022.2	closed	Saturday	Room 026
251	209	CS0101	50	2023.2	closed	Monday	Room 026
252	227	BU0309	60	2024.2	closed	Thursday	Room 008
253	236	PH0504	39	2021.1	closed	Thursday	Room 027
254	215	BU0308	49	2024.2	closed	Monday	Room 023
255	202	PH0508	59	2024.2	closed	Wednesday	Room 010
256	207	BU0309	38	2024.2	closed	Monday	Room 030
257	206	PH0509	48	2021.1	closed	Thursday	Room 022
258	229	CS0100	58	2021.2	closed	Tuesday	Room 002
259	213	BU0307	37	2022.2	closed	Tuesday	Room 013
260	211	BU0307	47	2021.2	closed	Tuesday	Room 013
261	220	CS0109	57	2022.2	closed	Thursday	Room 005
262	229	CS0105	36	2021.2	closed	Friday	Room 002
263	204	LA0410	46	2022.2	closed	Thursday	Room 016
264	227	LA0406	56	2024.1	closed	Wednesday	Room 001
265	217	EN0206	35	2024.1	closed	Monday	Room 028
266	211	PH0508	45	2023.1	closed	Thursday	Room 028
267	221	BU0306	55	2021.2	closed	Saturday	Room 018
268	223	CS0108	34	2022.1	closed	Saturday	Room 003
269	216	LA0401	44	2024.2	closed	Tuesday	Room 002
270	236	PH0504	54	2023.1	closed	Wednesday	Room 004
271	248	LA0404	33	2022.1	closed	Saturday	Room 025
272	242	PH0503	43	2022.2	closed	Saturday	Room 026
273	244	BU0306	53	2022.2	closed	Friday	Room 018
274	205	BU0307	32	2024.1	closed	Wednesday	Room 012
275	210	BU0305	42	2022.2	closed	Monday	Room 028
276	232	CS0105	52	2024.2	closed	Thursday	Room 021
277	232	LA0404	31	2024.2	closed	Monday	Room 021
278	214	CS0110	41	2023.1	closed	Monday	Room 021
279	249	CS0101	51	2022.2	closed	Friday	Room 010
280	237	BU0310	30	2024.1	closed	Thursday	Room 008
281	221	CS0103	40	2024.1	closed	Monday	Room 012
282	206	BU0307	50	2024.1	closed	Tuesday	Room 018
283	239	LA0407	60	2023.1	closed	Thursday	Room 029
284	204	PH0510	39	2023.2	closed	Wednesday	Room 026
285	218	CS0103	49	2021.1	closed	Saturday	Room 023
286	225	CS0108	59	2024.1	closed	Monday	Room 001
287	241	CS0107	38	2021.1	closed	Thursday	Room 017
288	238	BU0302	48	2021.2	closed	Wednesday	Room 010
289	218	PH0501	58	2024.1	closed	Tuesday	Room 008
290	221	EN0201	37	2021.2	closed	Wednesday	Room 006
291	206	BU0305	47	2023.2	closed	Wednesday	Room 003
292	212	EN0205	57	2023.2	closed	Tuesday	Room 001
293	211	EN0205	36	2022.2	closed	Saturday	Room 010
294	225	LA0406	46	2023.2	closed	Saturday	Room 002
295	215	CS0100	56	2021.2	closed	Saturday	Room 006
296	227	CS0108	35	2021.1	closed	Thursday	Room 001
297	235	BU0310	45	2023.2	closed	Thursday	Room 023
298	210	EN0202	55	2024.1	closed	Monday	Room 019
299	214	EN0209	34	2021.2	closed	Monday	Room 029
300	234	CS0102	44	2024.1	closed	Wednesday	Room 029
301	226	CS0103	54	2023.2	closed	Wednesday	Room 022
302	221	EN0206	33	2022.2	closed	Monday	Room 012
303	216	PH0501	43	2024.2	closed	Wednesday	Room 001
304	205	LA0408	53	2021.2	closed	Thursday	Room 016
305	221	CS0107	32	2024.2	closed	Monday	Room 021
306	206	EN0202	42	2021.1	closed	Saturday	Room 006
307	250	CS0109	52	2023.2	closed	Thursday	Room 016
308	212	LA0407	31	2021.2	closed	Friday	Room 005
309	211	BU0309	41	2023.2	closed	Friday	Room 013
310	224	CS0103	51	2023.1	closed	Friday	Room 008
311	217	EN0202	30	2022.1	closed	Monday	Room 013
312	239	BU0308	40	2023.2	closed	Friday	Room 027
313	230	LA0401	50	2022.1	closed	Wednesday	Room 007
314	245	LA0403	60	2021.2	closed	Monday	Room 013
315	238	BU0303	39	2023.1	closed	Friday	Room 013
316	223	EN0205	49	2024.2	closed	Saturday	Room 019
317	244	LA0409	59	2022.2	closed	Tuesday	Room 001
318	237	BU0303	38	2023.2	closed	Tuesday	Room 009
319	233	BU0310	48	2024.1	closed	Monday	Room 028
320	203	BU0302	58	2022.1	closed	Monday	Room 011
321	249	PH0507	37	2023.2	closed	Tuesday	Room 013
322	239	LA0410	47	2021.1	closed	Thursday	Room 022
323	212	LA0405	57	2023.1	closed	Thursday	Room 017
324	206	BU0308	36	2024.1	closed	Wednesday	Room 013
325	227	CS0104	46	2022.2	closed	Wednesday	Room 006
326	247	LA0402	56	2022.2	closed	Monday	Room 018
327	249	LA0403	35	2021.2	closed	Monday	Room 013
328	204	EN0206	45	2024.1	closed	Wednesday	Room 013
329	208	PH0506	55	2024.1	closed	Monday	Room 024
330	248	BU0310	34	2024.2	closed	Tuesday	Room 020
331	239	EN0208	44	2024.2	closed	Saturday	Room 013
332	235	CS0106	54	2021.1	closed	Saturday	Room 007
333	236	EN0202	33	2024.1	closed	Wednesday	Room 019
334	232	BU0307	43	2024.2	closed	Wednesday	Room 022
335	232	EN0204	53	2022.1	closed	Monday	Room 009
336	233	PH0504	32	2022.1	closed	Wednesday	Room 021
337	233	LA0403	42	2023.1	closed	Wednesday	Room 020
338	237	BU0309	52	2022.2	closed	Wednesday	Room 027
339	240	LA0406	31	2024.2	closed	Thursday	Room 023
340	250	CS0100	41	2023.1	closed	Thursday	Room 011
341	211	LA0402	51	2023.1	closed	Friday	Room 013
342	244	PH0501	30	2023.1	closed	Friday	Room 009
343	237	LA0406	40	2022.2	closed	Tuesday	Room 004
344	231	PH0507	50	2024.2	closed	Saturday	Room 018
345	208	BU0301	60	2024.2	closed	Tuesday	Room 017
346	229	LA0404	39	2021.1	closed	Tuesday	Room 019
347	218	LA0404	49	2023.2	closed	Wednesday	Room 023
348	250	EN0205	59	2024.1	closed	Wednesday	Room 019
349	227	EN0205	38	2022.2	closed	Tuesday	Room 016
350	218	BU0304	48	2024.1	closed	Wednesday	Room 003
351	225	CS0102	58	2022.2	closed	Thursday	Room 025
352	204	CS0107	37	2021.2	closed	Tuesday	Room 009
353	227	EN0204	47	2023.1	closed	Friday	Room 004
354	223	BU0302	57	2022.2	closed	Tuesday	Room 008
355	209	EN0205	36	2021.1	closed	Wednesday	Room 004
356	214	LA0402	46	2023.1	closed	Thursday	Room 016
357	250	PH0508	56	2022.1	closed	Tuesday	Room 002
358	216	PH0508	35	2021.1	closed	Monday	Room 017
359	241	BU0306	45	2024.1	closed	Friday	Room 008
360	222	CS0100	55	2024.2	closed	Tuesday	Room 022
361	206	BU0305	34	2021.2	closed	Monday	Room 004
362	227	PH0508	44	2021.1	closed	Tuesday	Room 028
363	208	LA0409	54	2022.1	closed	Wednesday	Room 015
364	250	BU0309	33	2021.2	closed	Saturday	Room 029
365	234	LA0402	43	2022.1	closed	Wednesday	Room 019
366	231	LA0401	53	2022.1	closed	Friday	Room 011
367	242	CS0107	32	2021.1	closed	Monday	Room 005
368	243	EN0205	42	2023.2	closed	Thursday	Room 011
369	242	EN0208	52	2024.1	closed	Friday	Room 014
370	214	EN0203	31	2024.1	closed	Friday	Room 007
371	247	LA0401	41	2023.1	closed	Friday	Room 005
372	246	EN0203	51	2021.2	closed	Saturday	Room 011
373	245	PH0508	30	2024.2	closed	Friday	Room 013
374	205	LA0403	40	2021.2	closed	Wednesday	Room 029
375	209	LA0402	50	2023.1	closed	Wednesday	Room 014
376	241	EN0206	60	2021.2	closed	Tuesday	Room 003
377	246	PH0510	39	2024.1	closed	Monday	Room 018
378	229	BU0307	49	2023.2	closed	Friday	Room 024
379	246	CS0105	59	2024.2	closed	Saturday	Room 023
380	211	PH0508	38	2023.2	closed	Saturday	Room 026
381	238	CS0101	48	2024.1	closed	Thursday	Room 001
382	243	PH0508	58	2023.2	closed	Saturday	Room 006
383	207	CS0109	37	2022.1	closed	Wednesday	Room 017
384	247	LA0408	47	2023.2	closed	Wednesday	Room 022
385	202	BU0310	57	2024.2	closed	Wednesday	Room 011
386	219	EN0205	36	2024.1	closed	Saturday	Room 012
387	229	CS0110	46	2024.2	closed	Wednesday	Room 001
388	248	BU0302	56	2024.1	closed	Wednesday	Room 008
389	228	EN0207	35	2023.1	closed	Friday	Room 004
390	203	CS0105	45	2024.1	closed	Tuesday	Room 009
391	226	LA0408	55	2022.2	closed	Monday	Room 028
392	236	PH0502	34	2024.1	closed	Tuesday	Room 008
393	223	LA0401	44	2024.2	closed	Friday	Room 028
394	209	PH0506	54	2024.1	closed	Wednesday	Room 004
395	214	EN0205	33	2024.1	closed	Tuesday	Room 006
396	237	LA0407	43	2022.2	closed	Monday	Room 005
397	246	EN0210	53	2024.2	closed	Wednesday	Room 016
398	234	EN0209	32	2023.2	closed	Saturday	Room 005
399	207	LA0409	42	2022.1	closed	Monday	Room 015
400	249	PH0509	52	2023.1	closed	Tuesday	Room 015
401	242	BU0301	31	2023.2	closed	Wednesday	Room 026
402	215	LA0405	41	2024.2	closed	Tuesday	Room 028
403	220	LA0403	51	2024.2	closed	Thursday	Room 021
404	221	CS0106	30	2022.2	closed	Wednesday	Room 012
405	214	PH0506	40	2022.1	closed	Monday	Room 012
406	211	CS0108	50	2021.1	closed	Friday	Room 003
407	226	EN0201	60	2022.2	closed	Wednesday	Room 009
408	227	EN0203	39	2023.2	closed	Monday	Room 013
409	241	CS0103	49	2022.2	closed	Saturday	Room 004
410	227	CS0110	59	2021.2	closed	Monday	Room 024
411	230	LA0407	38	2021.2	closed	Wednesday	Room 029
412	227	BU0305	48	2021.2	closed	Thursday	Room 027
413	221	PH0507	58	2021.1	closed	Wednesday	Room 023
414	224	LA0402	37	2021.2	closed	Wednesday	Room 013
415	225	BU0301	47	2021.2	closed	Tuesday	Room 016
416	247	BU0303	57	2024.1	closed	Friday	Room 008
417	245	LA0410	36	2024.2	closed	Saturday	Room 011
418	246	CS0104	46	2023.1	closed	Wednesday	Room 021
419	243	EN0203	56	2021.1	closed	Friday	Room 007
420	202	BU0302	35	2022.1	closed	Tuesday	Room 024
421	215	CS0105	45	2023.2	closed	Tuesday	Room 026
422	203	LA0406	55	2024.1	closed	Wednesday	Room 009
423	232	PH0509	34	2021.1	closed	Tuesday	Room 012
424	241	EN0202	44	2024.2	closed	Monday	Room 014
425	220	LA0402	54	2023.2	closed	Tuesday	Room 014
426	249	EN0209	33	2023.2	closed	Wednesday	Room 005
427	214	BU0308	43	2021.1	closed	Wednesday	Room 017
428	247	PH0506	53	2021.1	closed	Wednesday	Room 029
429	211	PH0506	32	2021.1	closed	Wednesday	Room 016
430	204	CS0109	42	2021.2	closed	Tuesday	Room 003
431	216	PH0502	52	2023.1	closed	Thursday	Room 010
432	219	PH0506	31	2023.2	closed	Saturday	Room 025
433	247	PH0503	41	2023.1	closed	Friday	Room 028
434	236	LA0404	51	2021.2	closed	Tuesday	Room 021
435	236	BU0305	30	2021.2	closed	Tuesday	Room 007
436	210	PH0506	40	2024.1	closed	Thursday	Room 006
437	205	LA0401	50	2024.1	closed	Tuesday	Room 029
438	226	CS0102	60	2022.2	closed	Wednesday	Room 008
439	217	PH0509	39	2022.2	closed	Wednesday	Room 010
440	233	EN0206	49	2024.1	closed	Monday	Room 025
441	231	EN0204	59	2021.1	closed	Saturday	Room 016
442	247	CS0101	38	2022.2	closed	Monday	Room 013
443	229	LA0403	48	2021.1	closed	Saturday	Room 016
444	220	PH0504	58	2022.2	closed	Saturday	Room 013
445	235	CS0110	37	2023.2	closed	Tuesday	Room 002
446	240	CS0106	47	2024.2	closed	Friday	Room 029
447	220	PH0501	57	2022.1	closed	Friday	Room 029
448	248	EN0210	36	2023.1	closed	Wednesday	Room 002
449	224	BU0303	46	2022.1	closed	Thursday	Room 003
450	230	CS0109	56	2021.2	closed	Wednesday	Room 012
451	227	LA0410	35	2024.1	closed	Tuesday	Room 018
452	219	LA0402	45	2022.2	closed	Thursday	Room 012
453	223	LA0408	55	2022.2	closed	Saturday	Room 003
454	205	LA0401	34	2022.1	closed	Saturday	Room 027
455	214	BU0308	44	2021.2	closed	Wednesday	Room 005
456	246	CS0106	54	2021.1	closed	Saturday	Room 030
457	208	CS0108	33	2023.2	closed	Saturday	Room 030
458	225	BU0306	43	2023.1	closed	Friday	Room 013
459	216	PH0508	53	2022.1	closed	Thursday	Room 030
460	205	CS0110	32	2021.2	closed	Thursday	Room 029
461	209	CS0105	42	2022.2	closed	Friday	Room 027
462	237	BU0310	52	2021.1	closed	Friday	Room 020
463	248	LA0405	31	2022.1	closed	Friday	Room 029
464	235	PH0503	41	2022.2	closed	Friday	Room 023
465	212	PH0508	51	2024.1	closed	Saturday	Room 010
466	224	LA0405	30	2022.2	closed	Thursday	Room 008
467	201	PH0504	40	2023.1	closed	Tuesday	Room 010
468	246	CS0106	50	2021.2	closed	Wednesday	Room 009
469	221	LA0410	60	2023.2	closed	Monday	Room 003
470	250	LA0408	39	2023.2	closed	Tuesday	Room 026
471	206	BU0306	49	2021.2	closed	Friday	Room 008
472	244	LA0407	59	2022.1	closed	Wednesday	Room 017
473	247	BU0302	38	2024.2	closed	Wednesday	Room 014
474	245	PH0502	48	2021.1	closed	Wednesday	Room 012
475	228	BU0308	58	2023.1	closed	Tuesday	Room 007
476	218	PH0505	37	2023.2	closed	Monday	Room 023
477	220	LA0409	47	2024.1	closed	Wednesday	Room 016
478	227	PH0501	57	2024.2	closed	Saturday	Room 009
479	204	LA0402	36	2024.1	closed	Monday	Room 003
480	237	PH0504	46	2023.2	closed	Thursday	Room 026
481	237	EN0204	56	2023.1	closed	Monday	Room 010
482	249	LA0410	35	2022.2	closed	Thursday	Room 022
483	202	LA0408	45	2022.2	closed	Friday	Room 006
484	229	CS0107	55	2024.1	closed	Wednesday	Room 028
485	241	PH0504	34	2024.1	closed	Thursday	Room 001
486	219	LA0403	44	2021.2	closed	Saturday	Room 001
487	244	CS0100	54	2022.1	closed	Thursday	Room 016
488	243	LA0408	33	2023.1	closed	Saturday	Room 020
489	221	PH0505	43	2023.1	closed	Monday	Room 027
490	228	LA0405	53	2023.2	closed	Thursday	Room 022
491	244	EN0205	32	2023.2	closed	Wednesday	Room 017
492	222	EN0203	42	2022.1	closed	Friday	Room 008
493	242	EN0203	52	2024.1	closed	Friday	Room 011
494	235	BU0307	31	2021.1	closed	Saturday	Room 025
495	209	LA0404	41	2022.2	closed	Friday	Room 028
496	217	BU0306	51	2023.1	closed	Thursday	Room 019
497	207	PH0509	30	2023.1	closed	Friday	Room 010
498	250	EN0208	40	2021.1	closed	Thursday	Room 015
499	234	CS0104	50	2022.2	closed	Thursday	Room 014
500	217	BU0308	60	2024.1	closed	Saturday	Room 009
501	229	BU0308	30	2025.1	open	Monday	Room 029
502	236	EN0205	40	2025.1	open	Tuesday	Room 020
503	201	LA0410	50	2025.1	open	Friday	Room 015
504	230	PH0505	60	2025.1	open	Monday	Room 011
505	239	PH0510	39	2025.1	open	Saturday	Room 003
506	217	LA0410	49	2025.1	open	Saturday	Room 027
507	213	EN0205	59	2025.1	open	Thursday	Room 009
508	246	BU0310	38	2025.1	open	Wednesday	Room 017
509	215	BU0310	48	2025.1	open	Saturday	Room 026
510	229	BU0302	58	2025.1	open	Monday	Room 019
511	238	LA0402	37	2025.1	open	Friday	Room 011
512	215	LA0410	47	2025.1	open	Friday	Room 030
513	202	LA0408	57	2025.1	open	Thursday	Room 019
514	242	CS0102	36	2025.1	open	Monday	Room 021
515	236	EN0206	46	2025.1	open	Thursday	Room 011
516	226	PH0508	56	2025.1	open	Monday	Room 026
517	208	EN0204	35	2025.1	open	Wednesday	Room 017
518	234	EN0210	45	2025.1	open	Friday	Room 023
519	223	CS0102	55	2025.1	open	Tuesday	Room 023
520	236	CS0108	34	2025.1	open	Saturday	Room 019
521	234	CS0101	44	2025.1	open	Wednesday	Room 007
522	246	BU0307	54	2025.1	open	Thursday	Room 026
523	209	PH0509	33	2025.1	open	Tuesday	Room 006
524	246	CS0104	43	2025.1	open	Tuesday	Room 025
525	238	CS0103	53	2025.1	open	Tuesday	Room 008
526	248	EN0201	32	2025.1	open	Tuesday	Room 020
527	238	LA0401	42	2025.1	open	Friday	Room 023
528	215	PH0507	52	2025.1	open	Friday	Room 010
529	237	EN0203	31	2025.1	open	Tuesday	Room 013
530	208	BU0309	41	2025.1	open	Saturday	Room 016
531	212	CS0101	51	2025.1	open	Saturday	Room 008
532	216	PH0510	30	2025.1	open	Wednesday	Room 001
533	238	EN0201	40	2025.1	open	Saturday	Room 027
534	212	BU0301	50	2025.1	open	Friday	Room 017
535	231	EN0205	60	2025.1	open	Thursday	Room 003
536	222	BU0303	39	2025.1	open	Friday	Room 009
537	221	EN0202	49	2025.1	open	Monday	Room 029
538	214	PH0506	59	2025.1	open	Wednesday	Room 018
539	218	PH0503	38	2025.1	open	Wednesday	Room 030
540	247	PH0507	48	2025.1	open	Tuesday	Room 014
541	233	LA0405	58	2025.1	open	Monday	Room 008
542	230	BU0308	37	2025.1	open	Saturday	Room 023
543	231	BU0302	47	2025.1	open	Friday	Room 005
544	244	EN0208	57	2025.1	open	Friday	Room 023
545	220	BU0302	36	2025.1	open	Friday	Room 022
546	202	CS0107	46	2025.1	open	Tuesday	Room 016
547	206	LA0402	56	2025.1	open	Monday	Room 006
548	235	PH0502	35	2025.1	open	Friday	Room 025
549	250	BU0305	45	2025.1	open	Thursday	Room 018
550	223	EN0209	55	2025.1	open	Monday	Room 019
551	248	BU0304	34	2025.1	open	Saturday	Room 028
552	223	BU0310	44	2025.1	open	Friday	Room 029
553	203	EN0210	54	2025.1	open	Friday	Room 013
554	242	EN0208	33	2025.1	open	Friday	Room 020
555	247	LA0401	43	2025.1	open	Friday	Room 014
556	239	CS0108	53	2025.1	open	Monday	Room 010
557	246	LA0401	32	2025.1	open	Friday	Room 021
558	223	BU0304	42	2025.1	open	Thursday	Room 022
559	211	CS0110	52	2025.1	open	Friday	Room 001
560	218	LA0403	31	2025.1	open	Friday	Room 011
561	249	PH0509	41	2025.1	open	Wednesday	Room 003
562	245	CS0100	51	2025.1	open	Saturday	Room 015
563	221	PH0502	30	2025.1	open	Thursday	Room 002
564	208	LA0407	40	2025.1	open	Monday	Room 011
565	223	PH0504	50	2025.1	open	Friday	Room 019
566	241	CS0103	60	2025.1	open	Friday	Room 029
567	222	CS0102	39	2025.1	open	Thursday	Room 002
568	236	CS0109	49	2025.1	open	Saturday	Room 004
569	238	BU0303	59	2025.1	open	Wednesday	Room 011
570	207	PH0509	38	2025.1	open	Tuesday	Room 002
571	202	CS0100	48	2025.1	open	Friday	Room 025
572	211	CS0110	58	2025.1	open	Friday	Room 009
573	215	LA0407	37	2025.1	open	Thursday	Room 028
574	238	LA0410	47	2025.1	open	Wednesday	Room 014
575	229	PH0510	57	2025.1	open	Friday	Room 027
576	205	EN0206	36	2025.1	open	Friday	Room 028
577	201	CS0109	46	2025.1	open	Wednesday	Room 029
578	208	BU0307	56	2025.1	open	Monday	Room 017
579	222	CS0107	35	2025.1	open	Monday	Room 027
580	229	LA0401	45	2025.1	open	Friday	Room 015
581	220	CS0108	55	2025.1	open	Thursday	Room 010
582	218	EN0205	34	2025.1	open	Wednesday	Room 021
583	236	CS0107	44	2025.1	open	Saturday	Room 015
584	245	CS0110	54	2025.1	open	Tuesday	Room 017
585	213	BU0305	33	2025.1	open	Monday	Room 028
586	217	LA0402	43	2025.1	open	Tuesday	Room 001
587	239	LA0409	53	2025.1	open	Saturday	Room 001
588	216	CS0107	32	2025.1	open	Thursday	Room 016
589	228	CS0100	42	2025.1	open	Saturday	Room 011
590	219	BU0307	52	2025.1	open	Saturday	Room 009
591	208	LA0410	31	2025.1	open	Saturday	Room 014
592	243	LA0402	41	2025.1	open	Saturday	Room 012
593	239	CS0109	51	2025.1	open	Saturday	Room 002
594	229	EN0206	30	2025.1	open	Tuesday	Room 014
595	219	PH0502	40	2025.1	open	Wednesday	Room 003
596	233	PH0506	50	2025.1	open	Saturday	Room 023
597	213	BU0302	60	2025.1	open	Friday	Room 007
598	241	CS0105	39	2025.1	open	Wednesday	Room 004
599	205	CS0105	49	2025.1	open	Tuesday	Room 008
600	229	CS0105	59	2025.1	open	Thursday	Room 007
601	201	LA0401	42	2024.2	closed	Saturday	Room 303
602	201	PH0505	40	2024.2	closed	Friday	Room 303
603	201	CS0109	47	2024.2	closed	Monday	Room 202
604	201	CS0105	49	2024.2	closed	Saturday	Room 303
605	201	PH0505	41	2024.2	closed	Monday	Room 404
606	201	EN0205	43	2024.2	closed	Friday	Room 303
607	201	LA0401	50	2024.2	closed	Wednesday	Room 101
608	201	CS0108	50	2024.2	closed	Friday	Room 101
\.


--
-- Data for Name: configs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.configs (current_semester, next_semester, class_reg_status) FROM stdin;
2024.2	2025.1	t
\.


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.courses (course_id, course_name, credit, tuition_per_credit, school_id, course_description) FROM stdin;
CS0101	Introduction to Programming	3	100	1	Covers programming basics using a modern language. Learn variables, loops, functions, and problem-solving.
CS0102	Data Structures	4	120	1	Introduces arrays, stacks, queues, linked lists, trees, and graphs for data organization.
CS0103	Algorithms	4	130	1	Focuses on algorithm design, analysis, and optimization techniques including sorting and searching.
CS0104	Database Systems	3	110	1	Covers relational databases, SQL, normalization, and database design principles.
CS0105	Computer Networks	4	140	1	Explores network architecture, protocols, OSI model, and internet technologies.
CS0106	Operating Systems	4	130	1	Study OS concepts like processes, memory, file systems, and concurrency.
CS0107	AI Fundamentals	3	150	1	An introduction to artificial intelligence including search, logic, and learning algorithms.
CS0108	Web Development	3	115	1	Learn HTML, CSS, JavaScript, and backend integration for web applications.
CS0109	Software Engineering	4	125	1	Covers SDLC, project management, testing, and software design patterns.
CS0110	Cybersecurity	3	145	1	Fundamentals of security principles, cryptography, and threat prevention.
EN0201	Thermodynamics	4	90	2	Study of energy systems, heat transfer, and the laws of thermodynamics.
EN0202	Circuit Analysis	4	110	2	Analyzes electrical circuits using Ohm’s and Kirchhoff’s laws.
EN0203	Fluid Mechanics	4	120	2	Covers fluid statics, dynamics, and applications in engineering systems.
EN0204	Materials Science	3	95	2	Study of engineering materials, their properties, and applications.
EN0205	Structural Design	4	115	2	Focuses on the analysis and design of structural components.
EN0206	Control Systems	3	105	2	Covers modeling and analysis of control systems with feedback principles.
EN0207	Robotics	4	130	2	Introduction to robotic systems, sensors, actuators, and automation.
EN0208	Renewable Energy	3	100	2	Study of sustainable energy sources and renewable power technologies.
EN0209	CAD Modeling	3	110	2	Covers the use of CAD tools for engineering design and modeling.
EN0210	Engineering Math	4	100	2	Mathematical methods and techniques used in engineering applications.
BU0302	Marketing Principles	3	130	3	Introduces marketing strategies, market research, and customer behavior.
BU0303	Business Statistics	3	120	3	Applies statistical methods to business data analysis and forecasting.
BU0304	Operations Management	4	140	3	Focuses on production planning, supply chains, and quality control.
BU0305	Organizational Behavior	3	110	3	Explores human behavior in organizations and workplace dynamics.
BU0306	Business Law	3	125	3	Introduction to legal concepts relevant to business and commerce.
BU0307	Strategic Management	4	160	3	Covers strategic planning, competitive analysis, and decision-making.
BU0308	Entrepreneurship	3	130	3	Teaches skills for launching and managing startups and new ventures.
BU0309	International Business	3	135	3	Explores global business environments and international trade practices.
BU0310	Digital Marketing	3	140	3	Focuses on online marketing, SEO, and digital advertising strategies.
LA0401	English Linguistics	3	90	4	Explores English phonology, syntax, semantics, and linguistic analysis.
LA0402	French Literature	3	95	4	Study of major works and authors in French literary history.
BU0301	Financial ncnc	4	150	3	Covers principles of financial accounting, balance sheets, and income statements.
LA0403	Spanish Grammar	3	85	4	Focuses on Spanish grammar structures and sentence formation.
LA0404	Chinese Characters	4	100	4	Covers traditional Chinese characters and their linguistic evolution.
LA0405	Translation Studies	3	110	4	Introduction to translation theories, methods, and practical exercises.
LA0406	Phonetics	2	80	4	Examines the articulation of speech sounds and transcription systems.
LA0407	Comparative Literature	3	105	4	Compares literary works across cultures, genres, and time periods.
LA0408	Academic Writing	2	75	4	Teaches formal academic writing and argumentation in English.
LA0409	Japanese Culture	3	95	4	An introduction to Japanese traditions, customs, and society.
LA0410	German Conversation	3	90	4	Focuses on conversational German for real-world communication.
PH0501	Classical Mechanics	4	110	5	Studies motion, forces, and energy in classical physical systems.
PH0502	Electromagnetism	4	120	5	Covers electric and magnetic fields, circuits, and Maxwell’s equations.
PH0503	Quantum Physics	4	130	5	Explores quantum theory, wave functions, and uncertainty principles.
PH0504	Thermodynamics	3	100	5	Analyzes heat, energy transfer, and entropy in physical systems.
PH0505	Nuclear Physics	4	140	5	Introduction to nuclear structure, decay processes, and applications.
PH0506	Astrophysics	3	125	5	Focuses on the structure and behavior of celestial bodies and galaxies.
PH0507	Optics	3	115	5	Covers the principles of light, reflection, refraction, and lenses.
PH0508	Particle Physics	4	150	5	Studies the particles and forces that compose matter at subatomic levels.
PH0509	Solid State Physics	4	135	5	Explores properties and behaviors of solids, including crystals and semiconductors.
PH0510	Computational Physics	3	120	5	Application of numerical and computational methods to physics problems.
CS0100	Object Oriented Programming	4	100	1	Object Oriented Programming.
CS1000	Database Lab	2	100	1	Database Lab
\.


--
-- Data for Name: enrollments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.enrollments (student_id, class_id, mid_term, final_term) FROM stdin;
1	601	5.00	5.00
1	602	9.00	9.00
1	603	9.00	9.00
19	19	5.00	7.00
1	1	4.00	10.00
2	2	2.00	8.00
3	3	9.00	9.00
4	4	7.00	9.00
5	5	3.00	6.00
6	6	8.00	0.00
7	7	9.00	6.00
8	8	7.00	9.00
9	9	1.00	10.00
10	10	3.00	7.00
11	11	3.00	1.00
12	12	10.00	9.00
13	13	3.00	10.00
14	14	7.00	4.00
15	15	10.00	0.00
16	16	0.00	10.00
17	17	8.00	8.00
18	18	0.00	9.00
20	20	7.00	8.00
21	21	6.00	2.00
22	22	3.00	10.00
23	23	4.00	9.00
24	24	4.00	10.00
25	25	3.00	0.00
26	26	10.00	4.00
27	27	4.00	10.00
28	28	0.00	4.00
29	29	5.00	10.00
30	30	3.00	3.00
31	31	10.00	10.00
32	32	1.00	0.00
33	33	1.00	0.00
34	34	6.00	2.00
35	35	9.00	8.00
36	36	8.00	1.00
37	37	0.00	6.00
38	38	2.00	0.00
39	39	0.00	0.00
40	40	4.00	10.00
41	41	3.00	10.00
42	42	2.00	8.00
43	43	7.00	10.00
44	44	10.00	0.00
45	45	0.00	7.00
46	46	3.00	1.00
47	47	1.00	9.00
48	48	5.00	10.00
49	49	5.00	5.00
50	50	0.00	8.00
51	51	3.00	1.00
52	52	0.00	6.00
53	53	4.00	5.00
54	54	2.00	4.00
55	55	8.00	10.00
56	56	1.00	4.00
57	57	2.00	1.00
58	58	8.00	4.00
59	59	5.00	9.00
60	60	9.00	2.00
61	61	1.00	1.00
62	62	4.00	4.00
63	63	10.00	0.00
64	64	10.00	8.00
65	65	10.00	1.00
66	66	6.00	7.00
67	67	4.00	7.00
68	68	4.00	3.00
69	69	6.00	0.00
70	70	9.00	6.00
71	71	8.00	2.00
72	72	7.00	5.00
73	73	0.00	7.00
74	74	6.00	5.00
75	75	10.00	3.00
76	76	6.00	9.00
77	77	9.00	7.00
78	78	2.00	10.00
79	79	8.00	3.00
80	80	2.00	2.00
81	81	3.00	4.00
82	82	5.00	4.00
83	83	2.00	10.00
84	84	3.00	4.00
85	85	3.00	5.00
86	86	9.00	3.00
87	87	3.00	8.00
88	88	0.00	6.00
89	89	5.00	3.00
90	90	7.00	8.00
91	91	4.00	8.00
92	92	5.00	9.00
93	93	6.00	8.00
94	94	5.00	4.00
95	95	8.00	1.00
96	96	5.00	4.00
97	97	4.00	9.00
98	98	2.00	7.00
99	99	2.00	5.00
100	100	3.00	1.00
101	101	3.00	0.00
102	102	2.00	4.00
103	103	8.00	1.00
104	104	5.00	2.00
105	105	4.00	9.00
106	106	0.00	5.00
107	107	1.00	2.00
108	108	0.00	7.00
109	109	10.00	1.00
110	110	9.00	2.00
111	111	0.00	5.00
112	112	3.00	7.00
113	113	4.00	3.00
114	114	7.00	8.00
115	115	1.00	1.00
116	116	7.00	1.00
117	117	3.00	8.00
118	118	8.00	3.00
119	119	5.00	10.00
120	120	8.00	9.00
121	121	6.00	3.00
122	122	10.00	6.00
123	123	1.00	3.00
124	124	10.00	0.00
125	125	2.00	10.00
126	126	3.00	9.00
127	127	9.00	10.00
128	128	2.00	7.00
129	129	4.00	7.00
130	130	0.00	7.00
131	131	9.00	3.00
132	132	0.00	3.00
133	133	4.00	2.00
134	134	3.00	8.00
135	135	3.00	6.00
136	136	0.00	3.00
137	137	5.00	9.00
138	138	0.00	5.00
139	139	5.00	7.00
140	140	3.00	1.00
141	141	9.00	8.00
142	142	7.00	10.00
143	143	8.00	7.00
144	144	9.00	5.00
145	145	5.00	7.00
146	146	7.00	0.00
147	147	6.00	7.00
148	148	5.00	9.00
149	149	4.00	9.00
150	150	7.00	5.00
151	151	7.00	7.00
152	152	8.00	3.00
153	153	7.00	1.00
154	154	6.00	2.00
155	155	2.00	6.00
156	156	9.00	0.00
157	157	7.00	9.00
158	158	7.00	4.00
159	159	8.00	5.00
160	160	1.00	8.00
161	161	2.00	0.00
162	162	7.00	3.00
163	163	7.00	3.00
164	164	4.00	10.00
165	165	4.00	5.00
166	166	2.00	8.00
167	167	7.00	10.00
168	168	0.00	10.00
169	169	3.00	9.00
170	170	2.00	4.00
171	171	4.00	3.00
172	172	9.00	8.00
173	173	8.00	0.00
174	174	6.00	9.00
175	175	10.00	4.00
176	176	9.00	8.00
177	177	10.00	7.00
178	178	2.00	0.00
179	179	3.00	8.00
180	180	8.00	8.00
181	181	9.00	4.00
182	182	6.00	0.00
183	183	9.00	9.00
184	184	5.00	9.00
185	185	7.00	3.00
186	186	2.00	8.00
187	187	9.00	2.00
188	188	6.00	8.00
189	189	5.00	7.00
190	190	5.00	9.00
191	191	5.00	6.00
192	192	4.00	9.00
193	193	0.00	10.00
194	194	6.00	10.00
195	195	8.00	3.00
196	196	5.00	4.00
197	197	9.00	5.00
198	198	0.00	10.00
199	199	0.00	5.00
200	200	9.00	10.00
1	201	4.00	9.00
2	202	3.00	7.00
3	203	0.00	9.00
4	204	10.00	2.00
5	205	3.00	8.00
6	206	0.00	2.00
7	207	10.00	3.00
8	208	9.00	6.00
9	209	8.00	7.00
10	210	7.00	10.00
11	211	7.00	5.00
12	212	1.00	8.00
13	213	9.00	3.00
14	214	8.00	5.00
15	215	3.00	1.00
16	216	6.00	5.00
17	217	9.00	4.00
18	218	8.00	10.00
20	220	1.00	0.00
21	221	6.00	9.00
22	222	5.00	7.00
23	223	10.00	1.00
24	224	4.00	1.00
25	225	5.00	9.00
26	226	4.00	4.00
27	227	10.00	5.00
28	228	7.00	0.00
29	229	4.00	9.00
30	230	7.00	5.00
31	231	3.00	6.00
32	232	0.00	3.00
33	233	3.00	2.00
34	234	0.00	8.00
35	235	10.00	7.00
36	236	9.00	2.00
37	237	6.00	6.00
38	238	9.00	4.00
39	239	1.00	8.00
40	240	3.00	7.00
41	241	7.00	3.00
42	242	4.00	4.00
43	243	6.00	7.00
44	244	3.00	1.00
45	245	8.00	7.00
46	246	3.00	4.00
47	247	2.00	8.00
48	248	6.00	9.00
49	249	0.00	0.00
50	250	3.00	0.00
51	251	8.00	5.00
52	252	4.00	3.00
53	253	9.00	9.00
54	254	4.00	0.00
55	255	3.00	9.00
56	256	8.00	4.00
57	257	0.00	0.00
58	258	1.00	1.00
59	259	1.00	5.00
60	260	0.00	1.00
61	261	2.00	9.00
62	262	5.00	8.00
63	263	1.00	6.00
64	264	10.00	5.00
65	265	4.00	10.00
66	266	9.00	0.00
67	267	8.00	8.00
68	268	9.00	4.00
69	269	10.00	10.00
70	270	0.00	5.00
71	271	5.00	7.00
72	272	3.00	2.00
73	273	1.00	6.00
74	274	6.00	9.00
75	275	8.00	7.00
76	276	7.00	8.00
77	277	8.00	3.00
78	278	5.00	5.00
79	279	3.00	1.00
80	280	7.00	0.00
81	281	8.00	10.00
82	282	6.00	8.00
83	283	2.00	5.00
84	284	8.00	7.00
85	285	3.00	1.00
86	286	6.00	4.00
87	287	3.00	10.00
88	288	3.00	0.00
89	289	2.00	3.00
90	290	1.00	3.00
91	291	6.00	4.00
92	292	5.00	4.00
93	293	3.00	9.00
94	294	0.00	4.00
95	295	7.00	10.00
96	296	3.00	0.00
97	297	8.00	6.00
98	298	3.00	0.00
99	299	7.00	1.00
100	300	4.00	6.00
101	301	7.00	10.00
102	302	6.00	7.00
103	303	9.00	7.00
104	304	7.00	0.00
105	305	10.00	6.00
106	306	1.00	4.00
107	307	1.00	5.00
108	308	6.00	2.00
109	309	8.00	6.00
110	310	1.00	2.00
111	311	5.00	10.00
112	312	4.00	10.00
113	313	6.00	10.00
114	314	10.00	6.00
115	315	10.00	9.00
116	316	2.00	4.00
117	317	10.00	3.00
118	318	10.00	0.00
119	319	7.00	7.00
120	320	9.00	4.00
121	321	2.00	8.00
122	322	6.00	5.00
123	323	6.00	2.00
124	324	9.00	10.00
125	325	3.00	0.00
126	326	7.00	4.00
127	327	6.00	5.00
128	328	3.00	3.00
129	329	8.00	2.00
130	330	1.00	7.00
131	331	6.00	1.00
132	332	0.00	2.00
133	333	7.00	1.00
134	334	2.00	6.00
135	335	4.00	1.00
136	336	8.00	9.00
137	337	5.00	1.00
138	338	1.00	8.00
139	339	1.00	5.00
140	340	4.00	1.00
141	341	8.00	7.00
142	342	8.00	3.00
143	343	1.00	1.00
144	344	10.00	10.00
145	345	6.00	1.00
146	346	2.00	3.00
147	347	7.00	4.00
148	348	2.00	0.00
149	349	9.00	0.00
150	350	0.00	6.00
151	351	6.00	4.00
152	352	1.00	8.00
153	353	5.00	3.00
154	354	5.00	2.00
155	355	9.00	2.00
156	356	0.00	4.00
157	357	5.00	1.00
158	358	2.00	4.00
159	359	5.00	8.00
160	360	8.00	7.00
161	361	0.00	3.00
162	362	7.00	10.00
163	363	8.00	6.00
164	364	6.00	2.00
165	365	3.00	9.00
166	366	0.00	4.00
167	367	3.00	4.00
168	368	10.00	3.00
169	369	3.00	6.00
170	370	5.00	7.00
171	371	0.00	10.00
172	372	10.00	7.00
173	373	7.00	4.00
174	374	5.00	8.00
175	375	4.00	2.00
176	376	4.00	0.00
177	377	1.00	9.00
178	378	7.00	9.00
179	379	10.00	3.00
180	380	7.00	1.00
181	381	4.00	3.00
182	382	9.00	0.00
183	383	8.00	3.00
184	384	7.00	3.00
185	385	7.00	2.00
186	386	9.00	6.00
187	387	2.00	3.00
188	388	10.00	9.00
189	389	0.00	1.00
190	390	9.00	6.00
191	391	2.00	0.00
192	392	5.00	0.00
193	393	1.00	8.00
194	394	5.00	8.00
195	395	6.00	0.00
196	396	1.00	8.00
197	397	7.00	8.00
198	398	6.00	4.00
199	399	0.00	10.00
200	400	10.00	1.00
1	401	9.00	5.00
2	402	5.00	10.00
3	403	6.00	6.00
4	404	3.00	5.00
5	405	2.00	10.00
6	406	8.00	3.00
7	407	4.00	9.00
8	408	3.00	4.00
9	409	9.00	0.00
10	410	3.00	5.00
11	411	6.00	8.00
12	412	0.00	4.00
13	413	8.00	0.00
14	414	4.00	6.00
15	415	0.00	7.00
16	416	2.00	5.00
17	417	3.00	10.00
18	418	7.00	7.00
20	420	3.00	0.00
21	421	1.00	10.00
22	422	7.00	4.00
23	423	2.00	7.00
24	424	8.00	10.00
25	425	9.00	8.00
26	426	10.00	5.00
27	427	8.00	6.00
28	428	3.00	10.00
29	429	8.00	9.00
30	430	0.00	9.00
31	431	6.00	2.00
32	432	1.00	3.00
33	433	1.00	1.00
34	434	9.00	3.00
35	435	0.00	10.00
36	436	0.00	6.00
37	437	10.00	0.00
38	438	1.00	6.00
39	439	1.00	10.00
40	440	5.00	1.00
41	441	9.00	8.00
42	442	2.00	8.00
43	443	5.00	9.00
44	444	6.00	8.00
45	445	9.00	7.00
46	446	10.00	9.00
47	447	10.00	8.00
48	448	3.00	7.00
49	449	6.00	8.00
50	450	8.00	8.00
51	451	8.00	10.00
52	452	5.00	10.00
53	453	3.00	4.00
54	454	2.00	7.00
55	455	3.00	6.00
56	456	2.00	5.00
57	457	0.00	6.00
58	458	6.00	7.00
59	459	7.00	8.00
60	460	10.00	8.00
61	461	2.00	1.00
62	462	8.00	5.00
63	463	5.00	6.00
64	464	3.00	9.00
65	465	9.00	2.00
66	466	3.00	1.00
67	467	1.00	3.00
68	468	0.00	6.00
69	469	0.00	1.00
70	470	5.00	1.00
71	471	2.00	4.00
72	472	9.00	3.00
73	473	8.00	9.00
74	474	8.00	10.00
75	475	6.00	8.00
76	476	5.00	10.00
77	477	2.00	0.00
78	478	0.00	2.00
79	479	6.00	10.00
80	480	10.00	6.00
81	481	5.00	7.00
82	482	9.00	1.00
83	483	0.00	7.00
84	484	9.00	3.00
85	485	9.00	4.00
86	486	5.00	0.00
87	487	2.00	10.00
88	488	6.00	9.00
89	489	8.00	5.00
90	490	10.00	5.00
91	491	2.00	2.00
92	492	5.00	10.00
93	493	3.00	7.00
94	494	3.00	10.00
95	495	9.00	7.00
96	496	9.00	2.00
97	497	0.00	9.00
98	498	2.00	8.00
99	499	4.00	0.00
100	500	6.00	4.00
101	1	0.00	6.00
102	2	10.00	8.00
103	3	2.00	8.00
104	4	2.00	6.00
105	5	8.00	8.00
106	6	9.00	3.00
107	7	5.00	9.00
108	8	7.00	3.00
109	9	6.00	2.00
110	10	5.00	3.00
111	11	10.00	10.00
112	12	1.00	7.00
113	13	0.00	10.00
114	14	2.00	0.00
115	15	5.00	1.00
116	16	10.00	8.00
117	17	5.00	7.00
118	18	8.00	0.00
119	19	7.00	7.00
120	20	5.00	10.00
121	21	6.00	2.00
122	22	9.00	5.00
123	23	4.00	4.00
124	24	2.00	9.00
125	25	9.00	0.00
126	26	10.00	7.00
127	27	10.00	2.00
128	28	9.00	6.00
129	29	4.00	4.00
130	30	4.00	8.00
131	31	2.00	3.00
132	32	8.00	0.00
133	33	0.00	7.00
134	34	9.00	5.00
135	35	8.00	1.00
136	36	7.00	5.00
137	37	8.00	7.00
138	38	10.00	10.00
139	39	6.00	8.00
140	40	5.00	6.00
141	41	0.00	10.00
142	42	1.00	5.00
143	43	3.00	7.00
144	44	2.00	5.00
145	45	1.00	1.00
146	46	10.00	1.00
147	47	4.00	0.00
148	48	6.00	9.00
149	49	7.00	2.00
150	50	10.00	2.00
151	51	0.00	10.00
152	52	9.00	10.00
153	53	1.00	1.00
154	54	2.00	4.00
155	55	10.00	2.00
156	56	6.00	3.00
157	57	0.00	3.00
158	58	6.00	4.00
159	59	6.00	2.00
160	60	10.00	8.00
161	61	9.00	6.00
162	62	4.00	2.00
163	63	7.00	6.00
164	64	5.00	0.00
165	65	0.00	7.00
166	66	6.00	5.00
167	67	7.00	1.00
168	68	2.00	8.00
169	69	1.00	0.00
170	70	7.00	0.00
171	71	6.00	1.00
172	72	8.00	1.00
173	73	6.00	1.00
174	74	2.00	7.00
175	75	6.00	0.00
176	76	2.00	3.00
177	77	1.00	2.00
178	78	7.00	7.00
179	79	9.00	5.00
180	80	8.00	4.00
181	81	5.00	7.00
182	82	7.00	4.00
183	83	6.00	9.00
184	84	1.00	10.00
185	85	7.00	3.00
186	86	7.00	3.00
187	87	4.00	6.00
188	88	8.00	0.00
189	89	6.00	5.00
190	90	7.00	1.00
191	91	7.00	5.00
192	92	8.00	6.00
193	93	2.00	8.00
194	94	3.00	10.00
195	95	5.00	7.00
196	96	5.00	5.00
197	97	7.00	1.00
198	98	0.00	10.00
199	99	3.00	10.00
200	100	0.00	7.00
1	101	2.00	2.00
2	102	2.00	8.00
3	103	3.00	7.00
4	104	6.00	2.00
5	105	8.00	6.00
6	106	1.00	0.00
7	107	4.00	8.00
8	108	10.00	4.00
9	109	4.00	6.00
10	110	7.00	1.00
11	111	7.00	4.00
12	112	4.00	0.00
13	113	10.00	8.00
14	114	4.00	10.00
15	115	6.00	3.00
16	116	2.00	7.00
17	117	9.00	4.00
18	118	3.00	10.00
20	120	0.00	2.00
21	121	2.00	4.00
22	122	7.00	5.00
23	123	7.00	5.00
24	124	6.00	6.00
25	125	8.00	1.00
26	126	7.00	7.00
27	127	6.00	3.00
28	128	4.00	6.00
29	129	7.00	5.00
30	130	3.00	10.00
31	131	2.00	8.00
32	132	8.00	8.00
33	133	0.00	0.00
34	134	5.00	6.00
35	135	6.00	1.00
36	136	8.00	0.00
37	137	1.00	8.00
38	138	4.00	5.00
39	139	7.00	6.00
40	140	0.00	5.00
41	141	4.00	6.00
42	142	2.00	8.00
43	143	7.00	6.00
44	144	5.00	0.00
45	145	5.00	7.00
46	146	3.00	8.00
47	147	1.00	9.00
48	148	4.00	9.00
49	149	3.00	3.00
50	150	4.00	3.00
51	151	6.00	5.00
52	152	9.00	8.00
53	153	8.00	0.00
54	154	9.00	6.00
55	155	8.00	9.00
56	156	6.00	3.00
57	157	3.00	9.00
58	158	10.00	10.00
59	159	10.00	9.00
60	160	3.00	3.00
61	161	3.00	4.00
62	162	0.00	7.00
63	163	10.00	10.00
64	164	3.00	1.00
65	165	10.00	7.00
66	166	9.00	8.00
67	167	8.00	3.00
68	168	7.00	6.00
69	169	9.00	4.00
70	170	8.00	8.00
71	171	9.00	5.00
72	172	2.00	5.00
73	173	10.00	7.00
74	174	7.00	0.00
75	175	2.00	2.00
76	176	0.00	10.00
77	177	10.00	0.00
78	178	2.00	10.00
79	179	6.00	6.00
80	180	7.00	9.00
81	181	6.00	0.00
82	182	1.00	10.00
83	183	10.00	3.00
84	184	8.00	2.00
85	185	10.00	7.00
86	186	4.00	10.00
87	187	2.00	3.00
88	188	2.00	0.00
89	189	4.00	10.00
90	190	4.00	6.00
91	191	10.00	10.00
92	192	4.00	7.00
93	193	9.00	2.00
94	194	4.00	4.00
95	195	1.00	9.00
96	196	7.00	0.00
97	197	2.00	9.00
98	198	7.00	1.00
99	199	3.00	6.00
100	200	5.00	7.00
101	201	0.00	5.00
102	202	9.00	0.00
103	203	5.00	4.00
104	204	1.00	9.00
105	205	5.00	9.00
106	206	3.00	5.00
107	207	8.00	3.00
108	208	10.00	2.00
109	209	5.00	10.00
110	210	2.00	9.00
111	211	9.00	10.00
112	212	5.00	0.00
113	213	2.00	7.00
114	214	0.00	4.00
115	215	3.00	6.00
116	216	7.00	2.00
117	217	6.00	2.00
118	218	0.00	5.00
119	219	3.00	3.00
120	220	6.00	10.00
121	221	6.00	0.00
122	222	3.00	0.00
123	223	0.00	8.00
124	224	2.00	3.00
125	225	0.00	6.00
126	226	7.00	3.00
127	227	2.00	10.00
128	228	10.00	2.00
129	229	0.00	8.00
130	230	3.00	6.00
131	231	8.00	6.00
132	232	2.00	1.00
133	233	10.00	5.00
134	234	2.00	1.00
135	235	6.00	9.00
136	236	3.00	4.00
137	237	3.00	7.00
138	238	6.00	1.00
139	239	0.00	7.00
140	240	9.00	4.00
141	241	5.00	2.00
142	242	9.00	10.00
143	243	3.00	4.00
144	244	7.00	5.00
145	245	2.00	1.00
146	246	1.00	4.00
147	247	8.00	10.00
148	248	4.00	10.00
149	249	2.00	10.00
150	250	8.00	1.00
151	251	0.00	3.00
152	252	1.00	2.00
153	253	10.00	8.00
154	254	0.00	7.00
155	255	1.00	8.00
156	256	5.00	7.00
157	257	0.00	9.00
158	258	6.00	10.00
159	259	2.00	2.00
160	260	9.00	7.00
161	261	4.00	4.00
162	262	4.00	5.00
163	263	4.00	1.00
164	264	3.00	1.00
165	265	2.00	0.00
166	266	10.00	5.00
167	267	5.00	5.00
168	268	5.00	3.00
169	269	10.00	10.00
170	270	7.00	0.00
171	271	0.00	6.00
172	272	9.00	6.00
173	273	7.00	0.00
174	274	10.00	4.00
175	275	8.00	2.00
176	276	9.00	8.00
177	277	1.00	1.00
178	278	4.00	2.00
179	279	0.00	0.00
180	280	9.00	0.00
181	281	3.00	7.00
182	282	8.00	0.00
183	283	4.00	10.00
184	284	2.00	2.00
185	285	9.00	3.00
186	286	0.00	2.00
187	287	0.00	6.00
188	288	6.00	0.00
189	289	6.00	10.00
190	290	0.00	6.00
191	291	1.00	6.00
192	292	0.00	1.00
193	293	7.00	3.00
194	294	5.00	5.00
195	295	0.00	10.00
196	296	4.00	4.00
197	297	2.00	0.00
198	298	8.00	7.00
199	299	6.00	10.00
200	300	5.00	4.00
19	219	5.00	7.00
2	302	8.00	10.00
3	303	0.00	4.00
4	304	10.00	2.00
5	305	8.00	0.00
6	306	5.00	6.00
7	307	7.00	2.00
8	308	10.00	4.00
9	309	0.00	8.00
10	310	0.00	5.00
11	311	3.00	1.00
12	312	2.00	0.00
13	313	7.00	9.00
14	314	6.00	4.00
15	315	2.00	9.00
16	316	1.00	4.00
17	317	8.00	4.00
18	318	8.00	10.00
20	320	3.00	0.00
21	321	10.00	1.00
22	322	9.00	10.00
23	323	8.00	2.00
24	324	9.00	7.00
25	325	1.00	8.00
26	326	1.00	7.00
27	327	8.00	1.00
28	328	6.00	9.00
29	329	6.00	4.00
30	330	2.00	4.00
31	331	1.00	6.00
32	332	2.00	3.00
33	333	6.00	6.00
34	334	9.00	4.00
35	335	8.00	4.00
36	336	10.00	7.00
37	337	4.00	3.00
38	338	4.00	1.00
39	339	2.00	0.00
40	340	3.00	10.00
41	341	2.00	9.00
42	342	5.00	8.00
43	343	9.00	2.00
44	344	10.00	9.00
45	345	3.00	10.00
46	346	4.00	5.00
47	347	9.00	0.00
48	348	6.00	4.00
49	349	1.00	1.00
50	350	4.00	3.00
51	351	5.00	0.00
52	352	0.00	4.00
53	353	6.00	0.00
54	354	9.00	9.00
55	355	5.00	9.00
56	356	3.00	1.00
57	357	8.00	0.00
58	358	5.00	5.00
59	359	1.00	1.00
60	360	3.00	7.00
61	361	2.00	6.00
62	362	9.00	3.00
63	363	10.00	10.00
64	364	4.00	10.00
65	365	10.00	9.00
66	366	0.00	8.00
67	367	3.00	9.00
68	368	10.00	1.00
69	369	10.00	0.00
70	370	1.00	5.00
71	371	6.00	0.00
72	372	9.00	1.00
73	373	2.00	0.00
74	374	8.00	1.00
75	375	4.00	5.00
76	376	0.00	2.00
77	377	8.00	8.00
78	378	7.00	10.00
79	379	4.00	2.00
80	380	4.00	8.00
81	381	2.00	9.00
82	382	0.00	9.00
83	383	9.00	3.00
84	384	9.00	1.00
85	385	1.00	9.00
86	386	4.00	9.00
87	387	8.00	4.00
88	388	3.00	8.00
89	389	6.00	8.00
90	390	4.00	9.00
91	391	6.00	1.00
92	392	2.00	5.00
93	393	9.00	6.00
94	394	9.00	5.00
95	395	1.00	10.00
96	396	2.00	4.00
97	397	1.00	6.00
98	398	9.00	0.00
99	399	4.00	7.00
100	400	4.00	0.00
101	401	9.00	0.00
102	402	0.00	1.00
103	403	8.00	2.00
104	404	9.00	4.00
105	405	0.00	7.00
106	406	4.00	7.00
107	407	3.00	10.00
108	408	2.00	10.00
109	409	5.00	6.00
110	410	6.00	2.00
111	411	2.00	10.00
112	412	6.00	5.00
113	413	0.00	2.00
114	414	1.00	9.00
115	415	3.00	8.00
116	416	4.00	6.00
117	417	4.00	4.00
118	418	6.00	2.00
119	419	8.00	2.00
120	420	3.00	10.00
121	421	4.00	1.00
122	422	4.00	2.00
123	423	4.00	0.00
124	424	3.00	9.00
125	425	9.00	0.00
126	426	7.00	4.00
127	427	7.00	10.00
128	428	10.00	9.00
129	429	7.00	5.00
130	430	7.00	6.00
131	431	2.00	3.00
132	432	9.00	9.00
133	433	5.00	0.00
134	434	3.00	10.00
135	435	5.00	4.00
136	436	7.00	1.00
137	437	9.00	2.00
138	438	1.00	4.00
139	439	3.00	0.00
140	440	1.00	8.00
141	441	4.00	2.00
142	442	1.00	5.00
143	443	2.00	10.00
144	444	4.00	6.00
145	445	9.00	8.00
146	446	6.00	7.00
147	447	1.00	6.00
148	448	4.00	4.00
149	449	7.00	10.00
150	450	5.00	2.00
151	451	1.00	2.00
152	452	4.00	1.00
153	453	2.00	6.00
154	454	10.00	7.00
155	455	6.00	8.00
156	456	3.00	1.00
157	457	1.00	10.00
158	458	7.00	0.00
159	459	10.00	8.00
160	460	6.00	7.00
161	461	2.00	2.00
162	462	4.00	1.00
163	463	7.00	10.00
164	464	2.00	8.00
165	465	9.00	2.00
166	466	6.00	1.00
167	467	8.00	4.00
168	468	2.00	6.00
169	469	6.00	4.00
170	470	5.00	0.00
171	471	10.00	4.00
172	472	1.00	4.00
173	473	0.00	10.00
174	474	0.00	4.00
175	475	10.00	9.00
176	476	0.00	2.00
177	477	9.00	0.00
178	478	3.00	10.00
179	479	5.00	1.00
180	480	4.00	4.00
181	481	7.00	9.00
182	482	7.00	10.00
183	483	10.00	10.00
184	484	8.00	3.00
185	485	6.00	7.00
186	486	0.00	10.00
187	487	4.00	0.00
188	488	9.00	1.00
189	489	2.00	8.00
190	490	2.00	1.00
191	491	0.00	8.00
192	492	9.00	4.00
193	493	8.00	9.00
194	494	6.00	8.00
195	495	2.00	10.00
196	496	0.00	5.00
197	497	9.00	9.00
198	498	0.00	7.00
199	499	6.00	10.00
200	500	6.00	3.00
1	222	7.00	7.00
1	3	7.00	7.00
1	164	7.00	7.00
1	279	7.00	7.00
1	6	7.00	7.00
1	460	7.00	7.00
1	372	7.00	7.00
1	81	7.00	7.00
1	454	7.00	7.00
1	184	7.00	7.00
1	411	7.00	7.00
1	503	7.00	7.00
1	272	7.00	7.00
1	329	7.00	7.00
1	14	7.00	7.00
1	301	1.00	1.00
181	606	2.00	2.00
157	607	2.00	7.00
1	114	7.00	8.00
1	302	7.00	8.00
129	606	1.00	7.00
7	602	3.00	7.00
8	604	10.00	1.00
134	602	10.00	4.00
79	603	4.00	5.00
91	608	8.00	7.00
5	604	9.00	8.00
65	607	1.00	6.00
72	603	8.00	8.00
166	601	6.00	3.00
30	602	4.00	9.00
91	602	7.00	8.00
95	608	2.00	6.00
62	601	4.00	10.00
78	601	10.00	7.00
193	604	10.00	9.00
39	607	8.00	1.00
169	605	1.00	7.00
120	606	8.00	4.00
162	608	1.00	6.00
112	603	10.00	2.00
22	608	8.00	7.00
88	604	3.00	3.00
128	602	6.00	1.00
197	601	8.00	7.00
167	605	3.00	9.00
142	604	8.00	9.00
153	605	9.00	3.00
165	603	3.00	6.00
126	601	8.00	10.00
123	605	1.00	9.00
25	601	2.00	0.00
10	603	6.00	3.00
163	604	3.00	8.00
67	603	5.00	6.00
11	601	2.00	4.00
61	603	3.00	6.00
143	607	5.00	10.00
40	601	4.00	6.00
110	605	8.00	0.00
76	608	10.00	3.00
51	608	4.00	6.00
173	605	7.00	5.00
45	601	8.00	5.00
85	606	7.00	7.00
58	604	2.00	9.00
150	601	7.00	7.00
153	603	8.00	1.00
79	604	6.00	9.00
200	608	2.00	2.00
53	604	10.00	1.00
130	601	10.00	5.00
22	602	0.00	2.00
156	607	4.00	5.00
60	602	0.00	2.00
187	604	7.00	7.00
184	603	1.00	9.00
56	604	3.00	9.00
192	602	2.00	0.00
37	605	3.00	0.00
19	419	5.00	7.00
127	601	5.00	7.00
76	605	4.00	8.00
155	607	1.00	5.00
46	601	1.00	5.00
47	602	8.00	7.00
5	608	4.00	10.00
65	608	7.00	9.00
112	602	5.00	6.00
144	606	4.00	7.00
141	603	6.00	6.00
140	608	9.00	10.00
187	606	0.00	9.00
17	605	7.00	0.00
138	607	2.00	6.00
170	604	1.00	4.00
3	607	4.00	9.00
58	608	3.00	5.00
175	602	7.00	0.00
155	605	10.00	6.00
23	602	7.00	6.00
145	605	0.00	5.00
57	604	4.00	10.00
96	606	7.00	7.00
185	602	7.00	1.00
90	603	0.00	8.00
57	603	1.00	7.00
25	608	8.00	7.00
186	603	8.00	10.00
85	601	1.00	3.00
2	603	0.00	8.00
42	605	1.00	3.00
76	606	9.00	3.00
21	603	8.00	4.00
10	604	8.00	1.00
144	603	5.00	8.00
51	603	8.00	8.00
171	606	8.00	4.00
50	607	8.00	8.00
76	607	1.00	1.00
144	608	8.00	1.00
159	605	6.00	6.00
125	603	2.00	3.00
52	602	2.00	3.00
38	604	6.00	0.00
69	604	0.00	10.00
54	607	3.00	2.00
69	607	0.00	3.00
152	602	6.00	9.00
106	601	4.00	3.00
145	608	6.00	4.00
79	606	0.00	9.00
64	608	0.00	4.00
138	606	3.00	9.00
9	606	9.00	3.00
113	605	6.00	1.00
30	607	4.00	0.00
53	602	3.00	3.00
87	604	10.00	1.00
182	606	8.00	4.00
43	606	4.00	9.00
153	601	5.00	3.00
170	608	1.00	5.00
140	607	3.00	10.00
26	606	0.00	3.00
108	607	2.00	10.00
70	603	10.00	7.00
19	119	5.00	7.00
60	608	7.00	0.00
86	602	1.00	6.00
176	602	3.00	8.00
170	605	8.00	4.00
23	605	3.00	3.00
45	606	9.00	5.00
189	605	0.00	4.00
7	603	5.00	9.00
77	603	7.00	7.00
192	605	4.00	7.00
2	605	3.00	9.00
28	601	5.00	8.00
166	603	8.00	0.00
82	606	9.00	3.00
19	319	5.00	7.00
198	604	5.00	1.00
47	601	5.00	7.00
69	606	3.00	8.00
19	604	5.00	7.00
27	603	3.00	0.00
163	603	0.00	2.00
6	602	5.00	8.00
181	603	5.00	10.00
147	601	0.00	6.00
12	601	7.00	6.00
71	607	6.00	8.00
127	603	9.00	8.00
97	605	9.00	6.00
22	601	8.00	8.00
68	607	3.00	4.00
141	607	0.00	3.00
183	603	7.00	2.00
85	604	5.00	3.00
152	605	7.00	10.00
119	604	2.00	8.00
125	602	8.00	10.00
19	605	5.00	7.00
13	605	10.00	5.00
1	578	\N	\N
67	607	10.00	5.00
124	605	4.00	9.00
161	601	1.00	6.00
33	608	4.00	8.00
147	608	8.00	7.00
134	607	5.00	0.00
4	601	3.00	6.00
157	605	10.00	10.00
106	603	10.00	10.00
11	606	7.00	9.00
194	601	6.00	8.00
89	607	3.00	4.00
88	607	9.00	2.00
120	602	8.00	2.00
59	607	2.00	10.00
185	604	5.00	7.00
104	603	6.00	1.00
16	601	2.00	5.00
161	607	4.00	7.00
131	608	5.00	7.00
96	604	8.00	1.00
160	606	4.00	7.00
75	606	9.00	6.00
64	602	10.00	0.00
109	603	1.00	8.00
71	603	2.00	7.00
104	602	5.00	2.00
48	603	4.00	9.00
90	601	1.00	4.00
35	603	2.00	2.00
198	606	0.00	6.00
71	608	5.00	10.00
48	606	10.00	2.00
44	603	0.00	3.00
179	605	0.00	7.00
119	607	4.00	8.00
168	607	10.00	4.00
148	603	2.00	2.00
158	607	6.00	2.00
151	601	10.00	6.00
54	606	2.00	8.00
48	604	8.00	7.00
92	602	2.00	2.00
191	602	2.00	2.00
184	604	10.00	3.00
184	607	8.00	6.00
19	602	5.00	7.00
158	608	3.00	3.00
171	607	1.00	1.00
182	605	8.00	10.00
173	606	0.00	5.00
76	602	9.00	7.00
160	605	5.00	4.00
168	605	10.00	6.00
187	607	4.00	8.00
52	605	8.00	10.00
43	602	7.00	10.00
58	605	10.00	6.00
12	607	6.00	4.00
155	602	9.00	10.00
70	606	0.00	6.00
123	604	3.00	10.00
166	608	5.00	0.00
129	607	0.00	7.00
121	607	6.00	7.00
22	605	0.00	3.00
152	603	8.00	0.00
6	606	0.00	0.00
113	602	4.00	5.00
25	605	6.00	1.00
156	602	7.00	7.00
109	605	1.00	10.00
34	601	3.00	4.00
141	608	6.00	1.00
156	601	8.00	5.00
25	607	5.00	3.00
164	605	4.00	5.00
152	608	7.00	9.00
6	607	2.00	4.00
191	606	10.00	3.00
130	602	4.00	10.00
42	606	3.00	2.00
113	604	1.00	7.00
114	608	3.00	10.00
132	604	1.00	4.00
51	607	1.00	2.00
180	607	2.00	5.00
41	608	6.00	8.00
107	601	8.00	2.00
9	602	3.00	8.00
32	602	0.00	0.00
103	606	7.00	4.00
20	602	9.00	1.00
37	604	2.00	1.00
162	603	5.00	5.00
83	608	0.00	3.00
17	601	0.00	2.00
83	602	8.00	9.00
74	608	1.00	1.00
25	606	8.00	5.00
170	603	7.00	9.00
44	604	5.00	3.00
4	608	4.00	4.00
198	605	0.00	0.00
31	604	7.00	4.00
85	608	0.00	4.00
190	607	8.00	0.00
160	603	10.00	2.00
60	606	2.00	1.00
15	605	10.00	9.00
21	605	3.00	6.00
122	608	4.00	3.00
178	601	8.00	1.00
81	604	3.00	7.00
189	608	1.00	7.00
153	608	1.00	5.00
80	601	10.00	8.00
160	608	2.00	6.00
116	607	1.00	10.00
120	603	9.00	1.00
125	606	6.00	8.00
121	606	5.00	4.00
122	602	10.00	10.00
110	604	7.00	3.00
166	602	1.00	4.00
136	603	7.00	10.00
54	605	3.00	2.00
92	606	8.00	7.00
176	607	8.00	6.00
151	608	5.00	6.00
194	603	4.00	2.00
14	606	7.00	10.00
168	601	5.00	8.00
155	606	7.00	0.00
130	606	10.00	10.00
167	601	6.00	1.00
36	607	9.00	9.00
113	606	2.00	7.00
94	605	7.00	6.00
17	606	4.00	1.00
142	608	3.00	8.00
154	606	5.00	9.00
71	601	10.00	7.00
121	601	0.00	0.00
40	603	3.00	6.00
37	608	4.00	4.00
5	606	1.00	3.00
175	608	5.00	9.00
192	603	1.00	4.00
132	602	8.00	5.00
128	606	7.00	9.00
141	606	1.00	8.00
29	605	6.00	1.00
73	604	5.00	0.00
110	607	10.00	7.00
154	602	1.00	4.00
41	606	5.00	2.00
36	601	4.00	6.00
59	604	5.00	7.00
60	601	2.00	9.00
126	607	3.00	8.00
165	602	1.00	0.00
187	602	9.00	3.00
188	607	3.00	9.00
181	608	4.00	4.00
144	602	4.00	5.00
37	601	3.00	0.00
53	607	5.00	9.00
26	603	4.00	8.00
138	601	0.00	8.00
139	604	5.00	6.00
102	605	0.00	4.00
110	603	4.00	3.00
175	605	4.00	8.00
198	602	0.00	3.00
27	606	2.00	5.00
190	601	0.00	8.00
40	602	8.00	1.00
14	602	9.00	5.00
100	607	10.00	2.00
13	604	2.00	7.00
75	603	7.00	0.00
73	607	0.00	6.00
165	606	4.00	5.00
148	601	8.00	9.00
126	605	1.00	1.00
87	607	8.00	5.00
98	605	8.00	10.00
95	602	2.00	4.00
99	605	4.00	2.00
94	602	4.00	7.00
\.


--
-- Data for Name: program_requirements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.program_requirements (program_id, course_id) FROM stdin;
1	CS0101
2	CS0102
3	CS0103
4	CS0104
5	CS0105
6	CS0106
7	CS0107
8	CS0108
9	CS0109
10	CS0110
11	EN0201
12	EN0202
13	EN0203
14	EN0204
15	EN0205
16	EN0206
17	EN0207
18	EN0208
19	EN0209
20	EN0210
21	BU0301
22	BU0302
23	BU0303
24	BU0304
25	BU0305
26	BU0306
27	BU0307
28	BU0308
29	BU0309
30	BU0310
1	LA0401
2	LA0402
3	LA0403
4	LA0404
5	LA0405
6	LA0406
7	LA0407
8	LA0408
9	LA0409
10	LA0410
11	PH0501
12	PH0502
13	PH0503
14	PH0504
15	PH0505
16	PH0506
17	PH0507
18	PH0508
19	PH0509
20	PH0510
21	CS0100
22	CS0101
23	CS0102
24	CS0103
25	CS0104
26	CS0105
27	CS0106
28	CS0107
29	CS0108
30	CS0109
1	CS0110
2	EN0201
3	EN0202
4	EN0203
5	EN0204
6	EN0205
7	EN0206
8	EN0207
9	EN0208
10	EN0209
11	EN0210
12	BU0301
13	BU0302
14	BU0303
15	BU0304
16	BU0305
17	BU0306
18	BU0307
19	BU0308
20	BU0309
21	BU0310
22	LA0401
23	LA0402
24	LA0403
25	LA0404
26	LA0405
27	LA0406
28	LA0407
29	LA0408
30	LA0409
1	LA0410
2	PH0501
3	PH0502
4	PH0503
5	PH0504
6	PH0505
7	PH0506
8	PH0507
9	PH0508
10	PH0509
11	PH0510
12	CS0100
13	CS0101
14	CS0102
15	CS0103
16	CS0104
17	CS0105
18	CS0106
19	CS0107
20	CS0108
21	CS0109
22	CS0110
23	EN0201
24	EN0202
25	EN0203
26	EN0204
27	EN0205
28	EN0206
29	EN0207
30	EN0208
1	EN0209
2	EN0210
3	BU0301
4	BU0302
5	BU0303
6	BU0304
7	BU0305
8	BU0306
9	BU0307
10	BU0308
11	BU0309
12	BU0310
13	LA0401
14	LA0402
15	LA0403
16	LA0404
17	LA0405
18	LA0406
19	LA0407
20	LA0408
21	LA0409
22	LA0410
23	PH0501
24	PH0502
25	PH0503
26	PH0504
27	PH0505
28	PH0506
29	PH0507
30	PH0508
1	PH0509
2	PH0510
3	CS0100
4	CS0101
5	CS0102
6	CS0103
7	CS0104
8	CS0105
9	CS0106
10	CS0107
11	CS0108
12	CS0109
13	CS0110
14	EN0201
15	EN0202
16	EN0203
17	EN0204
18	EN0205
19	EN0206
20	EN0207
21	EN0208
22	EN0209
23	EN0210
24	BU0301
25	BU0302
26	BU0303
27	BU0304
28	BU0305
29	BU0306
30	BU0307
1	BU0308
2	BU0309
3	BU0310
4	LA0401
5	LA0402
6	LA0403
7	LA0404
8	LA0405
9	LA0406
10	LA0407
11	LA0408
12	LA0409
13	LA0410
14	PH0501
15	PH0502
16	PH0503
17	PH0504
18	PH0505
19	PH0506
20	PH0507
21	PH0508
22	PH0509
23	PH0510
24	CS0100
25	CS0101
26	CS0102
27	CS0103
28	CS0104
29	CS0105
30	CS0106
1	CS0107
2	CS0108
3	CS0109
4	CS0110
5	EN0201
6	EN0202
7	EN0203
8	EN0204
9	EN0205
10	EN0206
11	EN0207
12	EN0208
13	EN0209
14	EN0210
15	BU0301
16	BU0302
17	BU0303
18	BU0304
19	BU0305
20	BU0306
21	BU0307
22	BU0308
23	BU0309
24	BU0310
25	LA0401
26	LA0402
27	LA0403
28	LA0404
29	LA0405
30	LA0406
1	LA0407
2	LA0408
3	LA0409
4	LA0410
5	PH0501
6	PH0502
7	PH0503
8	PH0504
9	PH0505
10	PH0506
11	PH0507
12	PH0508
13	PH0509
14	PH0510
15	CS0100
16	CS0101
17	CS0102
18	CS0103
19	CS0104
20	CS0105
21	CS0106
22	CS0107
23	CS0108
24	CS0109
25	CS0110
26	EN0201
27	EN0202
28	EN0203
29	EN0204
30	EN0205
1	EN0206
2	EN0207
3	EN0208
4	EN0209
5	EN0210
6	BU0301
7	BU0302
8	BU0303
9	BU0304
10	BU0305
11	BU0306
12	BU0307
13	BU0308
14	BU0309
15	BU0310
16	LA0401
17	LA0402
18	LA0403
19	LA0404
20	LA0405
21	LA0406
22	LA0407
23	LA0408
24	LA0409
25	LA0410
26	PH0501
27	PH0502
28	PH0503
29	PH0504
30	PH0505
1	PH0506
2	PH0507
3	PH0508
4	PH0509
5	PH0510
6	CS0100
7	CS0101
8	CS0102
9	CS0103
10	CS0104
11	CS0105
12	CS0106
13	CS0107
14	CS0108
15	CS0109
16	CS0110
17	EN0201
18	EN0202
19	EN0203
20	EN0204
21	EN0205
22	EN0206
23	EN0207
24	EN0208
25	EN0209
26	EN0210
27	BU0301
28	BU0302
29	BU0303
30	BU0304
1	BU0305
2	BU0306
3	BU0307
4	BU0308
5	BU0309
6	BU0310
7	LA0401
8	LA0402
9	LA0403
10	LA0404
11	LA0405
12	LA0406
13	LA0407
14	LA0408
15	LA0409
16	LA0410
17	PH0501
18	PH0502
19	PH0503
20	PH0504
21	PH0505
22	PH0506
23	PH0507
24	PH0508
25	PH0509
26	PH0510
27	CS0100
28	CS0101
29	CS0102
30	CS0103
1	CS0104
2	CS0105
3	CS0106
4	CS0107
5	CS0108
6	CS0109
7	CS0110
8	EN0201
9	EN0202
10	EN0203
11	EN0204
12	EN0205
13	EN0206
14	EN0207
15	EN0208
16	EN0209
17	EN0210
18	BU0301
19	BU0302
20	BU0303
21	BU0304
22	BU0305
23	BU0306
24	BU0307
25	BU0308
26	BU0309
27	BU0310
28	LA0401
29	LA0402
30	LA0403
1	LA0404
2	LA0405
3	LA0406
4	LA0407
5	LA0408
6	LA0409
7	LA0410
8	PH0501
9	PH0502
10	PH0503
11	PH0504
12	PH0505
13	PH0506
14	PH0507
15	PH0508
16	PH0509
17	PH0510
18	CS0100
19	CS0101
20	CS0102
21	CS0103
22	CS0104
23	CS0105
24	CS0106
25	CS0107
26	CS0108
27	CS0109
28	CS0110
29	EN0201
30	EN0202
1	EN0203
2	EN0204
3	EN0205
4	EN0206
5	EN0207
6	EN0208
7	EN0209
8	EN0210
9	BU0301
10	BU0302
11	BU0303
12	BU0304
13	BU0305
14	BU0306
15	BU0307
16	BU0308
17	BU0309
18	BU0310
19	LA0401
20	LA0402
21	LA0403
22	LA0404
23	LA0405
24	LA0406
25	LA0407
26	LA0408
27	LA0409
28	LA0410
29	PH0501
30	PH0502
1	PH0503
2	PH0504
3	PH0505
4	PH0506
5	PH0507
6	PH0508
7	PH0509
8	PH0510
9	CS0100
10	CS0101
11	CS0102
12	CS0103
13	CS0104
14	CS0105
15	CS0106
16	CS0107
17	CS0108
18	CS0109
19	CS0110
20	EN0201
21	EN0202
22	EN0203
23	EN0204
24	EN0205
25	EN0206
26	EN0207
27	EN0208
28	EN0209
29	EN0210
30	BU0301
1	BU0302
2	BU0303
3	BU0304
4	BU0305
5	BU0306
6	BU0307
7	BU0308
8	BU0309
9	BU0310
10	LA0401
11	LA0402
12	LA0403
13	LA0404
14	LA0405
15	LA0406
16	LA0407
17	LA0408
18	LA0409
19	LA0410
20	PH0501
\.


--
-- Data for Name: programs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.programs (program_id, program_name, total_credit) FROM stdin;
2	Computer Engineering	120
3	Information Technology	120
4	Software Engineering	140
5	Data Science	130
6	Cybersecurity	140
7	Artificial Intelligence	130
8	Game Development	120
9	Mobile App Development	120
10	Web Development	130
11	Database Administration	120
12	Network Engineering	140
13	Cloud Computing	130
14	DevOps Engineering	130
15	IT Project Management	120
16	Digital Forensics	140
17	Human-Computer Interaction	120
18	Machine Learning	130
19	Robotics	140
20	Big Data Analytics	130
21	Information Systems	120
22	Augmented Reality	140
23	Virtual Reality	130
24	Bioinformatics	120
25	E-commerce Technology	130
26	IT Support Specialist	120
27	Computer Graphics	130
28	Information Assurance	140
29	Quantum Computing	140
30	IT Governance	120
1	Computer Science	60
\.


--
-- Data for Name: schools; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schools (school_id, school_name) FROM stdin;
2	School of Engineering
3	School of Business
4	School of Language
5	School of Physics
1	School of Information Technology
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.students (student_id, program_id, enrolled_year, graduated, debt) FROM stdin;
56	11	2025	enrolled	2490
57	17	2021	enrolled	3220
72	16	2021	enrolled	2540
91	7	2025	enrolled	2335
62	25	2022	enrolled	2800
78	20	2024	enrolled	2475
61	25	2021	enrolled	2700
65	29	2025	enrolled	2415
112	5	2023	enrolled	2785
79	25	2020	enrolled	3250
86	8	2025	enrolled	2220
77	14	2023	enrolled	2190
82	30	2025	enrolled	2890
69	9	2021	enrolled	2820
68	18	2025	enrolled	2345
67	9	2020	enrolled	2700
89	13	2023	enrolled	2420
88	11	2022	enrolled	2450
64	16	2024	enrolled	2695
90	5	2023	enrolled	2755
76	17	2021	enrolled	4440
58	5	2021	enrolled	3680
70	1	2023	enrolled	2550
114	24	2020	enrolled	2160
83	15	2024	enrolled	2575
74	6	2021	enrolled	2320
85	2	2023	enrolled	3725
81	8	2025	enrolled	2515
80	20	2022	enrolled	2070
92	30	2021	enrolled	3025
113	4	2024	enrolled	4000
71	27	2022	enrolled	3115
59	26	2024	enrolled	3150
60	11	2025	enrolled	4110
75	19	2024	enrolled	2985
73	3	2022	enrolled	2660
87	3	2023	enrolled	2920
63	16	2022	enrolled	1825
66	11	2025	enrolled	1990
84	27	2023	enrolled	1880
127	11	2024	enrolled	2255
124	26	2023	enrolled	2765
119	16	2022	enrolled	2950
123	18	2022	enrolled	3205
129	25	2021	enrolled	2885
116	30	2025	enrolled	2450
120	18	2025	enrolled	3430
125	3	2020	enrolled	3310
122	26	2023	enrolled	2675
130	28	2023	enrolled	3230
121	11	2021	enrolled	3010
128	22	2025	enrolled	2955
126	20	2023	enrolled	2795
115	23	2023	enrolled	2250
117	14	2025	enrolled	1435
118	16	2022	enrolled	1775
2	2	2020	enrolled	2635
8	21	2024	enrolled	2335
31	2	2023	enrolled	2530
134	21	2025	enrolled	3130
106	19	2020	enrolled	2895
180	7	2025	enrolled	2070
47	28	2021	enrolled	2840
26	10	2021	enrolled	2655
18	21	2023	enrolled	1775
24	22	2023	enrolled	2205
49	8	2023	enrolled	1735
55	19	2022	enrolled	2155
93	28	2022	enrolled	1940
101	7	2023	enrolled	2315
105	10	2024	enrolled	2045
111	23	2021	enrolled	1790
133	21	2021	enrolled	2310
135	2	2025	enrolled	1860
137	24	2024	enrolled	1675
146	30	2020	enrolled	2200
149	26	2023	enrolled	1735
99	5	2025	enrolled	2165
100	29	2021	enrolled	2340
38	23	2021	enrolled	2965
34	7	2021	enrolled	2570
33	10	2024	enrolled	2655
173	10	2020	enrolled	2850
42	19	2024	enrolled	3010
152	2	2021	enrolled	3765
143	11	2022	enrolled	1970
169	6	2020	enrolled	2090
187	4	2022	enrolled	3940
172	7	2025	enrolled	2040
174	29	2020	enrolled	1975
177	21	2024	enrolled	1690
154	4	2024	enrolled	2885
158	27	2021	enrolled	2830
39	10	2025	enrolled	2220
142	21	2020	enrolled	2895
184	2	2025	enrolled	3210
148	28	2023	enrolled	2665
41	22	2022	enrolled	2430
186	11	2024	enrolled	2160
182	9	2025	enrolled	3450
164	16	2022	enrolled	2350
53	30	2020	enrolled	2615
166	24	2024	enrolled	3665
50	15	2023	enrolled	2380
15	15	2025	enrolled	2810
153	24	2020	enrolled	2900
150	17	2020	enrolled	2380
23	10	2020	enrolled	3205
156	11	2022	enrolled	3030
109	2	2025	enrolled	3335
140	1	2023	enrolled	2850
162	2	2024	enrolled	3375
185	13	2024	enrolled	3210
155	8	2021	enrolled	4005
46	5	2020	enrolled	2470
190	22	2025	enrolled	2525
27	29	2022	enrolled	2445
183	12	2023	enrolled	2170
138	20	2025	enrolled	3405
52	5	2023	enrolled	2920
25	2	2024	enrolled	3695
32	18	2022	enrolled	2650
3	30	2023	enrolled	2285
132	29	2020	enrolled	3210
136	25	2021	enrolled	2495
45	19	2020	enrolled	3095
30	18	2020	enrolled	2770
4	24	2024	enrolled	2115
170	14	2023	enrolled	3555
28	25	2021	enrolled	2205
141	29	2025	enrolled	3200
178	22	2025	enrolled	2475
10	8	2023	enrolled	2905
159	4	2022	enrolled	2880
37	15	2023	enrolled	3410
43	20	2024	enrolled	2720
48	29	2023	enrolled	3415
165	20	2023	enrolled	3320
11	3	2025	enrolled	2520
145	20	2023	enrolled	3270
139	7	2021	enrolled	2510
12	30	2024	enrolled	2265
160	27	2023	enrolled	4340
108	29	2022	enrolled	2045
151	3	2022	enrolled	2865
44	13	2023	enrolled	2710
7	5	2021	enrolled	3370
22	16	2024	enrolled	3505
163	10	2020	enrolled	2885
144	23	2021	enrolled	3515
167	19	2022	enrolled	2760
97	24	2022	enrolled	2920
6	23	2022	enrolled	3415
191	16	2022	enrolled	2450
131	29	2025	enrolled	2315
147	12	2022	enrolled	2625
157	20	2023	enrolled	2990
16	17	2022	enrolled	2450
161	21	2023	enrolled	2740
96	5	2025	enrolled	2795
104	2	2024	enrolled	2560
35	21	2025	enrolled	2360
19	24	2020	enrolled	3800
179	9	2021	enrolled	2290
188	26	2020	enrolled	1890
98	4	2022	enrolled	2630
171	5	2020	enrolled	2460
176	16	2023	enrolled	3075
29	10	2025	enrolled	2715
51	27	2023	enrolled	3365
36	24	2024	enrolled	2535
107	22	2025	enrolled	2580
9	25	2020	enrolled	3295
103	2	2022	enrolled	2475
20	5	2021	enrolled	2470
5	2	2021	enrolled	3410
40	18	2025	enrolled	3565
21	8	2025	enrolled	3070
189	26	2024	enrolled	3055
54	14	2023	enrolled	3155
168	14	2024	enrolled	3175
1	1	2021	enrolled	640
17	12	2024	enrolled	2725
14	10	2023	enrolled	2835
175	16	2024	enrolled	3490
181	15	2025	enrolled	3260
102	9	2024	enrolled	2135
110	13	2022	enrolled	3735
13	30	2021	enrolled	2980
95	8	2025	enrolled	3080
94	23	2024	enrolled	3115
195	6	2023	enrolled	2175
196	12	2024	enrolled	1775
199	18	2022	enrolled	1605
193	12	2023	enrolled	2500
197	3	2022	enrolled	2630
200	28	2022	enrolled	2415
194	10	2022	enrolled	2765
192	19	2022	enrolled	3625
198	18	2024	enrolled	4210
\.


--
-- Data for Name: teachers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teachers (teacher_id, school_id, hired_year, qualification, profession, "position") FROM stdin;
201	1	1995	B.Ed	Mathematics	Senior Teacher
202	3	2001	M.Ed	Science	Head of Department
203	2	1998	PhD	History	Lecturer
204	5	1992	B.Ed	English	Teacher
205	1	2005	M.Ed	Physics	Senior Teacher
206	4	2010	B.Ed	Biology	Teacher
207	2	2000	M.A	Geography	Lecturer
208	3	2015	B.Ed	Computer Science	IT Coordinator
209	4	1994	PhD	Chemistry	Head of Department
210	5	1996	M.Ed	Mathematics	Teacher
211	1	1991	B.Ed	Physics	Teacher
212	3	1993	M.Sc	Biology	Senior Teacher
213	2	1997	M.A	History	Teacher
214	5	2003	PhD	Literature	Lecturer
215	2	1999	M.Ed	Civics	Teacher
216	1	2006	B.Ed	English	Senior Teacher
217	4	1990	PhD	Philosophy	Professor
218	3	2008	M.Ed	Mathematics	Teacher
219	1	1995	M.Sc	Science	Lecturer
220	2	2007	B.Ed	Social Studies	Teacher
221	5	2012	M.Ed	Computer Science	IT Teacher
222	4	1996	B.Ed	Chemistry	Teacher
223	1	2013	M.A	Economics	Lecturer
224	3	2002	PhD	Political Science	Head of Department
225	2	1994	B.Ed	Math	Teacher
226	5	1998	M.Ed	Biology	Senior Teacher
227	4	2011	PhD	Statistics	Professor
228	3	2004	M.A	History	Lecturer
229	1	1992	M.Sc	Physics	Teacher
230	2	2000	B.Ed	English	Teacher
231	5	1993	M.Ed	Science	Lecturer
232	4	2009	PhD	Math	Professor
233	1	2001	M.Sc	Biology	Teacher
234	3	2006	M.Ed	Computer Science	Coordinator
235	2	2014	B.Ed	Civics	Teacher
236	5	2010	M.Ed	Chemistry	Teacher
237	4	1997	PhD	Sociology	Lecturer
238	1	2016	B.Ed	English	Teacher
239	3	1990	M.Sc	Physics	Senior Teacher
240	2	2005	PhD	History	Professor
241	5	2007	M.Ed	Math	Lecturer
242	1	2018	B.Ed	Biology	Teacher
243	3	2002	M.A	Geography	Teacher
244	2	1996	M.Ed	Economics	Teacher
245	4	2003	PhD	Political Science	Lecturer
246	1	2008	B.Ed	Math	Senior Teacher
247	5	2019	M.Sc	Science	Teacher
248	3	2011	PhD	Computer Science	Professor
249	4	1991	B.Ed	Physics	Teacher
250	2	1995	M.Ed	English	Senior Teacher
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, first_name, last_name, email, password, role, date_of_birth, address) FROM stdin;
3	Avrom	Minocchi	aminocchi0@ibm.com	aY5<k9l%s	student	2001-05-04	92 Delladonna Court
4	Simeon	Kleinsmuntz	skleinsmuntz1@bbc.co.uk	vW9!J97Qjxc	student	2004-06-14	1655 Dahle Crossing
5	Hayyim	Karel	hkarel2@wordpress.com	zG0|%LB_fTEs	student	2000-07-03	863 Homewood Road
6	Si	Newsham	snewsham3@sina.com.cn	yD0}NLveSzI5	student	2001-12-02	09 Lunder Park
7	Abbie	Francello	afrancello4@gravatar.com	vI8{mPz~u+a`.aM4	student	2003-12-09	11 Kropf Center
8	Cord	Peto	cpeto5@prweb.com	hB3,##5pm	student	2004-02-26	4868 Oak Valley Park
9	Korney	Fenning	kfenning6@odnoklassniki.ru	uX0)n5J&@RQ+N	student	2003-08-28	58 Corben Avenue
10	Wainwright	Lishmund	wlishmund7@clickbank.net	dO0&*w0*'b	student	2001-02-01	7 Green Road
11	Wadsworth	Swancott	wswancott8@dailymail.co.uk	dJ2`beQu	student	2001-01-01	7 Mariners Cove Lane
12	Emory	Medcraft	emedcraft9@ning.com	iC3}@#EcuWpX7g\\>	student	2002-08-31	0 Oxford Point
13	Kane	Tooze	ktoozea@devhub.com	iH9\\(>myg'X	student	2002-04-27	93 Fordem Hill
14	Wyn	Le Prevost	wleprevostb@ed.gov	qK1@0MR.v	student	2005-05-05	74 Merry Lane
15	Catie	Pinn	cpinnc@alexa.com	lR1(PN9db=#W,	student	2002-11-17	09539 Becker Street
16	Sergei	Celle	scelled@typepad.com	rU9(/)+cKFT5v	student	2002-05-24	59 Annamark Pass
17	Melloney	Whatman	mwhatmane@omniture.com	cP6{GNRg	student	2002-10-30	622 Garrison Drive
18	Louise	Burdge	lburdgef@trellian.com	nR4=%kP&*Bof\\3r	student	2003-07-19	1 Milwaukee Hill
19	Coletta	Spilsted	cspilstedg@washingtonpost.com	pI3'{o$=2e?W@<R	student	2002-06-20	4418 Shoshone Place
20	Merrill	Duferie	mduferieh@examiner.com	uP8_DvjQCYLH	student	2001-08-02	47 Esch Trail
21	Paulie	Rooper	prooperi@nih.gov	fC1_Raehz	student	2004-05-29	085 Nelson Parkway
22	Bea	Wibrew	bwibrewj@tripod.com	vQ0<%1ZDfu7p	student	2004-11-06	9 Iowa Circle
23	Kristyn	Petrovic	kpetrovick@intel.com	xZ6\\|Vdz	student	2004-08-27	63 Gina Terrace
24	Petronilla	MacGovern	pmacgovernl@t-online.de	vM6@6}QyY(n6	student	2001-09-09	45079 Scott Road
25	Corenda	Scothorn	cscothornm@cpanel.net	rJ4"K.vJ,0g(k<	student	2004-12-21	853 Nova Hill
26	Jeanette	Waylett	jwaylettn@usgs.gov	gT4|\\_t=>"M$Ee0r	student	2000-10-19	535 Dwight Crossing
27	Zorine	Pipkin	zpipkino@cnbc.com	iW1(,`d8Y4r|jr$e	student	2000-10-14	8 Del Sol Alley
28	Delphine	Brailsford	dbrailsfordp@phpbb.com	oB6=#nG3nrV	student	2002-04-29	7145 Hoard Park
29	Rad	Stedman	rstedmanq@wordpress.org	nO0<Nap5	student	2001-02-12	69114 Doe Crossing Plaza
30	Adelaide	Boerderman	aboerdermanr@tripod.com	tN6#kD{pr$z='@	student	2005-03-05	50958 Sommers Plaza
31	Dov	Sibbons	dsibbonss@yelp.com	fX9{'2xk1`j	student	2003-01-22	10618 Tennessee Pass
32	Daron	Arrandale	darrandalet@bizjournals.com	hL9+*PVQp	student	2000-03-29	0 Mitchell Terrace
33	Decca	Makinson	dmakinsonu@hexun.com	aN2|02J'v	student	2001-05-21	64882 Stone Corner Circle
34	Lindy	Petrina	lpetrinav@marketwatch.com	tY9,lt\\G	student	2000-08-16	77989 Basil Parkway
35	Dosi	Chirm	dchirmw@nyu.edu	nS4#Y|#vlUWA	student	2001-05-31	88333 Corscot Park
36	Dawna	Mays	dmaysx@irs.gov	jJ8(Kx*4mEGz$,~Z	student	2004-01-07	6 Anderson Court
37	Aleece	Poure	apourey@gnu.org	zX7)Rw@T	student	2001-07-19	30 Longview Avenue
38	Tiebout	Fatkin	tfatkinz@washingtonpost.com	uF2/(_X~@r6~NB	student	2002-05-27	8947 Farmco Pass
39	Roberto	Restieaux	rrestieaux10@army.mil	cH1"ddV&a\\M	student	2002-07-09	02 Elmside Place
40	Decca	Kybert	dkybert11@constantcontact.com	xY7`o13dDl9@	student	2001-09-11	092 Oak Valley Road
41	Anet	Benitez	abenitez12@wikispaces.com	mK2{SlgREyr\\zGM	student	2000-05-21	253 Summerview Junction
42	Adan	Luard	aluard13@answers.com	cB7<M,/l$|'('1	student	2003-01-02	30 Brentwood Center
43	Rafaelia	Jex	rjex14@washingtonpost.com	oB8?qRS"H=cL$i	student	2005-07-08	5 Express Park
44	Westbrook	Vautre	wvautre15@domainmarket.com	vF3%htX$2b'Jp+TU	student	2003-07-22	7540 Trailsway Drive
45	Dominick	McEllen	dmcellen16@bloglovin.com	iV7!9c0Mvqk~5td	student	2004-09-29	441 Cherokee Trail
46	Paulita	MacSorley	pmacsorley17@cargocollective.com	vG9<k}tGY	student	2004-07-24	02356 Utah Junction
47	Paquito	Daddow	pdaddow18@wikia.com	aB0+H\\Z9,wm*."{	student	2004-01-10	79 Lerdahl Circle
48	Chickie	Craghead	ccraghead19@sitemeter.com	lF8!b)SHXgc	student	2003-10-11	3038 Ridgeway Court
49	Gabriello	Weetch	gweetch1a@dropbox.com	yC1)eUp?	student	2005-09-16	21565 Ilene Lane
50	Petronilla	De Francesco	pdefrancesco1b@yelp.com	oN3",xGf|R	student	2002-04-20	071 2nd Way
51	Damita	Dunmuir	ddunmuir1c@t-online.de	xB0+L8l#XX	student	2002-03-31	867 Porter Way
52	Dniren	Shieber	dshieber1d@youtube.com	xL1{3uUz	student	2000-09-20	89536 Farragut Alley
53	Biron	Ryall	bryall1e@storify.com	uZ4)ze7ZCj\\	student	2005-05-17	2 Scott Trail
54	Rochella	Leyden	rleyden1f@npr.org	rB1`|THqTqM'c8w	student	2002-04-02	616 Lakewood Gardens Center
55	Lindsey	Mutton	lmutton1g@photobucket.com	aQ2$88LK8	student	2001-10-04	5 Becker Crossing
56	Trevar	Japp	tjapp1h@networksolutions.com	gL3`w`@Lshyy=pg	student	2000-02-29	043 Redwing Center
57	Judon	Janout	jjanout1i@livejournal.com	fU6~lT&jx	student	2000-07-05	71666 High Crossing Hill
58	Imelda	Eykelbosch	ieykelbosch1j@ehow.com	aX7>i(<zaz	student	2000-09-06	86980 Chive Terrace
59	Alexis	Morant	amorant1k@pagesperso-orange.fr	iD2>yW9Ws~pEqXku	student	2001-08-16	32564 Scoville Plaza
60	Tami	Padbury	tpadbury1l@cam.ac.uk	zX8(dmfWVc#&RkQh	student	2004-07-25	16292 Clyde Gallagher Pass
61	Thoma	Argont	targont1m@netlog.com	jI7<j+0*s	student	2001-09-04	26638 Crescent Oaks Alley
62	Kala	Lanfranconi	klanfranconi1n@cisco.com	gY2)'}$YBVP	student	2000-07-14	8 Jackson Plaza
63	Ted	Nappin	tnappin1o@taobao.com	aP1'V!JVLw#	student	2002-10-18	98909 Dapin Place
64	Anson	Levene	alevene1p@globo.com	wH8`?U}.W.n+ziUn	student	2002-05-07	9 Sachtjen Junction
65	Von	Lethbrig	vlethbrig1q@squidoo.com	cK6"vK+BOz5g/?e	student	2002-07-08	13 Luster Drive
66	Kippie	Lund	klund1r@woothemes.com	lY3\\a?)2x3	student	2004-11-02	284 Atwood Crossing
67	Celka	Hadcock	chadcock1s@tuttocitta.it	jZ4+$<Y5msbpMqN	student	2000-05-15	22 Haas Court
68	Ardine	Chazerand	achazerand1t@printfriendly.com	aI2/\\LfWHjn{	student	2000-06-10	49 Sunfield Drive
69	Jeromy	Kingshott	jkingshott1u@answers.com	jC4{M\\~`	student	2001-06-24	499 Rigney Alley
70	Flin	Sisneros	fsisneros1v@liveinternet.ru	wB3{n%Gh4"n	student	2003-07-28	25 Thackeray Place
71	Juliet	Flade	jflade1w@psu.edu	sS3=f/NdExs2n	student	2002-01-06	408 Waywood Alley
72	Valencia	Brinkler	vbrinkler1x@list-manage.com	cG0\\#7,,}C`	student	2001-01-06	6176 Haas Terrace
73	Chere	Sexti	csexti1y@ehow.com	gX7%D2a}!t&xMFlb	student	2001-02-13	0563 Annamark Pass
74	Dennis	Gatlin	dgatlin1z@sciencedirect.com	cY9=</skZd9	student	2001-04-20	78003 Hanover Junction
75	Wenonah	Edis	wedis20@angelfire.com	gN4&nb7Zcm	student	2001-12-10	5 Westport Street
76	Eleonora	Hayball	ehayball21@freewebs.com	rW6,}0\\m	student	2002-04-21	36546 Bunker Hill Pass
77	Brendon	Gounin	bgounin22@amazonaws.com	vO6&G9bXg	student	2000-03-26	706 Kennedy Drive
78	Felita	Matteuzzi	fmatteuzzi23@cpanel.net	yW3~"!i%9@/K)!U	student	2002-09-25	9738 Golf Course Court
79	Inger	Keslake	ikeslake24@reuters.com	jG5*Poq6Sd$d=xX2	student	2004-07-26	3380 Jana Junction
80	Aron	Kidder	akidder25@bloomberg.com	sG7\\Cevd$J<q	student	2005-03-07	5 Bayside Street
81	Grant	Monard	gmonard26@topsy.com	rM7}+eBwk}26	student	2005-02-09	40 Spenser Terrace
82	Sancho	Sellwood	ssellwood27@amazon.de	pH8|1XQim~R6fA	student	2001-11-07	589 Londonderry Junction
83	Lynnette	Blackmoor	lblackmoor28@mlb.com	mD9+gtG,iD7p	student	2000-02-16	61728 Bartelt Park
84	Teddi	McKinna	tmckinna29@smugmug.com	xI4\\gf<#x7ih,	student	2003-01-16	0269 Mitchell Parkway
85	Marcela	Dudleston	mdudleston2a@hugedomains.com	iF5+dJ!{vc	student	2000-12-25	24837 Kipling Avenue
86	Tildie	Thome	tthome2b@auda.org.au	gN3|QJwRVLMUroK	student	2000-07-11	781 Brentwood Place
87	Hedwig	Gofforth	hgofforth2c@slideshare.net	gW2>}$n!	student	2005-07-15	39234 Garrison Pass
88	Anastassia	Halfhead	ahalfhead2d@blogs.com	dS4>'(|f|"jrm.<B	student	2003-04-21	0 Springview Parkway
89	Cecilia	Millea	cmillea2e@phpbb.com	lT2)>r5Xf	student	2005-01-27	3 Sunbrook Center
90	Jacquie	Wakelam	jwakelam2f@independent.co.uk	nB3+?w@=	student	2004-11-14	9 Mayer Trail
91	Darcee	Bolan	dbolan2g@ycombinator.com	yA1/I1'ch	student	2002-04-10	90 8th Trail
92	West	Yuill	wyuill2h@nymag.com	vM8~a90@+?tU&V?C	student	2004-03-17	11 Ridgeview Trail
93	Genvieve	Recke	grecke2i@bravesites.com	iP3\\'|@wU	student	2004-02-08	23030 3rd Avenue
94	Alejandrina	Agnolo	aagnolo2j@bandcamp.com	hO7"JI{#bVaf4	student	2001-02-10	4092 Monica Lane
95	Sissie	Cranch	scranch2k@bravesites.com	jQ9@P'\\OA*}	student	2004-03-25	457 Sutherland Circle
96	Charlotte	Cairns	ccairns2l@google.nl	aO7|/C"?C@kq*Ff	student	2003-04-25	8501 Steensland Pass
97	Morey	Samwell	msamwell2m@wikia.com	nF1}SAp.Q	student	2001-01-07	0 Karstens Parkway
98	Stevana	Feavers	sfeavers2n@aol.com	aS0,IP(><xm9!	student	2002-02-17	65045 Starling Plaza
99	Alaric	Beckenham	abeckenham2o@ucoz.ru	dE1)y5Xih%07	student	2003-06-22	2505 Buhler Court
100	Winfield	Falkinder	wfalkinder2p@nps.gov	mR9`02V"8	student	2000-02-27	4325 Magdeline Plaza
101	Dael	Greensitt	dgreensitt2q@dion.ne.jp	kX1&$afVLW={0~	student	2005-09-06	570 Karstens Circle
102	Alexis	Sopp	asopp2r@slate.com	iL1\\S6p|<=	student	2000-05-14	58023 International Parkway
103	Cherish	Penhaligon	cpenhaligon0@typepad.com	lC7(cb'QW?	student	1979-02-28	3242 Lillian Street
104	Sigmund	Doogue	sdoogue1@hhs.gov	xS2.@@r<a%	student	1970-08-07	2716 Burrows Lane
105	Opalina	Yourell	oyourell2@yale.edu	fQ7>ZQ*.2l+	student	1979-11-08	28296 Westridge Drive
106	Karyn	Tithecott	ktithecott3@eepurl.com	yY9()ZFjq.bz)O	student	1974-03-19	79674 Sycamore Parkway
107	Flem	Haycock	fhaycock4@google.com	qL4&R!,iLW	student	1931-04-26	86 Meadow Vale Park
108	Carmelita	Danilov	cdanilov5@eventbrite.com	oO2/E".tY	student	1914-11-02	4183 Dryden Crossing
109	Gerrie	Pendlington	gpendlington6@jalbum.net	eG9?VZwfHX}5Q~	student	2004-10-14	357 Spohn Parkway
110	Dolores	Franca	dfranca7@mapquest.com	uR5`($gw5QIrp	student	2009-01-03	9370 Mayfield Hill
111	Fredra	Pelman	fpelman8@photobucket.com	mC8,t%%n?r	student	1966-01-21	2757 Coolidge Road
112	Rick	Eagling	reagling9@flavors.me	qV1_CvE2	student	1941-03-19	9 Hoard Alley
113	Piotr	Dahlberg	pdahlberga@cnet.com	yJ6*P|V%N@3s>1	student	2000-08-20	63329 Vidon Center
114	Denny	Shelmerdine	dshelmerdineb@hugedomains.com	wP8.6+cN4	student	1944-01-01	00759 Erie Lane
115	Calida	Olivet	colivetc@tuttocitta.it	aL0`Ipg.&	student	1922-03-11	08879 Harbort Junction
116	Audrie	Bateson	abatesond@slashdot.org	iM5_p.Q3W`w4u)	student	1968-07-25	59 Mockingbird Crossing
117	Moselle	Mandifield	mmandifielde@indiatimes.com	nM7>`ye\\=f6IbHd	student	1980-02-10	55871 Kenwood Hill
118	Joey	Choupin	jchoupinf@wisc.edu	cC8'<C?y!%QKh\\I	student	1973-02-05	96 Holy Cross Way
119	Ellwood	Gleed	egleedg@goo.gl	eA8/tMAZMq|	student	1921-03-10	342 Leroy Pass
120	Dionne	Twohig	dtwohigh@nydailynews.com	oP4>Fo!j(k|	student	2018-02-19	8 Mandrake Way
121	Kelvin	Macilhench	kmacilhenchi@ucoz.ru	mH1{SA*%W|~dG	student	1975-10-12	96008 Holy Cross Plaza
122	Jemie	Pitkethly	jpitkethlyj@soup.io	yE0(}C@o_{6h	student	1921-01-18	50727 Northridge Park
1	Ngoc	Tung	student@g.com	123456	student	2005-01-05	Tieu vuong quoc 36
123	Monah	Marciek	mmarciekk@alibaba.com	vR4<iLdOdZ9	student	1925-12-09	952 Hollow Ridge Terrace
124	Deanna	Mattioli	dmattiolil@bloomberg.com	aH6+XL)3t	student	1978-06-25	00688 Fulton Circle
125	Derk	Larenson	dlarensonm@trellian.com	oP8!B@ng\\&	student	1952-01-13	68017 2nd Avenue
126	Galvin	MacGovern	gmacgovernn@newsvine.com	uS4`xYe4@=	student	1908-06-04	97295 Melody Place
127	Winn	Courtonne	wcourtonneo@eepurl.com	dM7=@\\PV	student	1995-03-25	77 Bartillon Crossing
128	Briny	Bresland	bbreslandp@harvard.edu	aA4_B|u<75x|\\r	student	2018-06-23	8772 Towne Park
129	Latrena	Colston	lcolstonq@salon.com	dD3}az!UD~>@.3	student	1992-12-17	545 Morningstar Parkway
130	Herold	Lattey	hlatteyr@redcross.org	aQ7?f,Va)zX	student	2009-05-21	3200 Spohn Avenue
131	Jo-anne	Chattington	jchattingtons@theatlantic.com	wC6,?\\Dq	student	2012-09-18	48 Cordelia Avenue
132	Rosamund	Gylle	rgyllet@jigsy.com	wL6)KLV"	student	1908-07-25	46 Thompson Place
133	Letitia	Eaklee	leakleeu@spiegel.de	aV7#m~&D1i.yf	student	2022-10-09	54490 Melby Road
134	Tedd	Treversh	ttrevershv@wordpress.com	zE8"p\\Srr4\\'	student	1961-07-19	91773 Derek Pass
135	Aurora	Sunner	asunnerw@theatlantic.com	rQ0%@9E'%o	student	1919-08-17	1 Lyons Parkway
136	Kimberlyn	Songest	ksongestx@multiply.com	rF9+?h4JU71Sma6G	student	1950-06-22	03443 Katie Way
137	Sawyere	Kimbling	skimblingy@bluehost.com	oR5_9DXJ0zm')	student	1946-11-10	4 Schurz Junction
138	Casi	Aindrais	caindraisz@prlog.org	uN1/PlG\\$T?r	student	1912-04-25	445 Mendota Drive
139	Gerta	Emeline	gemeline10@fotki.com	pE5.aZPMTVh|	student	1915-08-06	75690 Tomscot Place
140	Jo-anne	Mengo	jmengo11@devhub.com	cF1!jT,FQXM	student	1974-02-13	38 School Point
141	John	Laviste	jlaviste12@foxnews.com	vX0.|7MGxqp>	student	1952-09-08	7 Delaware Terrace
142	Ferdinande	Doey	fdoey13@businesswire.com	nM1+i{I(|Kv)z	student	1901-08-14	341 Lukken Street
143	Zolly	Totman	ztotman14@gravatar.com	iX6{}'NTNK	student	1930-04-11	848 Caliangt Junction
144	Cully	Ellacott	cellacott15@addtoany.com	sH3{.n%|E	student	1935-01-03	7890 Atwood Court
145	Bryna	Dybald	bdybald16@wordpress.com	lE8>Y9)XN	student	1982-10-03	5358 Marcy Trail
146	Wallache	McCumskay	wmccumskay17@ibm.com	aV6"mO?5@V	student	2004-11-11	199 Spohn Plaza
147	Trixi	Dowsett	tdowsett18@nba.com	gU0&>vrXk}	student	1943-12-27	368 Roth Trail
148	Marven	Tumilson	mtumilson19@netvibes.com	sS5(0h.8QU<G{W1M	student	1968-09-05	2 Charing Cross Center
149	Halsy	Creebo	hcreebo1a@wp.com	yH1*<7d(5@wK	student	1933-11-20	95101 Hollow Ridge Avenue
150	Jermaine	Pulsford	jpulsford1b@gnu.org	cG6(Y|uh	student	1988-09-09	6365 Leroy Pass
151	Rick	Diggell	rdiggell1c@samsung.com	kM8*WL(cOl\\1x	student	1976-04-15	52239 Nobel Junction
152	Wilmar	Wardale	wwardale1d@earthlink.net	uN5_1UQZ	student	2006-10-01	17788 Forest Dale Road
153	Imogen	Hegg	ihegg1e@walmart.com	qT6&79JRKy?	student	1990-07-01	686 Becker Park
154	Natalee	Kingh	nkingh1f@wordpress.org	nF2+o&*0	student	1910-12-17	46918 Caliangt Trail
155	Sherwynd	Seemmonds	sseemmonds1g@gnu.org	wO2!j6"S)=	student	1930-05-19	940 Dayton Lane
156	Roana	Traynor	rtraynor1h@opera.com	bF4\\\\*!xDCE	student	1941-05-18	72414 Elgar Way
157	Regan	Kepp	rkepp1i@mashable.com	hK5|)vru"	student	1906-12-25	7 Buena Vista Parkway
158	Hi	Bligh	hbligh1j@histats.com	zQ6=%G0l7fT#a	student	1941-04-01	53660 Sullivan Center
159	Bunni	Jacob	bjacob1k@huffingtonpost.com	xC6'4{g{ra,Dt	student	1948-08-07	64 Towne Center
160	Liesa	Childe	lchilde1l@globo.com	cX7`\\(Xk6U$	student	1997-02-11	526 Maple Alley
161	Cassie	Guerrin	cguerrin1m@artisteer.com	nI1.+pJ&k7A=	student	2005-07-28	19 Lakeland Trail
162	Shayna	Wallsworth	swallsworth1n@github.com	kA1)h!$3},<	student	1916-06-17	7948 Bunting Street
163	Matteo	Seleway	mseleway1o@eventbrite.com	fM4./2gg2OI\\1%	student	1933-02-01	325 Orin Hill
164	Temple	Stansbie	tstansbie1p@simplemachines.org	iS8_55x)*$aHMt?e	student	1926-12-07	00 Forest Run Lane
165	Olva	Schapero	oschapero1q@ning.com	kZ9|8+6~vra'	student	1955-12-27	176 Arrowood Pass
166	Rahel	Okenden	rokenden1r@wunderground.com	hH1`NMQPOh#orX	student	1995-11-08	4089 Brickson Park Pass
167	Morrie	Ostridge	mostridge1s@reference.com	jJ8!dd%f_9,8W{O	student	1915-03-11	0754 Hagan Center
168	Matilda	Byas	mbyas1t@theglobeandmail.com	zG9&`2h=O4ted$	student	1993-10-12	76 Clyde Gallagher Place
169	Perice	Boulds	pboulds1u@amazonaws.com	tX2.HL0f.FH<>ne8	student	1978-10-09	4 Lake View Court
170	Hartwell	Eilert	heilert1v@europa.eu	aX3}q(I&{=dr	student	2010-02-28	73 Heath Center
171	Christine	Fillgate	cfillgate1w@narod.ru	qW0,%~4@lRfOt%	student	1971-02-24	7 Ridge Oak Way
172	Marybeth	Illes	milles1x@youtu.be	dE5!@`"rN\\v'9c	student	1971-06-09	7 Golf View Circle
173	Kaleb	Harmon	kharmon1y@wix.com	mQ9#y?Cg2Aq	student	1940-06-11	53 Buena Vista Parkway
174	Harland	Staniforth	hstaniforth1z@google.ru	eE7@#!V_@	student	1979-01-12	72047 South Place
175	Berty	McGuffog	bmcguffog20@webeden.co.uk	aT7'=9o23e?vET=T	student	1990-03-02	475 Debs Place
176	Suzanna	McIlheran	smcilheran21@yandex.ru	tS5?NwxQnsj5F4	student	1972-05-10	100 Truax Avenue
177	Koenraad	Flacknell	kflacknell22@fema.gov	oS9+y>k|""Mu{	student	1915-04-24	90 Dayton Crossing
178	Stanley	Maylour	smaylour23@altervista.org	tZ9!r/~&F\\nH$	student	1978-04-11	1 Roxbury Drive
179	Stavros	Gard	sgard24@nymag.com	lH3_Rp5.yppDw9	student	1911-07-04	6 Melrose Drive
180	Reggie	Potkin	rpotkin25@360.cn	iI8/w%cuxf=PTu	student	2007-05-07	102 Carberry Court
181	Vinnie	Goodridge	vgoodridge26@merriam-webster.com	sL0}mZH=0c$CW+}	student	1954-03-30	10 Lake View Center
182	Kin	Scorton	kscorton27@skyrock.com	hU1_bAR\\O4>TCmYt	student	1919-11-21	1 Almo Terrace
183	Hestia	Perview	hperview28@unicef.org	eH1*>K_r	student	2022-05-15	59452 Veith Way
184	Karol	Checcucci	kcheccucci29@tiny.cc	vI0'8S"o5w	student	1935-10-04	934 Corry Parkway
185	Mareah	Giacobelli	mgiacobelli2a@posterous.com	nH1.AxNp	student	1914-10-14	4 Cherokee Road
186	Von	Le Brom	vlebrom2b@mediafire.com	uG7<y!4em6YUY&.=	student	1956-11-19	7 Maple Wood Avenue
187	Arda	Staziker	astaziker2c@weebly.com	vL1?3ViW<	student	1964-09-11	64844 Waywood Road
188	Adolphe	Bohden	abohden2d@phpbb.com	mQ8(2soJNP)|FU	student	1906-05-20	06786 Esker Park
189	Jazmin	Bineham	jbineham2e@gov.uk	xU0&MyW&6\\	student	1951-04-07	7011 6th Lane
190	Kelcie	Kalf	kkalf2f@reverbnation.com	oJ6(h<EVZE7uV.$Y	student	1958-05-04	20398 Merrick Hill
191	Bronny	McGarvie	bmcgarvie2g@gnu.org	eM7)0lUie6Bg+	student	1993-01-11	94780 Johnson Junction
192	Danella	Reuter	dreuter2h@geocities.com	cY2<xZ/I_iv>Do,w	student	1919-02-20	46 Coleman Park
193	Brant	Roscrigg	broscrigg2i@booking.com	sL3|}5k\\	student	1992-10-04	850 Annamark Place
194	Ethelyn	Blankman	eblankman2j@examiner.com	mB5)aM\\ScA$um	student	1991-10-07	111 Union Park
195	Cooper	Juanico	cjuanico2k@blogger.com	dW4?x&5.vMyKXD	student	2016-02-23	4525 Twin Pines Road
196	Elonore	Holt	eholt2l@theglobeandmail.com	tB0,XZiX{YA~wS.	student	2015-03-22	69 Carey Point
197	Whitaker	Adicot	wadicot2m@economist.com	aW6`)S{RkkRcqW	student	1910-03-10	2 Cordelia Avenue
198	Babette	Littefair	blittefair2n@feedburner.com	hA8{{O<w8*`	student	1912-08-01	0245 Maple Wood Alley
199	Kelsey	Grandison	kgrandison2o@issuu.com	sD5\\9YFi&)a}=	student	1993-12-08	9 Mockingbird Street
202	Arlinda	Biggadike	abiggadike1@amazon.co.uk	fW8,U#UYO5Xa	teacher	1959-09-20	01294 Fairview Street
203	Margaretta	Pikesley	mpikesley2@nytimes.com	qF2\\{.!%Pfb	teacher	2006-02-01	378 Holmberg Place
204	Ricki	Simes	rsimes3@devhub.com	aI8@st`pP5T	teacher	1900-04-23	23155 Northview Terrace
205	Eliot	Howley	ehowley4@amazon.co.jp	tV6*+1@FV#FYN@!F	teacher	1940-11-26	1 Kings Point
206	Kiley	Fallowes	kfallowes5@issuu.com	rK5@?paQt7L	teacher	1950-04-01	49197 Acker Plaza
207	Rosco	Hamsley	rhamsley6@prlog.org	fW3~+WIgaJpa"(ES	teacher	1948-11-30	5 Monterey Drive
208	Henrie	Lowensohn	hlowensohn7@nature.com	nI6}boeHBa'	teacher	1968-02-22	1 Nevada Center
209	Carney	Satyford	csatyford8@vistaprint.com	mC1&eY$KO	teacher	1906-01-06	1061 Village Green Pass
210	Ardyth	Kaszper	akaszper9@gravatar.com	iS7{70d?&LO	teacher	1980-09-29	7267 Oriole Pass
211	Anne-marie	Loughran	aloughrana@joomla.org	cL5$t47hSQc	teacher	1968-03-12	51222 Orin Trail
212	Pearl	Fandrey	pfandreyb@linkedin.com	kJ9!R#`Uu4	teacher	1930-07-03	017 Florence Alley
213	Rois	Paolacci	rpaolaccic@bloomberg.com	lY5'yBO#&\\t?	teacher	1980-10-26	23637 Farwell Circle
214	Tiler	Smalles	tsmallesd@com.com	iD9{hY8.o`L~7~	teacher	1913-11-24	59 Elmside Trail
215	Bambie	Conrad	bconrade@bbc.co.uk	eC2>4!*xRD	teacher	2017-04-14	4 Loeprich Parkway
216	Doralynn	Fairbairn	dfairbairnf@domainmarket.com	uR5#F*sia	teacher	1981-06-10	6208 Stone Corner Park
217	Carmine	Cancott	ccancottg@apple.com	kH8\\09pYF5"L`}	teacher	1932-09-19	2 Continental Alley
218	Lotty	Woollcott	lwoollcotth@hp.com	yO1{D%1(&)_s`	teacher	1910-03-14	146 Almo Road
219	Merna	Colter	mcolteri@ucsd.edu	uB7{d?fM|F/	teacher	1942-02-12	461 Hayes Court
220	Tristan	McRobbie	tmcrobbiej@imgur.com	vU6|D`#n#t_e?%	teacher	1949-06-12	076 Rockefeller Junction
221	Tamiko	Matzl	tmatzlk@virginia.edu	gJ7{Z/AtwT3Qm	teacher	2016-09-27	9 Maryland Avenue
222	Berke	Courtonne	bcourtonnel@privacy.gov.au	qQ6\\H_Tb	teacher	1961-08-23	73 Eliot Street
223	Cammi	Windross	cwindrossm@nbcnews.com	cE9<gVQrxn"s	teacher	1904-06-17	09 Gulseth Lane
224	Susan	Astridge	sastridgen@amazon.de	jY9.(iH@.)0<ud	teacher	1958-01-26	87383 Dixon Hill
225	Kelsy	Dorking	kdorkingo@usgs.gov	iC1~jX<$UNF(CAK	teacher	1944-09-24	9 Mesta Lane
226	Sansone	Brason	sbrasonp@scientificamerican.com	hW6+wik~M2*F)	teacher	2003-09-18	27 Pankratz Parkway
227	Yettie	Durrington	ydurringtonq@wunderground.com	mH5_tJ$t4	teacher	1999-05-24	864 Hayes Parkway
228	Kira	Stothert	kstothertr@cornell.edu	eR6$2c.XsT(em_	teacher	1953-03-06	6154 Havey Road
229	Gnni	Mowday	gmowdays@jigsy.com	fM2$!J<$&(5	teacher	1961-04-24	2 Macpherson Park
230	Radcliffe	Tunno	rtunnot@cyberchimps.com	yE4<(WiK,Af	teacher	1931-11-27	3 Blackbird Point
231	Jules	Koppe	jkoppeu@networksolutions.com	cU2.R!M!'Lv	teacher	1900-09-17	77926 Straubel Point
232	Buck	Ehrat	behratv@ft.com	uM5+"eip.(58Z	teacher	1982-08-18	2163 Fieldstone Park
233	Margalo	Beautyman	mbeautymanw@wsj.com	wN1>)QNwG	teacher	1929-10-09	9 Kenwood Lane
234	Tomaso	Pawson	tpawsonx@canalblog.com	oH8#6vN)RR	teacher	1900-08-11	4 Ohio Way
235	Solomon	Hagger	shaggery@woothemes.com	fD4|OK?Rwwyq_2v1	teacher	1926-11-27	9276 Myrtle Avenue
236	Lilian	Gillingham	lgillinghamz@51.la	cQ8~"\\G8%l	teacher	2010-09-05	3404 Anhalt Circle
237	Teena	Stribling	tstribling10@shutterfly.com	nY8+D'UreNt$	teacher	1971-05-02	0 Summit Plaza
238	Karie	Inkin	kinkin11@cbc.ca	qR6%SP%!8R	teacher	1956-09-26	338 Westport Drive
239	Andie	Boswood	aboswood12@wikimedia.org	aH6"*Scyv	teacher	1909-09-05	340 Sunnyside Circle
240	Spense	Flew	sflew13@foxnews.com	uT9\\Z\\GzyRl	teacher	1943-07-24	46340 Cherokee Crossing
241	Tove	Gedling	tgedling14@liveinternet.ru	uZ8}3xz3Pl	teacher	1950-07-16	30710 Independence Avenue
242	Bibi	Calow	bcalow15@newyorker.com	kJ6('0dK	teacher	1902-12-28	4610 Columbus Crossing
243	Justina	Coster	jcoster16@nba.com	kA8}WAz\\0	teacher	1962-01-12	7281 Wayridge Crossing
244	Louise	Mizzen	lmizzen17@tumblr.com	kC6(pv/7hUaR	teacher	2005-05-29	797 Washington Way
245	Ronda	Harfoot	rharfoot18@scientificamerican.com	bL6{N`.hVnx.mR	teacher	1961-08-30	7 Shopko Street
246	Griffy	Kliemchen	gkliemchen19@ow.ly	bJ7}tv!YuA'wN$	teacher	1938-08-09	0933 Haas Avenue
247	Chaunce	Yetman	cyetman1a@ycombinator.com	tO8+dSYD*X6&~P\\	teacher	1940-04-25	08720 Amoth Hill
248	Sheila-kathryn	Breddy	sbreddy1b@usa.gov	dG1)K\\JH	teacher	2006-07-17	7 Moland Terrace
249	Francesca	Clemmen	fclemmen1c@biblegateway.com	aF8!RYvD	teacher	1999-09-01	359 Crowley Junction
250	Gabie	Durand	gdurand1d@ning.com	iI1*RR>O3/@nLy+	teacher	1908-10-14	72355 Lunder Alley
2	Devon	Griffen	fps4day@gmail.com	123456	student	2005-01-26	Le Thanh Nghi
200	Demetrius	Hollingby	zzz@g.com	123456	student	1955-12-14	2 Memorial Parkway
201	Stillmann	Ridpath	teacher@g.com	123456	teacher	1994-10-28	661 Summit Way
\.


--
-- Name: classes_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.classes_class_id_seq', 608, true);


--
-- Name: programs_program_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.programs_program_id_seq', 30, true);


--
-- Name: schools_school_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schools_school_id_seq', 1, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 102, true);


--
-- Name: classes classes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (class_id);


--
-- Name: courses courses_course_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_course_id_unique PRIMARY KEY (course_id);


--
-- Name: program_requirements program_course_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_requirements
    ADD CONSTRAINT program_course_unique UNIQUE (program_id, course_id);


--
-- Name: programs programs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_pkey PRIMARY KEY (program_id);


--
-- Name: schools schools_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT schools_pkey PRIMARY KEY (school_id);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (student_id);


--
-- Name: teachers teachers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_pkey PRIMARY KEY (teacher_id);


--
-- Name: enrollments unique_student_class; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT unique_student_class UNIQUE (student_id, class_id);


--
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: idx_classes_course_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_classes_course_id ON public.classes USING btree (course_id);


--
-- Name: idx_classes_semester; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_classes_semester ON public.classes USING btree (semester);


--
-- Name: idx_classes_teacher_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_classes_teacher_id ON public.classes USING btree (teacher_id);


--
-- Name: idx_courses_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courses_school_id ON public.courses USING btree (school_id);


--
-- Name: idx_enrollments_class_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_enrollments_class_id ON public.enrollments USING btree (class_id);


--
-- Name: idx_enrollments_student_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_enrollments_student_id ON public.enrollments USING btree (student_id);


--
-- Name: idx_program_requirements_course_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_program_requirements_course_id ON public.program_requirements USING btree (course_id);


--
-- Name: idx_program_requirements_program_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_program_requirements_program_id ON public.program_requirements USING btree (program_id);


--
-- Name: idx_students_graduated; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_graduated ON public.students USING btree (graduated);


--
-- Name: idx_students_program_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_program_id ON public.students USING btree (program_id);


--
-- Name: idx_teachers_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teachers_school_id ON public.teachers USING btree (school_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: classes_view _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.classes_view AS
 SELECT c.class_id,
    c.teacher_id,
    c.course_id,
    c.capacity,
    c.semester,
    c.status,
    c.day_of_week,
    c.location,
    count(e.student_id) AS enrolled_count
   FROM (public.classes c
     LEFT JOIN public.enrollments e ON ((e.class_id = c.class_id)))
  GROUP BY c.class_id;


--
-- Name: enrollments trg_adjust_student_debt; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_adjust_student_debt AFTER INSERT OR DELETE OR UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION public.adjust_student_debt();


--
-- Name: classes classes_course_id_courses_course_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_course_id_courses_course_id_fk FOREIGN KEY (course_id) REFERENCES public.courses(course_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: classes classes_teacher_id_teachers_teacher_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_teacher_id_teachers_teacher_id_fk FOREIGN KEY (teacher_id) REFERENCES public.teachers(teacher_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: courses courses_school_id_schools_school_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_school_id_schools_school_id_fk FOREIGN KEY (school_id) REFERENCES public.schools(school_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: enrollments enrollments_class_id_classes_class_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_class_id_classes_class_id_fk FOREIGN KEY (class_id) REFERENCES public.classes(class_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: enrollments enrollments_student_id_students_student_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_student_id_students_student_id_fk FOREIGN KEY (student_id) REFERENCES public.students(student_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: program_requirements program_requirements_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_requirements
    ADD CONSTRAINT program_requirements_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id);


--
-- Name: program_requirements program_requirements_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_requirements
    ADD CONSTRAINT program_requirements_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id);


--
-- Name: students students_program_id_programs_program_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_program_id_programs_program_id_fk FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: students students_student_id_users_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_student_id_users_user_id_fk FOREIGN KEY (student_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teachers teachers_school_id_schools_school_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_school_id_schools_school_id_fk FOREIGN KEY (school_id) REFERENCES public.schools(school_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teachers teachers_teacher_id_users_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_teacher_id_users_user_id_fk FOREIGN KEY (teacher_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

