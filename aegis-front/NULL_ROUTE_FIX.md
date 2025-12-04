# Null Route Fix - Blank Screen Resolution

## Problem
The app was showing a blank screen with the error:
```
flutter: Null check operator used on a null value
flutter: #0 _WidgetsAppState._onGenerateRoute.<anonymous closure>
```

## Root Cause
The `onGenerateRoute` method in `app_router.dart` was not handling the case where `settings.name` could be null. When Flutter initializes with an `initialRoute`, sometimes the route name can be null or empty, causing a null check error in the switch statement.

## Solution
Added null handling in the router:

```dart
static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  // Handle null or empty route name
  final routeName = settings.name ?? landing;
  
  switch (routeName) {
    // ... rest of the switch cases
  }
}
```

This ensures that if `settings.name` is null, it defaults to the landing route.

## Files Modified
- `lib/routes/app_router.dart` - Added null check for route name

## Testing
After the fix:
1. ✅ App launches without errors
2. ✅ Onboarding screen shows (first time)
3. ✅ Landing screen shows (after onboarding)
4. ✅ No more null check errors

## How to Apply
The fix has been applied and the app rebuilt. To run:

```powershell
cd aegis-front
.\build\windows\x64\runner\Release\aegis_front.exe
```

## Prevention
This type of error can be prevented by:
1. Always handling null cases in route generation
2. Providing default values for nullable parameters
3. Testing with fresh app state (cleared data)

---

**Status**: ✅ Fixed and tested
