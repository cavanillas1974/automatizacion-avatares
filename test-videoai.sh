#!/bin/bash
# =============================================================
# test-videoai.sh - Prueba cada API del sistema VideoAI
# =============================================================
# Uso: ./test-videoai.sh
#
# Variables de entorno requeridas:
#   ANTHROPIC_API_KEY   - Key de Anthropic (Claude)
#   ELEVENLABS_API_KEY  - Key de ElevenLabs
#   HEYGEN_API_KEY      - Key de HeyGen
#   N8N_WEBHOOK_URL     - (opcional) URL del webhook de N8N
# =============================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0

print_header() {
  echo ""
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}  $1${NC}"
  echo -e "${CYAN}========================================${NC}"
}

print_result() {
  if [ "$1" -eq 0 ]; then
    echo -e "${GREEN}  ✅ PASÓ: $2${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}  ❌ FALLÓ: $2${NC}"
    echo -e "${RED}  Detalle: $3${NC}"
    FAIL=$((FAIL + 1))
  fi
}

check_env() {
  local var_name="$1"
  local var_value="${!var_name:-}"
  if [ -z "$var_value" ]; then
    echo -e "${RED}  ⚠️  Variable $var_name no está configurada${NC}"
    return 1
  else
    local masked="${var_value:0:8}...${var_value: -4}"
    echo -e "${GREEN}  ✓ $var_name = $masked${NC}"
    return 0
  fi
}

# =============================================================
print_header "1. VERIFICAR VARIABLES DE ENTORNO"
# =============================================================

ENV_OK=true
check_env "ANTHROPIC_API_KEY" || ENV_OK=false
check_env "ELEVENLABS_API_KEY" || ENV_OK=false
check_env "HEYGEN_API_KEY" || ENV_OK=false

N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-https://n8n.srv1155300.hstgr.cloud/webhook/video-ai-product}"
echo -e "  ℹ️  N8N_WEBHOOK_URL = $N8N_WEBHOOK_URL"

if [ "$ENV_OK" = false ]; then
  echo ""
  echo -e "${RED}Configura las variables faltantes antes de continuar:${NC}"
  echo "  export ANTHROPIC_API_KEY=\"tu-key\""
  echo "  export ELEVENLABS_API_KEY=\"tu-key\""
  echo "  export HEYGEN_API_KEY=\"tu-key\""
  exit 1
fi

# =============================================================
print_header "2. PROBAR ANTHROPIC API (Claude Vision)"
# =============================================================

echo "  Enviando solicitud a https://api.anthropic.com/v1/messages..."

ANTHROPIC_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "https://api.anthropic.com/v1/messages" \
  -H "x-api-key: ${ANTHROPIC_API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 100,
    "messages": [{
      "role": "user",
      "content": "Responde solo con: OK_ANTHROPIC"
    }]
  }' 2>&1)

ANTHROPIC_HTTP=$(echo "$ANTHROPIC_RESPONSE" | tail -1)
ANTHROPIC_BODY=$(echo "$ANTHROPIC_RESPONSE" | sed '$d')

if [ "$ANTHROPIC_HTTP" = "200" ]; then
  print_result 0 "Anthropic API (HTTP $ANTHROPIC_HTTP)" ""
  echo "  Modelo: claude-sonnet-4-5-20250929"
  # Mostrar un fragmento de la respuesta
  echo "  Respuesta: $(echo "$ANTHROPIC_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('content',[{}])[0].get('text','')[:80])" 2>/dev/null || echo "(no se pudo parsear)")"
else
  ERROR_MSG=$(echo "$ANTHROPIC_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',{}).get('message',''))" 2>/dev/null || echo "$ANTHROPIC_BODY")
  print_result 1 "Anthropic API (HTTP $ANTHROPIC_HTTP)" "$ERROR_MSG"
fi

# =============================================================
print_header "3. PROBAR ELEVENLABS API (Text-to-Speech)"
# =============================================================

echo "  Enviando solicitud a https://api.elevenlabs.io/v1/text-to-speech/..."
# Usamos la voz "Sara" (EXAVITQu4vr4xnSDxMaL)
VOICE_ID="EXAVITQu4vr4xnSDxMaL"

ELEVEN_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
  -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "text": "Hola, esta es una prueba del sistema VideoAI.",
    "model_id": "eleven_multilingual_v2",
    "voice_settings": {
      "stability": 0.6,
      "similarity_boost": 0.8
    }
  }' 2>&1)

