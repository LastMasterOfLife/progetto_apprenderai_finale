# 📚 ApprenderAI

> **Piattaforma di studio AI-powered per scuole medie, superiori e università**
>
> Studia aprendo un vero libro interattivo: sfoglia i capitoli, leggi i contenuti generati
> dall'AI, chatta con Hooty il gufo assistente e visualizza mappe concettuali animate.

![Flutter](https://img.shields.io/badge/Flutter-3.6.1+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Windows%20Desktop-0078D4?logo=windows)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📖 Panoramica

ApprenderAI è un'applicazione desktop Flutter per Windows che trasforma lo studio in
un'esperienza coinvolgente attraverso la metafora del libro fisico. L'interfaccia principale
è un libro 3D che si apre e si sfoglia con animazioni realistiche.

### Funzionalità principali

| Funzione | Descrizione |
|----------|-------------|
| 📕 **Libro interattivo** | Libro 3D con animazione sfoglia-pagina, indice navigabile e copertine personalizzate per livello |
| 🤖 **Contenuti AI** | Ogni capitolo viene spiegato dall'AI (backend RAG) con linguaggio calibrato sul livello scolastico |
| 🦉 **Chat con Hooty** | Assistente gufo animato con eye-tracking; le risposte appaiono sulla pagina sinistra del libro |
| 🗺️ **Mappe concettuali** | Grafo SVG generato via n8n + QuickChart, navigabile con pan e zoom |
| 📝 **Note adesive** | Sticky notes colorate con angolo piegato, salvate per tutta la sessione |
| 🌙 **Tema chiaro/scuro** | Toggle persistente; i widget del libro restano sempre in "carta vintage" |

### Tecnologie

- **Flutter 3.6.1** — framework UI desktop
- **Backend Flask RAG** — server locale Python su `http://127.0.0.1:5000`
- **n8n** — workflow automation per la generazione di grafi DOT
- **QuickChart.io** — conversione DOT → SVG tramite API pubblica
- **SharedPreferences** — persistenza locale preferenze e statistiche

---

## ⚙️ Prerequisiti

Prima di poter avviare o compilare il progetto, assicurati di avere installato:

### 1. Flutter SDK ≥ 3.6.1

```bash
# Verifica versione installata
flutter --version

# Se Flutter non è installato:
# https://docs.flutter.dev/get-started/install/windows
```

Dopo l'installazione, abilita il target Windows Desktop:

```bash
flutter config --enable-windows-desktop
flutter doctor  # controlla che "Windows (desktop)" sia ✓
```

### 2. Visual Studio 2022

Scarica da [visualstudio.microsoft.com](https://visualstudio.microsoft.com) e installa il workload:
> **"Sviluppo di applicazioni desktop con C++"**

Senza questo workload la build Windows fallisce.

### 3. Git

```bash
# Verifica
git --version
```

### 4. Backend Flask (necessario per usare l'app)

Il backend RAG deve essere in esecuzione su `http://127.0.0.1:5000` e deve esporre:

| Endpoint | Metodo | Scopo |
|----------|--------|-------|
| `/recupera_indice` | GET | Restituisce l'indice dei capitoli |
| `/rag` | POST | Query RAG — caricamento capitolo + chat |

Senza il backend l'app si avvia ma l'indice e i contenuti non si caricano.

### 5. n8n (opzionale)

Necessario solo per la funzionalità **Mappa Concettuale**. Il webhook configurato in
`lib/config/constants.dart` punta a `https://n8ndev.inforelea.academy/webhook/generate-map`.
Se non disponibile, la mappa mostra un messaggio di errore con pulsante "Riprova".

---

## 📁 Struttura del progetto

```
progetto_finale/
├── lib/
│   ├── main.dart                    # Entry point: inizializza MediaKit e ThemeNotifier
│   │
│   ├── config/                      # Configurazione globale (nessuna logica UI)
│   │   ├── app_config.dart          # Flag: isDev, enableLogin, version
│   │   ├── app_theme.dart           # ThemeData light/dark + ThemeNotifier singleton
│   │   └── constants.dart           # Endpoint backend (baseUrl, ragEndpoint, …)
│   │
│   ├── models/                      # Data class pure (nessuna dipendenza Flutter)
│   │   ├── chat_message.dart        # ChatMessage, MessageRole, ContextResult
│   │   └── sticky_note.dart         # StickyNote con copyWith()
│   │
│   ├── services/
│   │   └── api_service.dart         # UNICO punto HTTP dell'app:
│   │                                #   fetchChaptersIndex, fetchChapterContent,
│   │                                #   sendChatMessage, generateConceptMap
│   │                                #   + ConceptMapResult + ApiException
│   │
│   ├── screens/                     # Una classe per schermata
│   │   ├── splash_screen.dart       # Animazione logo + typewriter + routing iniziale
│   │   ├── login_screen.dart        # Form email/password + accesso ospite
│   │   ├── start_screen.dart        # Dashboard: carosello livelli + statistiche + impostazioni
│   │   └── lesson_screen.dart       # Libro interattivo + texture carta vintage
│   │
│   ├── utils/                       # Utility pure
│   │   ├── app_enums.dart           # SchoolLevel, BookmarkTab, parseChaptersIndex()
│   │   ├── app_stats.dart           # Statistiche di utilizzo (SharedPreferences)
│   │   └── user_preferences.dart    # Login state, school level, email
│   │
│   └── widgets/
│       ├── common/                  # Design system riusabile
│       │   ├── app_spacing.dart     # Griglia 4pt: xs/sm/md/lg/xl/xxl/huge
│       │   ├── app_button.dart      # AppButton.primary / .secondary / .text
│       │   ├── app_card.dart        # Card con padding AppSpacing.lg di default
│       │   └── app_input.dart       # TextFormField pre-stilato
│       │
│       ├── book_stack_widget.dart   # Controller del libro (stato, animazioni, API)
│       ├── book_layer.dart          # Singolo foglio: decorativo o indice cliccabile
│       ├── book_painters.dart       # DottedLinePainter, BookmarkTabPainter,
│       │                            #   FoldedCornerPainter, TypingDotsWidget
│       ├── content_page_layer.dart  # Pagina sinistra: testo RAG + mappa SVG
│       ├── right_page_layer.dart    # Pagina destra: note adesive + chat Hooty
│       ├── owl_face_widget.dart     # Gufo animato (blinking + eye tracking)
│       ├── app_sidebar.dart         # Sidebar: Dashboard / Gruppi / Impostazioni
│       ├── book_selection_widget.dart  # Libro selezionabile nella StartScreen
│       ├── message_bubble.dart      # Bolla messaggio chat (Markdown)
│       └── full_screen_video.dart   # Video loop in background (media_kit)
│
├── assets/
│   ├── image/           # Logo, copertine libro (verde/blu/rosso), gufo, hand icon
│   ├── video/           # Video background splash e login
│   ├── backgrounds/     # Sfondi per livello (nature/study/sunset)
│   └── icons/           # Icone livello scolastico
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 🗺️ Flusso delle schermate

```
                        ┌─────────────┐
                        │ SplashScreen│  (rotta '/')
                        └──────┬──────┘
                               │ Tap "Clicca qui per iniziare"
              ┌────────────────┼────────────────┐
              │                │                │
       enableLogin=false    non             autenticato
              │           autenticato           │
              │                │        ┌───────┴───────┐
              │                │        │ livello        │
              │                │        │ salvato?       │
              │                │        └──┬──────────┬──┘
              │                │           │ sì        │ no
              ▼                ▼           ▼           ▼
         StartScreen      LoginScreen  LessonScreen  StartScreen
                               │
                    Accedi / Ospite
                               │
                               ▼
                          StartScreen  (rotta '/start')
                               │
                      Seleziona livello
                      Premi "ApprenderAI"
                               │
                               ▼
                         LessonScreen  (rotta '/lesson')
       ┌──────────────────────────────────────────────────────┐
       │  AppSidebar  │  Libro chiuso                         │
       │  ────────────│  ▼ Tap → apre il libro                │
       │  Dashboard   │  ┌─────────────┬──────────────┐       │
       │  Gruppi      │  │   Indice    │  Copertina   │       │
       │  Impostazioni│  │  capitoli   │   livello    │       │
       │              │  └──────┬──────┴──────────────┘       │
       │              │         │ Tap capitolo                │
       │              │  ┌──────▼──────┬──────────────┐       │
       │              │  │  Contenuto  │  Note /      │       │
       │              │  │  RAG / Mappa│  Chat Hooty  │       │
       │              │  └─────────────┴──────────────┘       │
       └──────────────────────────────────────────────────────┘
```

### Route map (`lib/main.dart`)

| Rotta | Widget | Note |
|-------|--------|------|
| `'/'` | `SplashScreen` | Rotta iniziale |
| `'/login'` | `LoginScreen` | Autenticazione client-side |
| `'/start'` | `StartScreen` | Dashboard selezione livello |
| `'/lesson'` | `LessonScreen` | Richiede `args: {schoolLevel: 'media'/'superior'/'university'}` |

---

## 📐 Implementazione grafica del libro

Questa sezione documenta come viene creata l'illusione di sfogliare un libro fisico.

### Stack di pagine fisico

Il libro è una pila di 6 layer sovrapposti con larghezze decrescenti.
Ogni layer ha un margine top/bottom di 8px che crea l'effetto spessore del volume:

```
bookWidth (100%)  ← base colorata (colore tematico del livello)
         99%      ← thinBookWidth    (foglio più esterno)
         97%      ← quartoBookWidth
         95%      ← terzoBookWidth
         93%      ← secondoBookWidth
         91%      ← primoBookWidth   (foglio più interno)
         96%      ← mediumBookWidth  (copertina, solo libro chiuso)
```

### Rotazione 3D con Matrix4

```dart
Transform(
  alignment: Alignment.centerLeft,   // perno = bordo sinistro (la rilegatura)
  transform: Matrix4.identity()
    ..setEntry(3, 2, 0.001)          // fattore prospettiva (simula la profondità)
    ..rotateY(angle),                // 0 (chiuso) → π (aperto, 180°)
)
```

- **`setEntry(3, 2, 0.001)`** — abilita la profondità prospettica: più la pagina ruota,
  più appare "piccola" in lontananza, esattamente come un foglio fisico
- **`rotateY(0 → math.pi)`** — ruota attorno all'asse verticale (Y) di 180°
- **`alignment: Alignment.centerLeft`** — il perno è fisso al bordo sinistro: la pagina
  si "apre" verso destra come un foglio rilegato

### Sequenza animazioni (cascading, 4 controller)

Le pagine si animano in cascata con delay progressivi:

```
t=0ms    _stackMoveController  (600ms)  ── lo stack si sposta lateralmente
t=200ms  _firstPageController  (800ms)  ── la copertina gira
t=500ms  _secondPageController (800ms)  ── la pagina indice gira
t=?      _thirdPageController  (1200ms) ── la pagina contenuto gira
                                           (solo quando si seleziona un capitolo)
```

### Contenuto specchiato oltre i 90°

Quando una pagina supera 90° di rotazione, il contenuto appare capovolto.
Si applica un secondo `Transform.rotateY(π)` per compensare:

```dart
final bool isFlipped = rotationY > math.pi / 2;

if (isFlipped)
  Transform(
    alignment: Alignment.center,
    transform: Matrix4.identity()..rotateY(math.pi),
    child: _buildContent(),
  )
```

### Pagine interattive vs. pagine animazione

Ogni pagina esiste in **due istanze separate**:

- **Layer animato** (`IgnorePointer`): visibile durante la rotazione, non riceve input
- **Layer interattivo**: appare solo quando la rotazione supera il 95% (≥ `π × 0.95`),
  riceve tap, scroll e gestures

Questo permette animazioni fluide senza perdere l'interattività.

### Zona swipe (bottom 60px)

Un `GestureDetector` invisibile sul bordo inferiore cattura i gesti orizzontali:

| Condizione | Gesto | Azione |
|-----------|-------|--------|
| Contenuto aperto | Swipe destra (velocity > 300) | Chiude la pagina contenuto |
| Libro aperto | Swipe sinistra (velocity < −500) | Chiude il libro |
| Libro chiuso | Swipe sinistra (velocity < −500) | Apre il libro |

### Texture carta vintage

`_VintagePaperPainter` disegna su tutto lo sfondo di `LessonScreen` (solo light mode):

- **100 puntini** casuali colore `0xFF8B7355`, opacità 0.02–0.12
- **30 linee** corte casuali, opacità 0.01–0.06
- **Vignettatura radiale** `RadialGradient(radius: 1.0, stops: [0.6, 1.0])` che scurisce i bordi

In dark mode lo sfondo è il navy scuro del tema (`0xFF0C0E1A`) — nessuna texture.

### Dorso del libro (spine)

Il bordo sinistro usa un gradiente 3-stop per simulare l'ombra della rilegatura:

```
0xFF150A09 (0.6) → 0xFF3E2723 (0.4) → transparent
```

### Angolo piegato delle note (FoldedCornerPainter)

Su ogni nota adesiva:
- Triangolo bottom-right con colore `Color.lerp(noteColor, black, 0.15)`
- Ombra sfumata (stesso triangolo, traslato) per dare profondità al foglio

### Segnalibri (BookmarkTabPainter)

Tab disegnati con `Path`:
1. Rettangolo verticale
2. Chevron (V rovesciata) sul bordo inferiore — 45°, altezza 14px
3. Tab attivo: highlight bianco in cima (gradiente 2–3px)

### Punti di attesa (TypingDotsWidget)

Tre cerchi con **opacità sinusoidale sfasata** (offset 0.3 tra ogni punto):

```
cerchio 1: sin((phase + 0.0) × π).clamp(0.3, 1.0)
cerchio 2: sin((phase + 0.3) × π).clamp(0.3, 1.0)
cerchio 3: sin((phase + 0.6) × π).clamp(0.3, 1.0)
```

Crea l'effetto `...` che si illumina progressivamente da sinistra a destra.

---

## 🧩 Widget principali

### BookStackWidget

Controller centrale del libro. Gestisce animazioni, navigazione, chat e note.

```dart
BookStackWidget(
  bookWidth: constraints.maxWidth * 0.40,
  bookHeight: constraints.maxHeight * 0.90,
  titleBook: 'media',          // 'media' | 'superior' | 'university'
  chaptersIndex: _chaptersIndex,
  isLoadingIndex: _isLoadingIndex,
  onChapterSelected: (chapter) => AppStats.recordTopicSearch(chapter),
)
```

Stato interno:
- `_chatHistories: Map<String, List<ChatMessage>>` — chat per capitolo, sopravvive
  al cambio capitolo, si azzera solo con "Nuova chat"
- `_notes: List<StickyNote>` — note in-memory per tutta la sessione
- `_pageContent: String` — ultimo testo ricevuto (capitolo o risposta chat)

### BookLayer

Singolo foglio del libro in due modalità:

| `indiceBook` | Contenuto |
|-------------|-----------|
| `false` | Pagina bianca decorativa con spine e light gradient |
| `true` | Lista capitoli scrollabile con `SUBJECT:` headers cliccabili |

Formato della stringa `chaptersIndex`:

```
SUBJECT:Matematica
Derivate e integrali
Limiti
SUBJECT:Fisica
Meccanica newtoniana
```

### ContentPageLayer

Pagina sinistra del libro con due modalità:

| Modalità | Descrizione |
|----------|-------------|
| `plainText` | Testo RAG in Markdown scrollabile (default) |
| `custom` | Mappa concettuale SVG con `InteractiveViewer` (pan + zoom) |

Loading: shimmer animato (8 barre con opacità sinusoidale) + testo "Hooty sta preparando...".

### RightPageLayer

Pagina destra con due tab:

- **Note** (default): sticky notes 130px, rotazione ±0.05 rad, 5 tonalità gialle
- **Chat**: messaggi utente + input multiline + OwlFaceWidget

### OwlFaceWidget — Hooty

Due comportamenti animati:

- **Blinking**: ogni 3–6 secondi, scheduling ricorsivo randomizzato, durata 150ms
- **Eye tracking**: la pupilla segue la lunghezza del testo digitato (range ±0.8)

```dart
_chatTextController.addListener(() {
  _owlController.updateEyeOffset(
    ((_chatTextController.text.length % 10 - 5) / 5).clamp(-0.8, 0.8),
  );
});
```

---

## 🎨 Design system

### AppSpacing — griglia 4pt

```dart
AppSpacing.xs   = 4    // micro-gap (badge, separatori)
AppSpacing.sm   = 8    // icona → label
AppSpacing.md   = 12   // ritmo verticale card
AppSpacing.lg   = 16   // padding card, sezioni
AppSpacing.xl   = 24   // tra sezioni, form
AppSpacing.xxl  = 32   // padding pagina
AppSpacing.huge = 48   // hero / splash
```

### AppButton — tre varianti

```dart
// Gradiente indigo→purple, altezza 50px, gestisce loading e disabled
AppButton.primary(context, label: 'Accedi', onPressed: _onLogin, isLoading: _busy)

// Bordo cs.primary, fill trasparente
AppButton.secondary(context, label: 'Annulla', onPressed: _onCancel)

// Solo testo colorato
AppButton.text(context, label: 'Continua come ospite', onPressed: _onGuest)
```

### Palette brand

| Token | Hex | Uso |
|-------|-----|-----|
| `indigo` | `#6366F1` | Primary, gradient start bottoni |
| `indigoLight` | `#818CF8` | Primary in dark mode |
| `purple` | `#AD46FF` | Secondary, gradient end |
| `cyan` | `#00B8DB` | Accent, highlights CTA |

**Light mode**: background `#F8FAFF`, surface `#FFFFFF`, testo `#1A1A2E`

**Dark mode**: background `#0C0E1A` (navy), surface `#131629`, testo `#F1F5F9`

### Eccezione — carta vintage

I widget del libro (`BookLayer`, `ContentPageLayer`, `RightPageLayer`) usano sempre
`#F3EBDD` (sfondo carta) e `Colors.black87/54` (testo) — **mai** `Theme.of(context)`.
Questo mantiene la metafora fisica del libro coerente indipendentemente dal tema app.

### ThemeNotifier

Singleton globale (`ValueNotifier<ThemeMode>`) inizializzato in `main()`:

```dart
themeNotifier = await ThemeNotifier.load();       // legge SharedPreferences
themeNotifier.setTheme('Chiaro');                  // 'Sistema' | 'Chiaro' | 'Scuro'
```

Il tema scelto è persistito in SharedPreferences chiave `setting_theme`.

---

## 💾 Gestione dello stato e della memoria

### Stato in-memory (in-session)

| Campo | Tipo | Widget | Descrizione |
|-------|------|--------|-------------|
| `_chatHistories` | `Map<String, List<ChatMessage>>` | `BookStackWidget` | Chat per capitolo, sopravvive al cambio capitolo |
| `_notes` | `List<StickyNote>` | `BookStackWidget` | Note adesive, si perdono alla chiusura app |
| `_pageContent` | `String` | `BookStackWidget` | Ultimo testo ricevuto (capitolo o risposta chat) |
| `_activeBookmarkTab` | `BookmarkTab?` | `BookStackWidget` | Tab attivo (`notes`/`chat`), null = notes |

### Persistenza (SharedPreferences)

| Chiave | Tipo | Contenuto |
|--------|------|-----------|
| `school_level` | String | `'media'` / `'superior'` / `'university'` |
| `is_logged_in` | bool | Stato login (email) |
| `is_guest` | bool | Modalità ospite |
| `user_email` | String | Email dell'utente |
| `setting_theme` | String | `'Sistema'` / `'Chiaro'` / `'Scuro'` |
| `setting_language` | String | `'Italiano'` / `'English'` |
| `setting_notifications` | bool | Notifiche attive |
| `app_opens_YYYY-MM-DD` | int | Aperture giornaliere |
| `app_total_sessions` | int | Sessioni totali cumulative |
| `app_topic_search_TOPIC` | int | Contatore ricerche per argomento |

### Nota su isDev

Con `AppConfig.isDev = true` (default), `UserPreferences` restituisce sempre `null/false`
in lettura: ogni avvio parte come al primo accesso, ignorando qualunque preferenza salvata.
Per abilitare la persistenza reale imposta `isDev = false` prima della build di release.

---

## 🔧 Configurazione

### `lib/config/app_config.dart`

```dart
static const bool isDev = true;       // ← false in produzione
static const bool enableLogin = true; // ← false per saltare il login (demo/kiosk)
static const String version = '1.0.0';
```

### `lib/config/constants.dart`

```dart
static const String baseUrl = 'http://127.0.0.1:5000';  // ← aggiorna per produzione
static const String ragEndpoint = '$baseUrl/rag';
static const String recuperaIndiceEndpoint = '$baseUrl/recupera_indice';
static const String generateMapEndpoint =
    'https://n8ndev.inforelea.academy/webhook/generate-map';
static const Duration mapRequestTimeout = Duration(seconds: 60);
```

### `lib/services/api_service.dart`

Tutti i widget usano `const ApiService()` — nessun `http` diretto nei widget.

| Metodo | Endpoint | Quando viene chiamato |
|--------|----------|----------------------|
| `fetchChaptersIndex()` | GET `/recupera_indice` | Avvio `LessonScreen` |
| `fetchChapterContent(topic, level)` | POST `/rag` | Tap su capitolo nell'indice |
| `sendChatMessage(question, topic, level, history)` | POST `/rag` | Invio messaggio chat |
| `generateConceptMap(topic)` | POST n8n + QuickChart | Tap icona mappa concettuale |

In caso di errore tutti i metodi lanciano `ApiException(message, {statusCode})`.

---

## ⬇️ Scaricare il progetto

```bash
git clone https://github.com/TUO_UTENTE/progetto_finale.git
cd progetto_finale

# Scarica tutte le dipendenze Dart/Flutter
flutter pub get
```

---

## ▶️ Avviare in sviluppo

```bash
flutter run -d windows
```

**Da VS Code**: premi `F5` con target `Windows (desktop)` selezionato nella status bar.

Per log dettagliati (utile per debug API):

```bash
flutter run -d windows --verbose
```

L'app parte in modalità DEV:
- Badge arancione `⚙ DEV v1.0.0` in alto a sinistra
- Le preferenze salvate vengono ignorate (ogni avvio = primo avvio)
- Il banner debug di Flutter è visibile

---

## 📦 Build di release

### 1. Prepara la configurazione

In `lib/config/app_config.dart`:

```dart
static const bool isDev = false;  // ← disabilita la modalità sviluppo
```

Se il backend non è su localhost, aggiorna anche `baseUrl` in `lib/config/constants.dart`.

### 2. Compila

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/`

La cartella contiene l'eseguibile e tutte le DLL necessarie al runtime.

---

## 💿 Creare il file `.exe` distribuibile

### Opzione A — Cartella portatile *(più semplice)*

Copia l'intera cartella `build/windows/x64/runner/Release/` sul PC di destinazione
e fai doppio clic su `progetto_finale.exe`. Non richiede installazione — funziona
anche da chiavetta USB o cartella di rete.

**Requisito sul PC di destinazione:**
> Visual C++ Redistributable 2022 (gratuito):
> [aka.ms/vs/17/release/vc_redist.x64.exe](https://aka.ms/vs/17/release/vc_redist.x64.exe)

---

### Opzione B — Installer MSIX *(consigliata)*

Genera un pacchetto installabile che appare nel menu Start come un'app normale.

**Step 1** — Aggiungi la dipendenza nel progetto:

```bash
flutter pub add --dev msix
```

**Step 2** — Configura in `pubspec.yaml` (in fondo al file):

```yaml
msix_config:
  display_name: ApprenderAI
  publisher_display_name: Inforelea Academy
  identity_name: com.inforelea.apprenderai
  logo_path: assets/image/logo.png
  capabilities: 'internetClient'
```

**Step 3** — Genera il pacchetto:

```bash
flutter pub run msix:create
```

Output: `build/windows/x64/runner/Release/progetto_finale.msix`

Doppio clic sul `.msix` → Windows mostra la procedura guidata d'installazione.

> **Nota**: potrebbe essere necessario abilitare il sideloading:
> *Impostazioni → App → Impostazioni app avanzate → Origine app → Ovunque*

---

### Opzione C — Installer classico con Inno Setup

Genera un singolo `ApprenderAI_Setup.exe` che installa tutto automaticamente.

**Step 1** — Scarica e installa [Inno Setup](https://jrsoftware.org/isinfo.php).

**Step 2** — Crea `installer.iss` nella radice del progetto:

```iss
[Setup]
AppName=ApprenderAI
AppVersion=1.0.0
AppPublisher=Inforelea Academy
DefaultDirName={autopf}\ApprenderAI
DefaultGroupName=ApprenderAI
OutputBaseFilename=ApprenderAI_Setup
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\ApprenderAI";       Filename: "{app}\progetto_finale.exe"
Name: "{commondesktop}\ApprenderAI"; Filename: "{app}\progetto_finale.exe"

[Run]
Filename: "{app}\progetto_finale.exe"; Description: "Avvia ApprenderAI"; Flags: nowait postinstall
```

**Step 3** — Apri il file `.iss` con Inno Setup Compiler e premi **Compile**.

Output: `Output/ApprenderAI_Setup.exe` — singolo file autoestraente con installazione guidata.

---

## 🐛 Risoluzione problemi comuni

| Problema | Causa probabile | Soluzione |
|----------|----------------|-----------|
| `No connected devices` | Windows desktop non abilitato | `flutter config --enable-windows-desktop` poi riavvia il terminale |
| Build fallisce: MSBuild not found | Visual Studio senza workload C++ | Apri Visual Studio Installer → aggiungi "Sviluppo desktop con C++" |
| Indice capitoli non si carica | Backend Flask non in esecuzione | Avvia il server Python su `http://127.0.0.1:5000` |
| Mappa concettuale: timeout | n8n non raggiungibile | Verifica la connessione internet; timeout configurato a 60s |
| MSIX: installazione bloccata | Sideloading disabilitato | Impostazioni → App → Impostazioni app avanzate → Ovunque |
| App parte sempre come primo avvio | `isDev = true` in produzione | Imposta `isDev = false` in `app_config.dart` prima della build |
| Video background non si vede | MediaKit non inizializzato | Verifica che `MediaKit.ensureInitialized()` sia in `main()` |
| Errore `depend_on_referenced_packages` | `media_kit` come dev dep | Nota: warning noto, non bloccante per la build |

---

## 📄 Licenza

MIT — © 2026 Inforelea Academy — simone.colomba@inforelea.academy
