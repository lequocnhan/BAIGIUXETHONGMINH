from flask import Flask, request, jsonify, send_from_directory
import firebase_admin
from firebase_admin import credentials, db
import os
from flask_cors import CORS
from datetime import datetime

app = Flask(__name__)
CORS(app)

# BẢNG GIÁ
PRICING = {'motorcycle': 5000, 'car': 20000}

# Folder chứa ảnh Face ID
FACE_DATA_FOLDER = "Faces_Data"
if not os.path.exists(FACE_DATA_FOLDER):
    os.makedirs(FACE_DATA_FOLDER)

# 1. KHỞI TẠO FIREBASE
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://tdmusmartparking-default-rtdb.asia-southeast1.firebasedatabase.app/' 
    })

# ==========================================
# HÀM TRỢ GIÚP: GỬI THÔNG BÁO LÊN FIREBASE
# ==========================================
def send_user_notification(username, title, content, n_type="info"):
    """
    n_type: 'info' (xanh), 'payment' (xanh), 'entry' (xanh), 'alert' (đỏ)
    """
    try:
        now = datetime.now().strftime("%H:%M - %d/%m")
        ref = db.reference(f'Users/{username}/notifications')
        ref.push({
            "title": title,
            "content": content,
            "time": now,
            "type": n_type
        })
        print(f"🔔 Đã gửi thông báo cho {username}: {title}")
    except Exception as e:
        print(f"❌ Lỗi gửi thông báo: {e}")

# ==========================================
# CHỨC NĂNG: NHẬN ẢNH TỪ APP
# ==========================================
@app.route('/upload_face', methods=['POST'])
def upload_face():
    try:
        if 'image' not in request.files or 'username' not in request.form:
            return jsonify({"status": "error", "message": "Thiếu dữ liệu"}), 400
        
        file = request.files['image']
        username = request.form['username']
        
        save_path = os.path.join(FACE_DATA_FOLDER, f"{username}.jpg")
        file.save(save_path)
        
        # Cập nhật Firebase
        ref = db.reference(f'Users/{username}')
        ref.update({'face_url': 'local_server'}) 

        # Gửi thông báo về App
        send_user_notification(username, "Cập nhật Face ID", "Ảnh khuôn mặt của bạn đã được lưu hệ thống thành công.", "info")

        return jsonify({"status": "success", "message": f"Đã cập nhật ảnh cho {username}"}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# ==========================================
# LOGIC HỆ THỐNG ĐIỀU KHIỂN CỔNG
# ==========================================
@app.route('/detect', methods=['POST'])
def detect_system():
    data = request.json
    plate = data.get('plate')
    vehicle_type = data.get('vehicle_type', 'motorcycle')
    gate_type = data.get('type') 
    detected_face = data.get('face_name')

    ref = db.reference('Users')
    users = ref.get()
    found_user = None

    # Tìm User dựa trên biển số
    if users:
        for username, details in users.items():
            if details.get('plate_number') == plate:
                found_user = username
                break
            user_vehicles = details.get('vehicles', {})
            for v_id, v_info in user_vehicles.items():
                if v_info.get('plate') == plate:
                    found_user = username
                    break
            if found_user: break

    # --- XỬ LÝ CỔNG VÀO ---
    if gate_type == 'TDMU_GATE_IN':
        if not found_user:
            return jsonify({"status": "unregistered", "message": "Xe lạ!"}), 200

        user_ref = ref.child(found_user)
        user_ref.update({'in_parking': True, 'current_vehicle': vehicle_type})
        
        # Gửi thông báo xe vào
        send_user_notification(found_user, "Xe vào bãi", f"Xe biển số {plate} đã vào bãi.", "entry")
        
        return jsonify({"status": "success", "message": f"Chào {found_user}!"})

    # --- XỬ LÝ CỔNG RA ---
    elif gate_type == 'TDMU_GATE_OUT':
        if not found_user:
            return jsonify({"status": "error", "message": "Xe chưa đăng ký!"}), 404

        user_ref = ref.child(found_user)
        user_data = user_ref.get()

        # Kiểm tra Face ID
        if detected_face != found_user:
            # Gửi thông báo cảnh báo sai mặt
            send_user_notification(found_user, "Cảnh báo bảo mật", "Phát hiện khuôn mặt không khớp khi yêu cầu ra cổng!", "alert")
            return jsonify({"status": "security_alert", "message": "Sai khuôn mặt!"}), 403

        price = PRICING.get(vehicle_type, 5000)
        current_balance = int(user_data.get('balance', 0))

        if current_balance >= price:
            new_balance = current_balance - price
            user_ref.update({
                'balance': str(new_balance), 
                'in_parking': False
            })
            
            # Gửi thông báo thanh toán
            send_user_notification(found_user, "Thanh toán thành công", f"Đã trừ {price}đ. Số dư còn lại: {new_balance}đ", "payment")
            
            return jsonify({"status": "paid", "message": "Mời xe ra!", "new_balance": new_balance})
        else:
            # Gửi thông báo hết tiền
            send_user_notification(found_user, "Số dư không đủ", "Vui lòng nạp thêm tiền để ra cổng.", "alert")
            return jsonify({"status": "low_balance", "message": "Hết tiền!"}), 402

# API lấy ảnh hiển thị trên App
@app.route('/get_face/<filename>')
def get_face(filename):
    return send_from_directory(FACE_DATA_FOLDER, filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)