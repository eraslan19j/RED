class_name UIRoot
extends CanvasLayer
## UIRoot - tüm oyun arayüzü (Türkçe): ana menü, HUD ve ayarlar paneli.
## Dokunmatik ekranlar için tasarlandı; fare ile de kullanılabilir.

signal play_pressed
signal quit_pressed
signal menu_requested
signal weather_cycle_pressed
signal time_plus_pressed
signal time_minus_pressed

var menu_panel: PanelContainer
var hud: Control
var settings_panel: PanelContainer
var fps_label: Label
var pos_label: Label
var time_label: Label
var weather_label: Label
var chunk_label: Label
var joystick: Joystick
var quality_option: OptionButton
var res_slider: HSlider
var res_value: Label
var shadows_check: CheckBox
var veg_slider: HSlider
var rain_slider: HSlider
var vib_check: CheckBox
var adaptive_check: CheckBox
var _fly_dir := 0.0

func _ready() -> void:
	layer = 10
	_build_menu()
	_build_hud()
	_build_settings()
	show_menu()

func _style_button(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 26)
	b.custom_minimum_size = Vector2(280, 64)

func _build_menu() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	menu_panel = PanelContainer.new()
	center.add_child(menu_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	menu_panel.add_child(vb)
	var title := Label.new()
	title.text = "DRAGON REALMS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35))
	vb.add_child(title)
	var sub := Label.new()
	sub.text = "Ejderha Diyarları - Açık Dünya Keşif Sürümü"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	vb.add_child(sub)
	var play := Button.new()
	play.text = "Oyuna Başla"
	_style_button(play)
	play.pressed.connect(_on_play_pressed)
	vb.add_child(play)
	var settings := Button.new()
	settings.text = "Ayarlar"
	_style_button(settings)
	settings.pressed.connect(show_settings)
	vb.add_child(settings)
	var quit_b := Button.new()
	quit_b.text = "Çıkış"
	_style_button(quit_b)
	quit_b.pressed.connect(_on_quit_pressed)
	vb.add_child(quit_b)

func _on_play_pressed() -> void:
	play_pressed.emit()

func _on_quit_pressed() -> void:
	quit_pressed.emit()

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.visible = false
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)

	# üst-sol bilgi paneli
	var info := PanelContainer.new()
	info.set_anchors_preset(Control.PRESET_TOP_LEFT)
	info.position = Vector2(16, 16)
	hud.add_child(info)
	var iv := VBoxContainer.new()
	info.add_child(iv)
	fps_label = _mk_label(iv, "FPS: --")
	pos_label = _mk_label(iv, "Konum: --")
	time_label = _mk_label(iv, "Saat: --:--")
	weather_label = _mk_label(iv, "Hava: --")
	chunk_label = _mk_label(iv, "Arazi Parçası: --")

	# üst-sağ düğmeler
	var btns := HBoxContainer.new()
	btns.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btns.anchor_left = 1.0
	btns.anchor_right = 1.0
	btns.offset_left = -16
	btns.offset_top = 16
	btns.alignment = BoxContainer.ALIGNMENT_END
	btns.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hud.add_child(btns)
	_mk_btn(btns, "Hava Durumu", _on_weather_pressed)
	_mk_btn(btns, "Saat +1", _on_time_plus)
	_mk_btn(btns, "Saat -1", _on_time_minus)
	_mk_btn(btns, "Ayarlar", show_settings)
	_mk_btn(btns, "Menü", _on_menu_pressed)

	# sol alt joystick
	joystick = Joystick.new()
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 60
	joystick.offset_top = -220
	joystick.offset_bottom = -60
	hud.add_child(joystick)

	# joystick yanı kalkış/iniş düğmeleri (basılı tut)
	var fly_box := VBoxContainer.new()
	fly_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	fly_box.anchor_top = 1.0
	fly_box.anchor_bottom = 1.0
	fly_box.offset_left = 260
	fly_box.offset_top = -200
	fly_box.offset_bottom = -80
	hud.add_child(fly_box)
	var up_b := Button.new()
	up_b.text = "Yukarı"
	up_b.add_theme_font_size_override("font_size", 20)
	up_b.custom_minimum_size = Vector2(140, 52)
	up_b.button_down.connect(_on_fly_up)
	up_b.button_up.connect(_on_fly_stop)
	fly_box.add_child(up_b)
	var down_b := Button.new()
	down_b.text = "Aşağı"
	down_b.add_theme_font_size_override("font_size", 20)
	down_b.custom_minimum_size = Vector2(140, 52)
	down_b.button_down.connect(_on_fly_down)
	down_b.button_up.connect(_on_fly_stop)
	fly_box.add_child(down_b)

	# sağ alt ipucu
	var hint := Label.new()
	hint.text = "Sol taraf: hareket joystick'i   |   Sağ taraf: sürükleyerek bak"
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 0.8))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.offset_left = -900
	hint.offset_top = -56
	hud.add_child(hint)

func _on_weather_pressed() -> void:
	weather_cycle_pressed.emit()

func _on_time_plus() -> void:
	time_plus_pressed.emit()

func _on_time_minus() -> void:
	time_minus_pressed.emit()

func _on_menu_pressed() -> void:
	menu_requested.emit()

func _on_fly_up() -> void:
	_fly_dir = 1.0

func _on_fly_down() -> void:
	_fly_dir = -1.0

func _on_fly_stop() -> void:
	_fly_dir = 0.0

func _mk_label(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 22)
	parent.add_child(l)
	return l

