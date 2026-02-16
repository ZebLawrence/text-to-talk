#!/usr/bin/env python3
"""
Simple example of using the TTS API from another application.

Run this after starting the API server:
    python api_server.py

Then in another terminal:
    python example_client.py
"""

import requests
import sys

def generate_speech(text, voice_id="serena", output_file="output.wav", format="wav"):
    """
    Generate speech using the TTS API.
    
    Args:
        text: Text to convert to speech
        voice_id: Voice to use (e.g., "Mac_V2", "serena", "ryan")
        output_file: Where to save the audio file
        format: Audio format ("wav", "m4a", "mp3", "ogg", "flac")
    
    Returns:
        True if successful, False otherwise
    """
    api_url = "http://localhost:8001/tts"
    
    # Prepare the request
    payload = {
        "text": text,
        "voice_id": voice_id,
        "language": "en",
        "format": format,
        "temperature": 0.3,
        "top_k": 50,
        "top_p": 0.85,
        "max_new_tokens": 512
    }
    
    print(f"Generating speech with voice '{voice_id}'...")
    print(f"Text: {text}")
    
    try:
        # Make the API request
        response = requests.post(api_url, json=payload, timeout=300)
        
        if response.status_code == 200:
            # Save the audio file
            with open(output_file, "wb") as f:
                f.write(response.content)
            
            # Print response headers
            print(f"✓ Success! Audio saved to: {output_file}")
            print(f"  Voice ID: {response.headers.get('X-Voice-ID')}")
            print(f"  Voice Type: {response.headers.get('X-Voice-Type')}")
            print(f"  Sample Rate: {response.headers.get('X-Sample-Rate')} Hz")
            print(f"  Format: {response.headers.get('X-Audio-Format')}")
            return True
        else:
            print(f"✗ Error {response.status_code}: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("✗ Could not connect to API server!")
        print("  Make sure the server is running: python api_server.py")
        return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def list_voices():
    """List all available voices from the API."""
    api_url = "http://localhost:8001/voices"
    
    try:
        response = requests.get(api_url)
        if response.status_code == 200:
            data = response.json()
            print(f"\n{data['count']} available voices:")
            print("\nPreset Voices:")
            for voice in data['voices']:
                if voice['type'] == 'preset':
                    print(f"  - {voice['voice_id']}")
            
            saved_voices = [v for v in data['voices'] if v['type'] == 'saved']
            if saved_voices:
                print("\nCustom Voices:")
                for voice in saved_voices:
                    print(f"  - {voice['voice_id']} ({voice.get('name', '')})")
            return True
        else:
            print(f"Error: {response.status_code}")
            return False
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    # Example usage
    print("=" * 60)
    print("TTS API Client Example")
    print("=" * 60)
    
    # List available voices
    list_voices()
    
    print("\n" + "=" * 60)
    
    # Example 1: Generate speech with a preset voice (WAV format)
    if generate_speech(
        text="Hello! This is a test of the text to speech API.",
        voice_id="serena",
        output_file="example_serena.wav",
        format="wav"
    ):
        print()
    
    # Example 2: Generate speech in M4A format
    if generate_speech(
        text="This is an example in M4A format.",
        voice_id="ryan",
        output_file="example_ryan.m4a",
        format="m4a"
    ):
        print()
    
    # Example 3: Generate speech with Mac_V2 in MP3 format (if available)
    # Uncomment this after confirming Mac_V2 is in your saved voices:
    # if generate_speech(
    #     text="Hello, this is Mac speaking from Philly!",
    #     voice_id="Mac_V2",
    #     output_file="example_mac_v2.mp3",
    #     format="mp3"
    # ):
    #     print()
    
    print("=" * 60)
