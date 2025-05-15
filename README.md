# 🚪 Gate In and Out

### Face-Based Attendance Management System

A smart, webcam-powered **In/Out Attendance System** built with **Ruby on Rails 8**, supporting user/admin roles, secure photo check-ins, and an interactive calendar view for tracking daily records.

![Demo Screenshot Placeholder]() <!-- Replace with actual demo screenshot -->

---

## ✨ Features at a Glance

### 🔐 Authentication & Roles

* Secure login and registration with **Devise**
* Role-based access (`user` and `admin`)
* Admin access toggled via a **secret catchphrase**

### 👥 User Permissions

* **Users**: Can create and manage their own attendance records
* **Admins**: Can view and delete any record
* ❗ **Attendance entries cannot be edited or modified**

### 📇 Comprehensive Record Management

* Record includes:

  * Name, Contact, Address, City, State, Pincode
  * Government ID number and photo
  * Live face photo (captured via webcam)
* Filter records by **Today**, **This Week**, or **This Month**
* Real-time **search functionality**
* Responsive **Bootstrap card-based UI**

### 🕒 Streamlined Attendance Tracking

* One-click **Check-In / Check-Out** using webcam
* **Check-Out** is enabled only after a Check-In
* Summary and detailed views of attendance history

### 📅 Interactive Calendar View

* Fully navigable monthly calendar
* Green-highlighted dates indicate check-ins
* Click a date to view full attendance for that day

### 📊 Attendance Summary Panel

* Quick overview of:

  * Total Check-Ins / Check-Outs / Pending
  * Most recent attendance activity

---

## 💡 User Experience Highlights

* 🛡️ **Role Display**: See the current user and their role in the top navigation bar
* 🔐 **Catchphrase Toggle**: Elevate to admin with a secure passphrase and padlock icon
* 📷 **Webcam-Only Photo Capture**: All photos taken live at the moment of action
* ⚡ **Live Filtering**: Instantly narrow down records by time period or keyword

---

## 🧪 How It Works

1. Sign in to your account
2. View a grid of user records
3. Select "View Details" to:

   * Perform **Check-In**
   * Access **Attendance History**
   * **Delete a record** (admins only)
4. Webcam activates to capture attendance photos
5. Upon check-out, you're redirected to the **history view**
6. Use the calendar to filter and browse attendance data

---

## 🖼️ Screenshots

> Replace these with actual screenshots before deploying

* 📋 **Record List View**
  ![Record List]()

* 📸 **Webcam Check-In/Out**
  ![Webcam Capture]()

* 🗓️ **Calendar Summary View**
  ![Calendar View]()

---

## 🚀 Getting Started

```bash
git clone https://github.com/amnindersingh12/ado-generator.git
cd gate-in-out

bundle install
rails db:setup

# Optional: Seed with demo data
rails db:seed
```

* Visit: `http://localhost:3000`
* Use the 🔒 icon to enter the catchphrase and toggle admin role

---

## ⚙️ Tech Stack

* **Ruby on Rails 8**
* **PostgreSQL**
* **Bootstrap 5**
* **Turbo / Hotwire**
* **ActiveStorage** for image uploads
* **OpenURI** for downloading seed images
* **Face recognition ready** (architecture supports integration)

---

## 🐳 Docker Setup

### Build the Image

```bash
docker build -t gate-in-out:latest .
```

### Save the Image

```bash
docker save -o gate-in-out.tar gate-in-out:latest
```

### Load the Image

```bash
docker load -i gate-in-out.tar
```

### Run the App

```bash
docker run -p 3000:3000 gate-in-out:latest
```

---

## 🙌 Acknowledgements

* [Bootstrap Icons](https://icons.getbootstrap.com/)
* [Faker](https://github.com/faker-ruby/faker) – For generating sample data
* [pic.re](https://pic.re/) – For placeholder photos

---

## 🚧 Roadmap / Future Enhancements

* Integrate face recognition (e.g., DeepFace or similar)
* Add analytics dashboards based on roles
* Export attendance data to **PDF/Excel**
* Enable email alerts for check-ins and check-outs

---

## 📬 Get in Touch

Have suggestions, ideas, or bug reports?
Reach out via Telegram or open an issue on the GitHub repository.
