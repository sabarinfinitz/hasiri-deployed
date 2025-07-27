import os
import sys
import re
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import requests
from PIL import Image
import io
import base64
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables from C:\dev\.env for local development
# In production (Render), environment variables are set in the dashboard
env_path = Path(r'C:\dev\.env')

# Only load .env file if it exists (for local development)
if env_path.exists():
    load_dotenv(env_path)
    print(f"🔍 Loading .env from: {env_path}")
    print(f"✅ .env file exists: {env_path.exists()}")
else:
    print("🌐 Running in production mode - using environment variables from hosting platform")

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

app = FastAPI(
    title="HASIRI Agricultural Assistant API",
    description="AI-powered agricultural assistant for farmers with automatic language detection",
    version="2.0.0"
)

# Configure CORS for Flutter web/app deployment
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["GET", "POST", "HEAD"],
    allow_headers=["*"],
)

def clean_text_for_tts(text: str) -> str:
    """
    Clean text for Text-to-Speech to avoid pronunciation of symbols and formatting.
    Removes markdown formatting, bullet points, and other symbols that TTS might pronounce.
    """
    if not text:
        return ""
    
    # Remove markdown formatting
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)  # Bold **text**
    text = re.sub(r'\*([^*]+)\*', r'\1', text)      # Italic *text*
    text = re.sub(r'__([^_]+)__', r'\1', text)      # Bold __text__
    text = re.sub(r'_([^_]+)_', r'\1', text)        # Italic _text_
    text = re.sub(r'`([^`]+)`', r'\1', text)        # Code `text`
    text = re.sub(r'```[^`]*```', '', text)         # Code blocks
    
    # Remove bullet points and list markers
    text = re.sub(r'^[\s]*[•·▪▫‣⁃]\s*', '', text, flags=re.MULTILINE)  # Unicode bullets
    text = re.sub(r'^[\s]*[-*+]\s*', '', text, flags=re.MULTILINE)     # ASCII bullets
    text = re.sub(r'^[\s]*\d+\.\s*', '', text, flags=re.MULTILINE)     # Numbered lists
    
    # Remove headers
    text = re.sub(r'^#+\s*', '', text, flags=re.MULTILINE)             # Markdown headers
    
    # Remove links
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)               # [text](url)
    text = re.sub(r'https?://[^\s]+', '', text)                        # Raw URLs
    
    # Remove common symbols that might be pronounced
    text = re.sub(r'[#@$%^&*(){}[\]|\\<>]', '', text)                  # Special characters
    text = re.sub(r'[→←↑↓⟹⟸⟷]', '', text)                             # Arrow symbols
    text = re.sub(r'[✓✗✘✔✕]', '', text)                                # Check marks
    text = re.sub(r'[©®™]', '', text)                                   # Copyright symbols
    text = re.sub(r'[°℃℉]', ' degrees ', text)                         # Temperature symbols
    text = re.sub(r'[₹$£€¥]', '', text)                                 # Currency symbols
    
    # Clean up excessive punctuation
    text = re.sub(r'[.]{2,}', '.', text)                               # Multiple dots
    text = re.sub(r'[-]{2,}', '-', text)                               # Multiple dashes
    text = re.sub(r'[!]{2,}', '!', text)                               # Multiple exclamations
    text = re.sub(r'[?]{2,}', '?', text)                               # Multiple questions
    
    # Replace common separators with natural pauses
    text = re.sub(r'[-–—]', ', ', text)                                 # Dashes to commas
    text = re.sub(r'[|]', ', ', text)                                   # Pipes to commas
    text = re.sub(r'[/]', ' or ', text)                                 # Slashes to "or"
    
    # Handle common abbreviations that might be mispronounced
    text = re.sub(r'\b(etc\.?)\b', 'and so on', text, flags=re.IGNORECASE)
    text = re.sub(r'\b(i\.e\.?)\b', 'that is', text, flags=re.IGNORECASE)
    text = re.sub(r'\b(e\.g\.?)\b', 'for example', text, flags=re.IGNORECASE)
    text = re.sub(r'\b(vs\.?)\b', 'versus', text, flags=re.IGNORECASE)
    
    # Clean up whitespace
    text = re.sub(r'\s+', ' ', text)                                    # Multiple spaces
    text = re.sub(r'\n\s*\n', '\n', text)                              # Multiple newlines
    text = text.strip()                                                 # Leading/trailing spaces
    
    return text

