# Nach dem Reset: alles neu definieren
import matplotlib.pyplot as plt
import numpy as np

# Vorgegebene Werte (nur erste 26 verwendet für 25 Frames)
raw_values = [
    176,176,176,176,177,177,177,177,177,178,178,178,
    177,177,176,175,175,174,173,173,172,172,171,171,
    170,171,171,171,172,173,175,175,175,176,175,171,
    171,170,170,171,175,175,176,177,177,177,177,177,
    176,175,173,175,174,173,172,172,172,173,175,178,
    183,183,185,186,187,187,184,184,183,182,179,179,
    178,177,175,173,173,172,171,170,169,169,169,169,
]

# Verwende die ersten 26 für 25 Frames
signal_points = raw_values[:26]
n_frames = 25
time_points = np.linspace(0, 1, n_frames + 1)

# Interpolierte Zeitachse (1000 fps)
time_fine = np.linspace(0, 1, 1000)
interpolated_signal = np.interp(time_fine, time_points, signal_points)

# IIR-Filter (Exponentialfilter)
alpha = 0.99
filtered_signal = np.zeros_like(interpolated_signal)
filtered_signal[0] = interpolated_signal[0]
for i in range(1, len(interpolated_signal)):
    filtered_signal[i] = alpha * filtered_signal[i - 1] + (1 - alpha) * interpolated_signal[i]

# Plot
fig, axs = plt.subplots(3, 1, figsize=(10, 8), sharex=True)
fig.suptitle("Vergleich: Diskrete Frames, Interpolation und IIR-gefiltertes Signal", fontsize=14)

# 1. Diskrete Frame-Werte
axs[0].step(time_points, signal_points, where='post')
axs[0].set_title("Gegebene Frame-Pixelwerte (25 fps, diskret)")
axs[0].set_ylabel("Pixelwert (0–255)")
axs[0].set_ylim(min(signal_points) - 5, max(signal_points) + 5)
axs[0].grid(True)

# 2. Linear interpoliert
axs[1].plot(time_fine, interpolated_signal)
axs[1].set_title("Linear interpoliertes Bildsignal (1000 fps)")
axs[1].set_ylabel("Pixelwert (0–255)")
axs[1].set_ylim(min(signal_points) - 5, max(signal_points) + 5)
axs[1].grid(True)

# 3. IIR-gefiltert
axs[2].plot(time_fine, filtered_signal, color='orange')
axs[2].set_title("IIR-gefiltertes Signal (α = 0.99)")
axs[2].set_xlabel("Zeit (s)")
axs[2].set_ylabel("Pixelwert (0–255)")
axs[2].set_ylim(min(signal_points) - 5, max(signal_points) + 5)
axs[2].grid(True)

plt.tight_layout(rect=[0, 0.03, 1, 0.95])
plt.show()
