class_name GameConstants
extends RefCounted
## Dragon Realms - global sabitler (dünya ölçeği, katmanlar)
## Not: Kod tanımlayıcıları İngilizce kalır; kullanıcıya dönük tüm metinler Türkçedir.

# --- Dünya ölçeği ---
const WORLD_SIZE := 6000.0          ## Kare dünya boyutu (metre), merkez (0,0)
const WORLD_HALF := 3000.0
const SEA_LEVEL := 0.0
const MIN_CHUNK_SIZE := 375.0       ## Quadtree'nin bölüneceği en küçük parça
const SPLIT_FACTOR := 1.15          ## Parça merkezine uzaklık < size * SPLIT_FACTOR ise bölünür
const MAX_CHUNK_VERTEX_DENSITY := 64 ## Bir kenardaki en fazla tepe noktası sayısı
const TARGET_CELL_SIZE := 5.0       ## Hedef hücre boyutu (metre)

# --- Okyanus ---
const OCEAN_NEAR_SIZE := 500.0      ## Kamerayı izleyen detaylı su alanı
const OCEAN_NEAR_SEGMENTS := 128
const OCEAN_FAR_SIZE := 18000.0     ## Ufuk su alanı
const OCEAN_FAR_SEGMENTS := 24
const HEIGHTMAP_TEXTURE_RES := 256  ## Kıyı derinliği için yükseklik dokusu çözünürlüğü

# --- Kamera ---
const CAMERA_FOV := 70.0
const CAMERA_NEAR := 0.15
const CAMERA_FAR := 20000.0
const CAM_MIN_HEIGHT_ABOVE_TERRAIN := 1.6
const CAM_MIN_HEIGHT_ABOVE_SEA := 1.2
const CAM_DEFAULT_SPEED := 45.0
const CAM_FAST_SPEED := 180.0
const CAM_LOOK_SPEED := 0.0042      ## Dokunmatik bakış hassasiyeti (radyan/piksel)

# --- Zaman ---
const DAY_LENGTH_SECONDS := 480.0   ## 24 saat = 8 dakika (milestone demo hızı)
const START_TIME := 10.0            ## Başlangıç saati (10:00)

# --- Depolama ---
const SETTINGS_PATH := "user://dragon_realms_ayarlar.cfg"

# --- Katmanlar (ileride ejderha ve yapay zeka için ayrıldı) ---
const LAYER_TERRAIN := 1
const LAYER_WATER := 2
const LAYER_VEGETATION := 3
const LAYER_STRUCTURES := 4
const LAYER_PLAYER := 5
