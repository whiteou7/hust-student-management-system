## Overview
A Nuxt project incorporating Drizzle ORM and PostgreSQL.

## Schema
1. users(**user_id**, first_name, last_name, date_of_birth, address, email, password, role)
2. sessions(**session_id**, user_id): user_id refers to users.user_id
3. students(**student_id**, program_id, enrolled_year, warning_level, accumulated_credit, graduated, debt, cpa):
- student_id refers to users.user_id
- program_id refers to programs.program_id
4. teachers(**teacher_id**, school_id, hired_year, qualification):
- teacher_id refers to users.user_id
- school_id refers to schools.school_id
5. programs(**program_id**, program_name, total_credit)
6. schools(**school_id**, school_name)
7. courses(**course_id**, course_name, course_description, credit, tuition_per_credit, school_id):
- school_id refers to schools.school_id
8. classes(**class_id**, teacher_id, course_id, capacity, semester, enrolled_count, status, day_of_week, location):
- teacher_id refers to teachers.teacher_id
- course_id refers to courses.course_id
9. enrollments(**student_id**, **class_id**, mid_term, final_term, pass):
- student_id refers to students.student_id
- class_id refers to classes.class_id

## To-do
1. Viết trigger để mỗi khi học sinh đăng kí hoặc đổi lớp trong enrollments, enrolled_count của các lớp bị ảnh hưởng được update.
2. Viết trigger để set enrollments.pass = false nếu mid_term < 3 || final_term < 4, enrollments.pass = true trong các trường hợp còn lại. Nếu mid_term = null hoặc final_term = null thì enrollments.pass = null.
3. Viết trigger để mỗi khi nhập điểm trong enrollments, cpa và accumulated_credit của sinh viên sẽ được update (cpa hệ 10, pass = false thì không tính cpa và accumulated_credit không tăng)
4. Viết trigger để mỗi khi học sinh đăng kí lớp trong enrollments, học phí (debt) được tăng.
5. Viết function để tính warning level của học sinh
- warning level = 0 nếu trượt < 3 môn
- warning level = 1 nếu trượt < 6 môn
- warning level = 2 nếu trượt < 9 môn
(câu này chú ý tính tổng môn trượt không phải lớp trượt, ý tưởng join enrollments x classes, nếu có 1 môn 2 lớp 1 trượt 1 đạt thì môn đó đạt)
6. Viết function để kiểm tra học sinh có đăng kí được lớp không (đăng kí được nếu enrolled_count < capacity, status = 'open', warning level = 0 thì đăng kí được tất cả các lớp, = 1 thì đăng kí max 75% tín chỉ, = 2 thì đăng kí max 50% tín chỉ) (câu này join khá nhiều bảng, enrollments x classes x courses để lấy thông tin tín chỉ, enrollments x students để tính tổng tín chỉ.
7. Viết procedure để đăng kí lớp (input student_id và class_id), gọi function bài 6 để kiểm tra trước khi insert vào enrollment.
8. Viết procedure để kiểm tra và update students.graduated, tốt nghiệp ('graduated') nếu đạt 100% tín chỉ và debt = 0, không tốt nghiệp ('enrolled') trong trường hợp còn lại.
9. Viết trigger để gọi function 5 mỗi khi nhập điểm.
10. Viết trigger để tính result = (mid_term + final_term)/2

## Roles

Tùng: manager/code review/backend/frontend

Vũ: 

- Design Relational Schema
- Exercise 2 ✔

Tín: 

- Design Use Case Diagram ✔
- Generate mock data ✔
- Exercise 1 ✔

Nguyệt: 

- Design ER Diagram ✔ (Late submission)
- Exercise 4 ✔ (Late submission)

## Setup

1. Fork this repo
2. Clone **your forked repo** to your machine
3. Use
```
git remote add upstream https://github.com/whiteou7/hust-student-management-system
```

## Workflow
1. **Always** pull from upstream first
```
git pull upstream main
```
2. Make changes, add and commit with meaningful messages
```
git add .
git commit -m "..."
```
3. Push to your repo
```
git push origin main
```
4. Go to your repo on github and make a pull request

## Resources
- Slides from class
- https://docs.google.com/document/d/1z4kSNJSZIf1RW-bD8KXOEY1H9KFlgj76gJ6-m-EUyeE/edit?usp=sharing
- https://github.com/hung9988/HUST-STUDENT-MANAGER/tree/main
