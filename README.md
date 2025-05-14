
# 🚪 Gate In and Out - Attendance Management System

A responsive, face-photo-based in/out attendance system built with **Ruby on Rails 8**, featuring admin/user roles, secure photo check-ins, and dynamic calendar views.

![Demo]() <!-- You can update this with an actual demo screenshot later -->

---

## ✨ Features Overview

- 🔐 **Authentication**
  - Secure **sign in / sign up** with Devise
  - Role-based access with `user` and `admin` roles
  - Role toggle via **secret catchphrase**

- 👤 **User Roles & Permissions**
  - `user`: Can create and manage their own check-ins/outs
  - `admin`: Can view, manage, and delete records
  - **No one** (not even admin) can edit or delete an existing attendance

- 📇 **Record Management**
  - Add records with:
    - Name, Contact, Address, City, State, Pincode
    - Government ID number + ID Photo
    - User Face Photo (webcam)
  - View all records in beautiful **Bootstrap cards**
  - Filter records by **Today / This Week / This Month**
  - Live **search bar**

- 🕓 **Attendance**
  - Check-In & Check-Out with **live webcam photos**
  - Check-Out only possible after Check-In
  - Attendance summary + detailed view

- 📅 **Interactive Calendar View**
  - Visual summary of daily/monthly attendance
  - Navigate by **Previous** / **Next** month
  - Dates with check-ins are highlighted in green
  - Clicking a date shows full attendance of that day

- 📊 **Record Summary View**
  - Total Check-Ins / Check-Outs / Pending
  - List of records with recent in/out timestamps

---

## 🧠 Smart UI UX Decisions

- 💡 **Role Indicator**: Top-left navbar shows `Signed in as email (role)`
- 🔐 **Role Toggle**: A padlock icon lets users enter a **catchphrase** to become admin
- 📷 **Webcam Integration**: All photos (record + attendance) are captured via webcam
- 🔎 **Responsive Filtering**: Records filter dynamically based on time window or keyword

---

## 🧪 How It Works

1. **User signs in**
2. **Records are displayed** in a responsive grid (photo, name, status, etc.)
3. **Click "View Details"** → see personal info + buttons:
   - New Check-In ✅
   - View History 📜
   - Delete Record 🗑️ (if admin)
4. **Check-In** opens webcam, captures image, stores with timestamp
5. **Check-Out** becomes available afterward, does the same
6. Upon checkout, user is redirected to **attendance history page**
7. **Calendar View** offers powerful day-wise filtering and summary

---

## 🖼️ Screenshots

> Replace the links below with your real image URLs once deployed

- 📌 Record List Page
  ![Records]()

- 📸 Webcam Capture (Check-In / Check-Out)
  ![Webcam]()

- 📅 Calendar Attendance Summary
  ![Calendar]()

---

## 🚀 Getting Started

```bash
git clone https://github.com/amnindersingh12/ado-generator.git
cd gate-in-out

bundle install
rails db:setup

# If you need demo data:
rails db:seed
```

- Visit: `http://localhost:3000`
- Use the catchphrase toggle (🔒) to switch to admin

---

## 📂 Tech Stack

- **Ruby on Rails 8**
- **PostgreSQL**
- **Bootstrap 5**
- **Turbo / Hotwire**
- **ActiveStorage** for photo uploads
- **OpenURI** for seed image downloads
- **Face matching** compatible structure (if integrated)

---

## 🙌 Acknowledgements

- [Bootstrap Icons](https://icons.getbootstrap.com/)
- [Faker](https://github.com/faker-ruby/faker) for seed data
- [pic.re](https://pic.re/) for placeholder images

---

## 💡 Future Improvements

- Face recognition integration with DeepFace or similar
- Role-based dashboard metrics
- Export attendance as PDF/Excel
- Email notifications

---

## 📬 Contact

Want to contribute or report a bug?
Message via Telegram or open an issue in the repo!
