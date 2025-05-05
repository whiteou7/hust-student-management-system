## Overview
Framework used: Nuxt, tailwind, drizzle, postgre

### Use Cases: (Tín sửa tại đây, phần này chỉ nháp)

#### For Student:
Login

View Profile

View Courses

View Grades

#### For Admin:
Login

Add/Edit Student

Add/Edit Course

Enter Grades

### Entities (Nguyệt sửa tại đây, phần này chỉ nháp)
Student

- Attributes: Student_ID (PK), Name, Email, Phone, Date_of_Birth

Course

- Attributes: Course_ID (PK), Course_Name, Credits, Teacher_ID (FK)

Teacher

- Attributes: Teacher_ID (PK), Name, Email, Department

Enrollment

- Attributes: Enrollment_ID (PK), Student_ID (FK), Course_ID (FK), Date_Enrolled, Status

Grade

- Attributes: Grade_ID (PK), Student_ID (FK), Course_ID (FK), Grade

### Relationships

Student - Enrollment (One to Many)

- One student can enroll in multiple courses.

- Student_ID in Enrollment references Student_ID in Student.

Course - Enrollment (One to Many)

- One course can have multiple students enrolled.

- Course_ID in Enrollment references Course_ID in Course.

Student - Grade (One to Many)

- One student can receive multiple grades for different courses.

- Student_ID in Grade references Student_ID in Student.

Course - Grade (One to Many)

- One course can have multiple grades for different students.

- Course_ID in Grade references Course_ID in Course.

Course - Teacher (Many to One)

- A course is taught by a single teacher.

- Teacher_ID in Course references Teacher_ID in Teacher.

## Roles

Tùng: manager/code review/backend/frontend

Vũ: 

- 

Tín: 

- Design use case diagram

Nguyệt: 

- Design ER diagram

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