// Web Speech Recognition for Flutter Web
class WebSpeechRecognition {
    constructor() {
        this.recognition = null;
        this.isSupported = false;
        this.isListening = false;
        this.onResult = null;
        this.onError = null;
        this.onEnd = null;
        
        this.init();
    }
    
    init() {
        // Check if browser supports speech recognition
        if ('webkitSpeechRecognition' in window) {
            this.recognition = new webkitSpeechRecognition();
            this.isSupported = true;
        } else if ('SpeechRecognition' in window) {
            this.recognition = new SpeechRecognition();
            this.isSupported = true;
        } else {
            console.log('Speech recognition not supported in this browser');
            return;
        }
        
        // Configure recognition
        this.recognition.continuous = false;
        this.recognition.interimResults = false;
        this.recognition.lang = 'en-US';
        this.recognition.maxAlternatives = 1;
        
        // Set up event handlers
        this.recognition.onresult = (event) => {
            const result = event.results[0][0].transcript;
            console.log('Speech recognition result:', result);
            if (this.onResult) {
                this.onResult(result);
            }
        };
        
        this.recognition.onerror = (event) => {
            console.error('Speech recognition error:', event.error);
            if (this.onError) {
                this.onError(event.error);
            }
        };
        
        this.recognition.onend = () => {
            console.log('Speech recognition ended');
            this.isListening = false;
            if (this.onEnd) {
                this.onEnd();
            }
        };
    }
    
    startListening() {
        if (!this.isSupported) {
            console.error('Speech recognition not supported');
            return false;
        }
        
        if (this.isListening) {
            console.warn('Already listening');
            return false;
        }
        
        try {
            this.recognition.start();
            this.isListening = true;
            console.log('Started listening...');
            return true;
        } catch (error) {
            console.error('Error starting speech recognition:', error);
            return false;
        }
    }
    
    stopListening() {
        if (!this.isListening) {
            return;
        }
        
        this.recognition.stop();
        this.isListening = false;
        console.log('Stopped listening');
    }
}

// Global instance
window.webSpeechRecognition = new WebSpeechRecognition();

// Flutter-callable functions
window.startSpeechRecognition = function(onResult, onError, onEnd) {
    const recognition = window.webSpeechRecognition;
    
    recognition.onResult = onResult;
    recognition.onError = onError;
    recognition.onEnd = onEnd;
    
    return recognition.startListening();
};

window.stopSpeechRecognition = function() {
    window.webSpeechRecognition.stopListening();
};

window.isSpeechRecognitionSupported = function() {
    return window.webSpeechRecognition.isSupported;
};
