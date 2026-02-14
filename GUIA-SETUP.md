# 🎬 VideoAI - Sistema Completo: Foto → Video con Avatar IA

## Guía de Instalación de 0 a 100

---

## 🧩 Arquitectura del Sistema

```
┌──────────────────────────────────────────────────────────────┐
│  📱 APP MÓVIL (PWA)                                          │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐  ┌─────────────┐ │
│  │ Cámara  │→ │ Preview  │→ │ Configurar│→ │ Ver Resultado│ │
│  │ o Galería│  │ Producto │  │ Avatar/Voz│  │ Descargar   │ │
│  └─────────┘  └──────────┘  └─────┬─────┘  └──────▲──────┘ │
└────────────────────────────────────┼───────────────┼────────┘
                                     │ POST webhook  │ JSON
                                     ▼               │
┌──────────────────────────────────────────────────────────────┐
│  ⚡ N8N WORKFLOW                                              │
│                                                              │
│  📱 Webhook ─→ ⚙️ Validar ─→ 🔍 Claude Vision               │
│                                  (analizar producto)         │
│                                        │                     │
│                              ✍️ Claude: Generar Guión         │
│                                        │                     │
│                              🎙️ ElevenLabs: Audio TTS        │
│                                        │                     │
│                              🔀 Switch: ¿D-ID o HeyGen?     │
│                               ╱                  ╲           │
│                     🎭 D-ID API          🎭 HeyGen API       │
│                     ⏳ Poll status        ⏳ Poll status      │
│                               ╲                  ╱           │
│                              🔗 Merge Final                  │
│                               ╱          ╲                   │
│                     📤 Webhook Resp    📧 Email Notif        │
└──────────────────────────────────────────────────────────────┘
```

---

## 📦 Archivos Incluidos

| Archivo | Descripción |
|---|---|
| `video-ai-app.html` | App móvil PWA (cámara + preview + resultados) |
| `n8n-video-ai-workflow.json` | Workflow N8N completo (importar directamente) |
| `GUIA-SETUP.md` | Esta guía de instalación |

---

## ⚡ PASO 1: Crear Cuentas en los Servicios

### 1.1 Anthropic (Claude Vision + Script) — OBLIGATORIO
- Web: https://console.anthropic.com
- Crear cuenta → API Keys → Copiar API Key
- **Costo**: ~$0.01-0.03 por ejecución
- **Para qué**: Analizar la foto del producto + generar el guión del avatar

### 1.2 ElevenLabs (Text-to-Speech) — OBLIGATORIO
- Web: https://elevenlabs.io
- Plan gratuito: 10,000 caracteres/mes (~30 videos)
- Plan Starter: $5 USD/mes (30,000 caracteres)
- API Keys → Copiar API Key
- **Para qué**: Generar la voz del avatar en español natural

### 1.3 D-ID (Avatar Video) — OPCIÓN A (Recomendada para empezar)
- Web: https://www.d-id.com
- Plan Trial: 5 minutos de video gratis
- Plan Lite: $5.90 USD/mes (10 minutos)
- Dashboard → API → Copiar API Key
- **Para qué**: Crear el video del avatar hablando

### 1.4 HeyGen (Avatar Video) — OPCIÓN B (Mayor calidad)
- Web: https://www.heygen.com
- Plan Free: 3 videos de prueba
- Plan Creator: $29 USD/mes
- Settings → API → Copiar API Key
- **Para qué**: Alternativa premium a D-ID con avatares más realistas

> 💡 **Recomendación**: Empieza con D-ID (más barato) y migra a HeyGen cuando necesites mayor calidad.

---

## ⚡ PASO 2: Configurar N8N

### 2.1 Si NO tienes N8N instalado

**Opción A: N8N Cloud (más fácil)**
```
1. Ve a https://n8n.io
2. Crea cuenta → Plan Starter ($20/mes) o Community (gratis con límites)
3. Listo, ya tienes N8N corriendo
```

**Opción B: Self-hosted con Docker (gratis)**
```bash
# Instalar con Docker (1 comando)
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  n8nio/n8n

# Abrir en navegador: http://localhost:5678
```

