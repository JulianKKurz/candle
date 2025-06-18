import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d
from scipy.signal import savgol_filter
from colour import SpectralDistribution, colour_rendering_index, wavelength_to_XYZ, XYZ_to_sRGB
from colour.colorimetry import SpectralShape

# 🔧 Projektverzeichnis bestimmen
project_dir = os.path.dirname(os.path.abspath(__file__))

# 📁 CSV-Dateien laden
csv_smd_led = os.path.join(project_dir, "data", "smd_led.csv")
csv_candle = os.path.join(project_dir, "data", "candle.csv")
csv_filament_led = os.path.join(project_dir, "data", "filament_led.csv")

df_smd_led = pd.read_csv(csv_smd_led)
df_candle = pd.read_csv(csv_candle)
df_filament_led = pd.read_csv(csv_filament_led)

# 🔎 Bereich auf 400–750 nm begrenzen
def trim(df):
    return df[(df["Wavelength [nm]"] >= 400) & (df["Wavelength [nm]"] <= 750)].reset_index(drop=True)

df_candle = trim(df_candle)
df_filament_led = trim(df_filament_led)
df_smd_led = trim(df_smd_led)

# 🎯 CRI-Berechnung
target_shape = SpectralShape(400, 750, 5)
def compute_cri(df):
    data = dict(zip(df["Wavelength [nm]"], df["Relative Intensity [%]"]))
    sd = SpectralDistribution(data, name="Sample")
    sd = sd.interpolate(target_shape)
    return colour_rendering_index(sd)

cri_candle = compute_cri(df_candle)
cri_filament = compute_cri(df_filament_led)
cri_smd = compute_cri(df_smd_led)

def wavelength_to_rgb(wavelength_nm):
    if 380 <= wavelength_nm <= 645:
        XYZ = wavelength_to_XYZ(wavelength_nm)
        rgb = XYZ_to_sRGB(XYZ / max(XYZ))
        return [max(0, min(1, c)) for c in rgb]
    elif 645 < wavelength_nm <= 800:
        t = (wavelength_nm - 645) / 100
        XYZ_visible = wavelength_to_XYZ(645)
        rgb_visible = XYZ_to_sRGB(XYZ_visible / max(XYZ_visible))
        rgb_visible = [max(0, min(1, c)) for c in rgb_visible]
        rgb_ir = [0.3, 0.0, 0.0]
        return [(1 - t) * v + t * i for v, i in zip(rgb_visible, rgb_ir)]
    elif wavelength_nm > 800:
        return [0.3, 0.0, 0.0]
    else:
        return [0, 0, 0]

# 🔍 Interpolation mit einheitlichem Bereich 400–750 nm
def interpolate_df(df, resolution=0.1, wl_range=(400, 750)):
    wl = df["Wavelength [nm]"].to_numpy()
    intensity = df["Relative Intensity [%]"].to_numpy()
    interp_func = interp1d(
        wl, intensity,
        kind="linear",
        bounds_error=False,
        fill_value=0.0
    )
    wl_fine = np.arange(wl_range[0], wl_range[1] + resolution, resolution)
    intensity_fine = interp_func(wl_fine)
    return wl_fine, intensity_fine

# 📊 Plotten
def plot_colored_spectrum(ax, df, title, cri, window_length=201, polyorder=2, resolution=0.1):
    wl, intensity = interpolate_df(df, resolution=resolution)
    smoothed = savgol_filter(intensity, window_length=window_length, polyorder=polyorder)
    smoothed = np.clip(smoothed, 0, None)

    for i in range(len(wl) - 1):
        wl1, wl2 = wl[i], wl[i + 1]
        inten1, inten2 = smoothed[i], smoothed[i + 1]
        rgb = wavelength_to_rgb((wl1 + wl2) / 2)
        ax.fill_between([wl1, wl2], [inten1, inten2], color=rgb, alpha=1.0)

    ax.plot(wl, smoothed, color='black', linewidth=1.2)
    ax.set_title(f"{title} (CRI = {cri:.2f} %)")
    ax.set_ylabel("Relative Intensität [%]")
    ax.grid(True)
    ax.set_xlim(400, 750)  # 👈 X-Achse auf 400–750 nm begrenzen

# 📈 Plots erzeugen
fig, axs = plt.subplots(3, 1, figsize=(10, 10), sharex=True)

plot_colored_spectrum(axs[0], df_candle, "Kerze", cri_candle, window_length=501, polyorder=2)
plot_colored_spectrum(axs[1], df_filament_led, "Filament LED", cri_filament)
plot_colored_spectrum(axs[2], df_smd_led, "SMD LED", cri_smd)

axs[2].set_xlabel("Wellenlänge [nm]")
plt.tight_layout()
plt.show()
