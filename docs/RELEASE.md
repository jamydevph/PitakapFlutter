# Release checklist — Pitakap

Everything the code can carry is done and verified. What remains needs a human: signing keys, store accounts, and a Firebase console.

**Verified 2026-09-09:** `flutter analyze` clean · 648/648 tests · Android AAB builds · iOS `Runner.app` builds.

---

## ✅ Done in the repo

| Item | Evidence |
|---|---|
| Application / bundle ID | `com.jamagno.pitakap` on both platforms |
| Android app name | merged release manifest shows `android:label="Pitakap"` |
| iOS app name | built bundle `CFBundleDisplayName` = `Pitakap` |
| iOS encryption declaration | `ITSAppUsesNonExemptEncryption` = `false` (stops the prompt on every upload) |
| iOS privacy manifest | `PrivacyInfo.xcprivacy` present **in the built `.app`**, wired into the Runner target |
| Android target SDK | 36 (Play's floor is 35) |
| Adaptive icon | background + foreground + monochrome |
| iOS icons | 21 sizes incl. 1024×1024 |
| Account deletion | Settings → Delete account (**both stores require this**) |
| Privacy policy + Terms | `docs/privacy-policy.md`, `docs/terms-of-service.md`, reachable in-app from Settings → About |
| Release signing config | reads `android/key.properties`, falls back to debug when absent |
| **Google Sign-In provider** | enabled in Firebase 2026-09-09 (it was **off**, so the button failed on *both* platforms) |
| **Android OAuth client** | `google-services.json` now has 2 `oauth_client` entries (was empty) |
| **iOS OAuth client** | `GoogleService-Info.plist` added to the Runner target; `CLIENT_ID` + `REVERSED_CLIENT_ID` present |
| **iOS URL scheme** | `CFBundleURLTypes` set to the `REVERSED_CLIENT_ID`, verified in the built bundle |
| Google consent screen | public name **Pitakap**, support email `jamagno.27@gmail.com` (both user-visible) |

---

## 🔴 Blockers — these are yours

### 1. ~~Fill in the contact email~~ — ✅ DONE 2026-09-09

Both policy documents now carry **`jamagno.27@gmail.com`** — the same address published on the Google sign-in consent screen, so users see one consistent contact.

⚠️ **Still read both documents.** They were drafted from what the code actually collects and are accurate as far as that goes, but they are legal documents published under your name.

### 2. Generate the upload keystore (Android)

```
keytool -genkey -v -keystore ~/pitakap-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `android/key.properties.example` → `android/key.properties` and fill it in. Then:

```
cd pitakapflutter
flutter build appbundle --release
```

Confirm it is no longer debug-signed:

```
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep Owner
```

It must **not** say `CN=Android Debug`.

> **Back the keystore up, off this machine.** Losing it means you can never update the same Play listing again.

### 3. Apple Developer Program ($99/yr) and signing

Needed before an iOS build can be uploaded at all. Then in Xcode: Runner → Signing & Capabilities → select your team, and archive with **Product → Archive** (or `flutter build ipa`).

### 4. ⚠️ Add the Play App Signing SHA-1 after your first Play upload

**Google Sign-In is now configured — but it will break for real Play users unless you do this.**

Play App Signing re-signs your app with **Google's** key, not your upload key. Three fingerprints matter:

| Fingerprint | Needed for | Status |
|---|---|---|
| This Mac's **debug** keystore | your own emulator/device testing | ✅ added (`7D:72:33:93:C7:21:79:64:46:62:A8:84:FE:28:30:FC:A8:DB:03:33`) |
| Your **upload** keystore | signing the AAB you upload | ⬜ after you create the keystore |
| **Play App Signing** key | **every user who installs from Play** | ⬜ **after the first upload** |

After your first AAB reaches Play: **Play Console → Test and release → Setup → App signing** → copy the *App signing key certificate* SHA-1 → add it in **Firebase → Project settings → your Android app → Add fingerprint**, then re-download `google-services.json`.

Skip this and Google Sign-In works perfectly on your machine and fails for everyone who installs from the store.

> The SHA-1 recorded in the older project notes (`5D:9E:19:CE:…`) is from the **retired Windows machine** and matches nothing built here.

### 5. Store listing assets

Not in the repo, and the emulator screenshots in `docs/screenshots/` are **not** the right dimensions for either store.

- **Play:** 512×512 icon, 1024×500 feature graphic, ≥2 phone screenshots, short + full description, content rating questionnaire, Data safety form (declare: email, name, user content; no tracking; no ads).
- **App Store:** 6.7" and 6.5" screenshots, description, keywords, support URL, privacy policy URL, App Privacy answers (matching `PrivacyInfo.xcprivacy`).

Privacy policy URL for both:
`https://github.com/jamydevph/PitakapFlutter/blob/main/docs/privacy-policy.md`

> A GitHub blob URL is accepted but looks unpolished. GitHub Pages on this repo would give you a real page for free.

---

## ⚠️ Known, deliberate

- **Two GitHub secret-scanning alerts are open** on the Firebase API keys in `lib/firebase_options.dart`. These are **client identifiers, not secrets** — access is controlled by Firestore rules. They cannot be hidden (they ship inside the app binary). The correct handling is to **restrict both keys** in Google Cloud Console to the app package/bundle + SHA-1, then close the alerts as *"Won't fix"*. Do **not** disable secret scanning.

- **Minimum iOS is now 15.0.** Flutter raised it from 13.0 during the first iOS build; iOS 13/14 devices are dropped.
- **Reminders do not survive a reboot** until the app is next opened — `RECEIVE_BOOT_COMPLETED` was deliberately not declared. Disclosed in the Terms.
- **The 35-row manual QA matrix has never been run.** Not a store gate, but the app has never been exercised against real Firestore on a device. Row #16 (second-account isolation) is the only real proof the security rules work.
- ~~**The Google `G` mark** is a styled letter~~ — **✅ FIXED 2026-09-09.** Replaced with Google's official four-colour mark, downloaded from `developers.google.com/static/identity/images/g-logo.png` and committed at `assets/branding/google_g_logo.png`. A test asserts the asset renders *and* that the placeholder `Text('G')` never returns.