def detect_language_from_text(text: str) -> str:
    """
    Fallback function to detect language from text patterns when Speech API doesn't provide it.
    """
    if not text:
        return "en-US"
    
    text_lower = text.lower()
    
    # Check for Hindi script (Devanagari)
    if re.search(r'[\u0900-\u097F]', text):
        return "hi-IN"
    
    # Check for Tamil script
    if re.search(r'[\u0B80-\u0BFF]', text):
        return "ta-IN"
    
    # Check for Telugu script
    if re.search(r'[\u0C00-\u0C7F]', text):
        return "te-IN"
    
    # Check for Kannada script
    if re.search(r'[\u0C80-\u0CFF]', text):
        return "kn-IN"
    
    # Check for Malayalam script
    if re.search(r'[\u0D00-\u0D7F]', text):
        return "ml-IN"
    
    # Check for Bengali script
    if re.search(r'[\u0980-\u09FF]', text):
        return "bn-IN"
    
    # Check for Gujarati script
    if re.search(r'[\u0A80-\u0AFF]', text):
        return "gu-IN"
    
    # Check for Punjabi script (Gurmukhi)
    if re.search(r'[\u0A00-\u0A7F]', text):
        return "pa-IN"
    
    # Check for Marathi vs Hindi (both use Devanagari)
    if re.search(r'[\u0900-\u097F]', text):
        hindi_words = ['है', 'और', 'का', 'की', 'को', 'में', 'से', 'पर', 'के', 'यह', 'वह']
        marathi_words = ['आहे', 'आणि', 'चा', 'ची', 'ला', 'मध्ये', 'पासून', 'वर', 'हा', 'तो']
        
        hindi_count = sum(1 for word in hindi_words if word in text_lower)
        marathi_count = sum(1 for word in marathi_words if word in text_lower)
        
        if marathi_count > hindi_count:
            return "mr-IN"
        else:
            return "hi-IN"
    
    # Check for common Tamil words written in English transliteration
    tamil_words = ['vanakkam', 'nandri', 'payan', 'arisi', 'vivasayam', 'tamil', 'seyyalama', 'aruvadai']
    if any(word in text_lower for word in tamil_words):
        return "ta-IN"
    
    # Check for common Hindi words in transliteration
    hindi_transliteration = ['kaise', 'kahan', 'kya', 'namaste', 'dhanyawad', 'krishi', 'fasal']
    if any(word in text_lower for word in hindi_transliteration):
        return "hi-IN"
    
    # Check for other language words in transliteration
    if any(word in text_lower for word in ['telugu', 'ela', 'enti', 'bagundi']):
        return "te-IN"
    
    if any(word in text_lower for word in ['kannada', 'hege', 'yaava', 'chennu']):
        return "kn-IN"
    
    # Default to English
    return "en-US"
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to your frontend URL in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Root endpoint for health check - support both GET and HEAD
@app.get("/")
@app.head("/")
async def root():
    return {
        "message": "HASIRI Agricultural Assistant API",
        "status": "active",
        "version": "2.0.0",
        "features": ["automatic language detection", "native speaker responses"],
        "endpoints": [
            "/chat",
            "/speech-to-text", 
            "/text-to-speech",
            "/analyze-image"
        ]
    }

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": "2025-07-27"}

# Test endpoint for debugging connections
@app.get("/test")
async def test_connection():
    return {
        "message": "Connection successful!",
        "backend": "Render",
        "api_keys_loaded": bool(GEMINI_API_KEY and GOOGLE_SPEECH_API_KEY),
        "cors_enabled": True,
        "features": ["automatic language detection", "native speaker responses"]
    }

# Simple POST test endpoint
@app.post("/test-post")
async def test_post(message: str = Form("Hello from frontend!")):
    return {
        "received": message,
        "response": "Backend received your message successfully!",
        "status": "working"
    }

