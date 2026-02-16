# TTS API - Quick Start Guide

## What Was Created

I've added a REST API to your Qwen3-TTS application that allows you to generate speech from text using your custom voices (like Mac_V2) via HTTP requests from any application.

## Files Created

1. **`api_server.py`** - FastAPI server with TTS endpoints
2. **`api_requirements.txt`** - Python dependencies for the API
3. **`API_README.md`** - Complete API documentation
4. **`example_client.py`** - Example Python client showing how to use the API
5. **`test_api.py`** - Test suite for the API

## How to Use

### Step 1: Start the API Server

Open a PowerShell terminal and run:

```powershell
cd C:\Projects\text-to-talk\qwen3-TTS-studio
python api_server.py
```

You should see:
```
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8001 (Press CTRL+C to quit)
```

**Keep this terminal window open** - the server needs to stay running to process requests.

### Step 2: Use the API from Another Application

The API runs on `http://localhost:8001` with the following endpoints:

#### List Available Voices
```bash
GET http://localhost:8001/voices
```

#### Generate Speech
```bash
POST http://localhost:8001/tts
Content-Type: application/json

{
  "text": "Your text here",
  "voice_id": "Mac_V2",
  "language": "en"
}
```

Returns: WAV audio file

## Example Usage

### Python

```python
import requests

# Generate speech
response = requests.post('http://localhost:8001/tts', json={
    "text": "Hello, this is Mac speaking from Philly!",
    "voice_id": "Mac_V2",
    "language": "en"
})

# Save the audio
with open("output.wav", "wb") as f:
    f.write(response.content)
```

Run the included example:
```bash
python example_client.py
```

### cURL

```bash
curl -X POST http://localhost:8001/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Mac!", "voice_id": "Mac_V2", "language": "en"}' \
  --output output.wav
```

### JavaScript/Node.js

```javascript
const response = await fetch('http://localhost:8001/tts', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    text: "Hello from Mac!",
    voice_id: "Mac_V2",
    language: "en"
  })
});

const audioBlob = await response.blob();
// Use the audio blob in your application
```

### C#

```csharp
var client = new HttpClient();
var content = new StringContent(
    JsonSerializer.Serialize(new {
        text = "Hello from Mac!",
        voice_id = "Mac_V2",
        language = "en"
    }),
    Encoding.UTF8,
    "application/json"
);

var response = await client.PostAsync("http://localhost:8001/tts", content);
var audioBytes = await response.Content.ReadAsByteArrayAsync();
await File.WriteAllBytesAsync("output.wav", audioBytes);
```

## Available Voices

### Preset Voices (always available)
- `serena`, `ryan`, `vivian`, `aiden`, `dylan`, `eric`, `sohee`, `uncle_fu`, `ono_anna`

### Custom Voices (from saved_voices folder)
- `Mac_V2` - Your custom Mac voice
- `Mac_IASIP` - If you have this saved
- Any other voices in your `saved_voices/` directory

To see all available voices:
```bash
curl http://localhost:8001/voices
```

## API Parameters

### Required
- `text` - Text to speak (1-5000 characters)
- `voice_id` - Voice to use

### Optional
- `language` - Language code (default: "en")
- `temperature` - Randomness 0.0-2.0 (default: 0.3)
- `top_k` - Top-k sampling (default: 50)
- `top_p` - Nucleus sampling (default: 0.85)
- `max_new_tokens` - Max tokens to generate (default: 512)
- `instruct` - Style instruction for the voice

## Interactive Documentation

While the server is running, visit these URLs in your browser for interactive API documentation:

- **Swagger UI**: http://localhost:8001/docs
- **ReDoc**: http://localhost:8001/redoc

You can test the API directly from these pages!

## Troubleshooting

### Port Already in Use
If you get "port 8001 is already in use", either:
1. Close any other instance of the server
2. Change the port in `api_server.py` (last line)

### Voice Not Found
- Make sure the voice ID matches exactly (case-sensitive)
- For custom voices, ensure they're in the `saved_voices/` directory
- Run from the `qwen3-TTS-studio` directory
- List voices with `GET /voices` to see what's available

### Import Errors
Install dependencies:
```bash
pip install -r api_requirements.txt
```

### Generation Timeout
For very long text, increase the timeout in your client code. Generation can take several minutes depending on:
- Text length
- Voice type
- Hardware (CPU/GPU)

## Next Steps

1. **Try it out**: Run `python example_client.py` to see it in action
2. **Integrate**: Use the examples above to integrate into your application
3. **Customize**: Modify parameters (temperature, top_k, etc.) to adjust voice quality
4. **Add CORS**: If accessing from a web browser, add CORS middleware (see API_README.md)

## Support

For detailed API documentation, see [API_README.md](API_README.md)

For testing, use [test_api.py](test_api.py):
```bash
python test_api.py
```
