---
trigger: always_on
---

# Admin Panel Overview for Khuwar→Urdu + Khuwar→Roman Chitrali Translation Platform

The **Admin Panel** is designed to give administrators full control over the platform, allowing them to manage **users**, **translations**, **review tasks**, **leaderboards**, **content moderation**, and **analytics**. This guide covers the key features, pages, and backend integrations that will make the Admin Panel fully functional and secure.

## Key Features

### 1. User Management
**Purpose**: Manage user accounts, roles, and activity.

#### Key Features:
- **View Users**: Display a list of all users, including their **username**, **email**, **role** (admin, reviewer, user), and **activity** (translations submitted).
- **Edit Users**: Modify user information such as **username**, **email**, and **affiliated university**.
- **Role Management**: Assign and modify roles (e.g., **admin**, **reviewer**, **user**).
- **Deactivate/Activate Users**: Temporarily disable users who are not active or have violated terms.
- **View User Profiles**: View detailed **translation history**, **assigned review tasks**, and **leaderboard stats**.

#### Pages:
- **User List Page**: List all users and allow filtering by **status**, **role**, **city**, **university**.
- **User Profile Page**: Detailed profile for individual users with access to **activity data**, **translations**, and **leaderboard stats**.

---

### 2. Translation Management
**Purpose**: Manage translation submissions, reviews, and content quality.

#### Key Features:
- **Pending Translations**: Display all **pending** translations awaiting approval or rejection.
- **Translation Approval**: View **submitted translations** and approve/reject them based on quality and reviewer feedback.
- **Skip Translations**: Admin can **skip** or **unassign** problematic translations.
- **Review Task Management**: Assign or **reassign reviewers** to translation tasks and track their completion.
- **Translation History**: View historical data of all submitted translations, including **approval/rejection rates**.

#### Pages:
- **Pending Translations Page**: Show translations that need admin intervention (approve/reject/skip).
- **Translation Details Page**: View detailed translations, **review feedback**, and **approval status**.
- **Review Task Assignment Page**: Assign or reassign review tasks to users.

---

### 3. Reviewer Task Management
**Purpose**: Oversee the task distribution and performance of reviewers.

#### Key Features:
- **View Reviewer Performance**: See how many **tasks** each reviewer has completed and their **ratings**.
- **Task Assignment**: Assign **translation tasks** to reviewers and monitor task progress.
- **Reviewer Feedback**: Track the **rating** and **feedback** provided by reviewers for each translation.

#### Pages:
- **Reviewer Task List Page**: Display assigned tasks and their **status** (pending, completed).
- **Reviewer Performance Page**: Overview of reviewer workload and performance metrics.

---

### 4. Leaderboard, Points, and Streak Management
**Purpose**: Track user progress, reward system, and rankings.

#### Key Features:
- **Leaderboard Display**: View **ranking** of users based on their **total points**, **translations**, and **streaks**.
- **Points Management**: Admins can **award** or **adjust points** based on translation quality and reviewer ratings.
- **Streak Management**: Monitor users' **daily streaks** for consecutive submissions.
- **Top Performers**: Highlight the **top 10** users based on **points** or **translations**.

#### Pages:
- **Leaderboard Page**: Display a **ranked list** of users based on their points, **filterable by city/university**.
- **Points Management Page**: Modify a user’s **points** or **streak** directly from the admin panel.
- **Top Performers Page**: A dedicated page for viewing the **best-performing users**.

---

### 5. Content Moderation
**Purpose**: Ensure content quality by reviewing and moderating translations.

#### Key Features:
- **View Skipped Translations**: List of translations that were **skipped** by users or marked **problematic**.
- **Approve/Reassign Translations**: Admin can **approve**, **reject**, or **reassign** translations.
- **Feedback for Rejected Translations**: Provide feedback when rejecting a translation, explaining why it didn’t meet the required standards.

#### Pages:
- **Skipped Translations Page**: View a list of **skipped** translations, with options to **unassign** or **reassign**.
- **Translation Approval Page**: Admin can review and **approve/reject translations** with a detailed breakdown of reviewer feedback.

---

