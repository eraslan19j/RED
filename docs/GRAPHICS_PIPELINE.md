# GRAPHICS_PIPELINE — Grafik hattı

## Render Ayarları (project.godot)

- `renderer/rendering_method = "mobile"` → Android'de **Vulkan**.
- `textures/vram_compression/import_etc2_astc = true` (ETC2/ASTC mobil VRAM sıkıştırma).
- MSAA 3D varsayılan 2x (kalite presetine göre 0/2x/4x).
- Directional shadow atlas 4096; güneş ışığı **PSSM 4 split** (cascade) gölge.
- Tonemap **AgX**, pozlama 1.05, glow (HIGH/ULTRA'da açık).
- Sis: exponential + aerial perspective + hafif yükseklik sisi (mobil uyumlu,
  volumetrik sis yerine).

## Materyaller

Tüm dokular çalışma zamanında üretilir (`TextureFactory`): dikişsiz (tileable)
fBm gürültü, biyom dokuları (kum/çim/kaya/kar), detay normal haritası, çim kartı,
köpük dokusu, şelale çizgisi. Bu sayede binary asset / lisans sorunu yoktur.

- **Arazi:** özel spatial shader — yükseklik+eğim+gürültü splat (4 katman),
  detay albedo + detay normal, ıslaklık (yağmurda koyulaşma + parlaklık).
- **Okyanus:** bkz. WORLD_SYSTEM. Fresnel + derinlik rengi + köpük + speküler.
- **Bitki:** özel shader, rüzgar salınımı (yükseklik maskeli), MultiMesh
  örnek renkleri, çim kartlarında alpha kesme (discard → mobil uyumlu).
- **Şelale/yağmur:** hafif unshaded şeffaf shader'lar.

## Kalite Presetleri (SettingsManager)

| Preset | Çözünürlük ölçeği | MSAA | Gölge | Bitki | Yağmur |
|---|---|---|---|---|---|
| Düşük | %60 | kapalı | kapalı | %35 | %50 |
| Orta | %75 | 2x | 700 m, 2 split | %60 | %70 |
| Yüksek | %85 | 2x | 1600 m, 4 split | %100 | %100 |
| Ultra | %100 | 4x | 2600 m, 4 split | %100 | %100 |

- **Adaptif çözünürlük:** 2 sn'lik FPS ortalaması < 50 ise ölçek %5 düşer
  (en az %50), > 58 ise preset hedefine yaklaşır (`viewport.scaling_3d_scale`).
- Ayarlar `user://dragon_realms_ayarlar.cfg` içinde kalıcı saklanır.

## Performans Hedefleri

- Birincil hedef **60 FPS** (Dimensity 8400 Ultra), 90/120 FPS uygunsa.
- Draw call hedefi < ~200 (quadtree yaprak sayısı ~15-18 + bitki multimesh'leri
  + yapılar + 2 okyanus katmanı).
- Termal: adaptif çözünürlük + preset sınırlaması ile kontrol edilir.
