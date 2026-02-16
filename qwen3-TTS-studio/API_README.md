# Qwen3-TTS API Server

This API server provides HTTP endpoints for text-to-speech generation using Qwen3-TTS models with custom voices.

## Quick Start

1. Install API dependencies:
```bash
pip install -r api_requirements.txt
```

2. Start the server:
```bash
cd qwen3-TTS-studio
python api_server.py
```

The server will start on `http://localhost:8001`

3. Test it:
```bash
# In another terminal
python example_client.py
```

## Installation

1. Install API dependencies:
```bash
pip install -r api_requirements.txt
```

2. Install FFmpeg (required for M4A, MP3, OGG, and FLAC formats):

**Windows:**
- Download from https://ffmpeg.org/download.html
- Or use Chocolatey: `choco install ffmpeg`
- Or use Scoop: `scoop install ffmpeg`

**macOS:**
```bash
brew install ffmpeg
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install ffmpeg

# Fedora
sudo dnf install ffmpeg
```

Note: WAV format works without FFmpeg. Other formats (M4A, MP3, OGG, FLAC) require FFmpeg to be installed and available in your system PATH.

## Starting the Server

```bash
python api_server.py
```

The server will start on `http://localhost:8001`

## API Endpoints

### 1. List Available Voices

**GET** `/voices`

Returns all available voices (preset and custom).

**Example Request:**
```bash
curl http://localhost:8001/voices
```

**Example Response:**
```json
{
  "success": true,
  "count": 11,
  "voices": [
    {
      "voice_id": "serena",
      "name": "Serena",
      "type": "preset"
    },
    {
      "voice_id": "Mac_V2",
      "name": "Mac_V2",
      "type": "saved",
      "created": "2026-02-04T20:13:53.289102"
    }
  ]
}
```

### 2. Generate Speech

**POST** `/tts`

Generate speech from text using a specified voice.

**Request Body:**
```json
{
  "text": "Hello, this is a test of the text to speech system.",
  "voice_id": "Mac_V2",
  "language": "en",
  "format": "m4a",
  "temperature": 0.3,
  "top_k": 50,
  "top_p": 0.85,
  "repetition_penalty": 1.0,
  "max_new_tokens": 512,
  "instruct": null
}
```

**Parameters:**
- `text` (required): Text to convert to speech (1-5000 characters)
- `voice_id` (required): Voice identifier (e.g., "Mac_V2", "serena", "ryan")
- `language` (optional): Language code - "en", "zh", "ja", etc. (default: "en")
- `format` (optional): Output audio format - "wav", "m4a", "mp3", "ogg", "flac" (default: "wav")
- `temperature` (optional): Sampling temperature 0.0-2.0 (default: 0.3)
- `top_k` (optional): Top-k sampling 1-100 (default: 50)
- `top_p` (optional): Top-p sampling 0.0-1.0 (default: 0.85)
- `repetition_penalty` (optional): Repetition penalty 1.0-2.0 (default: 1.0)
- `max_new_tokens` (optional): Maximum tokens 64-2048 (default: 512)
- `instruct` (optional): Style instruction for the voice

**Response:**
Returns an audio file in the requested format with headers:
- `X-Voice-ID`: Voice identifier used
- `X-Voice-Type`: "preset" or "saved"
- `X-Sample-Rate`: Audio sample rate
- `X-Audio-Format`: Output format (wav, m4a, mp3, ogg, or flac)

**Example cURL Request:**
```bash
# Generate WAV (default)
curl -X POST http://localhost:8001/tts \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello, this is Mac speaking from Philly.",
    "voice_id": "Mac_V2",
    "language": "en"
  }' \
  --output output.wav

# Generate M4A
curl -X POST http://localhost:8001/tts \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello, this is Mac speaking from Philly.",
    "voice_id": "Mac_V2",
    "language": "en",
    "format": "m4a"
  }' \
  --output output.m4a
```

