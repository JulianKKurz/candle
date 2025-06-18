import random
import math
from collections import deque
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib.patches import Rectangle

# =============================================================
# 0) GLOBALS & CONSTANTS
# =============================================================

# <<< Setze hier deine echten 750-Werte ein >>>
pixel_values = list(range(256))


TOTAL_LENGTH     = len(pixel_values)
CROSSFADE_LENGTH = 50          # Länge des Übergangs (Samples)
FPS              = 25
INTERVAL_MS      = 1000 / FPS
HISTORY_LENGTH   = TOTAL_LENGTH

# -------------------------------------------------------------
# 1) WELL512 RNG – unverändert
# -------------------------------------------------------------
class Well512:
    def __init__(self):
        self.state = [random.getrandbits(32) for _ in range(16)]
        self.index = 0
    def rand(self):
        a = self.state[self.index]
        c = self.state[(self.index + 13) & 15]
        b = a ^ c ^ ((a << 16) & 0xFFFFFFFF) ^ ((c << 15) & 0xFFFFFFFF)
        c = self.state[(self.index + 9) & 15]
        c ^= (c >> 11)
        self.state[self.index] = b ^ c
        a = self.state[self.index]
        d = a ^ ((a << 5) & 0xDA442D24)
        self.index = (self.index + 15) & 15
        self.state[self.index] ^= d
        return self.state[self.index] & 0xFFFFFFFF

well = Well512()

# -------------------------------------------------------------
# 2) CLIP-LOGIK
# -------------------------------------------------------------
current_clip = None
next_clip    = None
clip_changed = False
cutter_initialized = False

def create_new_clip_coords():
    min_in  = 0
    max_in  = TOTAL_LENGTH - 2 * CROSSFADE_LENGTH - 2
    in_pt   = min_in + (well.rand() % (max_in - min_in + 1))

    min_out = in_pt + 2 * CROSSFADE_LENGTH + 1
    max_out = TOTAL_LENGTH - 1
    out_pt  = min_out + (well.rand() % (max_out - min_out + 1))

    return {
        'in_point'            : in_pt,
        'crossfade_in_end'    : in_pt + CROSSFADE_LENGTH,
        'crossfade_out_begin' : out_pt - CROSSFADE_LENGTH,
        'out_point'           : out_pt,
        'frame_counter'       : in_pt,          # globaler Frame-Index
    }

def init_cutter():
    global current_clip, next_clip, cutter_initialized
    current_clip = create_new_clip_coords()
    next_clip    = create_new_clip_coords()
    cutter_initialized = True

def crossfade(pos, v_out, v_in, length_):
    w_in  = 0.5 * (1 - math.cos(math.pi * pos / length_))
    w_out = 1.0 - w_in
    return w_out * v_out + w_in * v_in

def get_next_pixel():
    """
    Liefert (frame_idx, pixel, second_play) – letzteres ist
    None außerhalb des Crossfades, sonst (idx, value) des
    synchronen Frames im nächsten Clip.
    """
    global current_clip, next_clip, clip_changed, cutter_initialized

    if not cutter_initialized:
        init_cutter()

    clip_changed = False
    frame = current_clip['frame_counter']

    # 1) Normaler Bereich
    if frame < current_clip['crossfade_out_begin']:
        px = pixel_values[frame]
        second_play = None
    else:
        # 2) Crossfade-Bereich
        cf_frame   = frame - current_clip['crossfade_out_begin']   # 0…49
        pixel_out  = pixel_values[frame]
        pixel_in   = pixel_values[next_clip['in_point'] + cf_frame]
        px         = crossfade(cf_frame, pixel_out, pixel_in, CROSSFADE_LENGTH)

        # -- parallelen play-Pointer für den nächsten Clip vorbereiten
        next_idx   = next_clip['in_point'] + cf_frame
        second_play = (next_idx, pixel_in)

        # Counter des nächsten Clips mitführen
        next_clip['frame_counter'] = next_idx + 1

    # 3) Frame-Zähler hochzählen & Clipwechsel prüfen
    current_clip['frame_counter'] += 1
    if current_clip['frame_counter'] > current_clip['out_point']:
        current_clip, next_clip = next_clip, create_new_clip_coords()
        clip_changed = True

    return frame, px, second_play

# -------------------------------------------------------------
# 3) VISUALISIERUNG
# -------------------------------------------------------------
fig, (ax_cur, ax_next, ax_hist) = plt.subplots(3, 1, figsize=(9, 8))

for ax in (ax_cur, ax_next):
    ax.plot(range(TOTAL_LENGTH), pixel_values, color='lightgray')
    ax.set_xlim(0, TOTAL_LENGTH)
    ax.set_ylim(0, 260)
    ax.set_ylabel("Pixelwert")

