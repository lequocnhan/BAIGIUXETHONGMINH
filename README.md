# 🚗 TDMU Smart Parking System - Hệ thống bãi đỗ xe thông minh

Hệ thống quản lý bãi giữ xe thông minh toàn diện tích hợp AI (Artificial Intelligence) [Trí tuệ nhân tạo], tự động hóa quy trình nhận diện biển số xe và xác thực khuôn mặt chủ xe. Hệ thống kết hợp ứng dụng di động đa nền tảng Framework [Khung làm việc] Flutter, Backend [Hệ thống máy chủ] Python (Flask) và Cloud Database [Cơ sở dữ liệu đám mây] Firebase Realtime Database để mang lại giải pháp an ninh tối ưu, ngăn chặn tình trạng gian lận và mất cắp phương tiện.

---

## 📷 Hình ảnh & Video Demo [Bản xem thử]

### 🎬 Video Trải nghiệm Hệ thống
👉 **[Xem Video Demo chi tiết tại đây]([Link_Video_Demo_Cua_Ban_Vao_Day])**

### 🖼️ Ảnh chụp màn hình ứng dụng
*Giao diện Đăng nhập & Xác thực OTP*
![Đăng nhập & OTP]([Link_Anh_Dang_Nhap_OTP_Vao_Day])

*Giao diện Quét mã QR & Nhận diện Biển số (YOLOv8)*
![Quét mã & Nhận diện biển số]([Link_Anh_Scanner_YOLO_Vao_Day])

*Giao diện Xác thực khuôn mặt chủ xe (DeepFace)*
![Xác thực khuôn mặt]([Link_Anh_DeepFace_Vao_Day])

*Giao diện Thanh toán & Nhật ký xe*
![Thanh toán & Nhật ký]([Link_Anh_Thanh_Toan_Vao_Day])

---

## ✨ Chức năng chính (Key Features)

### 📱 Phân hệ Ứng dụng Di động (Flutter App)
- **Xác thực bảo mật:** Đăng ký, đăng nhập hệ thống kết hợp gửi và xác thực mã OTP [Mã xác thực một lần] qua hệ thống Firebase Authentication [Xác thực Firebase].
- **Quét mã QR / Quét thẻ:** Giao diện camera quét mã định danh phương tiện nhanh chóng khi ra vào bãi.
- **Thanh toán trực tuyến:** Giao diện hiển thị chi phí gửi xe và tích hợp cổng thanh toán trực quan.
- **Nhật ký cá nhân:** Cho phép người dùng xem lịch sử ra vào bãi xe của cá nhân theo Real-time [Thời gian thực].

### 🤖 Phân hệ Xử lý AI & Máy chủ (Python Flask Server)
- **Nhận diện biển số xe tự động (ANPR):** Sử dụng mô hình YOLOv8 được huấn luyện tối ưu với bộ dữ liệu biển số xe Việt Nam (`vietnamese license plate.v1i.yolov8`). Nhận diện chính xác xe máy, ô tô, các loại biển số dài, biển quân đội, ngoại giao trong nhiều điều kiện thiếu sáng hoặc góc nghiêng.
- **Xác thực khuôn mặt (Face Recognition):** Tích hợp thư viện DeepFace kết hợp các mô hình trích xuất đặc trưng hình học nâng cao (FaceNet512, RetinaFace) giúp đối sánh khuôn mặt người lấy xe với ảnh chủ xe đã đăng ký ban đầu nhằm chống trộm.
- **Đồng bộ hóa dữ liệu kép:** Tự động đồng bộ trạng thái xe lên Firebase Cloud đồng thời sao lưu dữ liệu cục bộ dưới dạng tệp dữ liệu cấu trúc `nhat_ky_bai_xe.csv` và `nhat_ky_xe.txt`.

---

## 💻 Công nghệ sử dụng (Tech Stack)