**Example Python Request:**
```python
import requests

url = "http://localhost:8001/tts"
data = {
    "text": "Hello, this is Mac speaking from Philly.",
    "voice_id": "Mac_V2",
    "language": "en",
    "format": "m4a"  # Can be "wav", "m4a", "mp3", "ogg", or "flac"
}

response = requests.post(url, json=data)

if response.status_code == 200:
    audio_format = response.headers.get('X-Audio-Format', 'wav')
    with open(f"output.{audio_format}", "wb") as f:
        f.write(response.content)
    print(f"Audio saved to output.{audio_format}")
else:
    print(f"Error: {response.status_code}")
    print(response.json())
```

### 3. Health Check

**GET** `/health`

Check if the server is running.

**Example Request:**
```bash
curl http://localhost:8001/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "qwen3-tts-api"
}
```

## Usage from Another Application

### JavaScript/Node.js Example

```javascript
const fetch = require('node-fetch');
const fs = require('fs');

async function generateSpeech(text, voiceId, format = 'wav') {
  const response = await fetch('http://localhost:8001/tts', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      text: text,
      voice_id: voiceId,
      language: 'en',
      format: format  // 'wav', 'm4a', 'mp3', 'ogg', or 'flac'
    }),
  });

  if (response.ok) {
    const buffer = await response.buffer();
    const outputFormat = response.headers.get('x-audio-format') || format;
    fs.writeFileSync(`output.${outputFormat}`, buffer);
    console.log('Audio generated successfully');
  } else {
    const error = await response.json();
    console.error('Error:', error);
  }
}

generateSpeech("Hello from Mac!", "Mac_V2", "m4a");
```

### C# Example

```csharp
using System.Net.Http;
using System.Text;
using System.Text.Json;

var client = new HttpClient();
var request = new
{
    text = "Hello, this is Mac speaking from Philly.",
    voice_id = "Mac_V2",
    language = "en",
    format = "m4a"  // Can be "wav", "m4a", "mp3", "ogg", or "flac"
};

var json = JsonSerializer.Serialize(request);
var content = new StringContent(json, Encoding.UTF8, "application/json");

var response = await client.PostAsync("http://localhost:8001/tts", content);

if (response.IsSuccessStatusCode)
{
    var audioBytes = await response.Content.ReadAsByteArrayAsync();
    var format = response.Headers.GetValues("X-Audio-Format").FirstOrDefault() ?? "wav";
    await File.WriteAllBytesAsync($"output.{format}", audioBytes);
    Console.WriteLine($"Audio saved to output.{format}");
}
```

## Available Voices

### Preset Voices
- `serena` - Female voice
- `ryan` - Male voice
- `vivian` - Female voice
- `aiden` - Male voice
- `dylan` - Male voice
- `eric` - Male voice
- `sohee` - Female voice (Korean)
- `uncle_fu` - Male voice (Chinese)
- `ono_anna` - Female voice (Japanese)

### Custom Voices
Custom voices are loaded from the `saved_voices/` directory. Use the `/voices` endpoint to see all available custom voices including your `Mac_V2` voice.

## Error Handling

The API returns standard HTTP status codes:
- `200 OK` - Success
- `404 Not Found` - Voice not found
- `422 Unprocessable Entity` - Invalid request parameters
- `500 Internal Server Error` - Server error during generation

Error responses include a JSON body with details:
```json
{
  "detail": "Voice 'invalid_voice' not found. Use GET /voices to see available voices."
}
```

## Performance Notes

- First request may be slow as it loads the model into memory
- Subsequent requests with the same voice type are faster (model caching)
- Generation time depends on text length and hardware
- GPU/CUDA acceleration recommended for best performance

## Advanced Configuration

### Running on Different Port

```bash
python api_server.py
```

Or modify the last line in `api_server.py`:
```python
uvicorn.run(app, host="0.0.0.0", port=8001)  # Change port here
```

### Running with Uvicorn Directly

```bash
uvicorn api_server:app --host 0.0.0.0 --port 8001 --reload
```

### Enable CORS (for browser access)

Add to `api_server.py`:
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Interactive API Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:8001/docs
- **ReDoc**: http://localhost:8001/redoc

These provide interactive API documentation where you can test endpoints directly from your browser.
