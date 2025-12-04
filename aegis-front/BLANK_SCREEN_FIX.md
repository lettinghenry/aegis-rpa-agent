# Blank Screen Issue - Troubleshooting

## Problem
The Flutter app window opens but shows only a blank/gray screen with no UI content.

## Possible Causes

### 1. App Stuck in Loading State
The app might be stuck loading the onboarding status from SharedPreferences.

### 2. Missing Flutter Assets
Some Flutter assets might not be properly bundled.

### 3. Runtime Error Not Visible
There might be a runtime error that's not being displayed.

## Solutions to Try

### Solution 1: Clear App Data
The app might be stuck trying to load corrupted local storage data.

```powershell
# Delete the app's local storage
Remove-Item "$env:APPDATA\aegis_front" -Recurse -Force -ErrorAction SilentlyContinue
```

Then restart the app.

### Solution 2: Run in Debug Mode with Console
Run the app from command line to see error output:

```powershell
cd aegis-front
flutter run -d windows
```

Watch the console for any error messages.

### Solution 3: Check Backend Connection
The app might be trying to connect to the backend and timing out.

1. Ensure backend is running: http://localhost:8000
2. Check if backend is accessible:
   ```powershell
   Invoke-WebRequest -Uri "http://localhost:8000/" -UseBasicParsing
   ```

### Solution 4: Rebuild with Clean State
```powershell
cd aegis-front
flutter clean
flutter pub get
flutter build windows --release
.\build\windows\x64\runner\Release\aegis_front.exe
```

### Solution 5: Check for Missing DLLs
Ensure all required DLLs are in the Release folder:
- `flutter_windows.dll`
- `window_manager_plugin.dll`
- `screen_retriever_plugin.dll`

### Solution 6: Run with Verbose Logging
```powershell
$env:FLUTTER_LOG="debug"
.\build\windows\x64\runner\Release\aegis_front.exe
```

## Quick Fix: Use Debug Build Instead

If release build continues to have issues, use debug build:

```powershell
cd aegis-front
flutter run -d windows --debug
```

Debug builds have better error reporting and hot reload.

## Expected Behavior

When working correctly, you should see:
1. **First time**: Onboarding screen with introduction
2. **After onboarding**: Landing screen with task input field

## Next Steps

1. Try Solution 1 (clear app data) first
2. If that doesn't work, run Solution 2 (debug mode) to see errors
3. Check the console output for specific error messages
4. Report any error messages for further troubleshooting

---

**Note**: The blank screen is likely a runtime initialization issue, not a build problem, since the window opens successfully.
