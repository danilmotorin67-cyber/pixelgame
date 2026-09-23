# Солёный свет / Saltlight

Пиксельная 2D-игра на Godot 4.4+ по спецификации «Солёный свет».

## Требования

- Godot 4.4 или новее (рекомендуется 4.7.x), рендерер Compatibility
- Python 3.10+ и Pillow (`pip install pillow`) для сборки `.pxl`
- Опционально numpy + soundfile для рендера музыки

## Запуск

```bash
cd <папка-проекта>
python3 tools/validate_data.py
python3 tools/pxl_build.py assets_src assets
godot --path .
```

Главная сцена: `scenes/main/boot.tscn` → титул → мыс.

Управление: WASD, E взаимодействие, F фонарь, ~ консоль (`time 19:30`, `money +500`, `give fish_cod 10`).

## Структура

См. `docs/DESIGN_NOTES.md` и раздел 33 спецификации.

Вехи: M0 каркас (текущая сборка) → M1 время/мир → … → M10 полировка.

## Экспорт

Открыть `export_presets.cfg` в редакторе. Пресеты: Windows, Linux, macOS.