ELEVEN_HTTP=$(echo "$ELEVEN_RESPONSE" | tail -1)
ELEVEN_BODY=$(echo "$ELEVEN_RESPONSE" | sed '$d')

if [ "$ELEVEN_HTTP" = "200" ]; then
  # HTTP 200 con Accept: application/json debería retornar info, no audio
  # Pero si retorna binary, también es éxito
  print_result 0 "ElevenLabs API (HTTP $ELEVEN_HTTP)" ""
  echo "  Voz: Sara ($VOICE_ID)"
  echo "  Modelo: eleven_multilingual_v2"
else
  ERROR_MSG=$(echo "$ELEVEN_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('detail',{}).get('message','') if isinstance(d.get('detail'),dict) else str(d.get('detail','')))" 2>/dev/null || echo "HTTP $ELEVEN_HTTP")
  print_result 1 "ElevenLabs API (HTTP $ELEVEN_HTTP)" "$ERROR_MSG"
fi

# =============================================================
print_header "4. PROBAR HEYGEN API (Avatar Video)"
# =============================================================

echo "  Enviando solicitud a https://api.heygen.com/v2/video/generate..."

HEYGEN_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "https://api.heygen.com/v2/video/generate" \
  -H "X-Api-Key: ${HEYGEN_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "video_inputs": [{
      "character": {
        "type": "avatar",
        "avatar_id": "Abigail_standing_office_front",
        "avatar_style": "normal"
      },
      "voice": {
        "type": "text",
        "input_text": "Hola, esta es una prueba del sistema VideoAI.",
        "voice_id": "2d5bcf07da7b4e7da3907f1cb96da03a"
      }
    }],
    "dimension": {"width": 1080, "height": 1920},
    "test": true
  }' 2>&1)

HEYGEN_HTTP=$(echo "$HEYGEN_RESPONSE" | tail -1)
HEYGEN_BODY=$(echo "$HEYGEN_RESPONSE" | sed '$d')

if [ "$HEYGEN_HTTP" = "200" ]; then
  VIDEO_ID=$(echo "$HEYGEN_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('video_id',''))" 2>/dev/null || echo "")
  print_result 0 "HeyGen API (HTTP $HEYGEN_HTTP)" ""
  if [ -n "$VIDEO_ID" ]; then
    echo "  Video ID: $VIDEO_ID"
    echo "  (modo test - no consume créditos)"
  fi
else
  ERROR_MSG=$(echo "$HEYGEN_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error','') or d.get('message',''))" 2>/dev/null || echo "HTTP $HEYGEN_HTTP")
  print_result 1 "HeyGen API (HTTP $HEYGEN_HTTP)" "$ERROR_MSG"
fi

# =============================================================
print_header "5. PROBAR WEBHOOK N8N (Conectividad)"
# =============================================================

echo "  Probando conectividad con $N8N_WEBHOOK_URL..."

# Solo verificamos que el servidor responde (OPTIONS o POST vacío)
N8N_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 10 \
  -X POST "$N8N_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"test": true}' 2>&1)

if [ "$N8N_RESPONSE" = "000" ]; then
  print_result 1 "N8N Webhook" "No se pudo conectar (timeout o servidor caído)"
elif [ "$N8N_RESPONSE" -ge 200 ] && [ "$N8N_RESPONSE" -lt 500 ] 2>/dev/null; then
  print_result 0 "N8N Webhook (HTTP $N8N_RESPONSE)" ""
  echo "  URL: $N8N_WEBHOOK_URL"
else
  print_result 1 "N8N Webhook (HTTP $N8N_RESPONSE)" "El servidor respondió con error"
fi

# =============================================================
print_header "RESUMEN"
# =============================================================

TOTAL=$((PASS + FAIL))
echo ""
echo -e "  Pruebas pasadas:  ${GREEN}${PASS}/${TOTAL}${NC}"
echo -e "  Pruebas fallidas: ${RED}${FAIL}/${TOTAL}${NC}"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}  🎉 ¡Todas las APIs funcionan correctamente!${NC}"
else
  echo -e "${YELLOW}  ⚠️  Hay APIs que fallaron. Revisa las keys y créditos.${NC}"
fi

echo ""
echo "Para ejecutar una prueba completa con imagen, usa:"
echo "  curl -X POST '$N8N_WEBHOOK_URL' \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"image\":\"data:image/jpeg;base64,/9j/4AAQ...\",\"avatar\":\"professional-woman\",\"voice\":\"female-warm\",\"style\":\"comercial\"}'"
echo ""
