PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Starting Speech-to-Text service..."
(
    cd "$PROJECT_DIR/speech-to-text-service"
    conda run --no-capture-output -n stt \
        python -m uvicorn app.main:app \
        --host 0.0.0.0 \
        --port 8001
) &

echo "Starting Translation service..."
(
    cd "$PROJECT_DIR/translation-service"
    conda run --no-capture-output -n mt \
        python -m uvicorn app.main:app \
        --host 0.0.0.0 \
        --port 8002
) &

echo "Starting Text-to-Speech service..."
(
    cd "$PROJECT_DIR/text-to-speech-service"
    conda run --no-capture-output -n tts \
        python -m uvicorn app.main:app \
        --host 0.0.0.0 \
        --port 8003
) &

echo ""
echo "======================================"
echo " All services started"
echo "======================================"
echo " STT:         http://localhost:8001"
echo " Translation: http://localhost:8002"
echo " TTS:         http://localhost:8003"
echo "======================================"
echo ""
echo "Press Ctrl+C to stop all services."

wait