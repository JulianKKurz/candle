import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider
from scipy.interpolate import interp1d
from colour import SpectralDistribution, colour_rendering_index, wavelength_to_XYZ, XYZ_to_sRGB
from colour.colorimetry import SpectralShape
import os

# 🔧 CSV laden
project_dir = os.path.dirname(os.path.abspath(__file__))
csv_smd_led = os.path.join(project_dir, "data", "smd_led.csv")
csv_red_led = os.path.join(project_dir, "data", "red_led.csv")

df_smd = pd.read_csv(csv_smd_led)
df_smd = df_smd[(df_smd["Wavelength [nm]"] >= 400) & (df_smd["Wavelength [nm]"] <= 750)].reset_index(drop=True)

df_red = pd.read_csv(csv_red_led)
df_red = df_red[(df_red["Wavelength [nm]"] >= 400) & (df_red["Wavelength [nm]"] <= 750)].reset_index(drop=True)

# Interpolation auf gleichmäßiges Gitter
def interpolate_df(df, resolution=5):
    wl = df["Wavelength [nm]"].to_numpy()
    intensity = df["Relative Intensity [%]"].to_numpy()
    f = interp1d(wl, intensity, kind='linear', bounds_error=False, fill_value=0.0)
    wl_new = np.arange(400, 751, resolution)
    intensity_new = f(wl_new)
    return wl_new, intensity_new

# RGB-Konvertierung
def wavelength_to_rgb(wl):
    try:
        XYZ = wavelength_to_XYZ(wl)
        if np.max(XYZ) == 0:
            return [0, 0, 0]
        rgb = XYZ_to_sRGB(XYZ / np.max(XYZ))
        return np.clip(rgb, 0, 1)
    except Exception:
        return [0, 0, 0]

# CRI berechnen
def compute_cri(wl, intensity):
    data = dict(zip(wl, intensity))
    sd = SpectralDistribution(data, name="Sample")
    sd = sd.interpolate(SpectralShape(400, 750, 5))
    return colour_rendering_index(sd)

# Plotfunktion
def plot_spectrum(ax, wl, intensity, title):
    ax.clear()
    for i in range(len(wl) - 1):
        rgb = wavelength_to_rgb((wl[i] + wl[i + 1]) / 2)
        ax.fill_between([wl[i], wl[i + 1]], [intensity[i], intensity[i + 1]], color=rgb)
    ax.plot(wl, intensity, color='black', linewidth=0.8)
    ax.set_xlim(400, 750)
    ax.set_ylim(0, max(intensity)*1.1 if max(intensity) > 0 else 1)
    ax.set_ylabel("Intensität [%]")
    ax.set_title(title)
    ax.grid(True)

# 💡 Daten vorbereiten
wl, base_smd = interpolate_df(df_smd)
_, base_red = interpolate_df(df_red)

# 🎛 GUI vorbereiten
fig, axs = plt.subplots(4, 1, figsize=(10, 12), sharex=True)
plt.subplots_adjust(left=0.1, bottom=0.35)

slider_smd_ax = plt.axes([0.15, 0.27, 0.7, 0.03])
slider_red_ax = plt.axes([0.15, 0.20, 0.7, 0.03])
slider_phos_ax = plt.axes([0.15, 0.13, 0.7, 0.03])

slider_smd = Slider(slider_smd_ax, 'SMD Helligkeit [%]', 0, 100, valinit=100, valstep=5)
slider_red = Slider(slider_red_ax, 'Rot Helligkeit [%]', 0, 100, valinit=40, valstep=5)
slider_phos = Slider(slider_phos_ax, 'Phosphor Wirkungsgrad [%]', 0, 100, valinit=100, valstep=5)

# 🔁 Update-Funktion
def update(val=None):
    smd_gain = slider_smd.val / 100
    red_gain = slider_red.val / 100
    phos_eff = slider_phos.val / 100

    smd_scaled = base_smd * smd_gain
    red_scaled = base_red * red_gain

    # Absorption abhängig vom Phosphor-Wirkungsgrad
    absorption = phos_eff * np.exp(-((wl - 450) ** 2) / (2 * 10 ** 2))
    absorbed = smd_scaled * absorption

    energy_in = np.trapz(absorbed, wl)
    if energy_in > 0:
        phosphor = np.exp(-((wl - 580) ** 2) / (2 * 40 ** 2))
        phosphor *= (energy_in) / np.trapz(phosphor, wl)
    else:
        phosphor = np.zeros_like(wl)

    smd_remaining = smd_scaled * (1 - absorption)
    total = smd_remaining + red_scaled + phosphor

    cri_smd = compute_cri(wl, smd_scaled)
    cri_red = compute_cri(wl, red_scaled)
    cri_phos = compute_cri(wl, phosphor)
    cri_total = compute_cri(wl, total)

    plot_spectrum(axs[0], wl, smd_scaled, f"SMD LED (CRI = {cri_smd:.1f} %)")
    plot_spectrum(axs[1], wl, red_scaled, f"Rote LED (CRI = {cri_red:.1f} %)")
    plot_spectrum(axs[2], wl, phosphor, f"Phosphorlicht (CRI = {cri_phos:.1f} %)")
    plot_spectrum(axs[3], wl, total, f"Gesamtspektrum (CRI = {cri_total:.1f} %)")

    axs[3].set_xlabel("Wellenlänge [nm]")
    fig.canvas.draw_idle()

# Initialisieren & verbinden
update()
slider_smd.on_changed(update)
slider_red.on_changed(update)
slider_phos.on_changed(update)

plt.show()
