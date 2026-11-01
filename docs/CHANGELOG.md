# CHANGELOG — Değişiklik Günlüğü

## [0.1.0] - 2026-11-01 — Milestone 1: Dünya Ortamı

### Eklendi
- Godot 4.7.2 stable proje iskeleti (Mobile renderer, Vulkan, Android ARM64 preset)
- Prosedürel dünya: 8 ada, dağlar (ridged fBm), 3 nehir, 2 göl, şelaleler
- Quadtree LOD arazi parça sistemi + kamera takipli streaming (frame budget ile)
- İki katmanlı animasyonlu okyanus: Gerstner dalgaları, fresnel, güneş parıltısı,
  derinlik rengi, dalga tepesi ve kıyı köpüğü
- Özel sky shader'ı: 2 katmanlı hareketli fırtına bulutları, güneş/ay, gece
  yıldızları, şimşek aydınlatması
- Bitki örtüsü: çam/geniş yapraklı ağaç, kaya, çalı, çim (MultiMesh + rüzgar)
- Çevre yapıları: antik kalıntı, ana kale + uzak kale (yanan pencereler), mağaralar
- 7 hava durumu (Açık → Fırtına) yumuşak geçişli; yağmur (silindir shader) ve
  şimşek (cívata + flash) sistemleri
- Gün döngüsü (24 saat/480 sn), şafak/gündüz/akşam/gece paletleri, PSSM gölgeler
- Serbest kamera: çoklu dokunmatik joystick + bakış, klavye desteği
- Türkçe arayüz: ana menü, HUD (FPS/konum/saat/hava), ayarlar (4 kalite preset,
  çözünürlük ölçeği, gölgeler, bitki/yağmur yoğunluğu, titreşim)
- Adaptif çözünürlük (FPS tabanlı otomatik ölçekleme)
- Headless otomatik testler (`tests/test_runner.gd`)
- GitHub Actions: Godot 4.7.2 + SDK + template kurulumu, test, debug imzalı
  ARM64 APK dışa aktarımı, `DRAGON_REALMS_ANDROID_APK` artefaktı, `v*` release
- Ejderha sistemleri için arayüz stub'ları (`DragonController`, `DragonFlightPhysics`)

### Düzeltildi (CI iterasyonu, 2026-11-01)
- GDScript 4.7 uyumu: `append_primitive` parametresi `Mesh` olarak genişletildi;
  Variant'tan `:=` çıkarımı yapılan tüm noktalar açık tipe çevrildi
  (`debug/gdscript/warnings/inference_on_variant=1` ile INFERENCE_ON_VARIANT uyarıya indirildi)
- `shader_type sky` içinde geçersiz `render_mode sky` kaldırıldı; uniform sabit ifadeleri düzeltildi
- Godot 4.7 mesh API: tepe başına tangent artık `PackedFloat32Array` (4 float)
- `ImmediateMesh` Godot 4 API'sine çevrildi (`surface_begin/surface_add_vertex/surface_end`)
- `RainSystem`/`LightningSystem` başlatma sırası düzeltildi; UI çift `add_child` hatası giderildi
- CI: export template tpz yerleşimi düzeltildi; `android_source.zip` `res://android/build`
  içine kuruluyor, `.build_version = 4.7.2.stable`; `ANDROID_HOME` aynı adımda export edildi
- Sonuç: Actions workflow TAMAMI yeşil (13/13 adım), testler geçiyor,
  ARM64 APK üretildi ve `DRAGON_REALMS_ANDROID_APK` artefaktı yayınlandı (run 41304391092)

### Bilinen Sınırlamalar
- Tüm varlıklar prosedürel (dış asset yok) — M2'de CC0 asset entegrasyonu
- Ses yok — M2
- Ejderha yok — M3-M5
- Gölge atlas boyutu çalışma anında değiştirilemiyor (preset bazlı aç/kapa)
