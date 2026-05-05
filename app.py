from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, db
import os

app = Flask(__name__)

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
# CHỨC NĂNG MỚI: NHẬN ẢNH TỪ APP VÀ LƯU VÀO FACES_DATA
# ==========================================
@app.route('/upload_face', methods=['POST'])
def upload_face():
    try:
        # Kiểm tra xem có file và username gửi lên không
        if 'image' not in request.files or 'username' not in request.form:
            return jsonify({"status": "error", "message": "Thiếu dữ liệu ảnh hoặc tên người dùng"}), 400
        
        file = request.files['image']
        username = request.form['username']
        
        if file.filename == '':
            return jsonify({"status": "error", "message": "File trống"}), 400

        # Đường dẫn lưu file: Faces_Data/username.jpg
        # Tên file phải trùng với username để AI nhận diện đúng tên
        save_path = os.path.join(FACE_DATA_FOLDER, f"{username}.jpg")
        file.save(save_path)
        
        print(f"✅ Đã nhận ảnh từ App: {username}.jpg -> Đã lưu vào {FACE_DATA_FOLDER}")
        
        # Đồng thời cập nhật link "giả" lên Firebase để App biết là đã có ảnh
        ref = db.reference(f'Users/{username}')
        ref.update({'face_url': 'local_server'}) 

        return jsonify({"status": "success", "message": f"Đã cập nhật ảnh Face ID cho {username}"}), 200
    
    except Exception as e:
        print(f"❌ Lỗi khi nhận ảnh: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# ==========================================
# LOGIC HỆ THỐNG ĐIỀU KHIỂN CỔNG (GIỮ NGUYÊN)
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

    if users:
        for username, details in users.items():
            # Kiểm tra cả plate ở ngoài và trong node vehicles
            if details.get('plate_number') == plate:
                found_user = username
                break
            
            user_vehicles = details.get('vehicles', {})
            for v_id, v_info in user_vehicles.items():
                if v_info.get('plate') == plate:
                    found_user = username
                    break
            if found_user: break

    if gate_type == 'TDMU_GATE_IN':
        if not found_user:
            return jsonify({"status": "unregistered", "message": "Xe lạ chưa đăng ký!"}), 200

        user_ref = ref.child(found_user)
        user_ref.update({'in_parking': True, 'current_vehicle': vehicle_type})
        return jsonify({"status": "success", "message": f"Chào {found_user}, mời vào bãi!"})

    elif gate_type == 'TDMU_GATE_OUT':
        if not found_user:
            return jsonify({"status": "error", "message": "Xe chưa đăng ký!"}), 404

        user_ref = ref.child(found_user)
        user_data = user_ref.get()

        if detected_face != found_user:
            return jsonify({"status": "security_alert", "message": f"Cảnh báo: Sai khuôn mặt chủ xe {found_user}!"}), 403

        price = PRICING.get(vehicle_type, 5000)
        current_balance = int(user_data.get('balance', 0))

        if current_balance >= price:
            new_balance = current_balance - price
            user_ref.update({
                'balance': str(new_balance), 
                'in_parking': False
            })
            return jsonify({"status": "paid", "message": "Thanh toán thành công!", "new_balance": new_balance})
        else:
            return jsonify({"status": "low_balance", "message": "Tài khoản không đủ tiền!"}), 402

if __name__ == '__main__':
    # host='0.0.0.0' để điện thoại có thể truy cập qua IP Wifi
    app.run(host='0.0.0.0', port=5000, debug=True)