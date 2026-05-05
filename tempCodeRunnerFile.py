import cv2
from ultralytics import YOLO
import easyocr
import datetime
import os
import re
import pandas as pd
from fuzzywuzzy import fuzz
from deepface import DeepFace

# ==========================================
# 1. KHỞI TẠO HỆ THỐNG
# ==========================================
model_bike_car = YOLO('yolov8n.pt') 
model_plate = YOLO('runs/detect/train/weights/best.pt') 
reader = easyocr.Reader(['en'])

# Tạo cấu trúc thư mục
for path in ['Luu_Tru_Xe/Vao', 'Luu_Tru_Xe/Ra', 'Faces_Data']:
    if not os.path.exists(path): os.makedirs(path)

# BIẾN QUẢN LÝ
xe_trong_bai = {}   
xe_vua_ra = {}      
file_log = "nhat_ky_bai_xe.csv"
GIA_VE = {'motorcycle': 5000, 'car': 20000}

# Hàm xác thực khuôn mặt (Chạy trên Frame của Camera Laptop)
def xac_thuc_face(frame_hien_tai):
    try:
        results = DeepFace.find(img_path=frame_hien_tai, 
                                db_path="Faces_Data", 
                                model_name="Facenet512", 
                                detector_backend="retinaface",
                                distance_metric="euclidean_l2",
                                enforce_detection=False,
                                silent=True)
        if len(results) > 0 and not results[0].empty:
            res = results[0].iloc[0]
            if res['distance'] < 1.0: 
                path_khop = res['identity']
                ten = os.path.basename(path_khop).split('.')[0]
                conf = max(0, (1 - (res['distance'] / 1.3)) * 100)
                return ten, int(conf)
    except:
        pass
    return "Unknown", 0

def tim_xe_trong_bai(bien_moi):
    for bien_cu in xe_trong_bai.keys():
        if fuzz.ratio(bien_moi, bien_cu) > 85:
            return bien_cu
    return None

# ==========================================
# 2. KHỞI TẠO 2 CAMERA
# ==========================================
# Mở Camera Laptop (Số 0) - Dùng quét mặt
cap_lap = cv2.VideoCapture(0)

# Mở Camera Điện thoại (Số 1 - Iriun) - Dùng quét biển số/loại xe
cap_phone = cv2.VideoCapture(1) 

print("🚀 Hệ thống 2 Camera đang chạy...")
print("📸 Cam 1 (Phone): Biển số & Loại xe")
print("💻 Cam 0 (Laptop): Khuôn mặt")

while cap_lap.isOpened() and cap_phone.isOpened():
    success1, frame_face = cap_lap.read()  # Luồng mặt
    success2, frame_plate = cap_phone.read() # Luồng biển số
    
    if not success1 or not success2: break

    # BƯỚC A: NHẬN DIỆN LOẠI XE (Chạy trên Cam điện thoại)
    results_xe = model_bike_car.predict(frame_plate, classes=[2, 3], conf=0.5, verbose=False)
    loai_xe_hien_tai = "Unknown"
    for r in results_xe:
        for box in r.boxes:
            bx1, by1, bx2, by2 = map(int, box.xyxy[0])
            loai_xe_hien_tai = model_bike_car.names[int(box.cls[0])]
            cv2.rectangle(frame_plate, (bx1, by1), (bx2, by2), (255, 0, 0), 2)
            cv2.putText(frame_plate, f"Loai: {loai_xe_hien_tai}", (bx1, by1-10), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 0, 0), 2)

    # BƯỚC B: NHẬN DIỆN BIỂN SỐ (Chạy trên Cam điện thoại)
    results_plate = model_plate.predict(frame_plate, conf=0.6, verbose=False)
    
    for r in results_plate:
        for box in r.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            plate_crop = frame_plate[y1:y2, x1:x2]
            
            ocr_res = reader.readtext(plate_crop)
            raw_text = "".join([res[1] for res in ocr_res]).replace(" ", "").upper()
            bien_so = re.sub(r'[^A-Z0-9]', '', raw_text)

            if len(bien_so) >= 5:
                now = datetime.datetime.now()
                
                if bien_so in xe_vua_ra:
                    if (now - xe_vua_ra[bien_so]).seconds < 30: continue 
                    else: xe_vua_ra.pop(bien_so)

                bien_khop = tim_xe_trong_bai(bien_so)
                
                if bien_khop:
                    # --- XE RA: QUÉT MẶT TỪ CAMERA LAPTOP ---
                    ten_nguoi, phan_tram = xac_thuc_face(frame_face)
                    xe_trong_bai.pop(bien_khop)
                    xe_vua_ra[bien_khop] = now 
                    
                    phi_gui = GIA_VE.get(loai_xe_hien_tai, 5000)
                    status, folder, color = "RA", "Luu_Tru_Xe/Ra", (0, 0, 255)
                    print(f"📤 [OUT] {bien_khop} | Chủ: {ten_nguoi} | Phí: {phi_gui} VND")
                else:
                    # --- XE VÀO ---
                    xe_trong_bai[bien_so] = now.strftime("%H:%M:%S")
                    phi_gui, ten_nguoi, phan_tram = 0, "N/A", 0
                    status, folder, color = "VAO", "Luu_Tru_Xe/Vao", (0, 255, 0)
                    print(f"📥 [IN] {bien_so}")

                # Vẽ lên frame điện thoại (frame chính hiển thị biển số)
                cv2.rectangle(frame_plate, (x1, y1), (x2, y2), color, 2)
                hien_thi = f"{bien_so}-{status}-{ten_nguoi}"
                cv2.putText(frame_plate, hien_thi, (x1, y1-10), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
                
                # Lưu ảnh kết quả từ cam điện thoại
                cv2.imwrite(f"{folder}/{bien_so}_{now.strftime('%H%M%S')}.jpg", frame_plate)

                # Ghi Log
                log_data = pd.DataFrame([[bien_so, loai_xe_hien_tai, now.strftime("%Y-%m-%d %H:%M:%S"), status, phi_gui, ten_nguoi]], 
                                       columns=['BienSo', 'LoaiXe', 'ThoiGian', 'TrangThai', 'GiaTien', 'ChuXe'])
                log_data.to_csv(file_log, mode='a', index=False, header=not os.path.exists(file_log))

    # DASHBOARD
    cv2.putText(frame_plate, f"Trong bai: {len(xe_trong_bai)} xe", (20, 40), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)

    # Hiển thị 2 cửa sổ để Thầy thấy hệ thống đa camera
    cv2.imshow("CAMERA PHONE (PLATE & TYPE)", frame_plate)
    cv2.imshow("CAMERA LAPTOP (FACE ID)", frame_face)

    if cv2.waitKey(1) & 0xFF == ord('q'): break

cap_lap.release()
cap_phone.release()
cv2.destroyAllWindows()