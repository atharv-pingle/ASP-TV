# 📺 ASP TV - Android TV Edition

> **Live Marathi, Hindi & English News Channels for Smart TVs, Android TV, Fire TV & Google TV**
> Simple, Clean, Remote-First TV Live Streaming Application.

---

## 🌟 What is ASP TV?

**ASP TV** is an ultra-clean, lightweight Android TV live streaming app built specifically for Indian news viewers. It strips away all complexity, confusing menus, and touch-only UI patterns to deliver a seamless **couch viewing experience**:

- **3 Focused Languages**: **Marathi** (🚩), **Hindi** (🇮🇳), and **English** (🌐).
- **121 Verified News Channels** with **223 Live Stream Endpoints** (auto-failover mirrors).
- **100% Remote Control Friendly**: Operable with any Android TV / Fire TV remote D-Pad.
- **Fast 16:9 Fullscreen Playback**: Press **▲ / ▼** on your remote to surf channels directly.
- **Quick Guide Overlay**: Press **OK** while watching to peek at other channels without stopping the stream.
- **Bookmark Favorites**: Star your daily channels for instant 1-click access.

---

## 📺 Curated Channels by Language

### 🚩 Marathi News Channels (10 Channels)
- **ABP Majha** (Multiple live streams)
- **Zee 24 Taas**
- **TV9 Marathi**
- **News18 Lokmat / Marathi**
- **NDTV Marathi**
- **Jai Maharashtra**
- **Lokshahi News**
- **Pudhari News**
- **Top News Marathi**
- **News Marathi 24x7**

### 🇮🇳 Hindi News Channels (92 Channels)
- **Aaj Tak** & **Aaj Tak HD**
- **ABP News**
- **Zee News** & **Zee Bharat**
- **NDTV India**
- **India TV**
- **Republic Bharat**
- **Times Now Navbharat**
- **TV9 Bharatvarsh**
- **News18 India**
- **Good News Today (GNT)**
- **News24**, **Sudarshan News**, **Bharat 24**, and many more.

### 🌐 English News Channels (19 Channels)
- **NDTV 24x7**
- **India Today**
- **Republic TV**
- **Times Now** & **Times Now World**
- **CNN-News18**
- **WION**
- **DD India**
- **BT TV (Business Today)**, and more.

---

## 🎮 TV Remote Control Guide

```
┌────────────────────────────────────────────────────────┐
│                   ASP TV Remote Keymap                 │
├──────────────────┬─────────────────────────────────────┤
│ Remote Button    │ Action                              │
├──────────────────┼─────────────────────────────────────┤
│ ▲ / ▼ (Up/Down)  │ Channel Surfing (Next/Prev Channel) │
│ ◄ / ► (Left/Right│ Switch Categories / Channel Grid    │
│ OK / SELECT      │ Play Channel / Open Quick Guide     │
│ BACK / RETURN    │ Return to Channel Grid / Home       │
│ Long Press OK    │ Toggle Favorite (⭐)                │
└──────────────────┴─────────────────────────────────────┘
```

---

## 🚀 How to Build the APK

### Method 1: 1-Click Automated Cloud Build (Recommended)
1. Initialize a git repository and push to GitHub:
   ```bash
   git init
   git add .
   git commit -m "ASP TV initial commit"
   git remote add origin https://github.com/<your-username>/asp-tv.git
   git branch -M main
   git push -u origin main
   ```
2. Open your GitHub repository in your browser and click the **Actions** tab.
3. Select **Build ASP TV APK** and click **Run workflow**.
4. In ~2-3 minutes, download the ready-to-install **`app-release.apk`** from Artifacts or Releases!

### Method 2: Local Build (if Flutter & Android SDK installed)
```bash
flutter pub get
flutter build apk --release
# Generated APK: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📲 How to Install on your Smart TV

1. **Downloader App (Easiest)**:
   - Install **Downloader** on your TV from the Google Play Store / Amazon Appstore.
   - Enter the direct download link for your `app-release.apk` and press install.
2. **Send Files to TV**:
   - Transfer `app-release.apk` from your phone/PC to TV and open it with any TV file manager.
3. **ADB over WiFi**:
   ```bash
   adb connect <TV-IP-ADDRESS>:5555
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

---

## ⚖ Disclaimer

- All streams are sourced from public community directories ([iptv-org](https://github.com/iptv-org/iptv)).
- ASP TV is a personal HLS player client that does not re-broadcast or host proprietary stream servers.
