# Motor Araştırması ve Seçimi — 2026-11-01 (DRAGON REALMS)

> Kapsam: Godot dışındaki aday motorların **gerçek GitHub depoları, lisansları, Android
> platform kodları, upstream CI'ları ve dokümantasyonları** üzerinden incelenmesi;
> GitHub Actions üzerinde **gerçek Android ARM64 APK üretiminin kanıtlanması**.
> Mevcut Godot projesi bu araştırma sırasında silinmedi; `main` dalına dokunulmadı.
> Tüm bulgular `arena/aa30ce5a-red` dalında, `engine_probe/` altında canlı kanıtlarla.

---

## 1. Adaylar ve kanıt kaynakları

| Motor | Depo (gerçek) | Son sürüm (2026-11) | Lisans | Android kanıtı |
|---|---|---|---|---|
| **Unreal Engine 5** | `github.com/EpicGames/UnrealEngine` — **private/404** (Epic Games hesabı + GitHub bağlantısı zorunlu) | 5.8 | UE EULA: geliştirme ücretsiz, **brüt gelirin ilk 1 M$ üzerinde %5 royalty** | Kaynaktan Linux'ta Android derlenebilir (NDK), ama ~100 GB+ disk, saatler süren derleme, büyük runner gerekir; binary Launcher login ister → **CI'da kanıt üretilemez** |
| **O3DE** | `github.com/o3de/o3de` (233 MB, aktif) | 2605.0 (2026-05) | **Apache-2.0 OR MIT** | Resmi: docs.o3de.org "Android Support" (Gradle+CMake+NDK). Kendi CI'ı: `.github/workflows/android-build.yml` — ubuntu-22.04 + `maximize-build-space` (**70 GB disk**) + LFS + ccache ile APK üretir |
| **Flax Engine** | `github.com/FlaxEngine/FlaxEngine` (aktif) | 1.13.7012 (2026-10) | **Kendi EULA'sı** (flaxengine.com/licensing) — OSI değil; kullanım ücretsiz, royalty yok, kaynak erişimi var | docs.flaxengine.com/manual/platforms/android: **Vulkan**, API 24+, NDK + `dotnet workload install android`. Kendi CI'ı `build_android.yml`: windows-2022 üzerinde **Release ARM64 Android** build |
| **Stride** | `github.com/Stride3D/Stride` (aktif, 2026-11-01 push) | 4.4.1 (2026-10) | **MIT** | 4.4'te Android desteği eklendi (PR #3194), **Vulkan 1.3** üzerinden (GLES backend kaldırıldı). Kendi CI'ında `test-android-game.yml` (Vulkan, cihaz/emülatör) var; motor NuGet'ten gelir → CI hızlı |
| **Bevy** | `github.com/bevyengine/bevy` (49k ★, aktif) | **v0.20.1 (2026-10-28)** | **MIT OR Apache-2.0** (`LICENSE-MIT` + `LICENSE-APACHE`) | Resmi yol: `cargo-ndk` (arm64-v8a) + `android/` Gradle projesi, `android-game-activity` feature. **Bizim CI run'ımızla kanıtlandı** (aşağıda) |
| Ek: avian3d (fizik) | `github.com/avianphysics/avian` | 0.8 (Bevy 0.20 ile) | MIT/Apache-2.0 | — |

Diğer güçlü açık kaynak 3D motorlar (kısa eleme): Defold (2D odaklı), raylib/MonoGame
(kütüphane, AAA açık dünya için yetersiz), Urho3D (bakımıReduced), CryEngine (özel lisans,
kayıtlı erişim, mobil hedef zayıf), three.js/WebGPU (oyun motoru değil; paketleme
Capacitor ile olur ama fizik/LOD/streaming yok).

---

## 2. Teknik değerlendirme (zorunlu kriterlere göre)

