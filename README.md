# Qari App (تطبيق قارئ) 📖

A comprehensive Flutter-based platform designed to streamline the process of Quran memorization and management. The app connects **Sheikhs (Teachers)**, **Parents**, and **Students** in a unified ecosystem to track progress, attendance, and communication.

---

## 🌟 Key Features

### 👨‍🏫 For Sheikhs (Teachers)

- **Student Management:** View and manage a list of students, including their memorization progress.
- **Attendance Tracking:** Record daily attendance for students.
- **Progress Reports:** Generate and view detailed reports (Daily, Monthly) for each student.
- **User Requests:** Approve or reject requests from new parents and sheikhs joining the center.
- **Messaging:** Direct communication with parents and students.
- **Permissions Management:** Manage access and roles within the center.

### 👪 For Parents

- **Monitor Progress:** Track your child's daily memorization (Hifz) and revision (Muraja'ah).
- **View Reports:** Access monthly performance reports.
- **Communication:** Stay in touch with Sheikhs regarding your child's education.

### 🎓 For Students

- **Personal Dashboard:** View your own progress and goals.
- **Memorization Logs:** Access logs of daily sessions.

---

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Cross-platform UI)
- **Backend:** [Firebase](https://firebase.google.com/)
  - **Authentication:** Secure login for all user types.
  - **Cloud Firestore:** Real-time NoSQL database for student records, reports, and messages.
- **Typography:** [Google Fonts](https://fonts.google.com/) (Vazirmatn for beautiful Arabic typography).
- **State Management:** Reactive programming with `RxDart` and Streams.

---

## 📁 Project Structure

```text
lib/
├── core/           # Core utilities and constants
├── data/           # Data layer (if applicable)
├── models/         # Data models (Student, Report, User, etc.)
├── screens/        # UI Screens categorized by role
│   ├── auth/       # Login and Registration
│   ├── sheikh/     # Sheikh-specific functionality
│   ├── parent/     # Parent-specific functionality
│   ├── student/    # Student-specific functionality
│   └── splash/     # App entry splash screen
├── services/       # Business logic (Firebase, Auth, Database)
└── widgets/        # Reusable UI components
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Latest stable version recommended)
- Android Studio / VS Code
- Firebase Project configured for Android/iOS/Web

### Installation

1.  **Clone the repository:**

    ```bash
    git clone <repository-url>
    cd qari_app
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```

---
