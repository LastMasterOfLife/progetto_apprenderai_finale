# 📸 Istruzioni per aggiungere le immagini di sfondo

## 🎯 Immagini necessarie

Devi salvare le 3 immagini che ti ho mostrato nella cartella:
```
C:\Users\conra\Desktop\progetto_finale\assets\backgrounds\
```

Con i seguenti nomi:

### 1. 🟢 Immagine Verde (Scuola Media)
- **Nome file:** `green_nature.jpg`
- **Descrizione:** Finestra con piante verdi, luce naturale, tazza di caffè
- **Dimensioni consigliate:** 1920x1080 o superiore

### 2. 🔵 Immagine Blu (Superiori)
- **Nome file:** `blue_study.jpg`
- **Descrizione:** Scrivania con laptop, libri impilati, vista lago e montagne
- **Dimensioni consigliate:** 1920x1080 o superiore

### 3. 🔴 Immagine Rossa/Arancione (Università)
- **Nome file:** `red_sunset.jpg`
- **Descrizione:** Finestra con luce arancione del tramonto, piante, tazza di tè
- **Dimensioni consigliate:** 1920x1080 o superiore

---

## 📋 Passi per aggiungere le immagini

### Opzione 1: Salva le immagini dalla chat
1. Clicca con il tasto destro su ciascuna immagine che ti ho inviato
2. Seleziona "Salva immagine con nome"
3. Salvale nella cartella `assets/backgrounds/` con i nomi indicati sopra

### Opzione 2: Usa le tue immagini
Se preferisci usare altre immagini:
1. Cerca immagini simili su siti come Unsplash, Pexels, o Pixabay
2. Scaricale e rinominale con i nomi corretti
3. Mettile nella cartella `assets/backgrounds/`

---

## ⚙️ Aggiorna pubspec.yaml

Dopo aver aggiunto le immagini, apri il file `pubspec.yaml` e assicurati che ci sia questa sezione:

```yaml
flutter:
  assets:
    - assets/image/
    - assets/video/
    - assets/backgrounds/  # <-- AGGIUNGI QUESTA RIGA SE NON C'È
```

---

## 🚀 Come funziona

Quando l'utente seleziona un livello di istruzione nella StartScreen:

- ✅ **Scuola Media (Verde)** → Mostra `green_nature.jpg`
- ✅ **Superiori (Blu)** → Mostra `blue_study.jpg`
- ✅ **Università (Rosso)** → Mostra `red_sunset.jpg`

Lo sfondo cambierà automaticamente con una transizione animata di 800ms.

---

## ✨ Risultato finale

Ogni card avrà uno sfondo immersivo che si adatta al livello scolastico:
- 🌿 Verde = Ambiente rilassante e naturale per le medie
- 📚 Blu = Ambiente di studio serio per le superiori
- 🌅 Arancione = Ambiente accademico per l'università

---

## 🔧 Test

Dopo aver aggiunto le immagini:

1. Esegui `flutter pub get`
2. Riavvia l'app con `flutter run`
3. Vai alla StartScreen
4. Clicca su ciascun livello e verifica che lo sfondo cambi correttamente

Se vedi errori tipo "Unable to load asset", verifica che:
- Le immagini abbiano i nomi esatti
- Siano nella cartella corretta
- Il pubspec.yaml sia stato aggiornato
