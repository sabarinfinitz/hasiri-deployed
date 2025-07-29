import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert'; // For json, jsonDecode, base64Decode
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:ui'; // Needed for ImageFilter
import 'dart:js' as js; // For JavaScript interop
import '../config/api_config.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  ChatbotPageState createState() => ChatbotPageState();
}

class ChatbotPageState extends State<ChatbotPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final audio.AudioPlayer _audioPlayer = audio.AudioPlayer();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  
  // Audio recording state
  bool _isRecording = false;
  bool _isRecordingImageDesc = false; // For image description voice input
  
  // Audio playback state
  bool _isPlayingTTS = false;
  bool _isPausedTTS = false;
  
  // Image audio playback state
  bool _isImageAudioPlaying = false;
  bool _isImageAudioPaused = false;
  
  // Image analysis fields
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _imageReply;
  final TextEditingController _imageDescController = TextEditingController();
  bool _awaitingImageDesc = false;
  bool _isUploading = false;

  // Language consistency - track conversation language
  String _conversationLanguage = 'en-US'; // Default language
  String _conversationLanguageCode = 'en'; // Language code for backend

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    try {
      // Close any existing recorder first
      await _recorder.closeRecorder();
      
      // Wait a bit before reopening
      await Future.delayed(Duration(milliseconds: 500));
      
      // Open recorder with proper session
      await _recorder.openRecorder();
      
      // Set subscription duration for better recording
      await _recorder.setSubscriptionDuration(Duration(milliseconds: 100));
      
      print('Recorder initialized successfully');
    } catch (e) {
      print('Failed to initialize recorder: $e');
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    _controller.dispose();
    _imageDescController.dispose();
    super.dispose();
  }

  String _getLanguageCode(String languageTag) {
    // Convert language tag to simple language code for backend
    switch (languageTag) {
      case 'ta-IN':
        return 'ta';
      case 'hi-IN':
        return 'hi';
      case 'te-IN':
        return 'te';
      case 'kn-IN':
        return 'kn';
      case 'ml-IN':
        return 'ml';
      case 'bn-IN':
        return 'bn';
      case 'gu-IN':
        return 'gu';
      case 'pa-IN':
        return 'pa';
      case 'mr-IN':
        return 'mr';
      default:
        return 'en';
    }
  }

  String _detectLanguage(String text) {
    // Enhanced language detection based on character patterns and common words
    String cleanText = text.toLowerCase().trim();
    
    // Calculate the percentage of native characters for each language
    int totalChars = text.replaceAll(RegExp(r'\s'), '').length;
    if (totalChars < 3) return 'en-US'; // Too short to detect
    
    // Tamil detection with percentage check
    int tamilChars = RegExp(r'[\u0B80-\u0BFF]').allMatches(text).length;
    bool hasTamilWords = RegExp(r'\b(இந்த|அது|என்று|செய்|வேண்டும்|உள்ளது|பயிர்|நோய்|இலை|வளர்ச்சி)\b').hasMatch(cleanText);
    if (tamilChars > 0 || hasTamilWords) {
      double tamilPercentage = (tamilChars / totalChars) * 100;
      print('🔍 Tamil detection: ${tamilChars} chars (${tamilPercentage.toStringAsFixed(1)}%), words: $hasTamilWords');
      if (tamilChars > 2 || hasTamilWords) {
        return 'ta-IN';
      }
    }
    
    // Hindi/Devanagari detection with percentage check
    int hindiChars = RegExp(r'[\u0900-\u097F]').allMatches(text).length;
    bool hasHindiWords = RegExp(r'\b(यह|वह|है|में|से|को|की|का|के|फसल|बीमारी|पत्ते|विकास)\b').hasMatch(cleanText);
    if (hindiChars > 0 || hasHindiWords) {
      double hindiPercentage = (hindiChars / totalChars) * 100;
      print('🔍 Hindi detection: ${hindiChars} chars (${hindiPercentage.toStringAsFixed(1)}%), words: $hasHindiWords');
      if (hindiChars > 2 || hasHindiWords) {
        return 'hi-IN';
      }
    }
    
    // Telugu detection
    int teluguChars = RegExp(r'[\u0C00-\u0C7F]').allMatches(text).length;
    bool hasTeluguWords = RegExp(r'\b(ఈ|అది|అని|చేయు|వలె|ఉంది|పంట|వ్యాధి|ఆకులు|వృద్ధి)\b').hasMatch(cleanText);
    if (teluguChars > 0 || hasTeluguWords) {
      double teluguPercentage = (teluguChars / totalChars) * 100;
      print('🔍 Telugu detection: ${teluguChars} chars (${teluguPercentage.toStringAsFixed(1)}%), words: $hasTeluguWords');
      if (teluguChars > 2 || hasTeluguWords) {
        return 'te-IN';
      }
    }
    
    // Kannada detection
    int kannadaChars = RegExp(r'[\u0C80-\u0CFF]').allMatches(text).length;
    bool hasKannadaWords = RegExp(r'\b(ಇದು|ಅದು|ಎಂದು|ಮಾಡು|ಇದೆ|ಬೆಳೆ|ರೋಗ|ಎಲೆಗಳು)\b').hasMatch(cleanText);
    if (kannadaChars > 0 || hasKannadaWords) {
      double kannadaPercentage = (kannadaChars / totalChars) * 100;
      print('🔍 Kannada detection: ${kannadaChars} chars (${kannadaPercentage.toStringAsFixed(1)}%), words: $hasKannadaWords');
      if (kannadaChars > 2 || hasKannadaWords) {
        return 'kn-IN';
      }
    }
    
    // Malayalam detection
    int malayalamChars = RegExp(r'[\u0D00-\u0D7F]').allMatches(text).length;
    bool hasMalayalamWords = RegExp(r'\b(ഇത്|അത്|എന്ന്|ചെയ്യ്|ഉണ്ട്|വിള|രോഗം|ഇലകൾ)\b').hasMatch(cleanText);
    if (malayalamChars > 0 || hasMalayalamWords) {
      double malayalamPercentage = (malayalamChars / totalChars) * 100;
      print('🔍 Malayalam detection: ${malayalamChars} chars (${malayalamPercentage.toStringAsFixed(1)}%), words: $hasMalayalamWords');
      if (malayalamChars > 2 || hasMalayalamWords) {
        return 'ml-IN';
      }
    }
    
    // Bengali detection
    int bengaliChars = RegExp(r'[\u0980-\u09FF]').allMatches(text).length;
    bool hasBengaliWords = RegExp(r'\b(এই|সেই|বলে|করে|আছে|ফসল|রোগ|পাতা)\b').hasMatch(cleanText);
    if (bengaliChars > 0 || hasBengaliWords) {
      double bengaliPercentage = (bengaliChars / totalChars) * 100;
      print('🔍 Bengali detection: ${bengaliChars} chars (${bengaliPercentage.toStringAsFixed(1)}%), words: $hasBengaliWords');
      if (bengaliChars > 2 || hasBengaliWords) {
        return 'bn-IN';
      }
    }
    
    // Gujarati detection
    int gujaratiChars = RegExp(r'[\u0A80-\u0AFF]').allMatches(text).length;
    bool hasGujaratiWords = RegExp(r'\b(આ|તે|કહે|કરે|છે|પાક|રોગ|પાંદડા)\b').hasMatch(cleanText);
    if (gujaratiChars > 0 || hasGujaratiWords) {
      double gujaratiPercentage = (gujaratiChars / totalChars) * 100;
      print('🔍 Gujarati detection: ${gujaratiChars} chars (${gujaratiPercentage.toStringAsFixed(1)}%), words: $hasGujaratiWords');
      if (gujaratiChars > 2 || hasGujaratiWords) {
        return 'gu-IN';
      }
    }
    
    // Punjabi detection
    int punjabiChars = RegExp(r'[\u0A00-\u0A7F]').allMatches(text).length;
    bool hasPunjabiWords = RegExp(r'\b(ਇਹ|ਉਹ|ਕਹਿ|ਕਰ|ਹੈ|ਫਸਲ|ਬਿਮਾਰੀ|ਪੱਤੇ)\b').hasMatch(cleanText);
    if (punjabiChars > 0 || hasPunjabiWords) {
      double punjabiPercentage = (punjabiChars / totalChars) * 100;
      print('🔍 Punjabi detection: ${punjabiChars} chars (${punjabiPercentage.toStringAsFixed(1)}%), words: $hasPunjabiWords');
      if (punjabiChars > 2 || hasPunjabiWords) {
        return 'pa-IN';
      }
    }
    
    // Marathi detection (specific words that differ from Hindi)
    bool hasMarathiWords = RegExp(r'\b(हे|ते|म्हणे|करते|आहे|पीक|आजार|पाने)\b').hasMatch(cleanText);
    if (hasMarathiWords) {
      print('🔍 Marathi detected: Marathi-specific words found');
      return 'mr-IN';
    }
    
    // Default to English if no Indian language detected with sufficient confidence
    print('🔍 Defaulting to English - no Indian language patterns detected with sufficient confidence');
    return 'en-US';
  }

  // Helper method to clean text for TTS (remove symbols and formatting)
  String _cleanTextForTTS(String text) {
    // Remove common symbols and formatting that TTS shouldn't read
    String cleanedText = text
        // Remove asterisks used for emphasis
        .replaceAll(RegExp(r'\*+'), '')
        // Remove parentheses and content inside for cleaner speech
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        // Remove square brackets and content
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        // Remove extra punctuation
        .replaceAll(RegExp(r'[•◦▪▫]'), '') // bullet points
        .replaceAll(RegExp(r'[-–—]{2,}'), ' ') // multiple dashes
        .replaceAll(RegExp(r'[_]{2,}'), ' ') // underscores
        // Remove hashtags and special formatting
        .replaceAll(RegExp(r'#{2,}'), '')
        .replaceAll(RegExp(r'\*\*.*?\*\*'), '') // bold text markers
        // Clean up multiple spaces and newlines
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    print('🧹 Text cleaned for TTS. Original: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
    print('🧹 Cleaned: "${cleanedText.substring(0, cleanedText.length > 50 ? 50 : cleanedText.length)}..."');
    
    return cleanedText;
  }

  // Enhanced method to extract native language content only
  String _extractNativeLanguageContent(String text, String detectedLanguage) {
    String cleanedText = _cleanTextForTTS(text);
    
    // If it's English, return cleaned text as is
    if (detectedLanguage == 'en-US') {
      return cleanedText;
    }
    
    // For Indian languages, extract only the native script content
    List<String> nativeLines = [];
    List<String> lines = cleanedText.split('\n');
    
    for (String line in lines) {
      String trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Check if this line contains native script
      bool hasNativeScript = false;
      
      switch (detectedLanguage) {
        case 'ta-IN':
          hasNativeScript = RegExp(r'[\u0B80-\u0BFF]').hasMatch(trimmedLine);
          break;
        case 'hi-IN':
        case 'mr-IN':
          hasNativeScript = RegExp(r'[\u0900-\u097F]').hasMatch(trimmedLine);
          break;
        case 'te-IN':
          hasNativeScript = RegExp(r'[\u0C00-\u0C7F]').hasMatch(trimmedLine);
          break;
        case 'kn-IN':
          hasNativeScript = RegExp(r'[\u0C80-\u0CFF]').hasMatch(trimmedLine);
          break;
        case 'ml-IN':
          hasNativeScript = RegExp(r'[\u0D00-\u0D7F]').hasMatch(trimmedLine);
          break;
        case 'bn-IN':
          hasNativeScript = RegExp(r'[\u0980-\u09FF]').hasMatch(trimmedLine);
          break;
        case 'gu-IN':
          hasNativeScript = RegExp(r'[\u0A80-\u0AFF]').hasMatch(trimmedLine);
          break;
        case 'pa-IN':
          hasNativeScript = RegExp(r'[\u0A00-\u0A7F]').hasMatch(trimmedLine);
          break;
      }
      
      // Only include lines that have native script content
      if (hasNativeScript) {
        // Remove any remaining English words and numbers from native text
        String nativeLine = trimmedLine
            .replaceAll(RegExp(r'\b[A-Za-z]+\b'), '') // Remove English words
            .replaceAll(RegExp(r'\d+'), '') // Remove numbers that might confuse TTS
            .replaceAll(RegExp(r'[^\u0900-\u097F\u0B80-\u0BFF\u0C00-\u0C7F\u0C80-\u0CFF\u0D00-\u0D7F\u0980-\u09FF\u0A80-\u0AFF\u0A00-\u0A7F\s\.,!?]'), '') // Keep only native scripts and basic punctuation
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        
        if (nativeLine.isNotEmpty) {
          nativeLines.add(nativeLine);
        }
      }
    }
    
    String result = nativeLines.join(' ').trim();
    
    // If no native content found, use the first few words of cleaned text
    if (result.isEmpty) {
      List<String> words = cleanedText.split(' ');
      result = words.take(10).join(' '); // First 10 words only
    }
    
    print('🎯 Extracted native content for $detectedLanguage:');
    print('📝 Original length: ${cleanedText.length} characters');
    print('🔤 Native content: "${result.substring(0, result.length > 100 ? 100 : result.length)}..."');
    
    return result;
  }

  Future<void> _playTTS(String text, {bool useConversationLanguage = false}) async {
    try {
      print('Starting TTS for text: $text');
      
      // Enhanced language detection for TTS
      String detectedLanguage;
      if (useConversationLanguage && _conversationLanguage.isNotEmpty) {
        detectedLanguage = _conversationLanguage;
        print('🎯 Using conversation language: $detectedLanguage');
      } else {
        // Always detect from the actual text content for better accuracy
        detectedLanguage = _detectLanguage(text);
        print('🔍 Auto-detected language from text: $detectedLanguage');
        
        // Update conversation language if this is a new detection
        if (_conversationLanguage.isEmpty || _conversationLanguage == 'en-US') {
          _conversationLanguage = detectedLanguage;
          _conversationLanguageCode = _getLanguageCode(detectedLanguage);
          print('🌐 Updated conversation language to: $detectedLanguage');
        }
      }
      
      // Extract only native language content for consistent TTS
      String nativeText = _extractNativeLanguageContent(text, detectedLanguage);
      
      // Truncate text if it's too long for TTS
      String ttsText = nativeText;
      if (nativeText.length > 1000) { // Conservative limit to account for UTF-8 encoding
        ttsText = nativeText.substring(0, 1000) + "...";
        print('Native text truncated for TTS. Original length: ${nativeText.length}, TTS length: ${ttsText.length}');
      }
      
      // Skip TTS if no meaningful content
      if (ttsText.trim().length < 3) {
        print('⚠️ Skipping TTS - insufficient native content');
        return;
      }
      
      var uri = Uri.parse(ApiConfig.textToSpeechEndpoint);
      var response = await http.post(
        uri, 
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'text': ttsText, 'language': detectedLanguage}
      );
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String audioBase64 = data['audioContent'] ?? '';
        
        if (audioBase64.isNotEmpty) {
          try {
            Uint8List audioBytes = base64Decode(audioBase64);
            print('Playing TTS audio in $detectedLanguage, size: ${audioBytes.length} bytes');
            
            // Stop any currently playing audio
            await _audioPlayer.stop();
            
            // Set up audio player event listeners
            _audioPlayer.onPlayerStateChanged.listen((audio.PlayerState state) {
              if (mounted) {
                setState(() {
                  _isPlayingTTS = state == audio.PlayerState.playing;
                  _isPausedTTS = state == audio.PlayerState.paused;
                });
              }
            });
            
            // Play the audio
            setState(() {
              _isPlayingTTS = true;
              _isPausedTTS = false;
            });
            
            await _audioPlayer.play(audio.BytesSource(audioBytes));
            print('TTS playback started successfully in $detectedLanguage');
            
            // Show message if text was truncated
            if (text.length > 1000 && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Long text was truncated for speech playback'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            print('Error playing TTS audio: $e');
            setState(() {
              _isPlayingTTS = false;
              _isPausedTTS = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to play audio response')),
              );
            }
          }
        } else {
          print('No audio content received from TTS service');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No audio content received')),
            );
          }
        }
      } else {
        print('TTS request failed: ${response.statusCode} - ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Text-to-speech service unavailable')),
          );
        }
      }
    } catch (e) {
      print('Error in TTS: $e');
      setState(() {
        _isPlayingTTS = false;
        _isPausedTTS = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to convert text to speech')),
        );
      }
    }
  }

  Future<void> _pauseResumeTTS() async {
    try {
      if (_isPlayingTTS && !_isPausedTTS) {
        await _audioPlayer.pause();
        setState(() {
          _isPausedTTS = true;
          _isPlayingTTS = false;
        });
      } else if (_isPausedTTS) {
        await _audioPlayer.resume();
        setState(() {
          _isPausedTTS = false;
          _isPlayingTTS = true;
        });
      }
    } catch (e) {
      print('Error pausing/resuming TTS: $e');
    }
  }

  Future<void> _pauseTTS() async {
    try {
      if ((_isPlayingTTS && !_isPausedTTS) || (_isImageAudioPlaying && !_isImageAudioPaused)) {
        await _audioPlayer.pause();
        setState(() {
          _isPausedTTS = true;
          _isPlayingTTS = false;
          if (_isImageAudioPlaying) {
            _isImageAudioPaused = true;
            _isImageAudioPlaying = false;
          }
        });
      }
    } catch (e) {
      print('Error pausing TTS: $e');
    }
  }

  Future<void> _resumeTTS() async {
    try {
      if (_isPausedTTS || _isImageAudioPaused) {
        await _audioPlayer.resume();
        setState(() {
          if (_isPausedTTS) {
            _isPausedTTS = false;
            _isPlayingTTS = true;
          }
          if (_isImageAudioPaused) {
            _isImageAudioPaused = false;
            _isImageAudioPlaying = true;
          }
        });
      }
    } catch (e) {
      print('Error resuming TTS: $e');
    }
  }

  Future<void> _stopTTS() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlayingTTS = false;
        _isPausedTTS = false;
        _isImageAudioPlaying = false;
        _isImageAudioPaused = false;
      });
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  Future<void> _playImageTTS(String text) async {
    try {
      print('Starting Image TTS for text: $text');
      
      // Stop any currently playing audio first
      if (_isPlayingTTS || _isPausedTTS || _isImageAudioPlaying || _isImageAudioPaused) {
        await _audioPlayer.stop();
        setState(() {
          _isPlayingTTS = false;
          _isPausedTTS = false;
          _isImageAudioPlaying = false;
          _isImageAudioPaused = false;
        });
        await Future.delayed(Duration(milliseconds: 200)); // Brief pause
      }
      
      // Enhanced language detection - always detect from actual content
      String detectedLanguage;
      if (_conversationLanguage.isNotEmpty && _conversationLanguage != 'en-US') {
        detectedLanguage = _conversationLanguage;
        print('🎯 Using established conversation language: $detectedLanguage');
      } else {
        detectedLanguage = _detectLanguage(text);
        print('🔍 Auto-detected language for image TTS: $detectedLanguage');
        
        // Update conversation language if this is a new detection
        if (detectedLanguage != 'en-US') {
          _conversationLanguage = detectedLanguage;
          _conversationLanguageCode = _getLanguageCode(detectedLanguage);
          print('🌐 Updated conversation language to: $detectedLanguage');
        }
      }
      
      // Extract only native language content for consistent TTS
      String nativeText = _extractNativeLanguageContent(text, detectedLanguage);
      
      // Truncate text if it's too long for TTS
      String ttsText = nativeText;
      if (nativeText.length > 1000) {
        ttsText = nativeText.substring(0, 1000) + "...";
        print('Image TTS native text truncated. Original length: ${nativeText.length}, TTS length: ${ttsText.length}');
      }
      
      // Skip TTS if no meaningful content
      if (ttsText.trim().length < 3) {
        print('⚠️ Skipping Image TTS - insufficient native content');
        return;
      }
      
      var uri = Uri.parse(ApiConfig.textToSpeechEndpoint);
      var response = await http.post(
        uri, 
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'text': ttsText, 'language': detectedLanguage}
      );
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String audioBase64 = data['audioContent'] ?? '';
        
        if (audioBase64.isNotEmpty) {
          try {
            Uint8List audioBytes = base64Decode(audioBase64);
            print('Playing Image TTS audio in $detectedLanguage, size: ${audioBytes.length} bytes');
            
            // Set up audio player event listeners for image audio
            _audioPlayer.onPlayerStateChanged.listen((audio.PlayerState state) {
              if (mounted) {
                setState(() {
                  _isImageAudioPlaying = state == audio.PlayerState.playing;
                  _isImageAudioPaused = state == audio.PlayerState.paused;
                  
                  // Reset states when audio completes
                  if (state == audio.PlayerState.completed || state == audio.PlayerState.stopped) {
                    _isImageAudioPlaying = false;
                    _isImageAudioPaused = false;
                  }
                });
              }
            });
            
            // Start playing audio
            setState(() {
              _isImageAudioPlaying = true;
              _isImageAudioPaused = false;
            });
            
            await _audioPlayer.play(audio.BytesSource(audioBytes));
            print('Image TTS playback started successfully in $detectedLanguage');
            
            // Show message if text was truncated
            if (text.length > 1000 && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Long text was truncated for speech playback'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            print('Error playing Image TTS audio: $e');
            setState(() {
              _isImageAudioPlaying = false;
              _isImageAudioPaused = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to play audio response'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          print('No audio content received from Image TTS service');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No audio content received')),
            );
          }
        }
      } else {
        print('Image TTS request failed: ${response.statusCode} - ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Text-to-speech service unavailable')),
          );
        }
      }
    } catch (e) {
      print('Error in Image TTS: $e');
      setState(() {
        _isImageAudioPlaying = false;
        _isImageAudioPaused = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to convert text to speech')),
        );
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    // Detect input language and update conversation language
    String inputLanguage = _detectLanguage(text);
    String languageCode = _getLanguageCode(inputLanguage);
    
    // Update conversation language for consistency
    _conversationLanguage = inputLanguage;
    _conversationLanguageCode = languageCode;
    
    print('🌐 User input language detected: $inputLanguage ($languageCode)');
    
    setState(() {
      _messages.add({"text": text, "isUser": true});
      _isLoading = true;
    });
    _controller.clear();
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.chatEndpoint),
        body: {'text': text, 'language': languageCode},
      );
      if (response.statusCode == 200) {
        final reply = jsonDecode(response.body)['reply'];
        setState(() {
          _messages.add({"text": reply, "isUser": false});
        });
        // Always detect language from the reply content for more accurate TTS
        print('🔊 Playing TTS with auto-detected language from reply content');
        await _playTTS(reply, useConversationLanguage: false); // Let it auto-detect from content
      } else {
        setState(() {
          _messages.add({"text": "Sorry, I couldn't process your request.", "isUser": false});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"text": "Error connecting to server.", "isUser": false});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      print('Starting recording process...');
      
      if (kIsWeb) {
        // For web, use browser's built-in speech recognition
        _startWebSpeechRecognition();
        return;
      }
      
      // Request microphone permission first (for mobile)
      var status = await Permission.microphone.request();
      print('Microphone permission status: $status');
      
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Microphone permission is required for voice recording')),
          );
        }
        return;
      }

      // Stop any ongoing recording first
      if (_recorder.isRecording) {
        print('Stopping existing recording...');
        await _recorder.stopRecorder();
        await Future.delayed(Duration(milliseconds: 300));
      }

      // Ensure recorder is properly initialized
      try {
        // Check if recorder needs to be opened
        print('Checking recorder state...');
        await _recorder.openRecorder();
        await Future.delayed(Duration(milliseconds: 200));
      } catch (e) {
        print('Recorder may already be open: $e');
        // Try to reinitialize if there's an issue
        await _initializeRecorder();
      }

      // Start recording with proper configuration for mobile
      print('Starting actual recording...');
      await _recorder.startRecorder(
        toFile: 'voice_recording.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      
      setState(() { 
        _isRecording = true; 
      });
      
      print('Recording started successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording started! Tap the red button to stop.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('Error starting recording: $e');
      setState(() { _isRecording = false; });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _startWebSpeechRecognition() async {
    try {
      setState(() { _isRecording = true; });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listening... Speak now! Tap the red button to stop.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Check if speech recognition is supported
      if (kIsWeb && js.context.hasProperty('startSpeechRecognition')) {
        print('Starting web speech recognition...');
        
        // Set up callbacks
        js.context['onSpeechResult'] = (String result) {
          print('Speech result received: $result');
          if (mounted) {
            _controller.text = result;
            setState(() {
              _isRecording = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech recognized: $result'),
                backgroundColor: Colors.green,
              ),
            );
          }
        };
        
        js.context['onSpeechError'] = (String error) {
          print('Speech recognition error: $error');
          if (mounted) {
            setState(() { _isRecording = false; });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech recognition error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        };
        
        js.context['onSpeechEnd'] = () {
          print('Speech recognition ended');
          if (mounted) {
            setState(() { _isRecording = false; });
          }
        };
        
        // Start recognition
        bool started = js.context.callMethod('startSpeechRecognition', [
          js.allowInterop((String result) => js.context['onSpeechResult'](result)),
          js.allowInterop((String error) => js.context['onSpeechError'](error)),
          js.allowInterop(() => js.context['onSpeechEnd']())
        ]);
        
        if (!started) {
          throw Exception('Failed to start speech recognition');
        }
      } else {
        throw Exception('Speech recognition not supported in this browser');
      }
      
    } catch (e) {
      print('Error starting web speech recognition: $e');
      setState(() { _isRecording = false; });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech recognition not available. Please type your message instead.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _stopRecordingAndTranscribe() async {
    try {
      setState(() { _isRecording = false; });
      
      if (kIsWeb) {
        // For web, stop speech recognition
        if (js.context.hasProperty('stopSpeechRecognition')) {
          js.context.callMethod('stopSpeechRecognition');
          print('Web speech recognition stopped');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Speech recognition stopped.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      // Mobile recording processing
      String? path = await _recorder.stopRecorder();
      
      if (path != null && path.isNotEmpty) {
        print('Recording saved to: $path');
        
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Processing voice... Please wait.')),
          );
        }
        
        try {
          var audioBytes = await File(path).readAsBytes();
          String filename = 'voice.wav';
          
          // Determine filename based on the actual file path
          if (path.contains('.webm')) {
            filename = 'voice.webm';
          } else if (path.contains('.aac')) {
            filename = 'voice.aac';
          } else if (path.contains('.wav')) {
            filename = 'voice.wav';
          }
          
          var uri = Uri.parse(ApiConfig.speechToTextEndpoint);
          var request = http.MultipartRequest('POST', uri)
            ..files.add(http.MultipartFile.fromBytes(
              'audio', 
              audioBytes, 
              filename: filename
            ));
          
          var response = await request.send();
          var respStr = await response.stream.bytesToString();
          
          if (response.statusCode == 200) {
            var data = json.decode(respStr);
            String transcript = data['transcript'] ?? '';
            if (transcript.isNotEmpty) {
              _controller.text = transcript;
              setState(() {});
              print('Transcription: $transcript');
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No speech detected. Please try again.')),
                );
              }
            }
          } else {
            print('Transcription failed: ${response.statusCode}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Speech recognition failed. Please check your internet connection.')),
              );
            }
          }
        } catch (e) {
          print('Error processing audio: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to process voice recording. Please try again.')),
            );
          }
        }
      } else {
        print('No recording file found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recording failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() { _isRecording = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageReply = null;
        _awaitingImageDesc = true;
        _imageDescController.clear();
      });
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImage = null;
        });
      } else {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _selectedImageBytes = null;
        });
      }
    }
  }

  String _getImageAnalysisPrompt() {
    // Return language-specific image analysis prompt
    switch (_conversationLanguageCode) {
      case 'ta':
        return 'இந்த பயிர் படத்தை பகுப்பாய்வு செய்து நோய்கள், பூச்சிகள், வளர்ச்சி நிலை பற்றி சொல்லுங்கள்';
      case 'hi':
        return 'इस फसल की तस्वीर का विश्लेषण करें और बीमारी, कीट, विकास की स्थिति के बारे में बताएं';
      case 'te':
        return 'ఈ పంట చిత్రాన్ని విశ్లేషించి వ్యాధులు, కీటకాలు, పెరుగుదల స్థితి గురించి చెప్పండి';
      case 'kn':
        return 'ಈ ಬೆಳೆಯ ಚಿತ್ರವನ್ನು ವಿಶ್ಲೇಷಿಸಿ ಮತ್ತು ರೋಗಗಳು, ಕೀಟಗಳು, ಬೆಳವಣಿಗೆಯ ಸ್ಥಿತಿಯ ಬಗ್ಗೆ ಹೇಳಿ';
      case 'ml':
        return 'ഈ വിള ചിത്രം വിശകലനം ചെയ്ത് രോഗങ്ങൾ, കീടങ്ങൾ, വളർച്ചാ നില എന്നിവയെ കുറിച്ച് പറയുക';
      default:
        return 'Analyze this crop image and provide insights (disease, health, growth, pest, etc.)';
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() { _isUploading = true; });
    final uri = Uri.parse(ApiConfig.analyzeImageEndpoint);
    
    // Create language-specific prompt
    String defaultPrompt = _getImageAnalysisPrompt();
    
    final request = http.MultipartRequest('POST', uri)
      ..fields['prompt'] = _imageDescController.text.isNotEmpty
          ? _imageDescController.text
          : defaultPrompt
      ..fields['language'] = _conversationLanguageCode // Send conversation language
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    setState(() { _isUploading = false; _awaitingImageDesc = false; });
    if (response.statusCode == 200) {
      final data = json.decode(respStr);
      setState(() { _imageReply = data['reply']; });
      if (_imageReply != null && _imageReply!.isNotEmpty) {
        await _playImageTTS(_imageReply!); // Auto-detect language from reply content
      }
    } else {
      setState(() { _imageReply = 'Error analyzing image.'; });
    }
  }

  Future<void> _uploadImageWeb(Uint8List bytes, String filename) async {
    setState(() { _isUploading = true; });
    final uri = Uri.parse(ApiConfig.analyzeImageEndpoint);
    
    // Create language-specific prompt
    String defaultPrompt = _getImageAnalysisPrompt();
    
    final request = http.MultipartRequest('POST', uri)
      ..fields['prompt'] = _imageDescController.text.isNotEmpty
          ? _imageDescController.text
          : defaultPrompt
      ..fields['language'] = _conversationLanguageCode // Send conversation language
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    setState(() { _isUploading = false; _awaitingImageDesc = false; });
    if (response.statusCode == 200) {
      final data = json.decode(respStr);
      setState(() { _imageReply = data['reply']; });
      if (_imageReply != null && _imageReply!.isNotEmpty) {
        await _playImageTTS(_imageReply!); // Auto-detect language from reply content
      }
    } else {
      setState(() { _imageReply = 'Error analyzing image.'; });
    }
  }

  Future<void> _startRecordingImageDesc() async {
    try {
      print('Starting image description recording...');
      
      if (kIsWeb) {
        // For web, use browser's built-in speech recognition
        _startWebSpeechRecognitionForImageDesc();
        return;
      }
      
      // Request microphone permission first (for mobile)
      var status = await Permission.microphone.request();
      print('Microphone permission status: $status');
      
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Microphone permission is required for voice recording')),
          );
        }
        return;
      }

      // Stop any ongoing recording first
      if (_recorder.isRecording) {
        print('Stopping existing recording...');
        await _recorder.stopRecorder();
        await Future.delayed(Duration(milliseconds: 300));
      }

      // Ensure recorder is properly initialized
      try {
        print('Checking recorder state for image description...');
        await _recorder.openRecorder();
        await Future.delayed(Duration(milliseconds: 200));
      } catch (e) {
        print('Recorder may already be open: $e');
        await _initializeRecorder();
      }

      // Start recording with proper configuration for mobile
      print('Starting image description recording...');
      await _recorder.startRecorder(
        toFile: 'image_desc_recording.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      
      setState(() { 
        _isRecordingImageDesc = true; 
      });
      
      print('Image description recording started successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording... Describe what you want to analyze!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('Error starting image description recording: $e');
      setState(() { _isRecordingImageDesc = false; });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _startWebSpeechRecognitionForImageDesc() async {
    try {
      setState(() { _isRecordingImageDesc = true; });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listening for image description... Speak now!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Check if speech recognition is supported
      if (kIsWeb && js.context.hasProperty('startSpeechRecognition')) {
        print('Starting web speech recognition for image description...');
        
        // Set up callbacks for image description
        js.context['onImageDescSpeechResult'] = (String result) {
          print('Image description speech result received: $result');
          if (mounted) {
            _imageDescController.text = result;
            setState(() {
              _isRecordingImageDesc = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Description recorded: $result'),
                backgroundColor: Colors.green,
              ),
            );
          }
        };
        
        js.context['onImageDescSpeechError'] = (String error) {
          print('Image description speech recognition error: $error');
          if (mounted) {
            setState(() { _isRecordingImageDesc = false; });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech recognition error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        };
        
        js.context['onImageDescSpeechEnd'] = () {
          print('Image description speech recognition ended');
          if (mounted) {
            setState(() { _isRecordingImageDesc = false; });
          }
        };
        
        // Start recognition
        bool started = js.context.callMethod('startSpeechRecognition', [
          js.allowInterop((String result) => js.context['onImageDescSpeechResult'](result)),
          js.allowInterop((String error) => js.context['onImageDescSpeechError'](error)),
          js.allowInterop(() => js.context['onImageDescSpeechEnd']())
        ]);
        
        if (!started) {
          throw Exception('Failed to start speech recognition');
        }
      } else {
        throw Exception('Speech recognition not supported in this browser');
      }
      
    } catch (e) {
      print('Error starting web speech recognition for image description: $e');
      setState(() { _isRecordingImageDesc = false; });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech recognition not available. Please type your description instead.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _stopRecordingImageDescAndTranscribe() async {
    try {
      setState(() { _isRecordingImageDesc = false; });
      
      if (kIsWeb) {
        // For web, stop speech recognition
        if (js.context.hasProperty('stopSpeechRecognition')) {
          js.context.callMethod('stopSpeechRecognition');
          print('Web speech recognition for image description stopped');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Description recording stopped.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      // Mobile recording processing for image description
      String? path = await _recorder.stopRecorder();
      
      if (path != null && path.isNotEmpty) {
        print('Image description recording saved to: $path');
        
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Processing description... Please wait.')),
          );
        }
        
        try {
          var audioBytes = await File(path).readAsBytes();
          String filename = 'image_desc_voice.wav';
          
          // Determine filename based on the actual file path
          if (path.contains('.webm')) {
            filename = 'image_desc_voice.webm';
          } else if (path.contains('.aac')) {
            filename = 'image_desc_voice.aac';
          } else if (path.contains('.wav')) {
            filename = 'image_desc_voice.wav';
          }
          
          var uri = Uri.parse(ApiConfig.speechToTextEndpoint);
          var request = http.MultipartRequest('POST', uri)
            ..files.add(http.MultipartFile.fromBytes(
              'audio', 
              audioBytes, 
              filename: filename
            ));
          
          var response = await request.send();
          var respStr = await response.stream.bytesToString();
          
          if (response.statusCode == 200) {
            var data = json.decode(respStr);
            String transcript = data['transcript'] ?? '';
            if (transcript.isNotEmpty) {
              _imageDescController.text = transcript;
              setState(() {});
              print('Image description transcription: $transcript');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Description recorded: $transcript'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No speech detected. Please try again.')),
                );
              }
            }
          } else {
            print('Image description transcription failed: ${response.statusCode}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Speech recognition failed. Please check your internet connection.')),
              );
            }
          }
        } catch (e) {
          print('Error processing image description audio: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to process voice recording. Please try again.')),
            );
          }
        }
      } else {
        print('No image description recording file found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recording failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      print('Error stopping image description recording: $e');
      setState(() { _isRecordingImageDesc = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Dynamic animated background
            _buildAnimatedBackground(),
            
            // Main content with proper keyboard handling
            SafeArea(
              child: Column(
                children: [
                  // Enhanced header with glassmorphism
                  _buildEnhancedHeader(),
                  
                  // Dynamic messages area that adjusts to keyboard
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 0),
                      child: _buildMessagesArea(),
                    ),
                  ),
                  
                  // Dynamic input section with smart resizing
                  _buildDynamicInputSection(context),
                ],
              ),
            ),
            
            // Floating image analysis overlay
            if (_awaitingImageDesc || _selectedImage != null || _selectedImageBytes != null)
              _buildFloatingImageAnalysis(context),
              
            // Loading overlay
            if (_isLoading || _isUploading)
              _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedContainer(
      duration: Duration(seconds: 3),
      child: Stack(
        children: [
          // Background image with parallax effect
          Positioned.fill(
            child: Image.asset(
              'lib/img/chatbot-img.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Dynamic glassmorphism overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.green.withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated avatar
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [KissanColors.primary, KissanColors.accent],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: KissanColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(Icons.agriculture, color: Colors.white, size: 30),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HASIRI Assistant',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: KissanColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: KissanColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Online • Empowering Farmers',
                      style: TextStyle(
                        fontSize: 14,
                        color: KissanColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: KissanColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              'AI Ready',
              style: TextStyle(
                color: KissanColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (_messages.isEmpty) {
      return _buildWelcomeScreen();
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          return _buildMessageBubble(msg, index);
        },
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      margin: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated welcome icon
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  KissanColors.primary.withValues(alpha: 0.8),
                  KissanColors.accent.withValues(alpha: 0.6),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: KissanColors.primary.withValues(alpha: 0.3),
                  blurRadius: 25,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 30),
          
          // Welcome message
          Container(
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Welcome to HASIRI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: KissanColors.textPrimary,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Your AI-powered agricultural assistant is ready to help! Ask questions, analyze crops, or get farming advice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: KissanColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 30),
          
          // Quick action suggestions
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(Icons.mic, 'Voice Chat', KissanColors.primary, () {
          if (_isRecording) {
            _stopRecordingAndTranscribe();
          } else {
            _startRecording();
          }
        }),
        _buildQuickActionButton(Icons.camera_alt, 'Analyze Crop', KissanColors.accent, () {
          _pickImage();
        }),
        _buildQuickActionButton(Icons.chat, 'Ask Question', KissanColors.success, () {
          // Focus on the text input field
          FocusScope.of(context).requestFocus(FocusNode());
        }),
      ],
    );
  }

  Widget _buildQuickActionButton(IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, int index) {
    final isUser = msg["isUser"];
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // AI Avatar
            Container(
              width: 35,
              height: 35,
              margin: EdgeInsets.only(right: 8, bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [KissanColors.primary, KissanColors.accent],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
          ],
          
          // Message content
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [KissanColors.primary, KissanColors.accent],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.85),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: msg["text"],
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser ? Colors.white : KissanColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  if (!isUser) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Audio playback controls
                        if (_isPlayingTTS || _isPausedTTS) ...[
                          GestureDetector(
                            onTap: _stopTTS,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.withValues(alpha: 0.2),
                                    Colors.red.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stop, size: 14, color: Colors.red),
                                  SizedBox(width: 2),
                                  Text(
                                    'Stop',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          GestureDetector(
                            onTap: _pauseResumeTTS,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    KissanColors.accent.withValues(alpha: 0.2),
                                    KissanColors.accent.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: KissanColors.accent.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isPausedTTS ? Icons.play_arrow : Icons.pause,
                                    size: 14,
                                    color: KissanColors.accent,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    _isPausedTTS ? 'Resume' : 'Pause',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: KissanColors.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                        ],
                        
                        // Play TTS button
                        GestureDetector(
                          onTap: () async {
                            await _playTTS(msg["text"], useConversationLanguage: false); // Auto-detect from content
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  KissanColors.primary.withValues(alpha: 0.2),
                                  KissanColors.accent.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: KissanColors.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isPlayingTTS ? Icons.volume_up : Icons.volume_up_outlined,
                                  size: 16,
                                  color: _isPlayingTTS ? KissanColors.accent : KissanColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _isPlayingTTS ? 'Playing...' : 'Listen',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isPlayingTTS ? KissanColors.accent : KissanColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (isUser) ...[
            // User Avatar
            Container(
              width: 35,
              height: 35,
              margin: EdgeInsets.only(left: 8, bottom: 8),
              decoration: BoxDecoration(
                color: KissanColors.textSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicInputSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input row with enhanced buttons
          Row(
            children: [
              // Voice recording button with animation
              _buildVoiceButton(),
              SizedBox(width: 12),
              
              // Image picker button
              _buildImageButton(),
              SizedBox(width: 12),
              
              // Text input field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: KissanColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _isRecording ? 'Recording...' : 'Type your message...',
                      hintStyle: TextStyle(
                        color: KissanColors.textSecondary,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: KissanColors.textPrimary,
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        _sendMessage(text.trim());
                      }
                    },
                    maxLines: null,
                  ),
                ),
              ),
              SizedBox(width: 12),
              
              // Send button
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onTap: () {
        if (_isRecording) {
          _stopRecordingAndTranscribe();
        } else {
          _startRecording();
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isRecording
                ? [Colors.red, Colors.red.shade600]
                : [KissanColors.primary, KissanColors.accent],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Colors.red : KissanColors.primary)
                  .withValues(alpha: 0.4),
              blurRadius: _isRecording ? 20 : 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildImageButton() {
    return GestureDetector(
      onTap: () {
        _pickImage();
      },
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [KissanColors.accent, KissanColors.success],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: KissanColors.accent.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: () {
        if (_controller.text.trim().isNotEmpty) {
          _sendMessage(_controller.text.trim());
        }
      },
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [KissanColors.primary, KissanColors.accent],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: KissanColors.primary.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.send,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildFloatingImageAnalysis(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 25,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.agriculture, color: KissanColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Crop Image Analysis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: KissanColors.textPrimary,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _selectedImageBytes = null;
                            _awaitingImageDesc = false;
                            _imageDescController.clear();
                          });
                        },
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Image preview
                  if (_selectedImage != null || _selectedImageBytes != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : _selectedImageBytes != null
                                ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                                : Container(),
                      ),
                    ),
                  
                  SizedBox(height: 20),
                  
                  // Description input with voice option
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _imageDescController,
                              decoration: InputDecoration(
                                labelText: 'Describe what you want to know (optional)',
                                hintText: _isRecordingImageDesc 
                                    ? 'Recording your description...' 
                                    : 'e.g., Check for diseases, growth stage, pest analysis...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                prefixIcon: Icon(Icons.edit_note),
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    if (_isRecordingImageDesc) {
                                      _stopRecordingImageDescAndTranscribe();
                                    } else {
                                      _startRecordingImageDesc();
                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsets.all(8),
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _isRecordingImageDesc
                                            ? [Colors.red, Colors.red.shade600]
                                            : [KissanColors.primary, KissanColors.accent],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isRecordingImageDesc ? Colors.red : KissanColors.primary)
                                              .withValues(alpha: 0.3),
                                          blurRadius: _isRecordingImageDesc ? 15 : 10,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isRecordingImageDesc ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                      if (_isRecordingImageDesc) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Recording... Speak your description now!',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : () {
                            if (_selectedImage != null) {
                              _uploadImage(_selectedImage!);
                            } else if (_selectedImageBytes != null) {
                              _uploadImageWeb(_selectedImageBytes!, 'image.jpg');
                            }
                          },
                          icon: _isUploading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.analytics),
                          label: Text(_isUploading ? 'Analyzing...' : 'Analyze Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KissanColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Analysis result
                  if (_imageReply != null) ...[
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: KissanColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: KissanColors.success),
                              SizedBox(width: 8),
                              Text(
                                'Analysis Complete',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: KissanColors.success,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            _imageReply!,
                            style: TextStyle(
                              color: KissanColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  if (_imageReply != null && _imageReply!.isNotEmpty) {
                                    if (_isImageAudioPlaying && !_isImageAudioPaused) {
                                      await _pauseTTS();
                                      setState(() {
                                        _isImageAudioPaused = true;
                                      });
                                    } else if (_isImageAudioPaused) {
                                      await _resumeTTS();
                                      setState(() {
                                        _isImageAudioPaused = false;
                                      });
                                    } else {
                                      setState(() {
                                        _isImageAudioPlaying = true;
                                        _isImageAudioPaused = false;
                                      });
                                      await _playImageTTS(_imageReply!);
                                      setState(() {
                                        _isImageAudioPlaying = false;
                                        _isImageAudioPaused = false;
                                      });
                                    }
                                  }
                                },
                                icon: Icon(
                                  _isImageAudioPlaying && !_isImageAudioPaused
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: KissanColors.primary,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: KissanColors.primary, width: 1),
                                ),
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                onPressed: (_isImageAudioPlaying || _isImageAudioPaused) ? () async {
                                  await _stopTTS();
                                  setState(() {
                                    _isImageAudioPlaying = false;
                                    _isImageAudioPaused = false;
                                  });
                                } : null,
                                icon: Icon(
                                  Icons.stop,
                                  color: (_isImageAudioPlaying || _isImageAudioPaused) 
                                      ? KissanColors.warning 
                                      : Colors.grey,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: (_isImageAudioPlaying || _isImageAudioPaused) 
                                        ? KissanColors.warning 
                                        : Colors.grey, 
                                    width: 1
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              if (_isImageAudioPlaying && !_isImageAudioPaused)
                                Container(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(KissanColors.primary),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: KissanColors.primary,
                  strokeWidth: 3,
                ),
                SizedBox(height: 15),
                Text(
                  _isUploading ? 'Analyzing your crop...' : 'Processing...',
                  style: TextStyle(
                    fontSize: 16,
                    color: KissanColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
