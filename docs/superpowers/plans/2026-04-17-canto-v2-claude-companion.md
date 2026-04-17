# Canto v2 — Claude's Markdown Companion

> **Pivot:** Canto deja de ser "editor de .md genérico" y pasa a ser **add-on específico de Claude Code**. Una ventana por proyecto/sesión, centrada en gestionar el contexto de Claude (CLAUDE.md, Memory, Plans, Config) y los outputs markdown que Claude genera.

## Nueva propuesta de valor

> *"Claude no puede abrir un visor para enseñarte cómo queda tu CLAUDE.md o tus memorias. Canto sí. Una ventana por sesión, centrada en el contexto que Claude genera y consume."*

**Tagline nuevo:** *"Claude's markdown companion."*

---

## Problemas actuales a resolver

1. **Icono no aparece** en la app compilada (icono blanco genérico de Xcode)
2. **Sidebar muestra todos los ficheros** como VSCode — demasiado ruido, se ven .json, .ts, .swift, etc.
3. **Una sola ventana** — si trabajas con 3 proyectos en 3 sesiones de Claude Code paralelas, Canto no acompaña
4. **Visión poco clara** — hoy parece otro editor markdown más, no un compañero de Claude

---

## Lo que se mantiene

- Sección **CLAUDE** del sidebar (CLAUDE.md, Memory, Plans, Config) — **este es el core**
- Dashboard de CLAUDE.md con secciones colapsables y rule cards
- Memory browser con filtros por tipo
- Session timeline con eventos y stats
- Config panel (MCP servers, permissions, hooks)
- Command palette (Cmd+K)
- File watcher y git polling

---

## Lo que cambia

### 1. Multi-ventana (una por proyecto/sesión)

- Cada ventana Canto = un proyecto = una sesión de Claude Code
- **File → Open Folder in New Window** (⌘⇧N)
- Si el proyecto ya está abierto en otra ventana, traerla al frente en lugar de duplicar
- State restoration: reabrir las ventanas que estaban abiertas al cerrar la app
- Cada ventana tiene su propio `AppState` aislado

### 2. Sidebar rediseñado

**Sección CLAUDE** (se queda igual, es el core):
- CLAUDE.md (icono violeta, click → Dashboard)
- Memory (DisclosureGroup con memorias y sus tipos)
- Plans (DisclosureGroup con planes)
- Config (click → Config panel)

**Sección FILES → renombrada a DOCUMENTS**:
- Solo archivos `.md` (y carpetas que contengan `.md` descendientes)
- Ocultar: código (`.swift`, `.ts`, `.js`, `.py`, etc.), config (`.json`, `.yaml`), binarios, `node_modules`, `.git`, `build/`, etc.
- Un directorio solo se muestra si tiene al menos un `.md` descendiente
- Etiquetar visualmente como "Editable Markdown"
- Nota al final: "Other files are hidden. Canto only edits markdown."

### 3. Welcome screen

- Cambiar tagline a: *"Claude's markdown companion."*
- Mensaje explicativo: *"Open a project folder with a `.claude/` directory to start editing context, memories, and plans."*
- Botón principal: **Open Project** (no "Open Folder")
- Si la carpeta no tiene `.claude/`, mostrar aviso suave: *"No Claude Code project detected. You can still edit markdown files, but Canto works best with Claude projects."*

### 4. Icono de la app

- Investigar por qué el AppIcon no se aplica al `.app` compilado
- Revisar `Contents.json` vs nombres de archivos
- Verificar que xcodegen incluye `Assets.xcassets` en el target
- Force refresh del icon cache de macOS al instalar

### 5. Indicador de sesión Claude

En la ventana, un badge pequeño en el toolbar:
- **Claude active** (violeta pulsante) cuando se detecta actividad de Claude Code (cambios rápidos en el proyecto)
- **Idle** (gris) cuando no hay actividad reciente
- Tooltip: "Session: {name} · {n} files · {n} commits"

---

## Plan de tareas