**Opción C: En tu servidor/VPS**
```bash
# Con npm
npm install n8n -g
n8n start

# O con Docker Compose (recomendado para producción)
# Ver: https://docs.n8n.io/hosting/installation/docker/
```

### 2.2 Importar el Workflow

1. Abre N8N → **Workflows** → **Import from File**
2. Selecciona `n8n-video-ai-workflow.json`
3. Se cargarán los 15 nodos automáticamente

### 2.3 Configurar Variables de Entorno

En N8N: **Settings → Variables** (o Environment Variables si es self-hosted)

| Variable | Valor | Descripción |
|---|---|---|
| `NEWSAPI_KEY` | `tu-api-key` | (Solo si usas el blog workflow) |
| `VIDEO_SERVICE` | `did` o `heygen` | Qué servicio usar para avatares |
| `DID_API_KEY` | `tu-d-id-key` | API Key de D-ID (si usas D-ID) |
| `HEYGEN_API_KEY` | `tu-heygen-key` | API Key de HeyGen (si usas HeyGen) |
| `EMAIL_FROM` | `noreply@tudominio.com` | Email remitente |
| `NOTIFICATION_EMAIL` | `tu@email.com` | Dónde recibir notificaciones |

### 2.4 Configurar Credenciales en N8N

**Credencial 1: Anthropic API**
```
Settings → Credentials → Add Credential
→ Buscar "Anthropic"
→ Pegar tu API Key
→ Guardar
→ Asignar a los nodos "🤖 Claude Vision" y "🤖 Claude Script"
```

**Credencial 2: ElevenLabs**
```
Settings → Credentials → Add Credential
→ Buscar "HTTP Header Auth"
→ Name: "ElevenLabs API"
→ Header Name: "xi-api-key"
→ Header Value: tu-elevenlabs-api-key
→ Guardar
→ Asignar al nodo "🎙️ ElevenLabs: Generar Audio"
```

**Credencial 3: D-ID (si usas D-ID)**
```
Settings → Credentials → Add Credential
→ Buscar "HTTP Header Auth"
→ Name: "D-ID API"
→ Header Name: "Authorization"
→ Header Value: Basic TU_DID_API_KEY_EN_BASE64
→ Guardar
→ Asignar al nodo "🎭 D-ID: Crear Video Avatar"
```

**Credencial 4: HeyGen (si usas HeyGen)**
```
Settings → Credentials → Add Credential
→ Buscar "HTTP Header Auth"
→ Name: "HeyGen API"
→ Header Name: "X-Api-Key"
→ Header Value: tu-heygen-api-key
→ Guardar
→ Asignar al nodo "🎭 HeyGen: Crear Video Avatar"
```

### 2.5 Activar el Workflow

1. Click en el toggle **"Active"** (esquina superior derecha)
2. Tu webhook estará listo en: `https://TU-N8N.com/webhook/video-ai-product`
3. Copia esa URL

---

## ⚡ PASO 3: Configurar la App Móvil

### 3.1 Editar la URL del Webhook

Abre `video-ai-app.html` y cambia la línea:

```javascript
N8N_WEBHOOK_URL: 'https://TU-N8N.com/webhook/video-ai-product',
```

Reemplaza con la URL real de tu webhook de N8N.

### 3.2 Subir la App

**Opción A: En tu hosting actual (iamanos.com)**
```
1. Sube video-ai-app.html a tu servidor
2. Accede desde: https://iamanos.com/video-ai-app.html
3. En iPhone: Safari → Compartir → "Agregar a pantalla de inicio"
```

**Opción B: En Netlify (gratis, 1 minuto)**
```
1. Ve a https://app.netlify.com/drop
2. Arrastra la carpeta con el HTML
3. Te da una URL tipo: https://tu-app.netlify.app
```

**Opción C: En Vercel (gratis)**
```
1. Ve a https://vercel.com
2. Importa desde GitHub o arrastra archivos
3. URL: https://tu-app.vercel.app
```

### 3.3 Instalar como App en iPhone