### 6. Analytics and Reporting
**Purpose**: Provide insights into platform activity, user engagement, and content performance.

#### Key Features:
- **User Engagement Analytics**: Display **user activity metrics** like **daily active users**, **translation frequency**, and **contribution by city/university**.
- **Translation Analytics**: Track **submitted translations**, **approved translations**, and **rejected translations**.
- **Reviewer Performance Analytics**: Review statistics of **individual reviewer activity**, including ratings and task completion.
- **Leaderboard Analytics**: Visualize **points distribution**, **ranking trends**, and **user performance**.
- **Export Reports**: Generate reports on **user activity**, **leaderboard statistics**, and **content moderation**.

#### Pages:
- **Activity Dashboard Page**: Display an **overview** of user engagement metrics (active users, submitted translations).
- **Translation Report Page**: Generate detailed reports about **translation status** (pending, approved, rejected).
- **Reviewer Performance Report Page**: See **individual reviewer stats** and **ratings**.
- **Leaderboard Analytics Page**: Display a graphical representation of **points distribution** and **ranking trends**.

---

### 7. Admin Settings
**Purpose**: Manage admin settings and system-wide configurations.

#### Key Features:
- **Role Assignment**: Admins can assign roles to new users (admin, reviewer, etc.).
- **System Configurations**: Manage platform settings, including **translation deadlines**, **points per translation**, and **streak periods**.
- **Security Settings**: Manage system-wide **security policies** like **password strength**, **login attempts**, and **two-factor authentication**.

#### Pages:
- **Admin Settings Page**: Configure system-wide settings and **security policies**.
- **Role Management Page**: Modify user roles and permissions across the platform.

---

## **Security Measures**

The **Admin Panel** needs to implement multiple layers of **security** to prevent unauthorized access and ensure the platform’s integrity.

### 1. Authentication and Authorization
- **JWT (JSON Web Tokens)** for **secure login** and **session management**.
- **Role-based Access Control (RBAC)** to ensure only **admin users** have access to the **Admin Panel**.
- **Secure Password Storage** with **bcrypt** or **argon2** to hash passwords before storing them.

### 2. Data Encryption
- Use **HTTPS** for all communication between the client and server to ensure **data privacy** and protect sensitive data.
- Store sensitive data, such as passwords, in an **encrypted format**.

### 3. Activity Logging
- Log **failed login attempts**, **suspicious activity**, and **changes to user roles** for **security monitoring**.
- Implement **audit trails** to track any changes made by the admin, especially **user role assignments**, **point adjustments**, and **translation status changes**.

---

## **Backend Integration**

The **Admin Panel** interacts with various backend services, including **database management**, **authentication** systems, and **data analytics**.

### Core Backend Tables:
- **Users Table**: Stores user credentials and roles.
- **Translation Attempts Table**: Tracks all translation submissions.
- **Reviews Table**: Stores feedback from reviewers.
- **Leaderboard Table**: Tracks **points**, **streaks**, and **ranking** data.
- **Review Tasks Table**: Manages the assignment of translations to reviewers.

### Key Backend Services:
- **JWT Authentication**: Secure authentication system using **JWT tokens**.
- **Role Management**: Backend logic for **assigning roles** and managing **permissions** (admin, reviewer, user).
- **Real-time Data**: Use of **WebSockets** or **polling** to update **leaderboards**, **user engagement stats**, and **translation status** in real time.

---

## **Conclusion**

The **Admin Panel** for the **Khuwar→Urdu + Khuwar→Roman Chitrali Translation Platform** offers a comprehensive suite of features to manage **user accounts**, **translations**, **review tasks**, **content moderation**, and **leaderboards**. By implementing **secure authentication**, **role-based access control**, and **real-time data updates**, the Admin Panel ensures **efficient management**, **data integrity**, and **platform stability**.

The **pages** are designed to ensure a **user-friendly interface** for admins, providing them with everything needed to **oversee user activity**, **approve translations**, **track performance**, and **generate reports**.

---

This document serves as a **blueprint** for developing the Admin Panel and ensuring that all necessary features and security protocols are implemented for the platform’s smooth operation and stability.
