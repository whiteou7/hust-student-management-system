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
  FROM enrollments e
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
  SELECT 
    COALESCE(SUM(c.credit), 0),
    COALESCE(SUM(c.credit * ((e.mid_term + e.final_term)/2.0)), 0)
  INTO total_credits, total_weighted_score
  FROM enrollments e
  JOIN classes cl ON e.class_id = cl.class_id
  JOIN courses c ON cl.course_id = c.course_id
  WHERE e.student_id = calculate_cpa.student_id AND e.pass = TRUE;

  IF total_credits > 0 THEN
    result := total_weighted_score / total_credits;
  END IF;

  RETURN result;
END;
$$;


ALTER FUNCTION public.calculate_cpa(student_id integer) OWNER TO postgres;

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
    program_id integer,
    course_id character varying(6)
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
3	2	BU0309	30	2024.2	open	Saturday	Room 202
1	2	CS0101	30	2024.2	open	Monday	Room 101
4	9	CS0103	30	2023.2	open	Friday	Room 101
2	9	CS0102	30	2024.2	open	Tuesday	Room 102
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
BU0301	Financial Accounting	4	150	3	Covers principles of financial accounting, balance sheets, and income statements.
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
\.


--
-- Data for Name: enrollments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.enrollments (student_id, class_id, mid_term, final_term) FROM stdin;
1	1	6.00	9.00
1	3	6.00	9.00
1	2	6.00	3.00
1	4	6.00	3.00
2	1	6.00	7.00
\.


--
-- Data for Name: program_requirements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.program_requirements (program_id, course_id) FROM stdin;
1	CS0101
1	CS0102
\.


--
-- Data for Name: programs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.programs (program_id, program_name, total_credit) FROM stdin;
1	Computer Science	120
2	Computer Engineering	120
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
2	2	2020	enrolled	300
1	1	2022	enrolled	300
\.