```
1. Abre Safari en tu iPhone
2. Ve a la URL de tu app
3. Toca el botón "Compartir" (cuadrado con flecha)
4. Selecciona "Agregar a pantalla de inicio"
5. Ponle nombre "VideoAI"
6. ¡Listo! Aparece como app nativa
```

### 3.4 Instalar en Android

```
1. Abre Chrome
2. Ve a la URL de tu app
3. Chrome mostrará "Agregar a pantalla de inicio" automáticamente
4. O: Menú (⋮) → "Instalar aplicación"
```

---

## ⚡ PASO 4: Probar Todo

### Test rápido:

1. **Abre la app** en tu teléfono
2. **Toma una foto** de cualquier producto
3. **Elige avatar**: Sofía, Carlos, Ana, o Diego
4. **Elige voz**: Cálida, Profunda, Energética, o Casual
5. **Elige estilo**: Comercial, Informativo, o Viral
6. **Toca "Generar Video con IA"**
7. **Espera** 1-3 minutos
8. **Descarga** el video generado

### Verificar en N8N:

1. Ve a **Executions** en N8N
2. Deberías ver una ejecución nueva
3. Click para ver el detalle de cada nodo
4. Verifica que todos los pasos están en verde

---

## 💰 Costos Estimados por Video

| Servicio | Costo por video |
|---|---|
| Claude Vision + Script | ~$0.03 USD |
| ElevenLabs (30 seg audio) | ~$0.01 USD |
| D-ID (30 seg video) | ~$0.50 USD |
| HeyGen (30 seg video) | ~$1.00 USD |
| **Total con D-ID** | **~$0.54 USD** |
| **Total con HeyGen** | **~$1.04 USD** |

> Aproximado: **100 videos al mes = $54 - $104 USD**

---

## 🔧 Personalización Avanzada

### Cambiar avatares de D-ID

En el nodo "🎭 D-ID", puedes cambiar `source_url` por:
- Una URL de imagen de tu propio avatar
- Usa una foto de una persona real (con permiso) para crear un "presentador" custom

### Agregar tu propio avatar con HeyGen

1. Ve a HeyGen → **Instant Avatar**
2. Graba un video de 2 minutos de ti mismo
3. HeyGen creará tu clon digital
4. Copia el `avatar_id` y úsalo en el nodo de HeyGen

### Cambiar voces de ElevenLabs

Puedes clonar tu propia voz:
1. ElevenLabs → **Voice Lab** → **Add Voice** → **Instant Voice Cloning**
2. Sube 1 minuto de tu voz
3. Copia el `voice_id` generado
4. Actualiza el mapeo en el nodo "⚙️ Validar y Configurar"

### Agregar música de fondo

Agrega un nodo después del video para mezclar audio:
1. Usa **FFmpeg** en un nodo de Code
2. O integra con **Creatomate** API para composición de video

---

## 🐛 Troubleshooting

| Problema | Solución |
|---|---|
| La cámara no abre en iPhone | Asegúrate de usar HTTPS (obligatorio para cámara) |
| Error CORS en webhook | Verifica que el nodo Webhook Response tenga los headers CORS |
| D-ID retorna error 402 | Se acabaron tus créditos, recarga en d-id.com |
| ElevenLabs sin audio | Verifica que el voice_id sea válido y tengas créditos |
| Video tarda mucho | D-ID/HeyGen pueden tardar 1-5 min, es normal |
| Claude no analiza bien | Asegúrate que la foto tenga buena iluminación |
| App no se instala como PWA | Necesitas HTTPS y archivo manifest.json |

---

## 🚀 Mejoras Futuras

- [ ] Agregar subtítulos automáticos al video (Whisper API)
- [ ] Música de fondo con Suno AI o stock audio
- [ ] Múltiples escenas con producto + avatar
- [ ] Integración con TikTok/Instagram auto-upload
- [ ] Dashboard de analytics de videos generados
- [ ] Cola de procesamiento para múltiples videos
- [ ] Webhook de notificación por WhatsApp (Twilio)

---

*Sistema creado para iamanos.com · Consultoría en Inteligencia Artificial*
