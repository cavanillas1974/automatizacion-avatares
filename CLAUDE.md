# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Resumen del Proyecto

**VideoAI** es una PWA móvil que permite fotografiar un producto y generar automáticamente un video con un avatar de IA presentándolo. Sistema en español (es-MX) para iamanos.com.

## Arquitectura

Dos componentes conectados via webhook:

1. **`video-ai-app.html`** — PWA de un solo archivo (HTML/CSS/JS inline, sin build). Captura foto, selección de avatar/voz/estilo, envía al webhook N8N, muestra el video resultante.

2. **`n8n-video-ai-workflow.json`** — Workflow N8N principal (17 nodos). Pipeline:
   - Webhook POST recibe imagen base64 + config
   - Code node valida y mapea avatar/voz/estilo a IDs de cada API
   - **HTTP Request → Anthropic API** (`/v1/messages` con `claude-sonnet-4-5-20250929`) analiza la foto del producto con visión multimodal
   - **HTTP Request → Anthropic API** genera guión de video basado en el análisis
   - **HTTP Request → ElevenLabs** (`/v1/text-to-speech/{voice_id}` con `eleven_multilingual_v2`) genera audio TTS
   - **Switch** → D-ID o HeyGen según `$env.VIDEO_SERVICE`
   - **D-ID**: Usa el audio de ElevenLabs (`type: "audio"` con data URI)
   - **HeyGen**: Usa su propio TTS con el `voice_id` mapeado del usuario
   - Polling en Code nodes hasta que el video esté listo
   - Responde con `JSON.stringify()` para evitar problemas de escaping

3. **`heygen_working_workflow.json`** — Workflow simplificado solo-HeyGen para pruebas.

## Configuración Clave

- **Webhook URL en PWA**: Buscar `N8N_WEBHOOK_URL` en `video-ai-app.html`
  - Actual: `https://n8n.srv1155300.hstgr.cloud/webhook/video-ai-product`
- **Credenciales en N8N** (HTTP Header Auth):
  - `Anthropic API (x-api-key)` → header `x-api-key`
  - `ElevenLabs API` → header `xi-api-key`
  - `D-ID API` → header `Authorization` (valor: `Basic {key_en_base64}`)
  - `HeyGen API` → header `X-Api-Key`
- **Variables de entorno N8N** requeridas:
  - `VIDEO_SERVICE` → `did` o `heygen`
  - `DID_API_KEY` → key de D-ID en Base64 (para polling)
  - `HEYGEN_API_KEY` → key de HeyGen (para polling)

## Script de Prueba

```bash
export ANTHROPIC_API_KEY="..."
export ELEVENLABS_API_KEY="..."
export HEYGEN_API_KEY="..."
./test-videoai.sh
```

## Notas de Desarrollo

- Sin build tools ni tests — el HTML es autocontenido
- PWA requiere HTTPS para cámara y manifiesto (`manifest.json`)
- Flujo de pantallas: Home → Cámara/Galería → Preview/Config → Procesando → Resultado
- Los workflows N8N se editan en la UI de N8N y se exportan como JSON al repo
- Los nodos de Claude usan HTTP Request directo (no LangChain) para enviar imágenes como contenido multimodal
- El response del webhook usa `JSON.stringify()` para evitar JSON roto por caracteres especiales en el guión