ax_cur.set_title("Aktueller Clipverlauf")
ax_next.set_title("Nächster Clipverlauf")

ax_hist.set_xlim(0, HISTORY_LENGTH)
ax_hist.set_ylim(0, 260)
ax_hist.set_title("Verlauf von play(pixel_value)")
ax_hist.set_xlabel("Frames")
ax_hist.set_ylabel("Pixelwert")

history_line, = ax_hist.plot([], [], 'r-')

# ---------- Marker-Hilfen ----------
def _dot(ax, c): return ax.plot([], [], 'o', color=c)[0]
def _txt(ax, c): return ax.text(0, 0, '', color=c, ha='center', fontsize=8)

mk_keys  = ['in_point', 'crossfade_in_end', 'crossfade_out_begin', 'out_point']
mk_color = {'in_point':'green', 'crossfade_in_end':'green',
            'crossfade_out_begin':'purple', 'out_point':'purple'}

cur_mk  = {k: (_dot(ax_cur,  mk_color[k]), _txt(ax_cur,  mk_color[k])) for k in mk_keys}
next_mk = {k: (_dot(ax_next, mk_color[k]), _txt(ax_next, mk_color[k])) for k in mk_keys}

play_dot_cur   = _dot(ax_cur,  'red')
play_text_cur  = _txt(ax_cur,  'red')
play_dot_next  = _dot(ax_next, 'red')
play_text_next = _txt(ax_next, 'red')

cur_rect  = None
next_rect = None

def _place(markers, clip, prefix):
    for k, (pt, lbl) in markers.items():
        idx = clip[k]
        val = pixel_values[idx]
        pt.set_data([idx], [val])
        offset = 15 if k in ('in_point', 'crossfade_out_begin') else -20
        lbl.set_position((idx, val + offset))
        lbl.set_text(f"{prefix}{k}")

def _draw_rects():
    global cur_rect, next_rect
    for r in (cur_rect, next_rect):
        if r: r.remove()

    y0, y1 = ax_cur.get_ylim()
    cur_rect = ax_cur.add_patch(Rectangle(
        (current_clip['crossfade_out_begin'], y0 + 5),
        current_clip['out_point'] - current_clip['crossfade_out_begin'],
        y1 - y0 - 10, color='orange', alpha=0.2, animated=True))

    y0, y1 = ax_next.get_ylim()
    next_rect = ax_next.add_patch(Rectangle(
        (next_clip['in_point'], y0 + 5),
        next_clip['crossfade_in_end'] - next_clip['in_point'],
        y1 - y0 - 10, color='orange', alpha=0.2, animated=True))

# Erstinitialisierung
init_cutter()
_place(cur_mk,  current_clip, 'cur_')
_place(next_mk, next_clip,    'next_')
_draw_rects()

hist_buf = deque(maxlen=HISTORY_LENGTH)

# -------------------------------------------------------------
# 4) ANIMATION-CALLBACK
# -------------------------------------------------------------
def _update(_):
    idx, px, second_play = get_next_pixel()

    # Haupt-play-Marker
    play_dot_cur.set_data([idx], [px])
    play_text_cur.set_position((idx, px + 10))
    play_text_cur.set_text("play")

    # Zweiter play-Marker nur im Crossfade
    if second_play:
        idx2, _ = second_play  # y-Wert ignorieren
        play_dot_next.set_data([idx2], [px])  # gleicher y-Wert wie oben
        play_text_next.set_position((idx2, px + 10))
        play_text_next.set_text("play")
    else:
        play_dot_next.set_data([], [])
        play_text_next.set_text("")

    # History
    hist_buf.append(px)
    history_line.set_data(range(len(hist_buf)), list(hist_buf))

    # Marker neu positionieren, falls Clip gewechselt
    if clip_changed:
        _place(cur_mk,  current_clip, 'cur_')
        _place(next_mk, next_clip,    'next_')
        _draw_rects()

    # Alle Artists für blitting
    artists = [
        play_dot_cur, play_text_cur,
        play_dot_next, play_text_next,
        history_line, cur_rect, next_rect
    ]
    for bank in (cur_mk, next_mk):
        for p, t in bank.values():
            artists += [p, t]
    return artists

# -------------------------------------------------------------
# 5) ANIMATION STARTEN
# -------------------------------------------------------------
ani = animation.FuncAnimation(fig, _update,
                              interval=INTERVAL_MS,
                              blit=True,
                              frames=range(100000))

plt.tight_layout()
plt.show()