| Kriter | UE5 | O3DE | Flax | Stride | **Bevy** |
|---|---|---|---|---|---|
| Lisans / tamamen ücretsiz | ❌ royalty (%5 > 1 M$) | ✅ Apache/MIT | ⚠️ özel EULA (ücretsiz ama OSI değil) | ✅ MIT | ✅ MIT/Apache |
| Vulkan (Android) | ✅ | ✅ Atom | ✅ | ✅ Vulkan 1.3 (GLES yok) | ✅ wgpu-hal → Vulkan |
| PBR renderer | ✅ Nanite/Lumen | ✅ Atom | ✅ | ✅ | ✅ bevy_pbr |
| Fizik motoru | ✅ Chaos/PhysX | ✅ PhysX 5 | ✅ (dahili, ragdoll aracı var) | ✅ Bullet | ✅ avian3d (XPBD, CCD, eklemler) |
| Ragdoll | ✅ | ✅ PhysX | ✅ Ragdoll aktörü | ✅ Bullet | ⚠️ avian eklemleriyle kur (planlı) |
| IK | ✅ | ✅ EMotionFX | ✅ Aim/Two-Bone IK düğümleri | ⚠️ | ⚠️ custom (analitik two-bone + CCD) |
| Prosedürel animasyon | ✅ | ✅ | ✅ Anim Graph custom node | ⚠️ | ⚠️ custom (bevy_animation + kod) |
| Açık dünya: LOD / occlusion / streaming | ✅ World Partition/HLOD | ✅ LOD grupları, streaming | ✅ | ⚠️ | ⚠️ frustum ✅, **GPU occlusion culling ✅ (0.20 `OcclusionCulling` + DepthPrepass)**, LOD/streaming custom (ECS chunk) |
| Android ARM64 APK — GitHub Actions | ❌ kanıt üretilemez (hesap+disk+saat) | ⚠️ mümkün ama 70 GB disk + saatler | ⚠️ upstream CI Windows'ta | ✅ hızlı (NuGet) | ✅ **6 dk'da yeşil, artefakt yayında (kanıt aşağıda)** |
| Bilgisayarsız geliştirme | ❌ | ❌ (editör/asset pipeline ağır) | ⚠️ | ⚠️ (editör Windows) | ✅ kod-odaklı, CI üzerinden her şey |

### Dragon-spesifik eşleme (Bevy ile nasıl karşılanacak)
- Çok eklemli hareket / eklembacaklı yürüme: avian3d kinematik karakter + özel **adım planlayıcı** (spatial query raycast).
- Bağımsız ayak hedefleme (foot IK): her ayak için raycast → hedef pozisyon; two-bone analitik IK ile bacak çözümü.
- Fizik tabanlı denge: avian3d dynamic rigid body + PID denge kontrolcüsü (torque geri besleme).
- Yüzeye tutunma/tırmanma: normal algılama + yerçekimi yönü değiştirme + tutunma animasyonu.
- Kanat fiziği / aerodinamik uçuş: custom aerodynamics modülü (kaldırma/sürükleme katsayıları, flap) + kanat iskeleti için procedural pose.
- Ragdoll: avian3d eklemleriyle (fixed/revolute/spherical) iskelet → ragdoll geçişi (animasyon ↔ fizik blend).

---

## 3. Gerçek Android derleme kanıtı (Bevy)

Proje: `engine_probe/bevy/` (Bevy 0.20.1, `android-game-activity`, PBR küp+ışık+gölge+kamera sahnesi).
CI: `.github/workflows/engine-probe-bevy.yml` — ubuntu-24.04 üzerinde:
Rust stable + `aarch64-linux-android`, JDK 21, Android SDK (platforms;android-37.0,
build-tools, **NDK 27.3.13750724**), `cargo install cargo-ndk`,
`cargo ndk -t arm64-v8a -P 26 -o android/app/src/main/jniLibs build`,
ardından `./gradlew :app:assembleDebug` (AGP 9.4.1 / Gradle 9.8.0 wrapper).

