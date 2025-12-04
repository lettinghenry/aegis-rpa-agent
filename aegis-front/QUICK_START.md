# AEGIS RPA - Quick Start Guide

## ✅ System is Running!

Both backend and frontend are currently running and ready to use.

## 🚀 Quick Start (3 Steps)

### Step 1: Set Your API Key
Edit `aegis-back/.env` and add your Google API key:
```env
GOOGLE_ADK_API_KEY=your_actual_api_key_here
```

Get your key from: https://makersuite.google.com/app/apikey

### Step 2: Restart Backend (if needed)
If you just set the API key, restart the backend:
- Go to the PowerShell window running the backend
- Press `Ctrl+C` to stop
- Run: `uvicorn main:app --reload --host 0.0.0.0 --port 8000`

### Step 3: Use the App!
The Flutter desktop app is already running. Try submitting a simple task:
- "Open Calculator"
- "Open Notepad and type Hello World"

## 📍 URLs

- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Frontend**: Desktop application (already open)

## 🔄 Restart Commands

### Backend
```powershell
cd aegis-back
.\venv\Scripts\Activate.ps1
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend
```powershell
cd aegis-front
.\build\windows\x64\runner\Release\aegis_front.exe
```

## 🎯 What's Special

- **Model**: Using `gemini-robotics-er-1.5-preview` - optimized for RPA tasks
- **Real-time Updates**: WebSocket streaming shows live progress
- **Window Management**: Frontend minimizes during automation
- **History**: All executions are saved and reviewable

## 📖 Full Documentation

See `SUCCESS_STATUS.md` for complete details.

---

**Ready to automate!** 🤖
