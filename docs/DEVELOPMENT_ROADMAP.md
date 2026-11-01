# DEVELOPMENT_ROADMAP — Geliştirme Yol Haritası

## Milestone 1 (BU SÜRÜM) — Dünya Ortamı ✅
- Godot 4.7.2 projesi, mobil renderer, Android ARM64 APK otomasyonu
- Prosedürel ada/dağ/nehir/göl arazi + quadtree LOD + streaming
- Animasyonlu okyanus (Gerstner + fresnel + köpük + derinlik rengi)
- Dinamik fırtına gökyüzü (çok katmanlı bulutlar, şimşek, gece yıldızları)
- Ormanlar/bitki örtüsü (MultiMesh, rüzgar), şelaleler, kalıntılar, kale, mağaralar
- 7 hava durumu + gün döngüsü + şimşek/yağmur
- Serbest kamera (dokunmatik joystick + bakış), Türkçe arayüz, 4 kalite preset
- Adaptif çözünürlük, headless testler, GitHub Actions APK artefaktı

## Milestone 2 — Varlık Zenginliği ve Biyomlar
- Dış CC0/lisanslı asset entegrasyonu (Poly Haven, ambientCG, Kenney) — lisans
  doğrulamalı; yoksa prosedürel alternatif
- Daha fazla biyom (çöl, tundra, volkanik ada), yollar, köyler
- Su sıçraması ve yağmur-yer etkileşimi, sis sismi (height fog) iyileştirme
- Ses sistemi (müzik + ambiyans + gök gürültüsü)

## Milestone 3 — Ejderha Modeli ve Animasyon
- Yüksek kaliteli iskeletli ejderha (GLB) + kanat çırpma/iniş/yürüme animasyonları
- DragonAnimationController

## Milestone 4 — Uçuş Fiziği
- DragonFlightPhysics: aerodinamik (kaldırma/sürükleme), stall, alçalma, itki
- DragonAerodynamics, rüzgar ve hava durumu etkisi

## Milestone 5 — Binme ve Mobil Kontroller
- DragonMountSystem, DragonCamera ( chase + manuel), dokunmatik uçuş girdisi
- DragonInputController (joystick itki, kanat çırpma, fren)

## Milestone 6 — Açık Dünya Keşif
- Keşif noktaları, minimap, hızlı seyahat, DragonLandingSystem
- Iniş noktalari arazi sorgusuna bağlı

## Milestone 7 — Kale, Medeniyet ve Oynanış
- Yerleşimler, görevler, basit savaş (DragonCombatSystem)

## Milestone 8 — Optimizasyon ve Final Kalite
- Profil tabanlı optimizasyon, 90/120 FPS modu, termal yönetim,
  release imzalama (keystore dışarıda), Play Store hazırlığı