### Task 1: Fix icono de la app

**Objetivo:** que el icono violet→coral "C" aparezca en Dock, Finder, App Switcher.

**Pasos:**

1. Verificar que `Contents.json` del `AppIcon.appiconset` referencia correctamente los PNGs generados
2. Verificar que `Assets.xcassets` está en `sources:` del target Canto en `project.yml`
3. Revisar build setting `ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon`
4. Generar los PNGs con alpha correcto (macOS requiere alpha channel)
5. Tras build, verificar con `cat /Applications/Canto.app/Contents/Resources/AppIcon.icns | file -` que el `.icns` se genera
6. `killall Dock` para refrescar cache

**Aceptación:** icono visible en Dock, Finder, Cmd+Tab, Spotlight.

### Task 2: Multi-ventana support

**Objetivo:** poder abrir varias ventanas Canto, una por proyecto, de forma independiente.

**Pasos:**

1. Refactor `CantoApp.swift`:
   - `AppState` deja de ser `@State` a nivel de scene; pasa a crearse dentro del `WindowGroup`
   - Cada `MainWindowView` recibe su propio `AppState` recién creado
2. Añadir comando **File → Open Folder in New Window** (⌘⇧N) en `.commands`:
   - Abre `FolderAccessService.openFolderPanel()` y luego `openWindow(id: "main", value: url)`
3. Añadir `WindowGroup` con `for: URL.self` para ventanas paramétricas por URL
4. Detección de duplicados:
   - Al abrir carpeta, comprobar si ya hay una ventana con ese path
   - Si existe, traerla al frente (`NSApplication.shared.keyWindow?.orderFrontRegardless()`)
5. State restoration:
   - Guardar lista de URLs abiertas al cerrar la app (en `~/Library/Application Support/Canto/open-windows.json`)
   - Al lanzar la app, reabrir esas ventanas (respetando security-scoped bookmarks)

**Aceptación:**
- Puedo abrir `projectA` → una ventana se abre
- `File → Open Folder in New Window` → selecciono `projectB` → segunda ventana independiente
- Cierro la app, reabro → las 2 ventanas vuelven con su contenido
- Si intento abrir `projectA` de nuevo, trae la existente al frente

### Task 3: Sidebar — filtrar a solo markdown editable

**Objetivo:** el sidebar muestra solo contenido relevante (CLAUDE + markdown), no todos los ficheros del proyecto.

**Pasos:**

1. Modificar `FileTreeBuilder.build()`:
   - Nuevo parámetro `mode: .markdownOnly | .all`
   - En modo `.markdownOnly`, filtrar: solo incluir `.md` y directorios que tengan `.md` descendientes
2. Renombrar `FileTreeSection` → `DocumentsSection`
3. Cambiar label: `"FILES"` → `"DOCUMENTS"`
4. Añadir footer en el sidebar:
   ```
   "Only markdown files are editable in Canto."
   ```
   (texto pequeño, gris, separador arriba)
5. Ocultar archivos vacíos: si un directorio no tiene `.md` tras aplicar el filtro, no mostrarlo
6. Revisar exclusiones (ya existentes): `node_modules`, `.git`, `DerivedData`, `build`, `.next`, `__pycache__`

**Aceptación:** al abrir un proyecto como `InstantExam`:
- Sección CLAUDE: CLAUDE.md, Memory (0), Plans (0), Config
- Sección DOCUMENTS: solo `docs/` (con `faq.md`, `index.md`, `pricing.md`), `openspec/changes/whatsapp-metered/` (con `design.md`, `proposal.md`, `tasks.md`), etc.
- NO aparecen: `backend/`, `frontend/`, `src/`, `package.json`, etc.

### Task 4: Welcome screen — nuevo mensaje

**Objetivo:** comunicar el nuevo posicionamiento.

**Pasos:**

1. Cambiar tagline: `"See what you build with Claude."` → `"Claude's markdown companion."`
2. Añadir sub-mensaje debajo del drop zone:
   ```
   "Canto opens alongside Claude Code.
    One window per project — edit CLAUDE.md, memories, plans, and outputs visually."
   ```
