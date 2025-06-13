import numpy as np
import matplotlib.pyplot as plt

# Parameter
fs = 1000  # Samplingrate in Hz
duration = 2.0  # Gesamtdauer in Sekunden
t = np.linspace(0, duration, int(fs * duration), endpoint=False)

# Signale
x1 = np.sin(2 * np.pi * 5 * t)                     # Sinussignal
x2 = 0.5 * np.sign(np.cos(2 * np.pi * 5 * t))      # Rechtecksignal mit Amplitude 0.5

# Crossfade von 0.5 s bis 1.5 s (über 1 Sekunde)
fade_start = 0.5
fade_end = 1.5
balance = np.zeros_like(t)

# Indizes für Start und Ende des Fades
idx_start = int(fade_start * fs)
idx_end = int(fade_end * fs)

# Cosinusförmige Crossfade-Kurve im Bereich (0.5 s bis 1.5 s)
fade_range = np.linspace(0, np.pi, idx_end - idx_start)
cos_fade = (1 - np.cos(fade_range)) / 2
balance[idx_start:idx_end] = cos_fade

# Nach dem Fade: balance = 1
balance[idx_end:] = 1

# Crossfade-Anwendung
y = x1 + balance * (x2 - x1)

# Plotten
plt.figure(figsize=(14, 10))

plt.subplot(4, 1, 1)
plt.plot(t, x1, label='x1(t) = sin(2π5t)')
plt.title("Sinussignal")
plt.ylabel("Amplitude")
plt.grid(True)
plt.legend()

plt.subplot(4, 1, 2)
plt.plot(t, x2, label='x2(t) = Rechtecksignal (Amplitude 0.5)', color='orange')
plt.title("Rechtecksignal")
plt.ylabel("Amplitude")
plt.grid(True)
plt.legend()

plt.subplot(4, 1, 3)
plt.plot(t, y, label='Crossfade y(t)', color='green')
plt.title("Cosinus-Crossfade von 0.5s bis 1.5s")
plt.ylabel("Amplitude")
plt.grid(True)
plt.legend()

plt.subplot(4, 1, 4)
plt.plot(t, balance, label='Cosinus-Balance(t)', color='purple')
plt.title("Cosinusförmiger Balance-Verlauf: 0 → 1 von 0.5s bis 1.5s")
plt.xlabel("Zeit (s)")
plt.ylabel("Balance")
plt.grid(True)
plt.legend()

plt.tight_layout()
plt.show()
