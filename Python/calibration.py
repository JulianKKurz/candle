import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider

# Spannung von 0 bis 5 V
v = np.linspace(0, 5, 500)

# 3V-Kurve: Linear (Raumtemperatur) und Exponentiell (Betriebstemperatur)
i_rt_3v = v / 5
i_bt_3v = np.exp(1.2 * v) - 1
i_bt_3v /= np.max(i_bt_3v)
i_bt_3v = np.clip(i_bt_3v, 0, 1)

# 5V-Kurve: Sinus (Raumtemperatur) und Sägezahn (Betriebstemperatur)
i_rt_5v = 0.5 * (1 + np.sin(2 * np.pi * v / 5))
i_bt_5v = (v % 1)
i_bt_5v /= np.max(i_bt_5v)

# Initiale Slider-Werte
alpha_init = 0.5   # Temperaturgewichtung
beta_init = 0.0    # Spannung: 0 = 3V, 1 = 5V

# Mix-Funktion
def compute_mix(alpha, beta):
    mix_3v = (1 - alpha) * i_rt_3v + alpha * i_bt_3v
    mix_5v = (1 - alpha) * i_rt_5v + alpha * i_bt_5v
    return mix_3v, mix_5v, (1 - beta) * mix_3v + beta * mix_5v

# Initiale gemischte Kurven
mix_3v_init, mix_5v_init, i_mix = compute_mix(alpha_init, beta_init)

# Plot
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6))
plt.subplots_adjust(bottom=0.3, hspace=0.4)

# Oberer Plot: Rohkurven und Mischkurven
line_3v, = ax1.plot(v, mix_3v_init, label="3V (interpoliert)")
line_5v, = ax1.plot(v, mix_5v_init, label="5V (interpoliert)")
ax1.plot(v, i_rt_3v, 'r--', label="3V Raum", alpha=0.3)
ax1.plot(v, i_bt_3v, 'b--', label="3V Betrieb", alpha=0.3)
ax1.plot(v, i_rt_5v, 'g--', label="5V Raum", alpha=0.3)
ax1.plot(v, i_bt_5v, 'm--', label="5V Betrieb", alpha=0.3)
ax1.set_title("Kennlinien bei 3V und 5V mit Temperaturinterpolation")
ax1.set_xlabel("Spannung (V)")
ax1.set_ylabel("Strom (normiert)")
ax1.legend()
ax1.grid(True)

# Unterer Plot: Resultierende Mischkennlinie
line_mix, = ax2.plot(v, i_mix, color='black', linewidth=2, label="Interpolierte LED-Kennlinie")
ax2.set_title("Resultierende dynamische LED-Kennlinie")
ax2.set_xlabel("Spannung (V)")
ax2.set_ylabel("Strom (normiert)")
ax2.grid(True)
ax2.legend()

# Temperatur-Slider
ax_temp = plt.axes([0.25, 0.18, 0.5, 0.03])
slider_temp = Slider(ax_temp, "Temperatur (0 = Raum, 1 = Betrieb)", 0.0, 1.0, valinit=alpha_init)

# Spannungsslider
ax_volt = plt.axes([0.25, 0.1, 0.5, 0.03])
slider_volt = Slider(ax_volt, "Versorgung (0 = 3V, 1 = 5V)", 0.0, 1.0, valinit=beta_init)

# Update-Funktion
def update(val):
    alpha = slider_temp.val
    beta = slider_volt.val
    mix_3v, mix_5v, i_mix = compute_mix(alpha, beta)
    line_3v.set_ydata(mix_3v)
    line_5v.set_ydata(mix_5v)
    line_mix.set_ydata(i_mix)
    fig.canvas.draw_idle()

slider_temp.on_changed(update)
slider_volt.on_changed(update)

plt.show()