- **Mobile App [Ứng dụng di động]:** Flutter & Dart.
- **Backend Server [Hệ thống máy chủ]:** Python 3.x, Flask API [Giao diện lập trình ứng dụng Flask].
- **AI / Computer Vision [Thị giác máy tính]:** YOLOv8 (Ultralytics), DeepFace, OpenCV.
- **Cloud Services [Dịch vụ đám mây]:** Firebase Realtime Database, Firebase Authentication.

---

## 📂 Cấu trúc thư mục (Folder Structure)


```

```text
lequocnhan-baigiuxethongminh/
├── app.py                                # Máy chủ Flask API xử lý điều hướng chính
├── DeepFace.py                           # Thư viện xử lý đối sánh khuôn mặt chủ xe
├── serviceAccountKey.json                # Mã cấu hình quyền quản trị viên Firebase Cloud
├── nhat_ky_bai_xe.csv                    # Tệp lưu trữ lịch sử ra vào (Cục bộ)
├── Faces_Data/                           # Thư mục chứa dữ liệu khuôn mặt và các tệp mô hình .pkl
├── parking_app_tdmu/                     # Thư mục mã nguồn ứng dụng di động Flutter
│   ├── lib/
│   │   ├── login_page.dart              # Giao diện đăng nhập
│   │   ├── register_page.dart           # Giao diện đăng ký tài khoản
│   │   ├── otp_page.dart                # Giao diện xác thực mã OTP
│   │   ├── scanner_page.dart            # Giao diện camera quét mã/biển số
│   │   └── payment_screen.dart          # Giao diện thanh toán
└── vietnamese license plate.v1i.yolov8/  # Bộ dữ liệu và mô hình huấn luyện nhận diện biển số

```

---

## 🚀 Hướng dẫn cài đặt & Khởi chạy (Installation & Setup)

### 1. Cấu hình phân hệ Máy chủ & AI (Backend)

**Bước 1:** Di chuyển vào thư mục gốc dự án và cài đặt các thư viện Python cần thiết:

```bash
pip install flask opencv-python ultralytics deepface firebase-admin pandas

```

**Bước 2:** Liên kết Firebase:

1. Truy cập vào Firebase Console, tạo một dự án mới.
2. Tải tệp cấu hình Quản trị viên `serviceAccountKey.json` từ phần *Project Settings > Service Accounts*.
3. Đặt tệp `serviceAccountKey.json` vào thư mục gốc của Backend.

**Bước 3:** Khởi chạy máy chủ API:

```bash
python app.py

```

### 2. Cấu hình ứng dụng di động (Frontend)

**Bước 1:** Cài đặt môi trường Flutter (Đảm bảo đã cấu hình Flutter SDK [Bộ công cụ phát triển phần mềm Flutter] thành công).
**Bước 2:** Di chuyển vào thư mục ứng dụng di động:

```bash
cd parking_app_tdmu

```

**Bước 3:** Tải các thư viện phụ thuộc Dependency [Thư viện phụ thuộc]:

```bash
flutter pub get

```

**Bước 4:** Kết nối thiết bị Android/iOS hoặc Trình giả lập và khởi chạy ứng dụng:

```bash
flutter run

```

---

## 🛠 Khuyến nghị bảo mật & Tối ưu phát triển

1. **Quản lý phiên bản:** Cần tạo tệp `.gitignore` trong thư mục gốc trước khi đẩy mã nguồn lên GitHub nhằm loại bỏ các thư mục tự sinh như `.dart_tool/`, `build/`, `.metadata` để tối ưu kích thước Repository [Kho lưu trữ mã nguồn].
2. **Bảo mật mã nguồn:** Không chia sẻ công khai tệp `serviceAccountKey.json` chứa quyền truy cập Database [Cơ sở dữ liệu] tối cao. Nên thay thế bằng Biến môi trường khi triển khai thực tế.
3. **Quản lý dữ liệu lớn:** Thư mục dữ liệu huấn luyện hình ảnh của YOLOv8 nên được tách biệt lưu trữ trên các Cloud Storage [Lưu trữ đám mây] như Google Drive hoặc Roboflow để tránh làm nặng bộ lưu trữ mã nguồn cục bộ.

---
