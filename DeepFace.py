from gtts import gTTS
import pygame
import os
import time

def test_google_voice(text):
    print(f"🎤 Chị Google đang nói: {text}")
    # 1. Chuyển văn bản thành file mp3
    tts = gTTS(text=text, lang='vi')
    tts.save("test_voice.mp3")
    
    # 2. Khởi tạo pygame để phát âm thanh
    pygame.mixer.init()
    pygame.mixer.music.load("test_voice.mp3")
    pygame.mixer.music.play()
    
    # Đợi cho đến khi phát xong
    while pygame.mixer.music.get_busy():
        time.sleep(0.1)
    
    # 3. Dọn dẹp
    pygame.mixer.music.unload()
    os.remove("test_voice.mp3")

# Chạy thử
test_google_voice("Chào Nhân đẹp trai, hệ thống bãi xe thông minh của trường Thủ Dầu Một đã sẵn sàng hoạt động.")