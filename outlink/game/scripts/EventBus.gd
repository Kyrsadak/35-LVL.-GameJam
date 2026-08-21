# res://game/scripts/EventBus.gd
extends Node

## Глобальная шина событий для синхронизации всех систем игры.
## Все системы (Player / HUD / Camera / Audio / GameManager) общаются через сигналы.

# --- Player state ---
signal tether_broken(slingshot_impulse: Vector2, tension: float)   ## Игрок оторвал кабель (release)
signal socket_reached(socket_position: Vector2, progress_value: int) ## Стыковка с промежуточным оазисом
signal battery_changed(current: float, max_val: float)             ## Изменение автономности
signal tension_changed(tension: float)                             ## Натяжение [0..1]
signal player_died()                                               ## Игрок умер
signal player_respawned(position: Vector2)                         ## Игрок отреспавнился

# --- Level / game flow ---
signal level_completed()                                           ## Финальный оазис пройден
signal game_won()                                                  ## Все уровни пройдены
signal oasis_progress_changed(current: int, total: int)            ## Обновление счётчика "X/35"

# --- FX ---
signal request_camera_shake(strength: float, duration: float)      ## Запрос тряски камеры
signal request_hitstop(duration: float, scale: float)              ## Запрос hitstop (замедление времени)
signal request_flash(color: Color, duration: float)                ## Запрос вспышки экрана
