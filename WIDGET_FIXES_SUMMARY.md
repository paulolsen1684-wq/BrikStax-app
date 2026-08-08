# Widget Navigation and Display Fixes

## Changes Made

### 1. **Set Lookup Widget Deep Link Navigation** ✅
**Problem**: The Set Lookup widget didn't navigate to the SetLookupScreen when tapped.

**Solution**: 
- Added `DeepLinkService` (`lib/services/deep_link_service.dart`) - A new service that listens for deep links throughout the app's entire lifecycle, not just at startup
- Updated `main.dart` to initialize `DeepLinkService` in `_ShellState.initState()` with callbacks for:
  - `_goToScanner()` → navigates to ScannerScreen
  - `_goToSetLookup()` → navigates to SetLookupScreen  
  - `_goToSetDetail(setNum)` → navigates to SetDetailScreen for a specific set
- Added `app_links: ^7.2.1` to `pubspec.yaml` for proper deep link handling

**How it works**:
1. When app is already running and user taps the Set Lookup widget, Android sends `brikstax://lookup` intent
2. `DeepLinkService` listens via `uriLinkStream` and calls `_goToSetLookup()`
3. App navigates directly to SetLookupScreen

### 2. **Den Widget Visual Preview** ✅
**Problem**: The Avatar Den widget only showed an emoji (🏠) instead of an actual visual preview.

**Solution**:
- Added `DenScreenshotService` (`lib/services/den_screenshot_service.dart`) - Captures the den scene as a screenshot and caches it
- Updated `BrickDenScreen` to:
  - Convert from `StatelessWidget` to `StatefulWidget`
  - Wrap `DenSceneContent` in `RepaintBoundary` for screenshot capture
  - Automatically capture screenshot after first frame renders
  - Call `WidgetService.updateDenWidget()` to refresh the widget
- Updated `widget_service.dart` to add `updateDenWidget()` method
- Updated Android widget layout (`avatar_den_widget.xml`) to:
  - Show cached screenshot in `ImageView` when available
  - Fall back to emoji view if no screenshot exists
- Updated `AvatarDenWidgetProvider.kt` to:
  - Try loading the cached den screenshot from `context.cacheDir`
  - Display it in the widget if available
  - Show fallback emoji view otherwise

**How it works**:
1. User opens the Den screen
2. After the scene renders, a screenshot is automatically captured
3. Screenshot is saved to app's cache directory as `den_screenshot.png`
4. Widget reads the cached screenshot
5. Next time widget updates, it displays the actual den preview instead of just an emoji

### 3. **Dependencies**
- Added `app_links: ^7.2.1` for lifecycle-wide deep link handling
- All other dependencies already present

## Files Modified

- `pubspec.yaml` - Added app_links dependency
- `lib/main.dart` - Added DeepLinkService initialization and callbacks
- `lib/services/deep_link_service.dart` - **NEW** - Handles deep links throughout app lifecycle
- `lib/services/den_screenshot_service.dart` - **NEW** - Captures and caches den screenshots
- `lib/services/widget_service.dart` - Added `updateDenWidget()` method
- `lib/modules/avatar/widgets/brick_den.dart` - Convert to StatefulWidget, add screenshot capture
- `android/app/src/main/res/layout/avatar_den_widget.xml` - Added ImageView for screenshot + fallback layout
- `android/app/src/main/kotlin/com/brikstax/brikstax/AvatarDenWidgetProvider.kt` - Load and display cached screenshot

## Expected Behavior After Fixes

### Set Lookup Widget
- Tapping the Set Lookup widget now navigates directly to SetLookupScreen
- Works whether app is running, backgrounded, or not started
- Deep link pattern: `brikstax://lookup`

### Den Widget
- First time you open the Den screen, a screenshot is captured automatically
- Widget now displays the actual den scene preview
- Falls back to emoji view if screenshot is unavailable
- Screenshot updates each time you visit the Den screen

### Random Set Widget
- Already working as implemented - no changes needed

## Testing
1. Place Set Lookup widget on home screen → tap it → should navigate to SetLookupScreen
2. Place Den widget on home screen → open Den in app → wait for screenshot → widget should show den preview
3. Random Set widget should continue working as before

## Notes
- Screenshots are cached in the app's temp directory (`getCacheDir()` on Android)
- The screenshot capture happens automatically, no user action needed
- Both widgets will update when the app launches or when data changes
- Deep link service continuously listens for deep links, enabling widget navigation even when app is backgrounded