3. Renombrar botón: `"Open Folder"` → `"Open Project"`
4. Detección de proyecto Claude al abrir:
   - Si la carpeta NO tiene `.claude/`, mostrar banner suave:
     ```
     "No Claude Code project detected here.
      Canto works best with projects that have a .claude/ directory."
     ```
   - No bloquear la apertura, solo avisar

**Aceptación:** welcome screen clara sobre el propósito; al abrir una carpeta sin `.claude/` sale el aviso.

### Task 5: Indicador de sesión Claude activa

**Objetivo:** badge visual en la ventana que indica cuándo Claude está trabajando.

**Pasos:**

1. Crear `ClaudeActivityIndicator` view:
   - Círculo pulsante violeta cuando `sessionManager.state == .active`
   - Círculo gris cuando `.idle`
2. Colocarlo en el toolbar de la ventana (esquina superior derecha)
3. Texto al lado: nombre de la sesión actual o "Idle"
4. Tooltip: stats de la sesión (`{files} files · {commits} commits · started {time}`)
5. Click en el badge → abre `SessionTimelineView` en el content area

**Aceptación:** cuando Claude modifica 3+ archivos, el badge pasa a pulsante violeta. Click → abre timeline.

### Task 6: Routing correcto de vistas especiales

**Objetivo:** click en Memory/Plans/Config desde sidebar abre la vista correspondiente (no solo lista de archivos).

**Pasos:**

1. Añadir `activeView` enum a `AppState`:
   ```swift
   enum ActiveView {
       case welcome, editor, dashboard, memoryBrowser, sessionTimeline, configPanel
   }
   ```
2. En `ClaudeSidebarSection`:
   - Click en "Memory" label (no en un memory individual) → `appState.activeView = .memoryBrowser`
   - Click en "Plans" label → abrir plans browser
   - Click en "Config" → `appState.activeView = .configPanel`
3. En `EditorContainerView`:
   - Enrutar en base a `activeView` primero, luego al tab activo
4. Memory individual (click en un memory) → abre como tab normal con markdown preview

**Aceptación:**
- Click en "Memory" → muestra `MemoryBrowserView`
- Click en "Config" → muestra `ConfigPanelView`
- Click en "CLAUDE.md" → muestra `ClaudeMDDashboardView`
- Click en un `.md` de DOCUMENTS → muestra preview markdown

### Task 7: Testing y commit

**Pasos:**

1. Verificar que los 30 tests existentes siguen pasando
2. Añadir tests para:
   - `FileTreeBuilder` con modo `.markdownOnly` (solo incluye .md y contenedores)
   - State restoration (guardar/cargar lista de ventanas)
3. Commit final con mensaje de pivot

---

## Orden de ejecución recomendado

```
Task 1 (icono)         ──┐
Task 3 (sidebar filtro) ──┤── paralelo (independientes)
Task 4 (welcome)       ──┘
                          │
Task 2 (multi-window)  ───┤── después, toca CantoApp y estructura
Task 6 (routing vistas) ──┘

Task 5 (indicador)     ── al final, visual polish
Task 7 (tests + commit) ── último
```

---

## No incluido (v2.1 o después)

- Integración MCP server para que Claude pueda notificar a Canto directamente
- Comunicación Canto ↔ Claude Code CLI (listener de comandos)
- Sincronización de estado entre ventanas
- Plugin para VSCode o JetBrains

---

## Cómo medir éxito

- Puedo tener 3 ventanas Canto abiertas, cada una para un proyecto distinto
- Al hacer click en Memory, me abre el browser de memorias, no una lista plana
- El sidebar muestra solo markdown editable, sin ruido de código
- El icono violet→coral es visible en Dock y Finder
- Al reiniciar la app, mis ventanas reaparecen
- Un usuario nuevo entiende en 10 segundos qué es Canto al ver la welcome screen
