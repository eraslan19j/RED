# PROJECT_ARCHITECTURE — Mimari

## Motor ve Render

- **Motor:** Godot 4.7.2 stable (`config/features = ["4.7", "Mobile"]`)
- **Renderer:** `mobile` (Android'de Vulkan). Forward+ ve desktop-only
  efektler (SDFGI, volumetrik sis) mobilde mevcut değildir; yerine özel
  shader'lar ve klasik sis kullanılır.
- **Dil:** GDScript (performans kritik kısımlar C++ GDExtension'a ayrıldı; şu an
  gerek görülmedi).
- **Hedef:** Android ARM64, min SDK 24, target SDK 36, landscape, tam ekran.

## Üst Düzey Akış

```
main.tscn (Main, scripts/main.gd)
  ├── WorldManager (scripts/managers/world_manager.gd)
  │     ├── TerrainManager + TerrainChunk (quadtree LOD) + StreamingManager
  │     ├── BiomeManager
  │     ├── LightingManager + DayNightCycle (güneş/ay, gölgeler, sis, tonemap)
  │     ├── SkySystem (özel sky shader: fırtına bulutları, şimşek, yıldızlar)
  │     ├── Ocean (yakın/uzak katman, Gerstner dalgaları)
  │     ├── VegetationSystem (MultiMesh ağaç/kaya/çim, rüzgar)
  │     ├── WeatherManager (+ RainSystem, LightningSystem)
  │     └── EnvironmentManager (nehirler, göller, şelaleler, kalıntı, kale, mağara)
  ├── FreeCamera (scripts/player/free_camera.gd)
  └── UIRoot (Türkçe menü + HUD + ayarlar)
```

Autoload: `SettingsManager` (grafik presetleri LOW/MEDIUM/HIGH/ULTRA, adaptif
çözünürlük, kalıcı ayarlar `user://dragon_realms_ayarlar.cfg`).

## Tasarım İlkeleri

1. **Tek doğruluk kaynağı:** arazi yüksekliği yalnızca
   `TerrainManager.get_height(x, z)` üzerinden okunur. Okyanus kıyısı, bitki
   yerleşimi, şelale konumları ve (gelecekte) ejderha inişi bu fonksiyonu
   kullanır.
2. **Akış (streaming):** dünya tek parça yüklenmez; quadtree parçaları kamera
   etrafında yüklenir/boşaltılır (`StreamingManager` frame budget ile).
3. **Genişlemeye açık arayüzler:** `DragonController` / `DragonFlightPhysics`
   stub'ları M3-M5'te doldurulmak üzere sabit API sunar.
4. **Mobil öncelikli:** az draw call, MultiMesh bitki, tek-pass shader'lar,
   adaptif çözünürlük, MSAA kontrollü, PSSM gölgeler.
5. **Hata gizlenmez:** testler (`tests/test_runner.gd`) CI'da her derlemede
   çalışır; `SCRIPT ERROR` logu derlemeyi başarısız olarak işaretler.
