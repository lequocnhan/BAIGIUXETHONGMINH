import cv2
from ultralytics import YOLO
import easyocr
import datetime
import os
import re
import pandas as pd
from fuzzywuzzy import fuzz
from deepface import DeepFace
import requests
from gtts import gTTS
import pygame
import time

# ==========================================
# 0. KHỞI TẠO ÂM THANH & TỰ ĐỘNG CẬP NHẬT FACE ID
# ==========================================
pygame.mixer.init()

db_path = "Faces_Data"
pkl_path = os.path.join(db_path, "representations_facenet512.pkl")
count_file = "last_count.txt"

def check_and_update_db():
    print("🔍 Đang kiểm tra dữ liệu Face ID...")
    if not os.path.exists(db_path):
        os.makedirs(db_path)
        
    # 1. Đếm số lượng ảnh hiện có (.jpg, .jpeg, .png)
    current_images = [f for f in os.listdir(db_path) if f.endswith(('.jpg', '.jpeg', '.png'))]
    current_count = len(current_images)
    
    # 2. Đọc số lượng ảnh của lần chạy trước đó
    last_count = 0
    if os.path.exists(count_file):
        with open(count_file, "r") as f:
            try:
                last_count = int(f.read().strip())
            except:
                last_count = 0
    
    # 3. So sánh: Nếu có ảnh mới hoặc mất ảnh -> Xóa .pkl để DeepFace quét lại
    if current_count != last_count:
        print(f"🔄 Phát hiện thay đổi dữ liệu: {last_count} -> {current_count} ảnh.")
        if os.path.exists(pkl_path):
            os.remove(pkl_path)
            print("🗑️ Đã xóa bộ nhớ cũ (.pkl) để cập nhật danh sách người dùng mới.")
        
        # Lưu lại con số mới để so sánh cho lần sau
        with open(count_file, "w") as f:
            f.write(str(current_count))
    else:
        print(f"✅ Không có người dùng mới ({current_count} ảnh). Khởi động AI nhanh...")

# GỌI HÀM KIỂM TRA TRƯỚC KHI VÀO VÒNG LẶP
check_and_update_db()

def thong_bao_voice(text):
    try:
        print(f"🎤 Chị Google đang nói: {text}")
        tts = gTTS(text=text, lang='vi')
        filename = "thong_bao.mp3"
        tts.save(filename)
        pygame.mixer.music.load(filename)
        pygame.mixer.music.play()
        while pygame.mixer.music.get_busy():
            time.sleep(0.1)
        pygame.mixer.music.unload()
    except Exception as e:
        print(f"❌ Lỗi âm thanh Google: {e}")

# ==========================================
# 1. KHỞI TẠO HỆ THỐNG AI
# ==========================================
model_bike_car = YOLO('yolov8n.pt') 
model_plate = YOLO('runs/detect/train/weights/best.pt') 
reader = easyocr.Reader(['en'])

for path in ['Luu_Tru_Xe/Vao', 'Luu_Tru_Xe/Ra', 'Faces_Data']:
    if not os.path.exists(path): os.makedirs(path)

xe_trong_bai = {}   
xe_vua_ra = {}      
file_log = "nhat_ky_bai_xe.csv"

def xac_thuc_face(frame_hien_tai):
    try:
        results = DeepFace.find(img_path=frame_hien_tai, 
                                db_path="Faces_Data", 
                                model_name="Facenet512", 
                                detector_backend="opencv", 
                                enforce_detection=False, 
                                silent=True)
        if len(results) > 0 and not results[0].empty:
            res = results[0].iloc[0]
            # Độ tin cậy (càng nhỏ càng chính xác)
            if res['distance'] < 1.0: 
                path_khop = res['identity']
                ten = os.path.basename(path_khop).split('.')[0]
                return ten
    except Exception as e:
        print(f"⚠️ Lỗi FaceID: {e}")
    return "Unknown"

def tim_xe_trong_bai(bien_moi):
    for bien_cu in xe_trong_bai.keys():
        if fuzz.ratio(bien_moi, bien_cu) > 85: return bien_cu
    return None

# ==========================================
# 2. KHỞI TẠO 2 CAMERA
# ==========================================
cap_lap = cv2.VideoCapture(0)  
cap_phone = cv2.VideoCapture(1) 

print("🚀 Hệ thống Smart Parking TDMU đang chạy (Giọng Google)...")

