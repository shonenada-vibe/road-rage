extends RefCounted
class_name UIFont

const EMBEDDED_FONT_PATH := "res://assets/fonts/ArialUnicode.ttf"


static func create_default() -> Font:
	if ResourceLoader.exists(EMBEDDED_FONT_PATH):
		var embedded_font := load(EMBEDDED_FONT_PATH)
		if embedded_font is Font:
			return embedded_font

	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"PingFang SC",
		"Hiragino Sans GB",
		"Microsoft YaHei",
		"Noto Sans CJK SC",
		"Noto Sans SC",
		"Source Han Sans SC",
		"WenQuanYi Micro Hei",
		"STHeiti",
		"Arial Unicode MS",
		"sans-serif",
	])
	return font
