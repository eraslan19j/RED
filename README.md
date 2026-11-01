# DRAGON REALMS — Ejderha Diyarları

**AAA mobil açık dünya ejderha oyunu** — Godot 4.7.2 (stable) ile geliştiriliyor.
Hedef platform: **Android (ARM64, Vulkan, Mobile renderer)**. Hedef cihaz sınıfı:
MediaTek Dimensity 8400 Ultra / 12 GB RAM / 120 Hz ekran.

> Bu depo, geliştirmeyi tamamen Bulut + GitHub Actions üzerinden yürütür:
kullanıcının PC kurmasına gerek yoktur. APK her push'ta otomatik derlenir ve
`DRAGON_REALMS_ANDROID_APK` artefaktı olarak yayınlanır.

## Hızlı Başlangıç

1. Depoyu klonla: `git clone https://github.com/eraslan19j/RED.git`
2. En son APK'yı indir: GitHub → **Actions** → son başarılı koşunun **DRAGON_REALMS_ANDROID_APK**
   artefaktı (veya `v*` etiketli bir **Release** içindeki APK).
3. APK'yı telefona kur (debug imzalı dahili test derlemesi) ve aç.

## Kontroller

| Girdi | İşlev |
|---|---|
| Sol ekran yarısı (joystick) | İleri/geri + sağ/sol hareket |
| Sağ ekran yarısı (sürükle) | Bakış yönü (çoklu dokunmatik destekli) |
| Yukarı / Aşağı düğmeleri | Uçarak yüksel/alçal |
| W A S D + Q/E, Shift (klavye) | Hareket / hızlı uçuş (masaüstü test) |
| Üstteki düğmeler | Hava durumu, saat, ayarlar, menü |

## Proje Yapısı

```
project.godot                 Godot 4.7 proje ayarları (Mobile renderer, Vulkan)
export_presets.cfg            Android ARM64 preset (min SDK 24, target 36)
scenes/main.tscn              Giriş sahnesi
scripts/
  main.gd                     Oyun kökü (dünya + kamera + arayüz)
  autoload/settings_manager.gd  Grafik presetleri + kalıcı ayarlar
  managers/                   WorldManager, TerrainManager, BiomeManager,
                              WeatherManager, EnvironmentManager,
                              StreamingManager, LightingManager
  world/                      TerrainChunk (quadtree), Ocean, SkySystem,
                              VegetationSystem, DayNightCycle
  weather/                    RainSystem, LightningSystem
  player/free_camera.gd       Serbest keşif kamerası (dokunmatik + klavye)
  ui/                         Türkçe arayüz (menü, HUD, ayarlar, joystick)
  dragon/                     Ejderha sistemleri arayüzleri (M3-M5 için hazır)
  utils/                      Prosedürel mesh + doku fabrikaları
shaders/                      sky, ocean, terrain, vegetation, rain, waterfall
tests/test_runner.gd          Headless otomatik testler
.github/workflows/            Android APK derleme otomasyonu
docs/                         Mimari dokümantasyonu
```

## Derleme (otomatik)

`.github/workflows/android-build.yml` her push'ta:

1. Godot 4.7.2 headless + export template'lerini kurar,
2. JDK 17 + Android SDK (platform-36, build-tools 36.1.0) kurar,
3. debug keystore üretir (gizli anahtar YOK, yalnızca yerel debug imza),
4. projeyi içe aktarır (`--import`),
5. otomatik testleri çalıştırır (`tests/test_runner.gd`),
6. `godot --headless --export-debug "Android"` ile **ARM64 APK** üretir,
7. APK'yı doğrular ve `DRAGON_REALMS_ANDROID_APK` artefaktı olarak yayınlar.

Ayrıca `v*` etiketlerinde otomatik **GitHub Release** oluşturulur.

## Lisanslar

Tüm kod ve prosedürel olarak üretilen varlıklar bu projenin bir parçasıdır.
Dış asset kullanılmadığından ek lisans yükümlülüğü yoktur; tüm dokular/modeller
çalışma zamanında deterministik tohumlarla üretilir (bkz. `scripts/utils/`).

Ayrıntılı dokümantasyon: `docs/` klasörü (PROJECT_ARCHITECTURE, WORLD_SYSTEM,
GRAPHICS_PIPELINE, ANDROID_BUILD, DEVELOPMENT_ROADMAP, CHANGELOG).
