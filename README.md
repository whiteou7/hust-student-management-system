## Overview
A Nuxt project incorporating Drizzle ORM and PostgreSQL.

## Stuff
1. Tạo classes_view: enrolled_count.
2. Tạo enrollments_view: pass = false nếu mid_term < 3 || final_term < 4, pass = true trong các trường hợp còn lại. Nếu mid_term = null hoặc final_term = null thì pass = null.
3. Tạo students_view: cpa và accumulated_credit của sinh viên (cpa hệ 10, pass = false thì không tính cpa và accumulated_credit không tăng)
4. Viết trigger để mỗi khi học sinh đăng kí lớp trong enrollments, học phí (debt) được tăng.
5. Viết function để tính warning level của học sinh
- warning level = 0 nếu trượt < 3 môn
- warning level = 1 nếu trượt < 6 môn
- warning level = 2 nếu trượt < 9 môn
  
(chú ý trượt môn != trượt lớp, ví dụ nếu có 1 môn 2 lớp 1 trượt 1 đạt thì môn đó đạt)

6. Viết function để kiểm tra học sinh có đăng kí được lớp không, trả về boolean 

Đăng kí được nếu enrolled_count < capacity, status = 'open', warning level = 0 thì đăng kí được tất cả các lớp, = 1 thì đăng kí max 75% tín chỉ, = 2 thì đăng kí max 50% tín chỉ (idea join enrollments x classes x courses để lấy thông tin tín chỉ, enrollments x students để tính tổng tín chỉ)

7. Viết procedure để đăng kí lớp (input student_id và class_id), gọi function bài 6 để kiểm tra trước khi insert vào enrollment.
8. Viết function để kiểm tra điều kiện tốt nghiệp: đạt 100% tín chỉ và hoàn thành các môn học, không tốt nghiệp ('enrolled') trong trường hợp còn lại.
9. Tạo students_view: warning_level.
10. Tạo enrollments_view: result (= avg(mid_term, final_term))
11. Viết function tính gpa.

## Roles

Tùng: Manager/code review/backend/frontend + exercise 3 + 10 + 11

Vũ: 

- Design Relational Schema + ER Diagram
- Exercise 2 ✔
- Exercise 5 + 9 ✔ (Late submission)

Tín: 

- Design Use Case Diagram ✔
- Generate mock data ✔
- Exercise 1 ✔
- Exercise 6 + 7 ✔ (Late submission)

Nguyệt: 

- Design ER Diagram ✔ (Late submission)
- Exercise 4 ✔ (Late submission)
- Exercise 8 ✔ (Late submission)

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

