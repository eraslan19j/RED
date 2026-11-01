# ANDROID_BUILD — Android Derleme (tamamen otomatik)

Kullanıcı PC kullanmaz. Her push'ta GitHub Actions APK üretir.

## Workflow: `.github/workflows/android-build.yml`

1. **JDK 17** (Temurin) — Godot 4.7 Android gradle derlemesi gereksinimi.
2. **Android SDK:** cmdline-tools + `platform-tools`, `platforms;android-36`,
   `build-tools;36.1.0` (Godot 4.7.2'nin `compileSdk 36 / buildTools 36.1.0`
   gereksinimine uygun). NDK gerekmez (saf GDScript, hazır .so'lar template ile gelir).
3. **Godot 4.7.2-stable headless** + **export templates** (`~/.local/share/godot/
   export_templates/4.7.2.stable/`).
4. **Debug keystore** (`~/.android/debug.keystore`, alias `androiddebugkey`,
   şifre `android`) keytool ile üretilir — gizli/private anahtar commit'lenmez.
5. `godot --headless --path . --import` — asset içe aktarma.
6. `godot --headless --path . -s res://tests/test_runner.gd` — otomatik testler;
   logda `SCRIPT ERROR` / `Parse Error` varsa derleme **başarısız** sayılır.
7. `godot --headless --path . --export-debug "Android" build/android/DRAGON_REALMS.apk`
   — debug imzalı **ARM64 APK**.
8. APK varlığı + `lib/arm64-v8a/libgodot_android.so` içeriği doğrulanır.
9. Artefakt: **`DRAGON_REALMS_ANDROID_APK`** (30 gün saklanır).
10. `v*` etiketlerinde ek iş: APK'lı otomatik **GitHub Release** (`contents: write`).

## Export Preset (export_presets.cfg)

- Paket: `com.dragonrealms.game`, ad "Dragon Realms", versiyon 0.1.0
- **Yalnızca `arm64-v8a`** (hedef cihaz ARM64)
- `gradle_build/use_gradle_build = true`, APK formatı (AAB değil)
- min SDK 24, target SDK 36
- İzin: yalnızca `android.permission.VIBRATE`
- Oryantasyon: landscape (`display/window/handheld/orientation = 0`), tam ekran

## APK'yı İndirme

GitHub → **Actions** → ilgili koşum → **Artifacts** → `DRAGON_REALMS_ANDROID_APK`
(veya bir `v*` Release sayfasından). Debug imzalı olduğu için telefonda
"bilinmeyen kaynak" onayı ile kurulur.