# Speech-to-Text endpoint with automatic language detection
@app.post("/speech-to-text")
async def speech_to_text(audio: UploadFile = File(...)):
    try:
        print(f"🎤 Processing speech-to-text for file: {audio.filename}")
        audio_bytes = await audio.read()
        
        headers = {"Content-Type": "application/json"}
        stt_url = f"https://speech.googleapis.com/v1/speech:recognize?key={GOOGLE_SPEECH_API_KEY}"
        
        # Enhanced configuration for automatic language detection
        data = {
            "config": {
                "encoding": "WEBM_OPUS",  # Updated for web audio
                "sampleRateHertz": 48000,  # Updated sample rate for web audio
                "languageCode": "en-US",  # Primary language hint
                "alternativeLanguageCodes": [
                    "ta-IN",    # Tamil
                    "hi-IN",    # Hindi  
                    "te-IN",    # Telugu
                    "kn-IN",    # Kannada
                    "ml-IN",    # Malayalam
                    "bn-IN",    # Bengali
                    "gu-IN",    # Gujarati
                    "pa-IN",    # Punjabi
                    "mr-IN"     # Marathi
                ],
                "enableAutomaticPunctuation": True,
                "enableWordConfidence": True,
                "enableSpokenPunctuation": True,
                "enableWordTimeOffsets": True,
                "audioChannelCount": 1,
                "model": "latest_long"
            },
            "audio": {
                "content": base64.b64encode(audio_bytes).decode("utf-8")
            }
        }
        
        response = requests.post(stt_url, headers=headers, json=data)
        print(f"🔍 Speech API response status: {response.status_code}")
        
        # Debug: Print the full response to understand the structure
        if response.ok:
            result = response.json()
            print(f"🔍 Full Speech API response: {result}")
        else:
            print(f"❌ Speech API error response: {response.text}")
        
        if response.ok:
            result = response.json()
            transcript = ""
            detected_language = "en-US"  # Default fallback
            
            if "results" in result and result["results"]:
                # Get the best alternative from results
                best_result = result["results"][0]
                alt = best_result["alternatives"][0]
                transcript = alt["transcript"]
                
                # Try multiple ways to get detected language from Google Speech API
                detected_language = None
                
                # Method 1: Check if language_code is in the result metadata
                if "languageCode" in best_result:
                    detected_language = best_result["languageCode"]
                    print(f"🌐 Language detected from result metadata: {detected_language}")
                
                # Method 2: Check alternative's language_code
                elif "languageCode" in alt:
                    detected_language = alt["languageCode"]
                    print(f"🌐 Language detected from alternative: {detected_language}")
                
                # Method 3: Check if it's in the response root
                elif "languageCode" in result:
                    detected_language = result["languageCode"]
                    print(f"🌐 Language detected from response root: {detected_language}")
                
                # If Google Speech API didn't return language, use our text-based detection
                if not detected_language:
                    detected_language = detect_language_from_text(transcript)
                    print(f"🧠 Using text-based language detection: {detected_language}")
                else:
                    print(f"🌐 Google Speech API detected language: {detected_language}")
                
                print(f"✅ Transcription successful: {transcript[:50]}...")
                print(f"🌐 Final detected language: {detected_language}")
            else:
                print("⚠️ No speech detected in audio")
                # Still try to detect language from any available text
                if transcript:
                    detected_language = detect_language_from_text(transcript)
            
            return {
                "transcript": transcript, 
                "languageCode": detected_language,
                "language_code": detected_language  # Also include this for frontend compatibility
            }
        else:
            print(f"❌ Speech API error: {response.text}")
            return {"error": response.text}
            
    except Exception as e:
        print(f"❌ Speech-to-text error: {str(e)}")
        return {"error": f"Processing error: {str(e)}"}

# Text-to-Speech endpoint
@app.post("/text-to-speech")
async def text_to_speech(text: str = Form(...), languageCode: str = Form("en-US")):
    try:
        print(f"🔊 Processing text-to-speech")
        print(f"🌐 Using languageCode: {languageCode}")
        print(f"📝 Original text length: {len(text)} characters")
        
        # Clean text to remove symbols and formatting that TTS might pronounce
        cleaned_text = clean_text_for_tts(text)
        print(f"🧹 Cleaned text length: {len(cleaned_text)} characters")
        
        headers = {"Content-Type": "application/json"}
        tts_url = f"https://texttospeech.googleapis.com/v1/text:synthesize?key={GOOGLE_SPEECH_API_KEY}"
        
        # Handle long text by truncating intelligently
        tts_text = cleaned_text
        if len(cleaned_text.encode('utf-8')) > 4500:  # Conservative limit to avoid 5000 byte limit
            print(f"⚠️ Text too long for TTS ({len(cleaned_text.encode('utf-8'))} bytes), truncating...")
            
            # Try to find natural break points (sentences)
            sentences = cleaned_text.split('।')  # Hindi sentence separator
            if len(sentences) == 1:
                sentences = cleaned_text.split('.')  # English sentence separator
            
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
                    tts_text = cleaned_text[:1000] + "..."
            else:
                # Simple truncation if no sentence breaks found
                tts_text = cleaned_text[:1000] + "..."
            
            print(f"✂️ TTS text truncated to {len(tts_text.encode('utf-8'))} bytes")
        
        # Select appropriate voice based on language
        voice_config = {"languageCode": languageCode, "ssmlGender": "FEMALE"}
        
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
        
        if languageCode in voice_names:
            voice_config["name"] = voice_names[languageCode]
            print(f"🎭 Using voice: {voice_names[languageCode]}")
        else:
            print(f"🎭 Using default voice for: {languageCode}")
        
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

