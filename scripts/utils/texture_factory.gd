class_name TextureFactory
extends RefCounted
## Çalışma zamanında üretilen dokular (PBR-doku setleri, gürültü, yükseklik haritası).
## Bu yaklaşım sayesinde depoya binary asset koymaya gerek kalmaz; tüm dokular
## deterministik tohumlarla üretilir ve lisans sorunu yaşanmaz (CC0 eşdeğeri, dahili üretim).

## Periyodik (dikişsiz / tileable) değer gürültüsü üretir.
## Sinüs toplamı kullanıldığı için doku kenarları otomatik olarak uyuşur.
static func make_tileable_noise(p_size: int, p_seed: int, p_octaves: int = 4, p_base_freq: int = 3) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	var img := Image.create(p_size, p_size, false, Image.FORMAT_RF)
	for oct in range(p_octaves):
		var freq := p_base_freq * (1 << oct)
		var amp := pow(0.5, float(oct))
		var harmonics: Array = []
		var total_amp := 0.0
		for h in range(3):
			var fx := rng.randi_range(0, freq)
			var fy := rng.randi_range(0, freq)
			var phase := rng.randf_range(0.0, TAU)
			var a := amp * rng.randf_range(0.5, 1.0)
			harmonics.append([fx, fy, phase, a])
			total_amp += a
		for y in range(p_size):
			for x in range(p_size):
				var v := img.get_pixel(x, y).r
				var nx := float(x) / float(p_size)
				var ny := float(y) / float(p_size)
				for h in harmonics:
					v += sin(TAU * (float(h[0]) * nx + float(h[1]) * ny) + float(h[2])) * float(h[3])
				img.set_pixel(x, y, Color(v / total_amp * 0.5 + 0.5, 0, 0, 1))
	return img

## Gürültü dokusundan (tek kanal) detaylı bir albedo dokusu üretir.
static func make_detail_albedo(p_size: int, p_seed: int, p_base: Color, p_variation: Color, p_contrast: float = 0.35) -> ImageTexture:
	var noise := make_tileable_noise(p_size, p_seed, 5, 2)
	var img := Image.create(p_size, p_size, false, Image.FORMAT_RGBA8)
	for y in range(p_size):
		for x in range(p_size):
			var n := noise.get_pixel(x, y).r
			var n2 := noise.get_pixel((x * 2 + 37) % p_size, (y * 2 + 11) % p_size).r
			var t := clamp(n * 0.7 + n2 * 0.3, 0.0, 1.0)
			var c := p_base.lerp(p_variation, t * p_contrast + (n - 0.5) * 0.7)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

## Yükseklik görselinden (RF) kabartma/normal haritası üretir (Sobel).
static func make_normal_map_from_height(p_height: Image, p_strength: float = 2.0) -> ImageTexture:
	var w := p_height.get_width()
	var h := p_height.get_height()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var xl := p_height.get_pixel((x - 1 + w) % w, y).r
			var xr := p_height.get_pixel((x + 1) % w, y).r
			var yd := p_height.get_pixel(x, (y - 1 + h) % h).r
			var yu := p_height.get_pixel(x, (y + 1) % h).r
			var dx := (xl - xr) * p_strength
			var dy := (yd - yu) * p_strength
			var n := Vector3(dx, dy, 1.0).normalized()
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
	return ImageTexture.create_from_image(img)

## Çim kartı dokusu: alpha kanallı, dikey çim yaprakları.
static func make_grass_card(p_size: int = 128, p_seed: int = 7) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	var img := Image.create(p_size, p_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var blades := 46
	for b in range(blades):
		var x0 := rng.randf_range(0.02, 0.98) * p_size
		var w := rng.randf_range(1.5, 3.5)
		var lean := rng.randf_range(-0.25, 0.25) * p_size
		var h := rng.randf_range(0.55, 1.0) * p_size
		var c := Color(0.16, 0.32, 0.10).lerp(Color(0.42, 0.58, 0.20), rng.randf())
		for y in range(int(h)):
			var t := float(y) / h
			var x := x0 + lean * t
			var half := w * (1.0 - t * 0.8) * 0.5
			for xx in range(int(x - half), int(x + half) + 1):
				if xx >= 0 and xx < p_size and y < p_size:
					img.set_pixel(xx, p_size - 1 - y, Color(c.r, c.g, c.b, 1.0))
	return ImageTexture.create_from_image(img)

## Fern/foam dokusu: beyaz gürültü lekeleri (köpük, serpinti).
static func make_foam_texture(p_size: int = 256, p_seed: int = 21) -> ImageTexture:
	var noise := make_tileable_noise(p_size, p_seed, 5, 2)
	var img := Image.create(p_size, p_size, false, Image.FORMAT_RGBA8)
	for y in range(p_size):
		for x in range(p_size):
			var n := noise.get_pixel(x, y).r
			var n2 := noise.get_pixel((x * 3 + 91) % p_size, (y * 3 + 57) % p_size).r
			var v := clamp((n * 0.65 + n2 * 0.35 - 0.52) * 4.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v, v))
	return ImageTexture.create_from_image(img)

## Dünya yükseklik haritasını RF dokusuna çevirir (okyanus kıyı derinliği için).
## p_height_fn: func(x: float, z: float) -> float
static func make_heightmap_texture(p_res: int, p_world_size: float, p_height_fn: Callable, p_min_h: float, p_max_h: float) -> ImageTexture:
	var img := Image.create(p_res, p_res, false, Image.FORMAT_RF)
	var range_h := p_max_h - p_min_h
	for y in range(p_res):
		for x in range(p_res):
			var wx := (float(x) / float(p_res - 1) - 0.5) * p_world_size
			var wz := (float(y) / float(p_res - 1) - 0.5) * p_world_size
			var h := p_height_fn.call(wx, wz)
			img.set_pixel(x, y, Color(clamp((h - p_min_h) / range_h, 0.0, 1.0), 0, 0, 1))
	return ImageTexture.create_from_image(img)

## Basit dikey degrade (su şelalesi / sis) dokusu.
static func make_streak_texture(p_size: int = 128, p_seed: int = 33) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	var img := Image.create(p_size, p_size, false, Image.FORMAT_RGBA8)
	for x in range(p_size):
		var col := rng.randf()
		for y in range(p_size):
			var v := clamp(col * 1.4 - 0.25 + sin(float(y) * 0.7 + col * 40.0) * 0.08, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v, v))
	return ImageTexture.create_from_image(img)
