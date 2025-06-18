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
alpha_init = 0.5
beta_init = 0.0

# Mischfunktion
def compute_mix(alpha, beta):
    mix_3v = (1 - alpha) * i_rt_3v + alpha * i_bt_3v
    mix_5v = (1 - alpha) * i_rt_5v + alpha * i_bt_5v
    return mix_3v, mix_5v, (1 - beta) * mix_3v + beta * mix_5v

mix_3v_init, mix_5v_init, i_mix = compute_mix(alpha_init, beta_init)

# Layout
fig, axs = plt.subplots(2, 2, figsize=(10, 8))
plt.subplots_adjust(bottom=0.25, hspace=0.6)

# Mini-Plots der vier Basisfunktionen
axs[0, 0].plot(v, i_rt_3v, 'r', label='3V Raum')
axs[0, 0].set_title("3V – Raumtemperatur")
axs[0, 0].grid(True)

axs[0, 1].plot(v, i_bt_3v, 'b', label='3V Betrieb')
axs[0, 1].set_title("3V – Betriebstemperatur")
axs[0, 1].grid(True)

axs[1, 0].plot(v, i_rt_5v, 'g', label='5V Raum')
axs[1, 0].set_title("5V – Raumtemperatur")
axs[1, 0].grid(True)

axs[1, 1].plot(v, i_bt_5v, 'm', label='5V Betrieb')
axs[1, 1].set_title("5V – Betriebstemperatur")
axs[1, 1].grid(True)

plt.show()
