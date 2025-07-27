"""
Test the text cleaning function for TTS
This shows how symbols and formatting will be cleaned before speech synthesis
"""

import re

def clean_text_for_tts(text: str) -> str:
    """
    Clean text for Text-to-Speech to avoid pronunciation of symbols and formatting.
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

# Test cases showing how the cleaning works
test_cases = [
    # Example with symbols that cause Tamil TTS to say "natchathirakuri"
    "**பயிர் பராமரிப்பு*** செய்ய வேண்டும்:\n• தண்ணீர் கொடுங்கள்\n• உரம் போடுங்கள்",
    
    # English with formatting
    "**Important:** Use *organic* fertilizer. Check these points:\n• Water regularly\n• Remove weeds\n• Monitor for pests",
    
    # Mixed with symbols
    "நல்ல விளைச்சலுக்கு: 1. தண்ணீர் 2. உரம் | 3. வெயில் → சிறந்த பயிர்",
    
    # Currency and temperature symbols
    "செலவு ₹500 | வெப்பநிலை 25°C | விலை $10",
    
    # Abbreviations
    "i.e., தாது உரம் etc. போன்றவை vs. இரசாயன உரம்"
]

print("🧪 Testing TTS Text Cleaning Function\n")
print("=" * 60)

for i, test_text in enumerate(test_cases, 1):
    print(f"\n📝 Test Case {i}:")
    print(f"Original: {test_text}")
    cleaned = clean_text_for_tts(test_text)
    print(f"Cleaned:  {cleaned}")
    print("-" * 60)

print("\n✅ The cleaning function will remove symbols like * that cause TTS to say 'natchathirakuri' in Tamil")
print("✅ It also removes bullet points, formatting, and other symbols that TTS might mispronounce")
print("✅ Text will sound more natural when converted to speech in any language")