**Sonuç — run 41310656240 (commit 9590c03): TÜM ADIMLAR YEŞİL, 6m7s**
- `cargo ndk` → Bevy 0.20.1 `aarch64-linux-android` için derlendi, `.so` jniLibs'e kopyalandı.
- Gradle → `app-debug.apk` üretildi.
- Doğrulama adımı (yeşil çünkü assert'ler geçti): APK içinde
  `lib/arm64-v8a/libdragon_realms_probe.so` var; Python ile kontrol: **ELF magic ✅,
  ELF64 ✅, makine = 0xB7 (EM_AARCH64) ✅**, `classes.dex` ✅.
- Artefakt: **`BEVY_ANDROID_PROBE_APK`** (run 41310656240, id 13084399914) indirilebilir.

Karşılaştırma: aynı koşullarda Godot M1 APK'sı ~3 dk (motor binary hazır geldordan);
Bevy'de motor da kaynaktan/NuGet'ten derleniyor — ilk soğuk derleme ~6 dk, cache ile
~3 dk. UE5 aynı sahne için saatler + 70-100 GB disk + büyük runner (ücretli) ister.

---

## 4. Karar

**Seçilen motor: Bevy 0.20 (Rust) + wgpu/Vulkan + avian3d.**

Gerekçe:
1. **Tamamen ücretsiz ve OSI lisanslı** (MIT OR Apache-2.0) — royalty yok, hesap bağlama yok.
2. **Vulkan + PBR + yüksek performanslı renderer** (wgpu; Android'de Vulkan backend).
3. **Gerçek APK kanıtı bizde**: `engine_probe` run'ı yeşil, ARM64 ELF .so + classes.dex
   doğrulanmış artefakt.
4. **Bilgisayarsız geliştirme birebir uyumlu**: tüm geliştirme repo + GitHub Actions
   üzerinden; editör bağımlılığı yok (kod-odaklı ECS).
5. Fizik (avian3d), GPU occlusion culling (0.20), frustum culling, PBR, gölge, ses, UI,
   dokunmatik girdi (bevy_input touch) hazır. Eksikler (IK, ragdoll, kanat/aero, world
   streaming) dragon projesinin zaten custom yazılacak sistemleridir — motor seçimini
   engellemez.
6. Ekosistem canlı (49k★, 3 ayda bir majör sürüm; 0.20 = 2026-10).

**2. seçenek (yedek):** O3DE — en güçlü "hazır" paket (PhysX ragdoll, EMotionFX IK, Atom),
ama CI maliyeti (70 GB disk, saatler, LFS) ve asset pipeline ağırlığı nedeniyle
"tamamen ücretsiz + hızlı CI" hedefiyle uyuşmuyor. UE5 royalty + hesap/doku engeliyle elendi.

---

## 5. Yeni mimari planı (Bevy geçişi)

```
dragon_realms/                 # Rust workspace (yeni)
  Cargo.toml                   # workspace; bevy 0.20, avian3d 0.8
  crates/
    dr_app/                    # giriş (android cdylib + masaüstü bin), plugin sırası
    dr_core/                   # ayarlar (LOW/MED/HIGH/ULTRA), kalite, adaptif çözünürlük, Türkçe UI kökü
    dr_world/                  # arazi (prosedürel ada/dağ), biyom, quadtree chunk streaming, LOD, occlusion
    dr_ocean/                  # Gerstner dalgaları, fresnel, köpük, derinlik rengi (wgpu shader)
    dr_sky/                    # fırtına gökyüzü, bulut katmanları, şimşek aydınlatması
    dr_weather/                # 7 hava durumu, yağmur, gölge/şimşek, gün döngüsü
    dr_vegetation/             # ağaç/kaya/çim (prosedürel mesh), rüzgar, MultiMesh eşleniği (instancing)
    dr_environment/            # kalıntılar, kale, mağaralar, nehirler/şelaleler
    dr_dragon/                 # YENİ: iskelet, kanat, uçuş aero-fiziği, yer yürüyüşü,
                               # foot IK, denge PID, ragdoll (avian), tırmanma
    dr_input/                  # dokunmatik joystick + bakış, klavye
    dr_audio/                  # ses (M2)
  android/                     # Gradle projesi (engine_probe/bevy/android şablonu)
  .github/workflows/dragon-realms-bevy.yml   # cargo test + clippy + ARM64 APK + artefakt + v* release
```

- **CI:** her push'ta `cargo test` (headless) + `cargo clippy`; Android job'u probe ile kanıtlanan
  aynı pipeline: `cargo ndk -t arm64-v8a` + `gradlew assembleRelease` → artefakt
  `DRAGON_REALMS_BEVY_ANDROID_APK`, `v*` etiketinde GitHub Release.
- **Hedef cihaz:** Dimensity 8400 Ultra (Vulkan 1.3+, 12 GB) — wgpu Vulkan, 60 FPS hedefi,
  kalite preset'leriyle adaptif çözünürlük.
- **Varlıklar:** %100 prosedürel (lisans-temiz) + M2'de CC0 (glTF) — bevy_gltf hazır.
- **Godot projesi:** bu dalda dokunulmadan duruyor; geçiş onaylanınca `legacy/godot_m1/`
  altına taşınacak. `main` dalı değiştirilmedi.
- **Milestonelar (Bevy'e uyarlanmış):** M1 dünya temeli (arazi/okyanus/gökyüzü/hava/döngü/kamera/UI/testler) →
  M2 biyomlar + CC0 asset + ses → M3 ejderha model/iskelet/animasyon → M4 uçuş fiziği + kanat aero →
  M5 biniş + mobil kontroller + foot IK/denge/ragdoll → M6 keşif → M7 medeniyetler → M8 optimizasyon (occlusion, LOD, streaming, 60 FPS doğrulama).

## 6. Riskler ve dürüst notlar
- Bevy'de occlusion culling 0.20'de var ama **DepthPrepass ister ve deferred ile uyumsuz**; erken test edilecek.
- IK/ragdoll/kanat fiziği **custom** yazılacak (avian eklemleriyle) — M3-M5 kapsamına alındı.
- World streaming hazır değil; quadtree chunk sistemi Rust'ta yeniden yazılacak (Godot M1 mantığı taşınır).
- Android'de wgpu Vulkan 1.0+ gerektirir; hedef cihazda sorun yok (Vulkan 1.3).
- Bevy API'si hızlı değişiyor (0.20'de `shadow_maps_enabled`, `bevy::window::WindowMode` gibi kırılmalar yaşadık) — Cargo.lock commit'lenir, sürüm geçişleri migration guide ile yapılır.
