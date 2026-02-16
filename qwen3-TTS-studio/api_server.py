#!/usr/bin/env python3
"""
FastAPI server for Qwen3-TTS API requests.

Provides endpoints for text-to-speech generation using custom voices.
"""

import os

# Change to the script's directory to ensure correct paths
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

os.environ["no_proxy"] = "localhost,127.0.0.1"
os.environ["NO_PROXY"] = "localhost,127.0.0.1"

import json
import logging
import pickle
import tempfile
import time
from pathlib import Path
from typing import Optional, Literal

import soundfile as sf
from fastapi import FastAPI, HTTPException, Response
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from pydub import AudioSegment

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Language code to full name mapping
LANGUAGE_MAP = {
    "en": "english",
    "zh": "chinese",
    "ja": "japanese",
    "ko": "korean",
    "fr": "french",
    "de": "german",
    "it": "italian",
    "pt": "portuguese",
    "ru": "russian",
    "es": "spanish",
}


app = FastAPI(
    title="Qwen3-TTS API",
    description="Text-to-speech API using Qwen3-TTS models with custom voices",
    version="1.0.0"
)

SAVED_VOICES_DIR = Path("saved_voices")


class TTSRequest(BaseModel):
    """Request model for TTS generation."""
    text: str = Field(..., description="Text to convert to speech", min_length=1, max_length=5000)
    voice_id: str = Field(..., description="Voice ID (e.g., 'Mac_V2', 'serena', 'ryan')")
    language: str = Field(default="en", description="Language code (en, zh, ja, etc.)")
    format: Literal["wav", "m4a", "mp3", "ogg", "flac"] = Field(default="wav", description="Output audio format")
    temperature: float = Field(default=0.9, ge=0.0, le=2.0, description="Sampling temperature")
    top_k: int = Field(default=50, ge=1, le=100, description="Top-k sampling")
    top_p: float = Field(default=1, ge=0.0, le=1.0, description="Top-p (nucleus) sampling")
    repetition_penalty: float = Field(default=1.0, ge=1.0, le=2.0, description="Repetition penalty")
    max_new_tokens: int = Field(default=512, ge=64, le=2048, description="Maximum tokens to generate")
    instruct: Optional[str] = Field(default=None, description="Optional instruction for voice style")


class TTSResponse(BaseModel):
    """Response model for TTS generation."""
    success: bool
    message: str
    audio_path: Optional[str] = None
    voice_info: Optional[dict] = None


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "name": "Qwen3-TTS API",
        "version": "1.0.0",
        "endpoints": {
            "/voices": "GET - List all available voices",
            "/tts": "POST - Generate speech from text",
            "/health": "GET - Health check"
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "qwen3-tts-api"}


@app.get("/voices")
async def list_voices():
    """
    List all available voices (preset and saved custom voices).
    
    Returns:
        List of available voices with metadata
    """
    logger.info("Retrieving available voices...")
    try:
        from storage.voice import get_available_voices
        voices = get_available_voices()
        logger.info(f"Found {len(voices)} available voices")
        return {
            "success": True,
            "count": len(voices),
            "voices": voices
        }
    except Exception as e:
        logger.error(f"Failed to list voices: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to list voices: {str(e)}")


