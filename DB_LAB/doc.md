## Overview
Framework used: Nuxt, tailwind, drizzle, postgre

### Use Cases: (Tín sửa tại đây, phần này chỉ nháp)

#### For Student:
Login

View Profile

View Classs

View Grades

#### For Admin:
Login

Add/Edit Student

Add/Edit Class

Enter Grades

### Entities (Nguyệt sửa tại đây, phần này chỉ nháp)
Student

- Attributes: Student_ID (PK), Name, Email, Phone_number, Date_of_Birth, Gender

Instructor

- Attributes: Instructor_ID (PK), Name, Email, Phone_number

Class

- Attributes: Class_ID (PK), Class_Name, Credits, Instructor_ID (FK)

Enrollment

- Attributes: Enrollment_ID (PK), Student_ID (FK), Class_ID (FK), Date_Enrolled

Grade

- Attributes: Grade_ID (PK), Student_ID (FK), Class_ID (FK), Grade

### Relationships

Student - Enrollment (One to Many)

- One student can enroll in multiple Classs.

- Student_ID in Enrollment references Student_ID in Student.

Class - Enrollment (One to Many)

- One Class can have multiple students enrolled.

- Class_ID in Enrollment references Class_ID in Class.

Student - Grade (One to Many)

- One student can receive multiple grades for different Classs.

- Student_ID in Grade references Student_ID in Student.

Class - Grade (One to Many)

- One Class can have multiple grades for different students.

- Class_ID in Grade references Class_ID in Class.

Class - Teacher (Many to One)

- A Class is taught by a single teacher.

- Instructor_ID in Class references Instructor_ID in Teacher.

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