# Chat endpoint with native speaker responses
@app.post("/chat")
async def chat(text: str = Form(...), languageCode: str = Form("en-US")):
    try:
        # Extract language part (e.g., 'ta' from 'ta-IN')
        language = languageCode.split('-')[0]
        
        print(f"💬 Processing chat request")
        print(f"🌐 Detected languageCode: {languageCode}")
        print(f"� Extracted language: {language}")
        print(f"�📝 User message: {text[:100]}...")
        
        headers = {"Content-Type": "application/json"}
        params = {"key": GEMINI_API_KEY}
        
        # Map language codes to language names for better AI understanding
        language_names = {
            "ta": "Tamil",
            "hi": "Hindi", 
            "te": "Telugu",
            "kn": "Kannada",
            "ml": "Malayalam",
            "bn": "Bengali",
            "gu": "Gujarati",
            "pa": "Punjabi",
            "mr": "Marathi",
            "en": "English"
        }
        
        language_name = language_names.get(language, "English")
        
        # Native speaker context based on language
        native_context = {
            "ta": "நீங்கள் ஒரு தமிழ் விவசாயி மற்றும் விவசாய நிபுணர். தமிழ்நாட்டின் உள்ளூர் விவசாய முறைகள், பயிர்கள், மற்றும் சூழ்நிலைகளை நன்கு தெரிந்தவர்.",
            "hi": "आप एक भारतीय किसान और कृषि विशेषज्ञ हैं। भारतीय खेती, फसलों और स्थानीय परिस्थितियों की गहरी समझ रखते हैं।",
            "te": "మీరు ఒక తెలుగు రైతు మరియు వ్యవసాయ నిపుణుడు. ఆంధ్రప్రదేశ్ మరియు తెలంగాణ వ్యవసాయ పద్ధతులను బాగా తెలుసు.",
            "kn": "ನೀವು ಕನ್ನಡ ರೈತ ಮತ್ತು ಕೃಷಿ ತಜ್ಞ. ಕರ್ನಾಟಕದ ಸ್ಥಳೀಯ ಕೃಷಿ ವಿಧಾನಗಳನ್ನು ಚೆನ್ನಾಗಿ ತಿಳಿದಿದ್ದೀರಿ.",
            "ml": "നിങ്ങൾ ഒരു മലയാളി കർഷകനും കാർഷിക വിദഗ്ധനുമാണ്. കേരളത്തിന്റെ പ്രാദേശിക കാർഷിക രീതികൾ നന്നായി അറിയാം.",
            "bn": "আপনি একজন বাঙালি কৃষক এবং কৃষি বিশেষজ্ঞ। পশ্চিমবঙ্গ ও বাংলাদেশের স্থানীয় কৃষি পদ্ধতি ভালো জানেন।",
            "gu": "તમે એક ગુજરાતી ખેડૂત અને કૃષિ નિષ્ણાત છો. ગુજરાતની સ્થાનિક કૃષિ પદ્ધતિઓ સારી રીતે જાણો છો।",
            "pa": "ਤੁਸੀਂ ਇੱਕ ਪੰਜਾਬੀ ਕਿਸਾਨ ਅਤੇ ਖੇਤੀਬਾੜੀ ਮਾਹਿਰ ਹੋ। ਪੰਜਾਬ ਦੇ ਸਥਾਨਕ ਖੇਤੀਬਾੜੀ ਦੇ ਤਰੀਕਿਆਂ ਨੂੰ ਚੰਗੀ ਤਰ੍ਹਾਂ ਜਾਣਦੇ ਹੋ।",
            "mr": "तुम्ही एक मराठी शेतकरी आणि कृषी तज्ञ आहात. महाराष्ट्राच्या स्थानिक शेती पद्धती चांगल्या माहीत आहेत।",
            "en": "You are an experienced Indian farmer and agricultural expert familiar with diverse farming practices across India."
        }
        
        # Enhanced agricultural context with VERY strict native speaker enforcement
        native_intro = native_context.get(language, native_context["en"])
        
        prompt = (
            f"{native_intro} "
            f"आपको अपनी मातृभाषा {language_name} में एक स्थानीय किसान की तरह जवाब देना है। "
            f"CRITICAL: आपका पूरा उत्तर केवल {language_name} भाषा में होना चाहिए। "
            f"किसी भी अन्य भाषा का एक भी शब्द उपयोग न करें। "
            f"आप एक स्थानीय {language_name} किसान हैं, विदेशी नहीं। "
            f"सरल, व्यावहारिक और क्षेत्रीय रूप से प्रासंगिक कृषि सलाह दें। "
            f"तुरंत कार्यान्वित किए जा सकने वाले कदमों पर ध्यान दें। "
            f"फसल, मौसम, कीट, रोग, उर्वरक, सिंचाई, सरकारी योजनाएं, बाजार भाव, जैविक खेती, और मौसमी सलाह जैसे विषयों को कवर करें। "
            f"हमेशा किसानों के प्रति उत्साहजनक और सहायक रहें। "
            f"TTS के लिए सरल टेक्स्ट का उपयोग करें, विशेष प्रतीक या बुलेट पॉइंट न लगाएं। "
            f"बुलेट पॉइंट के बजाय नंबर वाली सूची या पैराग्राफ का उपयोग करें। "
            f"याद रखें: आपका पूरा जवाब केवल {language_name} भाषा में होना चाहिए। कोई अंग्रेजी शब्द नहीं। "
            f"किसान का संदेश: {text}"
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

# Image analysis endpoint with native language support
@app.post("/analyze-image")
async def analyze_image(
    file: UploadFile = File(...),
    prompt: str = Form("Analyze this crop image for diseases, pests, growth stage, and provide farming advice"),
    languageCode: str = Form("en-US")
):
    try:
        # Extract language part (e.g., 'ta' from 'ta-IN')
        language = languageCode.split('-')[0]
        
        print(f"📸 Processing image analysis for file: {file.filename}")
        print(f"📝 Analysis prompt: {prompt[:100]}...")
        print(f"🌐 Image analysis languageCode: {languageCode}")
        print(f"🔤 Extracted language: {language}")
        
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
        
        # Map language codes to language names for better AI understanding
        language_names = {
            "ta": "Tamil",
            "hi": "Hindi", 
            "te": "Telugu",
            "kn": "Kannada",
            "ml": "Malayalam",
            "bn": "Bengali",
            "gu": "Gujarati",
            "pa": "Punjabi",
            "mr": "Marathi",
            "en": "English"
        }
        
        language_name = language_names.get(language, "English")
        
        # Native speaker context for image analysis
        native_context = {
            "ta": "நீங்கள் ஒரு தமிழ் விவசாயி மற்றும் பயிர் நோய் நிபுணர். ",
            "hi": "आप एक भारतीय किसान और फसल रोग विशेषज्ञ हैं। ",
            "te": "మీరు ఒక తెలుగు రైతు మరియు పంట వ్యాధి నిపుణుడు। ",
            "kn": "ನೀವು ಕನ್ನಡ ರೈತ ಮತ್ತು ಬೆಳೆ ರೋಗ ತಜ್ಞ। ",
            "ml": "നിങ്ങൾ ഒരു മലയാളി കർഷകനും വിള രോഗ വിദഗ്ധനുമാണ്। ",
            "bn": "আপনি একজন বাঙালি কৃষক এবং ফসলের রোগ বিশেষজ্ঞ। ",
            "gu": "તમે એક ગુજરાતી ખેડૂત અને પાક રોગ નિષ્ણાત છો। ",
            "pa": "ਤੁਸੀਂ ਇੱਕ ਪੰਜਾਬੀ ਕਿਸਾਨ ਅਤੇ ਫਸਲ ਰੋਗ ਮਾਹਿਰ ਹੋ। ",
            "mr": "तुम्ही एक मराठी शेतकरी आणि पीक रोग तज्ञ आहात। ",
            "en": "You are an experienced Indian farmer and crop disease specialist. "
        }
        
        native_intro = native_context.get(language, native_context["en"])
        
        # Enhanced prompt for better crop analysis with native speaker enforcement
        enhanced_prompt = (
            f"{native_intro}"
            f"CRITICAL INSTRUCTION: Your response must be written ENTIRELY in {language_name} language ONLY. "
            f"DO NOT write even a single word in English or any other language. "
            f"Start your response immediately in {language_name} without any English introduction. "
            f"Analyze this crop image and provide in {language_name} language: "
            f"1. Crop identification (if possible) "
            f"2. Disease detection (symptoms, causes, treatment) "
            f"3. Pest identification (if visible) "
            f"4. Growth stage assessment "
            f"5. Soil/environmental conditions visible "
            f"6. Recommended actions for the farmer "
            f"7. Prevention tips for future "
            f"Be specific, practical, and provide actionable advice in {language_name} language as a native speaker. "
            f"Use simple text without special symbols, bullet points, or formatting as your response will be converted to speech. "
            f"Instead of bullet points, use numbered lists or paragraphs. "
            f"Remember: Write your ENTIRE response in {language_name} language only. No English words allowed. "
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