# WORLD_SYSTEM — Dünya Sistemi

## Arazi (TerrainManager + TerrainChunk)

- Dünya 6000×6000 m kare, merkez (0,0). Deniz seviyesi y=0.
- **Adalar:** 8 ada merkezi (ana kita + 5 büyük ada + 3 küçük ada);
  yükseklik ada maskesi (smoothstep) ile karışır.
- **Dağlar:** ridged fBm gürültüsü, ada pik yüksekliği ile ölçeklenir (ana
  kitada ~420 m'ye kadar çıkar). Kar çizgisi ~150 m.
- **Nehirler:** 3 nehir yolu; nehre olan mesafe 256×256 önceden hesaplanan bir
  grid üzerinden O(1) sorgulanır ve arazi oyulur. Nehirler denize şelale ile dökülür.
- **Göller:** 2 çöküntü havzası + su diski.
- **Quadtree LOD:** kök parça 6000 m; kamera `size * 1.15` mesafesindeyken
  parça 4'e bölünür (en küçük 375 m). Parça başına tepe yoğunluğu
  `TARGET_CELL_SIZE = 5 m` hedefiyle 8..64 arası ölçeklenir. Normal ve tangent
  CPU'da finite-difference ile hesaplanır (detay normal haritası için).
- **Streaming:** `StreamingManager` her 0.2 sn quadtree'yi günceller ve kare
  başına en fazla 2 parça inşa eder (hit-free deneyim).

## Biyomlar (BiomeManager)

Okyanus, Plaj, Çayır, Orman, Kaya, Kar — yükseklik, eğim, nem ve enlem
(z ekseni) ile belirlenir. Arazi splat'ı ve bitki dağılımı bu veriyi kullanır.

## Okyanus (Ocean + shaders/ocean.gdshader)

- Yakın alan 500×500 m, 128×128 segment; kamerayı 4 m'lik ızgaraya yaslı takip
  eder (doku kayması önlenir). Uzak alan 18000×18000 m, dalgalar yumuşar.
- Vertex'te 4 Gerstner dalgası (yön, dalga boyu, diklik) + analitik normal.
- Fragment'te 2 kayan detay normal katmanı, Schlick fresnel, güneş speküler
  parıltısı, derinlik rengi (dünya yükseklik haritası dokusundan), dalga
  tepesi + kıyı köpüğü (foam dokusu).

## Gökyüzü (SkySystem + shaders/sky.gdshader)

- Özel `sky` shader'ı: atmosferik degrade (zenit/ufuk), güneş/ay diski ve
  parıltı, 2 katmanlı domain-warped fBm fırtına bulutları (dikişsiz üretilen
  gürültü dokusu ile), gece yıldızları, şimşek flaşı.
- Bulut kaplama/koyuluk/hız WeatherManager tarafından sürülür.

## Bitki Örtüsü (VegetationSystem)

- Parça başına MultiMeshInstance3D: çam, geniş yapraklı ağaç, kaya/çalı
  (birleşik "scatter" mesh), çim kartları (yalnızca yakında).
- Rüzgar: vertex shader'da `COLOR.a` yükseklik maskesi ile salınım; hava
  durumuna göre değişir.
- Yoğunluk, parça uzaklığına (LOD) ve kalite presetine göre ölçeklenir.

## Çevre Yapıları (EnvironmentManager)

- Nehir su şeritleri, göl diskleri, şelale kuadları + havuzlar (nehrin denize
  döküldüğü noktalarda), antik kalıntı (kırık sütunlar), ana kale + uzak ada
  kalesi (pencereler gece yanar), sahil mağara ağızları.

## Hava Durumu ve Zaman (WeatherManager, DayNightCycle, LightingManager)

- 7 hava durumu: Açık, Bulutlu, Yoğun Bulutlu, Yağmurlu, Gök Gürültülü
  Fırtına, Sisli, Fırtına. 6 sn'lik yumuşak geçişle hedef duruma yaklaşılır;
  otomatik rastgele değişim 60-140 sn'de bir.
- Yağmur: kamerayı saran silindir shader (tek draw call); ıslaklık arazi ve
  okyanusa yansır. Şimşek: jagged cıvata çizgisi + gökyüzü/okyanus flaşı.
- Zaman: 24 saat = 480 sn (milestone hızı). Güneş konumu, renk paleti
  (şafak/gündüz/akşam/gece), ay ışığı, sis rengi ve gölge senkronize edilir.
