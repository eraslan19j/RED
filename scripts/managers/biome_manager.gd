class_name BiomeManager
extends Node3D
## BiomeManager - yükseklik, eğim, nem ve enlemden biyom belirler.
## Arazi boyama (splat) ve bitki dağılımı bu veriyi kullanır.

enum Biome { OCEAN, BEACH, GRASSLAND, FOREST, ROCK, SNOW }
const BIOME_NAMES := ["Okyanus", "Plaj", "Çayır", "Orman", "Kaya", "Kar"]

var noise_moisture: FastNoiseLite
var world_manager: WorldManager

func initialize(p_wm: WorldManager) -> void:
	world_manager = p_wm
	noise_moisture = FastNoiseLite.new()
	noise_moisture.seed = 9917
	noise_moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_moisture.frequency = 0.0011
	noise_moisture.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_moisture.fractal_octaves = 3

## Nem (0..1) - orman dağılımı için
func get_moisture(x: float, z: float) -> float:
	return noise_moisture.get_noise_2d(x, z) * 0.5 + 0.5

## Sıcaklık: enleme (z) ve yüksekliğe göre (0..1)
func get_temperature(x: float, z: float, height: float) -> float:
	var lat := clampf(1.0 - abs(z) / GameConstants.WORLD_HALF, 0.0, 1.0)
	return clampf(lat * 0.7 + 0.3 - height / 500.0, 0.0, 1.0)

func get_biome(x: float, z: float, height: float, slope: float) -> Dictionary:
	if height < 0.6:
		return {"type": Biome.OCEAN, "name": BIOME_NAMES[Biome.OCEAN]}
	if height < 3.6:
		return {"type": Biome.BEACH, "name": BIOME_NAMES[Biome.BEACH]}
	if height > 150.0:
		return {"type": Biome.SNOW, "name": BIOME_NAMES[Biome.SNOW]}
	if slope > 0.75:
		return {"type": Biome.ROCK, "name": BIOME_NAMES[Biome.ROCK]}
	var moisture := get_moisture(x, z)
	if moisture > 0.42 and height < 120.0:
		return {"type": Biome.FOREST, "name": BIOME_NAMES[Biome.FOREST]}
	return {"type": Biome.GRASSLAND, "name": BIOME_NAMES[Biome.GRASSLAND]}
