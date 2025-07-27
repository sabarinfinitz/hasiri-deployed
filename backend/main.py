import os
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import requests
import base64

# Load environment variables from C:\dev\.env (adjust if needed)
env_path = Path(__file__).parent.parent.parent / '.env'
load_dotenv(env_path)

print(f"🔍 Loading .env from: {env_path}")
print(f"📁 Absolute path: {env_path.absolute()}")
print(f"✅ .env file exists: {env_path.exists()}")

# Get API keys
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GOOGLE_SPEECH_API_KEY = os.getenv("GOOGLE_SPEECH_API_KEY")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent"

if GOOGLE_SPEECH_API_KEY:
    print(f"🔑 Google Speech API Key loaded: {GOOGLE_SPEECH_API_KEY[:15]}...")
else:
    print("❌ Google Speech API Key not found!")

if GEMINI_API_KEY:
    print(f"🔑 Gemini API Key loaded: {GEMINI_API_KEY[:15]}...")
else:
    print("❌ Gemini API Key not found!")

if not GOOGLE_SPEECH_API_KEY or not GEMINI_API_KEY:
    print(f"❌ Error: API keys not found in {env_path}")
    print("Please ensure your .env file exists at C:\\dev\\.env with:")
    print("GOOGLE_SPEECH_API_KEY=your_key_here")
    print("GEMINI_API_KEY=your_key_here")
    raise ValueError("Missing required API keys in .env file")

app = FastAPI()

# Allow CORS for all origins (adjust in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to your frontend URL in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Root endpoint to avoid 404
@app.get("/")
async def root():
    return {
        "message": "HASIRI AgriAssistant Backend is running.",
        "available_endpoints": [
            "POST /chat",
            "POST /speech-to-text",
            "POST /text-to-speech",
            "POST /analyze-image"
        ]
    }

# Speech-to-Text endpoint
@app.post("/speech-to-text")
async def speech_to_text(audio: UploadFile = File(...)):
    try:
        print(f"🎤 Processing speech-to-text for file: {audio.filename}")
        audio_bytes = await audio.read()
        
        headers = {"Content-Type": "application/json"}
        stt_url = f"https://speech.googleapis.com/v1/speech:recognize?key={GOOGLE_SPEECH_API_KEY}"
        
        data = {
            "config": {
                "encoding": "LINEAR16",
                "sampleRateHertz": 16000,
                "languageCode": "en-US",
                "alternativeLanguageCodes": ["hi-IN", "ta-IN", "te-IN", "kn-IN"],
                "enableAutomaticPunctuation": True,
                "model": "latest_long"
            },
            "audio": {
                "content": base64.b64encode(audio_bytes).decode("utf-8")
            }
        }
        
        response = requests.post(stt_url, headers=headers, json=data)
        print(f"🔍 Speech API response status: {response.status_code}")
        
        if response.ok:
            result = response.json()
            transcript = ""
            if "results" in result and result["results"]:
                transcript = result["results"][0]["alternatives"][0]["transcript"]
                print(f"✅ Transcription successful: {transcript[:50]}...")
            else:
                print("⚠️ No speech detected in audio")
            return {"transcript": transcript}
        else:
            print(f"❌ Speech API error: {response.text}")
            return {"error": response.text}
            
    except Exception as e:
        print(f"❌ Speech-to-text error: {str(e)}")
        return {"error": f"Processing error: {str(e)}"}

# Text-to-Speech endpoint
@app.post("/text-to-speech")
async def text_to_speech(text: str = Form(...), language: str = Form("en-US")):
    try:
        print(f"🔊 Processing text-to-speech for language: {language}")
        print(f"📝 Text length: {len(text)} characters")
        
        headers = {"Content-Type": "application/json"}
        tts_url = f"https://texttospeech.googleapis.com/v1/text:synthesize?key={GOOGLE_SPEECH_API_KEY}"
        
        tts_text = text
        if len(text.encode('utf-8')) > 4500:
            print(f"⚠️ Text too long for TTS ({len(text.encode('utf-8'))} bytes), truncating...")
            sentences = text.split('।')
            if len(sentences) == 1:
                sentences = text.split('.')
            if len(sentences) > 1:
                tts_text = ""
                for sentence in sentences:
                    test_text = tts_text + sentence + "।" if tts_text else sentence
                    if len(test_text.encode('utf-8')) < 4500:
                        tts_text = test_text
                    else:
                        break
                if not tts_text:
                    tts_text = text[:1000] + "..."
            else:
                tts_text = text[:1000] + "..."
            print(f"✂️ TTS text truncated to {len(tts_text.encode('utf-8'))} bytes")
        
        voice_config = {"languageCode": language, "ssmlGender": "FEMALE"}
        voice_names = {
            "ta-IN": "ta-IN-Standard-A",
            "hi-IN": "hi-IN-Standard-A",
            "te-IN": "te-IN-Standard-A",
            "kn-IN": "kn-IN-Standard-A",
            "ml-IN": "ml-IN-Standard-A",
            "bn-IN": "bn-IN-Standard-A",
            "gu-IN": "gu-IN-Standard-A",
            "pa-IN": "pa-IN-Standard-A",
            "mr-IN": "mr-IN-Standard-A",
            "en-US": "en-US-Standard-C",
        }
        if language in voice_names:
            voice_config["name"] = voice_names[language]
            print(f"🎭 Using voice: {voice_names[language]}")
        
        data = {
            "input": {"text": tts_text},
            "voice": voice_config,
            "audioConfig": {"audioEncoding": "MP3"}
        }
        
        response = requests.post(tts_url, headers=headers, json=data)
        print(f"🔍 TTS response status: {response.status_code}")
        
        if response.ok:
            result = response.json()
            audio_content = result.get("audioContent", "")
            print(f"✅ TTS successful, audio content length: {len(audio_content)} chars")
            return {"audioContent": audio_content}
        else:
            print(f"❌ TTS error: {response.text}")
            return {"error": response.text}
            
    except Exception as e:
        print(f"❌ Text-to-speech error: {str(e)}")
        return {"error": f"Processing error: {str(e)}"}