--
-- Data for Name: teachers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teachers (teacher_id, school_id, hired_year, qualification, profession, "position") FROM stdin;
9	1	2015	PhD	Mathematics	Teacher
32	1	2020	PhD	Mathematics	Secretary
53	2	2023	PhD	Mathematics	Secretary
2	1	2025	PhD	Mathematics	Teacher
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, first_name, last_name, email, password, role, date_of_birth, address) FROM stdin;
3	Darci	Armall	\N	\N	student	\N	\N
4	Portie	Vedeneev	pvedeneev2@meetup.com	\N	student	\N	\N
5	Maddie	Joist	\N	rX1('PO!n>	student	\N	\N
6	Cody	Bailes	\N	tB4'lQBDZ	student	\N	\N
7	Meggie	O' Timony	\N	\N	student	\N	\N
8	Corette	Lismore	clismore6@amazon.de	\N	student	\N	\N
9	Kaine	Takis	ktakis7@zimbio.com	eK1><s6p<"6	teacher	\N	\N
10	Sayers	Rothchild	srothchild8@google.com.au	mR3|oJ')K>3_6	student	\N	\N
11	Jana	McLice	jmclice9@yandex.ru	\N	student	\N	\N
12	Amye	Davana	adavanaa@mlb.com	fR2#"l6GPU	student	\N	\N
13	Florina	Abell	fabellb@desdev.cn	dZ9!PSx$	student	\N	\N
14	Erminia	Knatt	eknattc@jalbum.net	bV6#eM2}NjKG$	student	\N	\N
15	Hedvig	Kobierzycki	\N	cS3=LE&>L	student	\N	\N
16	Vachel	Creavan	vcreavane@privacy.gov.au	\N	student	\N	\N
17	Lorene	Drackford	\N	\N	student	\N	\N
18	Rutter	Ingliss	ringlissg@dedecms.com	\N	student	\N	\N
19	Luz	Lyddon	llyddonh@barnesandnoble.com	nN2%*(r+Q8S	student	\N	\N
20	Lorne	Lidstone	\N	\N	student	\N	\N
21	Lew	Georger	lgeorgerj@mozilla.org	mX2/Z4e{}2	student	\N	\N
22	Vere	Mc Faul	vmcfaulk@npr.org	kK6~XZ{>~8pCT.v	student	\N	\N
23	Milton	Goodnow	\N	\N	student	\N	\N
24	Gavra	Bartke	gbartkem@hhs.gov	\N	student	\N	\N
25	Iorgos	Bryden	\N	kT4+a,Tk?569??n	student	\N	\N
26	Wilton	Ringer	wringero@weebly.com	oT0&34Ej#Z	student	\N	\N
27	Tabbie	Martusov	tmartusovp@smh.com.au	\N	student	\N	\N
28	Ronalda	Mabone	rmaboneq@4shared.com	mF9<8MMV&5+JOl5~	student	\N	\N
29	Merle	Parkeson	\N	\N	student	\N	\N
30	Godwin	Diaper	\N	bQ6+3.)=A~3f<t4E	student	\N	\N
31	Torin	Phibb	\N	qP8*1"Uhme	student	\N	\N
32	Nathaniel	Frend	nfrendu@ucsd.edu	\N	teacher	\N	\N
33	Cordi	Francis	cfrancisv@auda.org.au	kL7<S$}@s(ZrJ~	student	\N	\N
34	Kessia	Pigden	kpigdenw@google.pl	yS0{IAZSE2#v$k	student	\N	\N
35	Carmela	Belison	cbelisonx@cnet.com	\N	student	\N	\N
36	Reuven	Longlands	\N	sQ3+QzY&@X1wL5XK	student	\N	\N
37	Major	Duiged	\N	wC7\\6W\\~kqwa@	student	\N	\N
38	Sheila-kathryn	Pidwell	\N	\N	student	\N	\N
39	Scarlet	MacAllister	smacallister11@biglobe.ne.jp	\N	student	\N	\N
40	Melisent	Filby	\N	\N	student	\N	\N
41	Rudie	Elderkin	\N	jX4(>h`3OkiqIh	student	\N	\N
42	Morrie	Barns	mbarns14@usnews.com	\N	student	\N	\N
43	Brandise	Harron	bharron15@1und1.de	\N	student	\N	\N
44	Avie	Tesoe	atesoe16@cdc.gov	\N	student	\N	\N
45	Caye	Saw	\N	pL6,>gSE	student	\N	\N
46	Giff	Stable	gstable18@chicagotribune.com	\N	student	\N	\N
47	Brander	Feyer	bfeyer19@imdb.com	vZ5?pwC"~,nSf	student	\N	\N
48	Donia	Normanville	dnormanville1a@merriam-webster.com	oK0.P{Vv44q><'	student	\N	\N
49	Augusta	Drury	adrury1b@youtube.com	\N	student	\N	\N
50	Emogene	Ivanin	eivanin1c@is.gd	fB4=B}xS%	student	\N	\N
51	Zsazsa	Deas	zdeas1d@istockphoto.com	mR5@Nn'yC'	student	\N	\N
52	Billy	Petracchi	\N	vF2%NY2*O	student	\N	\N
53	Clay	Moorton	cmoorton1f@si.edu	\N	teacher	\N	\N
54	Jose	Mielnik	\N	\N	student	\N	\N
55	Fanny	Shortall	\N	\N	student	\N	\N
56	Reamonn	Eckly	\N	\N	student	\N	\N
57	Blondelle	Wheelhouse	\N	\N	student	\N	\N
58	Hatti	Finley	hfinley1k@nifty.com	sT9#0BtIz	student	\N	\N
59	Bertie	Rollo	brollo1l@fotki.com	lB0_!qC}l@}|O	student	\N	\N
60	Dean	Lyddon	\N	\N	student	\N	\N
61	Britta	Kyneton	bkyneton1n@pen.io	\N	student	\N	\N
62	Oswell	McCully	\N	\N	student	\N	\N
63	Ty	Lundberg	\N	aH2)+,'4BtPR	teacher	\N	\N
64	Roddie	Smitherham	rsmitherham1q@imgur.com	\N	student	\N	\N
65	Haily	McCord	hmccord1r@over-blog.com	kW8.ew+(7	student	\N	\N
66	Genvieve	Gouthier	\N	aB3'8IEb}*	student	\N	\N
67	Gareth	Surgenor	\N	aS4}GI4)+5i3	student	\N	\N
68	Timmi	Gockelen	\N	\N	student	\N	\N
69	Dedra	Catley	\N	\N	student	\N	\N
70	Llewellyn	Carolan	\N	\N	student	\N	\N
71	Clay	Wetton	\N	\N	student	\N	\N
72	Isis	Meake	imeake1y@w3.org	lF1~8TgUj3	student	\N	\N
73	Rozamond	Northill	rnorthill1z@fotki.com	\N	student	\N	\N
74	Cobbie	Bonifazio	\N	\N	student	\N	\N
75	Kamillah	Woodruffe	\N	\N	student	\N	\N
76	Kanya	Ferrandez	\N	\N	teacher	\N	\N
77	Wolfie	Llopis	\N	\N	student	\N	\N
78	Susy	Sango	\N	tK5?xK3({kw	student	\N	\N
79	La verne	Impy	limpy25@cloudflare.com	\N	student	\N	\N
80	Anni	Dexter	\N	uR2&Ndbhwq>NN>	student	\N	\N
81	Siobhan	Barnsdale	\N	bQ1%\\sl8P&!	student	\N	\N
82	Man	Jaquemar	mjaquemar28@hibu.com	tV2)hpVX	student	\N	\N
83	Rosalind	Raveau	\N	nI7=@MG0>E>	student	\N	\N
84	Bessy	Cashman	\N	\N	student	\N	\N
85	Agata	Bamlet	\N	nO4={T_$	student	\N	\N
86	Andromache	Knoller	\N	\N	student	\N	\N
87	Bernelle	MacKean	bmackean2d@cyberchimps.com	tR6,5by`LGaF8=V	student	\N	\N
88	Alix	Flade	\N	\N	student	\N	\N
89	Adela	Demange	ademange2f@pcworld.com	mF2\\4#/vI5w	student	\N	\N
90	Alexandre	Naris	\N	yD7#7%ydEW	student	\N	\N
91	Nollie	Priest	\N	oM8~#j`dO9<r|O	student	\N	\N
92	Phyllida	Cavnor	pcavnor2i@cnet.com	mU1=!xJ)\\e@	student	\N	\N
93	Andy	Tomaschke	atomaschke2j@de.vu	\N	student	\N	\N
94	Marney	Waud	\N	\N	student	\N	\N
95	Sean	Skoggings	\N	\N	student	\N	\N
96	Frederica	Cason	fcason2m@redcross.org	qQ6$|@c_	student	\N	\N
97	Sisile	Allain	sallain2n@desdev.cn	\N	student	\N	\N
98	Laurel	Daunay	ldaunay2o@mozilla.com	vZ6+B`D.a}E@Y4Vt	student	\N	\N
99	Hestia	Ofener	hofener2p@typepad.com	iE6(y#EZ	student	\N	\N
100	Winne	Hatfield	\N	aU3@\\@3+%VLxVj\\j	student	\N	\N
101	Piper	Rosina	prosina2r@buzzfeed.com	\N	student	\N	\N
102	Glyn	Galego	\N	\N	student	\N	\N
103	Jamaal	Olczak	\N	\N	student	\N	\N
104	Sibby	Bohje	\N	\N	student	\N	\N
105	Jens	Demeza	\N	\N	student	\N	\N
106	Burk	Battison	bbattison2w@virginia.edu	tR9>8|c5RjBC_+>N	student	\N	\N
107	Amie	Brenstuhl	\N	\N	student	\N	\N
108	Kaia	Cowell	\N	\N	student	\N	\N
109	Pearce	Eneas	peneas2z@reuters.com	\N	student	\N	\N
110	Leif	Swash	lswash30@discovery.com	\N	student	\N	\N
111	Audry	Semeradova	\N	\N	student	\N	\N
112	Annabel	Franceschi	afranceschi32@tumblr.com	\N	teacher	\N	\N
113	Cordie	Audiss	caudiss33@techcrunch.com	\N	student	\N	\N
114	Brenden	Krikorian	\N	iX4<)dOR!&`mx	student	\N	\N
115	Chip	Johnikin	\N	\N	student	\N	\N
116	Lyle	Link	\N	zJ6{PwxIAcK<h	student	\N	\N
117	Helenka	O'Hoolahan	\N	hA9\\<NF*l	student	\N	\N
118	Gregorius	Furmage	\N	\N	student	\N	\N
119	Arley	Everist	\N	kZ2}g5D0+!~<k~	student	\N	\N
120	Ferrel	Diggles	fdiggles3a@narod.ru	\N	student	\N	\N
121	Gothart	Horbart	ghorbart3b@wikimedia.org	\N	student	\N	\N
122	Hannah	Posselt	\N	\N	teacher	\N	\N
123	Pamelina	Regis	\N	oR2\\H!#AxZ	student	\N	\N
124	Pauline	Pearcey	\N	jC5"}&Pda1%	teacher	\N	\N
125	Ki	Ferraraccio	\N	\N	student	\N	\N
126	Samaria	Sollon	\N	nO3#/{2%	student	\N	\N
127	Hedi	Follen	\N	tX1~_cX,iY	student	\N	\N
128	Gael	Mowle	gmowle3i@vk.com	\N	student	\N	\N
129	Natal	Crummy	ncrummy3j@patch.com	\N	student	\N	\N
130	Kalli	Albone	\N	uV2~bL8dxr\\M	student	\N	\N
131	Ingrim	Mateescu	imateescu3l@gnu.org	dB9*bGK1	student	\N	\N
132	Bren	Symmons	\N	\N	teacher	\N	\N
133	Kettie	Ochterlonie	kochterlonie3n@purevolume.com	\N	student	\N	\N
134	Jock	Lucia	jlucia3o@vk.com	\N	student	\N	\N
135	Gayle	Davage	gdavage3p@umich.edu	\N	student	\N	\N
136	Gert	Shelmerdine	\N	\N	student	\N	\N
137	Melony	Wrenn	\N	yU3+os!{k2E`	student	\N	\N
138	Amargo	Allabarton	\N	\N	student	\N	\N
139	Marga	Fowlds	mfowlds3t@mayoclinic.com	\N	student	\N	\N
140	Griswold	Havoc	ghavoc3u@ebay.com	\N	student	\N	\N
141	Kahaleel	Veighey	\N	oS3=r!=li8	student	\N	\N
142	Damaris	Wittey	dwittey3w@webnode.com	\N	student	\N	\N
143	Kelly	Cattonnet	kcattonnet3x@apple.com	wV6&Sw+jcj~U@#j/	student	\N	\N
144	Sile	Cummings	scummings3y@yellowbook.com	\N	student	\N	\N
145	Reggie	O'Loughane	roloughane3z@arizona.edu	\N	student	\N	\N
146	Hastie	Camsey	hcamsey40@odnoklassniki.ru	\N	student	\N	\N
147	Urbain	Thurlbeck	uthurlbeck41@lulu.com	\N	student	\N	\N
148	Edna	Rubinow	\N	rU6<i{4@Rmx	student	\N	\N
149	Trixie	Hampson	thampson43@cnet.com	\N	student	\N	\N
150	Cherish	Deveril	\N	\N	student	\N	\N
151	Adam	Van Cassel	\N	\N	student	\N	\N
152	Feliks	Alkin	falkin46@vimeo.com	\N	student	\N	\N
153	Alfons	Martinec	amartinec47@google.nl	uV5'4eV&HGt9J	student	\N	\N
154	Modesta	Whiteway	\N	\N	student	\N	\N
155	Ruggiero	Arnout	\N	eL2?3hq`6Wz>	student	\N	\N
156	Petunia	Ortsmann	\N	zE9<{(eS!`bZE	student	\N	\N
157	Lanny	Alenikov	lalenikov4b@squarespace.com	oG6|>oh}g<E9p	student	\N	\N
158	Niven	Adamoli	nadamoli4c@mapy.cz	\N	student	\N	\N
159	Kristien	Fawdrie	\N	\N	student	\N	\N
160	Bradley	Huburn	\N	qQ2!%X,h	student	\N	\N
161	Arlana	Glastonbury	aglastonbury4f@army.mil	\N	student	\N	\N
162	Missie	Eyden	\N	\N	student	\N	\N
163	Kelcey	Havick	\N	\N	student	\N	\N
164	Margo	Batie	\N	hZ9,}&o7hp	student	\N	\N
165	Hamid	Lindsell	\N	\N	student	\N	\N
166	Jobey	Hindrick	\N	rD8"51b`y#Y	student	\N	\N
167	Gaynor	Mandrey	\N	\N	student	\N	\N
168	Kori	Mothersdale	kmothersdale4m@dyndns.org	lE6}=#!gHCpg	student	\N	\N
169	Maynord	Spleving	\N	\N	student	\N	\N
170	Ali	McKimmie	amckimmie4o@about.com	\N	student	\N	\N
171	Nikolas	Rawlison	\N	oC3#NL.z&&gE%	student	\N	\N
172	Pavel	Spurdens	\N	\N	student	\N	\N
173	Brnaby	Napper	\N	zI3_%MkGTmrsSk	student	\N	\N
174	Davida	Brinson	\N	qL6>p#}Ma!z60YY	student	\N	\N
175	Cindee	Fodden	\N	wB3*uOu#{za	student	\N	\N
176	Janine	Haward	\N	kM6)0xc3\\#>X{	student	\N	\N
177	Elana	Pittwood	epittwood4v@chicagotribune.com	\N	student	\N	\N
178	Bernadette	Gonneau	\N	\N	student	\N	\N
179	Rorie	Gruszecki	rgruszecki4x@cyberchimps.com	uJ4+t>L7>{9fD	student	\N	\N
180	Dudley	Taphouse	dtaphouse4y@taobao.com	\N	student	\N	\N
181	Keen	Aliman	\N	bW5`_sC{Vec	student	\N	\N
182	Boyce	Dyka	bdyka50@prlog.org	\N	student	\N	\N
183	Matthew	Wratten	mwratten51@businesswire.com	\N	student	\N	\N
184	Rudolfo	Rizzardo	rrizzardo52@netvibes.com	\N	student	\N	\N
185	Sharron	Phonix	\N	\N	student	\N	\N
186	Barbara-anne	Cristofalo	bcristofalo54@pinterest.com	\N	student	\N	\N
187	Claudia	Rikard	crikard55@reference.com	kC7/!Qjjida~$%	student	\N	\N
188	Toiboid	Shardlow	tshardlow56@sina.com.cn	wD9_\\MNFJ)7SL	student	\N	\N
189	Maible	Yitshak	\N	kN3'1KKt<)ZW	student	\N	\N
190	Samuel	Allkins	sallkins58@amazon.de	\N	student	\N	\N
191	Cooper	Mundee	cmundee59@nyu.edu	bJ1|OqRaA"A	student	\N	\N
192	Codee	Arntzen	\N	\N	student	\N	\N
193	Almira	Shevlan	\N	\N	student	\N	\N
194	Michel	Goldsby	\N	hW9_~MD&8+N}`4tJ	student	\N	\N
195	Magda	Kelwaybamber	\N	bP6{vDR4Ad"	student	\N	\N
196	Laurette	Paulus	lpaulus5e@google.ca	\N	student	\N	\N
197	Margot	Guyer	mguyer5f@yelp.com	\N	student	\N	\N
198	Dillon	Martinson	\N	fX7_opGtI	student	\N	\N
199	Cosetta	Trye	\N	\N	student	\N	\N
200	Sandy	Corwin	\N	hP6}~nnXx+`<l3	student	\N	\N
201	Myrvyn	Broe	mbroe5j@loc.gov	\N	student	\N	\N
2	Devon	Griffen	teacher@g.com	123456	teacher	2005-01-26	Tieu vuong quoc 36
1	John	Doe	fps4day@gmail.com	123456	student	2005-01-05	Tieu vuong quoc 36
\.


--
-- Name: classes_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.classes_class_id_seq', 1, true);


--
-- Name: programs_program_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.programs_program_id_seq', 1, true);


--
-- Name: schools_school_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schools_school_id_seq', 1, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 202, true);


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
     JOIN public.enrollments e ON ((e.class_id = c.class_id)))
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