func _mk_btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 20)
	b.custom_minimum_size = Vector2(0, 52)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _build_settings() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.custom_minimum_size = Vector2(640, 0)
	settings_panel.visible = false
	add_child(settings_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	settings_panel.add_child(vb)
	var title := Label.new()
	title.text = "Ayarlar"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	vb.add_child(title)

	# grafik kalitesi
	var qrow := HBoxContainer.new()
	vb.add_child(qrow)
	_mk_label(qrow, "Grafik Kalitesi:")
	quality_option = OptionButton.new()
	for n in DRSettings.QUALITY_NAMES:
		quality_option.add_item(n)
	quality_option.selected = DRSettings.get_instance().quality
	quality_option.item_selected.connect(_on_quality_selected)
	qrow.add_child(quality_option)

	# çözünürlük ölçeği
	var rrow := HBoxContainer.new()
	vb.add_child(rrow)
	_mk_label(rrow, "Çözünürlük Ölçeği:")
	res_slider = HSlider.new()
	res_slider.min_value = 0.5
	res_slider.max_value = 1.0
	res_slider.step = 0.05
	res_slider.value = DRSettings.get_instance().resolution_scale
	res_slider.custom_minimum_size = Vector2(280, 0)
	res_slider.value_changed.connect(_on_res_changed)
	res_value = _mk_label(rrow, "")
	_update_res_label()
	res_slider.value_changed.connect(_on_res_label_only)
	rrow.add_child(res_slider)

	shadows_check = CheckBox.new()
	shadows_check.text = "Gölgeler açık"
	shadows_check.button_pressed = DRSettings.get_instance().shadows_enabled
	shadows_check.toggled.connect(_on_shadows_toggled)
	vb.add_child(shadows_check)

	var vrow := HBoxContainer.new()
	vb.add_child(vrow)
	_mk_label(vrow, "Bitki Yoğunluğu:")
	veg_slider = HSlider.new()
	veg_slider.min_value = 0.2
	veg_slider.max_value = 1.5
	veg_slider.step = 0.05
	veg_slider.value = DRSettings.get_instance().vegetation_density
	veg_slider.custom_minimum_size = Vector2(280, 0)
	veg_slider.value_changed.connect(_on_veg_changed)
	vrow.add_child(veg_slider)

	var r2row := HBoxContainer.new()
	vb.add_child(r2row)
	_mk_label(r2row, "Yağmur Yoğunluğu:")
	rain_slider = HSlider.new()
	rain_slider.min_value = 0.3
	rain_slider.max_value = 1.0
	rain_slider.step = 0.05
	rain_slider.value = DRSettings.get_instance().rain_quality
	rain_slider.custom_minimum_size = Vector2(280, 0)
	rain_slider.value_changed.connect(_on_rain_changed)
	r2row.add_child(rain_slider)

	vib_check = CheckBox.new()
	vib_check.text = "Titreşim açık"
	vib_check.button_pressed = DRSettings.get_instance().vibration
	vib_check.toggled.connect(_on_vib_toggled)
	vb.add_child(vib_check)

	adaptive_check = CheckBox.new()
	adaptive_check.text = "Adaptif çözünürlük (FPS'e göre otomatik ölçek)"
	adaptive_check.button_pressed = DRSettings.get_instance().adaptive_resolution
	adaptive_check.toggled.connect(_on_adaptive_toggled)
	vb.add_child(adaptive_check)

	var back := Button.new()
	back.text = "Geri"
	back.add_theme_font_size_override("font_size", 26)
	back.custom_minimum_size = Vector2(200, 60)
	back.pressed.connect(hide_settings)
	vb.add_child(back)

func _on_quality_selected(i: int) -> void:
	DRSettings.get_instance().set_quality(i)

func _on_res_changed(v: float) -> void:
	DRSettings.get_instance().resolution_scale = v
	DRSettings.get_instance()._adaptive_scale = v
	DRSettings.get_instance().apply()
	DRSettings.get_instance().save_settings()

func _on_res_label_only(_v: float) -> void:
	_update_res_label()

func _on_shadows_toggled(v: bool) -> void:
	DRSettings.get_instance().shadows_enabled = v
	DRSettings.get_instance().apply()
	DRSettings.get_instance().save_settings()

func _on_veg_changed(v: float) -> void:
	DRSettings.get_instance().vegetation_density = v
	DRSettings.get_instance().save_settings()

func _on_rain_changed(v: float) -> void:
	DRSettings.get_instance().rain_quality = v
	DRSettings.get_instance().save_settings()

func _on_vib_toggled(v: bool) -> void:
	DRSettings.get_instance().vibration = v
	DRSettings.get_instance().save_settings()

func _on_adaptive_toggled(v: bool) -> void:
	DRSettings.get_instance().adaptive_resolution = v
	DRSettings.get_instance().save_settings()

func _update_res_label() -> void:
	if res_value and res_slider:
		res_value.text = "%d%%" % int(res_slider.value * 100.0)

func show_menu() -> void:
	menu_panel.visible = true
	hud.visible = false

func show_game() -> void:
	menu_panel.visible = false
	hud.visible = true
	settings_panel.visible = false

func show_settings() -> void:
	settings_panel.visible = true
	settings_panel.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 - 340, 60)

func hide_settings() -> void:
	settings_panel.visible = false

func update_hud(fps: int, pos: Vector3, hour: float, weather_name: String, chunks: int, joystick_value: Vector2) -> void:
	if fps_label == null:
		return
	fps_label.text = "FPS: %d" % fps
	pos_label.text = "Konum: X %.0f  Z %.0f  Y %.0f" % [pos.x, pos.z, pos.y]
	var hh := int(hour)
	var mm := int((hour - hh) * 60.0)
	time_label.text = "Saat: %02d:%02d" % [hh, mm]
	weather_label.text = "Hava: %s" % weather_name
	chunk_label.text = "Arazi Parçası: %d" % chunks
	joystick.set_value(joystick_value)

func get_fly_input() -> float:
	return _fly_dir