# Chat endpoint
@app.post("/chat")
async def chat(text: str = Form(...), language: str = Form("en")):
    try:
        print(f"💬 Processing chat request in language: {language}")
        print(f"📝 User message: {text[:100]}...")
        
        headers = {"Content-Type": "application/json"}
        params = {"key": GEMINI_API_KEY}
        
        prompt = (
            f"You are HASIRI, an expert agricultural assistant for Indian farmers. "
            f"Provide clear, practical, and regionally relevant advice in simple language. "
            f"Focus on actionable steps that farmers can take immediately. "
            f"If the user asks in a specific Indian language, respond in that same language. "
            f"Cover topics like: crops, weather, pests, diseases, fertilizers, irrigation, "
            f"government schemes, market prices, organic farming, and seasonal advice. "
            f"Always be encouraging and supportive to farmers. "
            f"User's language preference: {language}. "
            f"User message: {text}"
        )
        
        data = {"contents": [{"role": "user", "parts": [{"text": prompt}]}]}
        
        response = requests.post(GEMINI_API_URL, headers=headers, params=params, json=data)
        print(f"🔍 Gemini response status: {response.status_code}")
        
        if response.ok:
            result = response.json()
            reply = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
            print(f"✅ Chat response generated: {reply[:100]}...")
            return {"reply": reply}
        else:
            print(f"❌ Gemini error: {response.text}")
            return {"reply": "Sorry, I couldn't process your request. Please try again."}
            
    except Exception as e:
        print(f"❌ Chat error: {str(e)}")
        return {"reply": "I'm having trouble right now. Please try again in a moment."}

# Image analysis endpoint
@app.post("/analyze-image")
async def analyze_image(
    file: UploadFile = File(...),
    prompt: str = Form("Analyze this crop image for diseases, pests, growth stage, and provide farming advice")
):
    try:
        print(f"📸 Processing image analysis for file: {file.filename}")
        print(f"📝 Analysis prompt: {prompt[:100]}...")
        
        headers = {"Content-Type": "application/json"}
        params = {"key": GEMINI_API_KEY}
        
        image_bytes = await file.read()
        print(f"📊 Image size: {len(image_bytes)} bytes")
        
        mime_type = file.content_type
        if not mime_type or mime_type == "application/octet-stream":
            if file.filename:
                if file.filename.lower().endswith(".png"):
                    mime_type = "image/png"
                elif file.filename.lower().endswith((".jpg", ".jpeg")):
                    mime_type = "image/jpeg"
                else:
                    mime_type = "image/jpeg"
            else:
                mime_type = "image/jpeg"
        
        print(f"🖼️ Detected MIME type: {mime_type}")
        
        image_base64 = base64.b64encode(image_bytes).decode("utf-8")
        
        enhanced_prompt = (
            "You are an expert agricultural specialist. Analyze this crop image and provide: "
            "1. Crop identification (if possible) "
            "2. Disease detection (symptoms, causes, treatment) "
            "3. Pest identification (if visible) "
            "4. Growth stage assessment "
            "5. Soil/environmental conditions visible "
            "6. Recommended actions for the farmer "
            "7. Prevention tips for future "
            "Be specific, practical, and provide actionable advice. "
            f"User's specific request: {prompt}"
        )
        
        data = {
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {"text": enhanced_prompt},
                        {
                            "inline_data": {
                                "mime_type": mime_type,
                                "data": image_base64
                            }
                        }
                    ]
                }
            ]
        }
        
        response = requests.post(GEMINI_API_URL, headers=headers, params=params, json=data)
        print(f"🔍 Image analysis response status: {response.status_code}")
        
        if response.ok:
            result = response.json()
            reply = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
            print(f"✅ Image analysis completed: {reply[:100]}...")
            return {"reply": reply}
        else:
            print(f"❌ Image analysis error: {response.text}")
            return {"reply": "Sorry, I couldn't analyze this image. Please try with a clearer crop image."}
            
    except Exception as e:
        print(f"❌ Image analysis error: {str(e)}")
        return {"reply": "I'm having trouble analyzing this image. Please try again with a different image."}

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    print("🚀 Starting HASIRI Backend Server...")
    print(f"📁 Using .env file from: {env_path.absolute()}")
    print(f"🌐 Server will be available at: http://localhost:{port}")
    print(f"📋 API Endpoints:")
    print(f"   • POST /chat - Chat with AI assistant")
    print(f"   • POST /speech-to-text - Convert speech to text")
    print(f"   • POST /text-to-speech - Convert text to speech")
    print(f"   • POST /analyze-image - Analyze crop images")
    uvicorn.run(app, host="0.0.0.0", port=port)