while cap_lap.isOpened() and cap_phone.isOpened():
    success1, frame_face = cap_lap.read()
    success2, frame_plate = cap_phone.read()
    if not success1 or not success2: break

    # Nhận diện loại xe
    results_xe = model_bike_car.predict(frame_plate, classes=[2, 3], conf=0.5, verbose=False)
    loai_xe_hien_tai = "motorcycle"
    for r in results_xe:
        for box in r.boxes:
            loai_xe_hien_tai = model_bike_car.names[int(box.cls[0])]

    # Nhận diện biển số
    results_plate = model_plate.predict(frame_plate, conf=0.6, verbose=False)
    
    for r in results_plate:
        for box in r.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            plate_crop = frame_plate[y1:y2, x1:x2]
            ocr_res = reader.readtext(plate_crop)
            bien_so = re.sub(r'[^A-Z0-9]', '', "".join([res[1] for res in ocr_res]).upper())

            if len(bien_so) >= 5:
                now = datetime.datetime.now()
                # Chống spam: Nếu biển này vừa quét xong trong 30s thì bỏ qua
                if bien_so in xe_vua_ra and (now - xe_vua_ra[bien_so]).seconds < 30: continue 

                bien_khop = tim_xe_trong_bai(bien_so)
                qr_gate = "TDMU_GATE_OUT" if bien_khop else "TDMU_GATE_IN"
                
                ten_nguoi = "Unknown"
                if qr_gate == "TDMU_GATE_OUT":
                    ten_nguoi = xac_thuc_face(frame_face)

                try:
                    payload = {
                        "plate": bien_khop if bien_khop else bien_so,
                        "vehicle_type": loai_xe_hien_tai,
                        "type": qr_gate,
                        "face_name": ten_nguoi
                    }
                    response = requests.post("http://127.0.0.1:5000/detect", json=payload)
                    result = response.json()
                    status_flask = result.get('status')
                    msg_flask = result.get('message')
                    print(f"📡 {qr_gate}: {msg_flask}")

                    # --- PHÁT ÂM THANH ---
                    if status_flask == "success":
                        thong_bao_voice("Chào mừng bạn đã đến bãi xe Đại học Thủ Dầu Một.")
                    elif status_flask == "paid":
                        thong_bao_voice("Thanh toán thành công. Tạm biệt và hẹn gặp lại.")
                    elif status_flask == "security_alert":
                        thong_bao_voice("Cảnh báo. Khuôn mặt không khớp chủ xe.")
                    elif status_flask == "low_balance":
                        thong_bao_voice("Tài khoản không đủ tiền.")

                    # --- LƯU ẢNH VÀ LOG ---
                    if response.status_code == 200 or status_flask == 'paid':
                        if qr_gate == "TDMU_GATE_IN":
                            xe_trong_bai[bien_so] = now
                            folder = "Luu_Tru_Xe/Vao"
                            text_display = f"{bien_so} - VAO"
                        else:
                            xe_trong_bai.pop(bien_khop)
                            xe_vua_ra[bien_khop] = now
                            folder = "Luu_Tru_Xe/Ra"
                            text_display = f"{bien_so} - RA"
                        
                        # Vẽ khung và thông tin lên ảnh bằng chứng
                        frame_to_save = frame_plate.copy()
                        cv2.rectangle(frame_to_save, (x1, y1), (x2, y2), (0, 255, 0), 2)
                        cv2.putText(frame_to_save, text_display, (x1, y1 - 10), 
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
                        
                        img_filename = f"{folder}/{bien_so}_{now.strftime('%H%M%S')}.jpg"
                        cv2.imwrite(img_filename, frame_to_save)
                        
                        # Ghi nhật ký CSV
                        log_data = pd.DataFrame([[bien_so, loai_xe_hien_tai, now.strftime("%Y-%m-%d %H:%M:%S"), qr_gate, ten_nguoi]], 
                                               columns=['BienSo', 'LoaiXe', 'ThoiGian', 'Cong', 'ChuXe'])
                        log_data.to_csv(file_log, mode='a', index=False, header=not os.path.exists(file_log))

                except Exception as e:
                    print(f"❌ Lỗi xử lý cổng: {e}")

    # Hiển thị lên màn hình
    cv2.putText(frame_plate, f"Xe trong bai: {len(xe_trong_bai)}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)
    cv2.imshow("Plate Cam (Phone)", frame_plate)
    cv2.imshow("Face Cam (Laptop)", frame_face)
    
    if cv2.waitKey(1) & 0xFF == ord('q'): break

cap_lap.release()
cap_phone.release()
cv2.destroyAllWindows()