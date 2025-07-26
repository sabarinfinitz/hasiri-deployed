import os
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import requests
from PIL import Image
import io
import base64

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GOOGLE_SPEECH_API_KEY = os.getenv("GOOGLE_SPEECH_API_KEY")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent"

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
    audio_bytes = await audio.read()
    headers = {
        "Content-Type": "application/json",
    }
    stt_url = f"https://speech.googleapis.com/v1/speech:recognize?key={GOOGLE_SPEECH_API_KEY}"
    data = {
        "config": {
            "encoding": "LINEAR16",
            "sampleRateHertz": 16000,
            "languageCode": "en-US"
        },
        "audio": {
            "content": base64.b64encode(audio_bytes).decode("utf-8")
        }
    }
    response = requests.post(stt_url, headers=headers, json=data)
    if response.ok:
        result = response.json()
        transcript = ""
        if "results" in result and result["results"]:
            transcript = result["results"][0]["alternatives"][0]["transcript"]
        return {"transcript": transcript}
    return {"error": response.text}

# Text-to-Speech endpoint
@app.post("/text-to-speech")
async def text_to_speech(text: str = Form(...), language: str = Form("en-US")):
    headers = {
        "Content-Type": "application/json",
    }
    tts_url = f"https://texttospeech.googleapis.com/v1/text:synthesize?key={GOOGLE_SPEECH_API_KEY}"
    
    # Handle long text by truncating intelligently
    tts_text = text
    if len(text.encode('utf-8')) > 4500:  # Conservative limit to avoid 5000 byte limit
        print(f"Text too long for TTS ({len(text.encode('utf-8'))} bytes), truncating...")
        
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
        
        print(f"TTS text truncated to {len(tts_text.encode('utf-8'))} bytes")
    
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
    
    data = {
        "input": {"text": tts_text},
        "voice": voice_config,
        "audioConfig": {"audioEncoding": "MP3"}
    }
    
    print(f"TTS request for language: {language}, text length: {len(tts_text)} chars")
    response = requests.post(tts_url, headers=headers, json=data)
    print(f"TTS response status: {response.status_code}")
    
    if response.ok:
        result = response.json()
        audio_content = result.get("audioContent", "")
        return {"audioContent": audio_content}
    else:
        print(f"TTS error: {response.text}")
        return {"error": response.text}

# Chat endpoint
@app.post("/chat")
async def chat(text: str = Form(...), language: str = Form("en")):
    headers = {"Content-Type": "application/json"}
    params = {"key": GEMINI_API_KEY}
    # Add agricultural context and language support to the prompt
    prompt = (
        f"You are HASIRI, an expert agricultural assistant for Indian farmers. "
        f"Provide clear, practical, and regionally relevant advice. "
        f"If the user asks in a specific language, reply in that language. "
        f"If the user asks about crops, weather, pests, government schemes, or market prices, give actionable, simple steps. "
        f"User message: {text}"
    )
    data = {
        "contents": [
            {"role": "user", "parts": [{"text": prompt}]}
        ]
    }
    response = requests.post(GEMINI_API_URL, headers=headers, params=params, json=data)
    print("Gemini status:", response.status_code)
    print("Gemini response:", response.text)
    if response.ok:
        result = response.json()
        reply = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
        return {"reply": reply}
    return {"reply": "Sorry, I couldn't process your request."}

# Image analysis endpoint
@app.post("/analyze-image")
async def analyze_image(
    file: UploadFile = File(...),
    prompt: str = Form("Identify crop disease and give advice for this image")
):
    headers = {"Content-Type": "application/json"}
    params = {"key": GEMINI_API_KEY}
    image_bytes = await file.read()
    # Detect MIME type, fallback to image/jpeg if unknown
    mime_type = file.content_type
    if not mime_type or mime_type == "application/octet-stream":
        # Try to guess from file extension
        if file.filename.lower().endswith(".png"):
            mime_type = "image/png"
        else:
            mime_type = "image/jpeg"
    image_base64 = base64.b64encode(image_bytes).decode("utf-8")
    data = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {"text": prompt},
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
    print("Gemini status:", response.status_code)
    print("Gemini response:", response.text)
    if response.ok:
        result = response.json()
        reply = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
        return {"reply": reply}
    return {"reply": "Sorry, I couldn't process your request."}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
