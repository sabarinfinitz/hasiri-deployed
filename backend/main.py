import os
import sys
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import requests
from PIL import Image
import io
import base64

# Load environment variables from C:\dev\.env
# Go up two levels from backend folder: backend -> lasthope -> dev
env_path = Path(__file__).parent.parent.parent / '.env'

# Alternative: Direct path specification (uncomment if relative path doesn't work)
# env_path = Path(r'C:\dev\.env')

# Load the .env file
load_dotenv(env_path)

# Print debug info to verify it's loading correctly
print(f"🔍 Loading .env from: {env_path}")
print(f"📁 Absolute path: {env_path.absolute()}")
print(f"✅ .env file exists: {env_path.exists()}")

# Get API keys
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GOOGLE_SPEECH_API_KEY = os.getenv("GOOGLE_SPEECH_API_KEY")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent"

# Verify keys are loaded (show only first few characters for security)
if GOOGLE_SPEECH_API_KEY:
    print(f"🔑 Google Speech API Key loaded: {GOOGLE_SPEECH_API_KEY[:15]}...")
else:
    print("❌ Google Speech API Key not found!")

if GEMINI_API_KEY:
    print(f"🔑 Gemini API Key loaded: {GEMINI_API_KEY[:15]}...")
else:
    print("❌ Gemini API Key not found!")

# Raise error if keys are missing
if not GOOGLE_SPEECH_API_KEY or not GEMINI_API_KEY:
    print(f"❌ Error: API keys not found in {env_path}")
    print("Please ensure your .env file exists at C:\\dev\\.env with:")
    print("GOOGLE_SPEECH_API_KEY=your_key_here")
    print("GEMINI_API_KEY=your_key_here")
    raise ValueError("Missing required API keys in .env file")

app = FastAPI()

# Allow CORS for Flutter web/app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Speech-to-Text endpoint
@app.post("/speech-to-text")
async def speech_to_text(audio: UploadFile = File(...)):
    try:
        print(f"🎤 Processing speech-to-text for file: {audio.filename}")
        audio_bytes = await audio.read()
        
        headers = {
            "Content-Type": "application/json",
        }
        stt_url = f"https://speech.googleapis.com/v1/speech:recognize?key={GOOGLE_SPEECH_API_KEY}"
        
        # Enhanced configuration for better recognition
        data = {
            "config": {
                "encoding": "LINEAR16",
                "sampleRateHertz": 16000,
                "languageCode": "en-US",
                "alternativeLanguageCodes": ["hi-IN", "ta-IN", "te-IN", "kn-IN"],  # Support Indian languages
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
        
        headers = {
            "Content-Type": "application/json",
        }
        tts_url = f"https://texttospeech.googleapis.com/v1/text:synthesize?key={GOOGLE_SPEECH_API_KEY}"
        
        # Handle long text by truncating intelligently
        tts_text = text
        if len(text.encode('utf-8')) > 4500:  # Conservative limit to avoid 5000 byte limit
            print(f"⚠️ Text too long for TTS ({len(text.encode('utf-8'))} bytes), truncating...")
            
            # Try to find natural break points (sentences)
            sentences = text.split('।')  # Hindi sentence separator
            if len(sentences) == 1:
                sentences = text.split('.')  # English sentence separator
            
            if len(sentences) > 1:
                # Take first few sentences that fit within limit
                tts_text = ""
                for sentence in sentences:
                    test_text = tts_text + sentence + "।" if tts_text else sentence
                    if len(test_text.encode('utf-8')) < 4500:
                        tts_text = test_text
                    else:
                        break
                
                if not tts_text:  # Fallback if even first sentence is too long
                    tts_text = text[:1000] + "..."
            else:
                # Simple truncation if no sentence breaks found
                tts_text = text[:1000] + "..."
            
            print(f"✂️ TTS text truncated to {len(tts_text.encode('utf-8'))} bytes")
        
        # Select appropriate voice based on language
        voice_config = {"languageCode": language, "ssmlGender": "FEMALE"}
        
        # Use specific voice names for Indian languages for better quality
        voice_names = {
            "ta-IN": "ta-IN-Standard-A",  # Tamil female voice
            "hi-IN": "hi-IN-Standard-A",  # Hindi female voice
            "te-IN": "te-IN-Standard-A",  # Telugu female voice
            "kn-IN": "kn-IN-Standard-A",  # Kannada female voice
            "ml-IN": "ml-IN-Standard-A",  # Malayalam female voice
            "bn-IN": "bn-IN-Standard-A",  # Bengali female voice
            "gu-IN": "gu-IN-Standard-A",  # Gujarati female voice
            "pa-IN": "pa-IN-Standard-A",  # Punjabi female voice
            "mr-IN": "mr-IN-Standard-A",  # Marathi female voice
            "en-US": "en-US-Standard-C",  # English female voice
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
        
        # Enhanced agricultural context and language support
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
        
        data = {
            "contents": [
                {"role": "user", "parts": [{"text": prompt}]}
            ]
        }
        
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
        
        # Detect MIME type, fallback to image/jpeg if unknown
        mime_type = file.content_type
        if not mime_type or mime_type == "application/octet-stream":
            # Try to guess from file extension
            if file.filename and file.filename.lower().endswith(".png"):
                mime_type = "image/png"
            elif file.filename and file.filename.lower().endswith(".jpg"):
                mime_type = "image/jpeg"
            elif file.filename and file.filename.lower().endswith(".jpeg"):
                mime_type = "image/jpeg"
            else:
                mime_type = "image/jpeg"  # Default fallback
        
        print(f"🖼️ Detected MIME type: {mime_type}")
        
        image_base64 = base64.b64encode(image_bytes).decode("utf-8")
        
        # Enhanced prompt for better crop analysis
        enhanced_prompt = (
            f"You are an expert agricultural specialist. Analyze this crop image and provide: "
            f"1. Crop identification (if possible) "
            f"2. Disease detection (symptoms, causes, treatment) "
            f"3. Pest identification (if visible) "
            f"4. Growth stage assessment "
            f"5. Soil/environmental conditions visible "
            f"6. Recommended actions for the farmer "
            f"7. Prevention tips for future "
            f"Be specific, practical, and provide actionable advice. "
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
    print("🚀 Starting HASIRI Backend Server...")
    print(f"📁 Using .env file from: {env_path.absolute()}")
    print(f"🌐 Server will be available at: http://localhost:8000")
    print(f"📋 API Endpoints:")
    print(f"   • POST /chat - Chat with AI assistant")
    print(f"   • POST /speech-to-text - Convert speech to text")
    print(f"   • POST /text-to-speech - Convert text to speech")
    print(f"   • POST /analyze-image - Analyze crop images")
    uvicorn.run(app, host="0.0.0.0", port=8000)
