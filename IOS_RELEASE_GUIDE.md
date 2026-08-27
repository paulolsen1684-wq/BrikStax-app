# iOS Release Guide

Step-by-step for building, archiving, and submitting a BrikStax release on the Mac. Written for v2.4.0+10, but the process itself is the same every release — just swap in the new version's details each time.

## This release

- **Version:** 2.4.0+10 (`pubspec.yaml`)
- **Branch to pull:** `add-quest-builder-tool` — **not** `main`. Everything for this release lives here; it hasn't been merged yet.
- **What's New copy:** see the bottom of this doc — already written, just paste it in.

---

## 0. One-time checks (skip if these are already true)

- [ ] Xcode is up to date (Mac App Store, or check Xcode → About Xcode). Newer Firebase/plugin SDKs occasionally require a newer Xcode than you'd expect — if a pod fails to compile with a cryptic Swift/SDK error, this is the first thing to check.
- [ ] You're signed into the right Apple ID in Xcode (Xcode → Settings → Accounts) and it has access to the BrikStax app in App Store Connect.
- [ ] CocoaPods itself is installed and current (`pod --version`; `sudo gem install cocoapods` if it's missing or ancient).

## 1. Pull the code

```bash
cd /path/to/brikstax_fresh   # wherever this repo lives on the Mac
git fetch origin
git checkout add-quest-builder-tool
git pull
```

If this is a fresh clone instead of an existing checkout, clone the repo first, then check out that branch — don't build from `main`, it's missing everything in this release.

## 2. Refresh dependencies

Given how much native-dependency-touching work went into this release (Firebase, share_plus, image_cropper, qr_flutter all changed at various points), do a clean pass rather than an incremental one:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

If `pod install` complains about version conflicts or a missing spec, try `pod repo update && pod install` before troubleshooting further — that alone fixes most "can't find compatible version" errors.

**Note:** `ios/Podfile` isn't tracked in this repo's git history (never committed, going back to before this session). If it already exists locally on the Mac from past builds, `pod install` just updates it in place and nothing below changes. If it's ever missing entirely, `flutter pub get`/`pod install` will regenerate it fresh from `pubspec.yaml` — that's expected, not an error.

## 3. Open the workspace (not the project)

```bash
open ios/Runner.xcworkspace
```

Opening `Runner.xcodeproj` directly instead of the `.xcworkspace` is the single most common way to get "framework not found" build errors on a CocoaPods project — the workspace is what actually links the Pods in.

## 4. Verify version, bundle ID, and signing

In Xcode, select the **Runner** target → **General** tab:

- [ ] **Version** shows `2.4.0` and **Build** shows `10` (or whatever this release's numbers are — Flutter should sync these from `pubspec.yaml` automatically, but confirm rather than assume, especially after a `flutter clean`).
- [ ] **Bundle Identifier** is `com.brikstax.brikstax` — should already be set correctly (it's what's checked into the project file), but confirm it matches the app record you're targeting in App Store Connect.

Then **Signing & Capabilities** tab:

- [ ] A **Team** is selected (your Apple Developer Program team).
- [ ] "Automatically manage signing" is checked, and Xcode isn't showing a red error about a missing/invalid provisioning profile. If it is, click "Try Again" or toggle automatic signing off/on — this almost always self-heals as long as your Apple ID has the right access.

No new capabilities need adding for this release — push notifications are still Android-only (no `GoogleService-Info.plist`, no APNs key configured yet), so there's nothing iOS-specific to wire up for that feature. It simply won't do anything on iOS builds, silently and safely.

## 5. Archive

- [ ] At the top of the Xcode window, set the run destination to **Any iOS Device (arm64)** — not a simulator, not your own iPhone. Archiving is greyed out if a simulator is selected.
- [ ] **Product → Archive.** This takes a few minutes — it's a full release build, not incremental.

## 6. Validate before uploading

When the archive finishes, **Organizer** opens automatically (or **Window → Organizer** if not). Select the new archive.

- [ ] Click **Validate App** first, not Distribute directly. Pick the default options (App Store Connect distribution, automatic signing) and let it run — this catches missing icons, bad entitlements, and other packaging problems *before* they turn into a slower reject-and-fix cycle after a real upload.
- [ ] Once validation passes, click **Distribute App** → **App Store Connect** → **Upload**, same options as validation.

## 7. Wait for processing

After upload, Apple processes the build server-side — usually 15 minutes to a couple of hours, occasionally longer. You'll get an email when it's ready. No action needed on your end during this window.

## 8. Recommended: TestFlight smoke test before submitting

This release has a lot of surface area — push notification infrastructure (even though it's dormant on iOS), the What's New quest system with the new scheduling feature, a full icon/asset sweep, and Worker-side changes. Given that, it's worth the extra 20 minutes:

- [ ] Once the build finishes processing, it's automatically available under **TestFlight** in App Store Connect. Add yourself as an internal tester if you aren't already, install via the TestFlight app, and do a quick pass: open the app, check the dashboard loads, check a share card, check Settings looks right.
- [ ] If nothing looks obviously broken, move on to submitting.

## 9. Submit for review

In App Store Connect → your app → **App Store** tab:

- [ ] Create a new version if one doesn't already exist for 2.4.0 (**+ Version or Platform**).
- [ ] Under **Build**, select the build you just uploaded (it'll appear here once processing finishes — not before).
- [ ] Paste the **What's New in This Version** text — see below.
- [ ] Screenshots: not required to change for this release unless you want to show off the new Post share format specifically — existing screenshots are still accurate to the app's core flows.
- [ ] **Export Compliance**: if asked, this app only uses standard HTTPS/TLS (no custom encryption) — answer the same way as the last submission (typically "No" to needing an export compliance document, since standard HTTPS is exempt).
- [ ] Click **Add for Review**, then **Submit to App Review**.

That's it — from here it's Apple's review queue (historically anywhere from a few hours to a couple of days).

---

## What's New in This Version (paste into App Store Connect)

```
What's New in BrikStax 2.4.0:

• New Post sharing format — square-friendly for your feed, alongside the original Story format
• Choose exactly how your photo crops before sharing, with a new composition guide
• Community feed photos now show in a taller, Instagram-style layout
• New in-app rewards to discover — check out "What's New" after updating
• Fresh avatar cosmetics, plus general polish and bug fixes
```

---

## Troubleshooting quick reference

| Symptom | Likely cause |
|---|---|
| "Framework not found" at build time | Opened `.xcodeproj` instead of `.xcworkspace` |
| Pod install fails on a version conflict | Run `pod repo update` first, then `pod install` again |
| Signing shows a red error, can't resolve | Toggle automatic signing off then on; confirm your Apple ID has App Store Connect access to this app in Xcode → Settings → Accounts |
| Archive option greyed out | Run destination is set to a simulator — switch to "Any iOS Device (arm64)" |
| Build never appears in App Store Connect after upload | Still processing (check email) — or Validate/Upload silently failed, check Organizer's own log for the archive |
| Odd Swift/SDK compile errors from a plugin | Xcode version may be older than what a recently-updated pod (Firebase, etc.) expects — update Xcode |