@app.post("/tts")
async def generate_speech(request: TTSRequest):
    """
    Generate speech from text using specified voice.
    
    Args:
        request: TTSRequest with text, voice_id, and optional parameters
    
    Returns:
        Audio file (WAV format)
    
    Raises:
        HTTPException: If voice not found or generation fails
    """
    start_time = time.time()
    logger.info(f"TTS request received - Voice: {request.voice_id}, Language: {request.language}, Format: {request.format}, Text length: {len(request.text)} chars")
    
    try:
        from storage.voice import get_available_voices
        from audio.model_loader import get_model
        
        # Validate voice exists
        logger.info(f"Validating voice '{request.voice_id}'...")
        available_voices = get_available_voices()
        voice_info = None
        voice_type = None
        
        for voice in available_voices:
            if voice["voice_id"] == request.voice_id:
                voice_info = voice
                voice_type = voice.get("type", "preset")
                break
        
        if voice_info is None:
            logger.warning(f"Voice '{request.voice_id}' not found")
            raise HTTPException(
                status_code=404,
                detail=f"Voice '{request.voice_id}' not found. Use GET /voices to see available voices."
            )
        
        logger.info(f"Voice validated - Type: {voice_type}")
        
        # Determine model to use
        model_name = "1.7B-CustomVoice"
        
        if voice_type == "saved":
            # Load metadata to check which model was used
            voice_meta_path = SAVED_VOICES_DIR / request.voice_id / "metadata.json"
            if voice_meta_path.exists():
                with open(voice_meta_path) as f:
                    voice_meta = json.load(f)
                    model_name = voice_meta.get("model", "1.7B-Base")
            else:
                model_name = "1.7B-Base"
        
        # Load model
        logger.info(f"Loading model '{model_name}'...")
        try:
            model = get_model(model_name)
            logger.info(f"Model '{model_name}' loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load model '{model_name}': {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to load model '{model_name}': {str(e)}"
            )
        
        # Normalize language (convert 'en' to 'english', etc.)
        language = LANGUAGE_MAP.get(request.language, request.language)
        logger.info(f"Starting audio generation - Language: {language}, Tokens: {request.max_new_tokens}")
        
        # Generate audio
        gen_start = time.time()
        if voice_type == "preset":
            logger.info(f"Generating audio with preset voice '{request.voice_id}'...")
            wavs, sr = model.generate_custom_voice(
                text=request.text,
                speaker=request.voice_id,
                language=language,
                instruct=request.instruct,
                temperature=request.temperature,
                top_k=request.top_k,
                top_p=request.top_p,
                repetition_penalty=request.repetition_penalty,
                max_new_tokens=request.max_new_tokens,
                subtalker_temperature=request.temperature,
                subtalker_top_k=request.top_k,
                subtalker_top_p=request.top_p,
            )
        elif voice_type == "saved":
            # Load voice clone prompt
            logger.info(f"Loading voice clone data for '{request.voice_id}'...")
            prompt_path = SAVED_VOICES_DIR / request.voice_id / "prompt.pkl"
            if not prompt_path.exists():
                logger.error(f"Voice prompt file not found for '{request.voice_id}'")
                raise HTTPException(
                    status_code=500,
                    detail=f"Voice prompt file not found for '{request.voice_id}'"
                )
            
            with open(prompt_path, "rb") as f:
                raw_prompt = pickle.load(f)
            
            # Prepare the voice clone prompt (normalize dtype/device to match model)
            from audio.generator import _prepare_voice_clone_prompt
            voice_clone_prompt = _prepare_voice_clone_prompt(raw_prompt, model)
            logger.info(f"Generating audio with cloned voice '{request.voice_id}'...")
            
            wavs, sr = model.generate_voice_clone(
                text=request.text,
                language=language,
                voice_clone_prompt=voice_clone_prompt,
                instruct=request.instruct,
                temperature=request.temperature,
                top_k=request.top_k,
                top_p=request.top_p,
                repetition_penalty=request.repetition_penalty,
                max_new_tokens=request.max_new_tokens,
                subtalker_temperature=request.temperature,
                subtalker_top_k=request.top_k,
                subtalker_top_p=request.top_p,
            )
        else:
            logger.error(f"Invalid voice type: {voice_type}")
            raise HTTPException(
                status_code=400,
                detail=f"Invalid voice type: {voice_type}"
            )
        
        gen_time = time.time() - gen_start
        logger.info(f"Audio generation completed in {gen_time:.2f}s - Sample rate: {sr}Hz, Duration: {len(wavs[0])/sr:.2f}s")
        
        # Save to temporary WAV file first
        logger.info("Saving audio to temporary file...")
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp_file:
            wav_path = tmp_file.name
            sf.write(wav_path, wavs[0], sr)
        
        # Convert to requested format if not WAV
        if request.format != "wav":
            logger.info(f"Converting audio to {request.format.upper()} format...")
            convert_start = time.time()
            try:
                audio = AudioSegment.from_wav(wav_path)
                with tempfile.NamedTemporaryFile(delete=False, suffix=f".{request.format}") as tmp_file:
                    output_path = tmp_file.name
                
                # Export with format-specific parameters
                if request.format == "m4a":
                    audio.export(output_path, format="mp4", codec="aac", bitrate="192k")
                elif request.format == "mp3":
                    audio.export(output_path, format="mp3", bitrate="192k")
                elif request.format == "ogg":
                    audio.export(output_path, format="ogg", codec="libvorbis")
                elif request.format == "flac":
                    audio.export(output_path, format="flac")
                
                # Clean up WAV file
                os.unlink(wav_path)
                convert_time = time.time() - convert_start
                logger.info(f"Format conversion completed in {convert_time:.2f}s")
            except Exception as e:
                # Clean up WAV file on error
                if os.path.exists(wav_path):
                    os.unlink(wav_path)
                logger.error(f"Failed to convert audio to {request.format}: {str(e)}")
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to convert audio to {request.format}: {str(e)}. Make sure ffmpeg is installed."
                )
        else:
            output_path = wav_path
            logger.info("Using WAV format (no conversion needed)")
        
        # Determine media type
        media_types = {
            "wav": "audio/wav",
            "m4a": "audio/mp4",
            "mp3": "audio/mpeg",
            "ogg": "audio/ogg",
            "flac": "audio/flac"
        }
        
        total_time = time.time() - start_time
        logger.info(f"TTS request completed successfully in {total_time:.2f}s - Format: {request.format}, Size: {os.path.getsize(output_path)/1024:.1f}KB")
        
        # Return audio file
        return FileResponse(
            output_path,
            media_type=media_types.get(request.format, "audio/wav"),
            filename=f"{request.voice_id}_output.{request.format}",
            headers={
                "X-Voice-ID": request.voice_id,
                "X-Voice-Type": voice_type,
                "X-Sample-Rate": str(sr),
                "X-Audio-Format": request.format
            }
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"TTS generation failed with unexpected error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"TTS generation failed: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    logger.info("Starting Qwen3-TTS API server on http://0.0.0.0:8001")
    logger.info("Visit http://localhost:8001/docs for interactive API documentation")
    uvicorn.run(app, host="0.0.0.0", port=8001)
