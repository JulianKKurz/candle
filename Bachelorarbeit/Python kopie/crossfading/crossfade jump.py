import numpy as np
import matplotlib.pyplot as plt

# Parameter
fs = 1000  # Samplingrate in Hz
duration = 2.0  # Gesamtdauer in Sekunden
t = np.linspace(0, duration, int(fs * duration), endpoint=False)

# Signale
x1 = np.sin(2 * np.pi * 5 * t)                     # Sinussignal
x2 = 0.5 * np.sign(np.cos(2 * np.pi * 5 * t))      # Rechtecksignal mit Amplitude 0.5

# Crossfade von 1 s bis 1 s (über 0 Sekunden)
fade_start = 1
fade_end = 1
balance = np.zeros_like(t)

# Indizes für Start und Ende des Fades
idx_start = int(fade_start * fs)
idx_end = int(fade_end * fs)

# Balance im Fade-Bereich (hier: kein Bereich)
if idx_end > idx_start:
    balance[idx_start:idx_end] = np.linspace(0, 1, idx_end - idx_start)

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
plt.title("Crossfade mit 0 Sekunden Dauer (Wechsel bei 1s)")
plt.ylabel("Amplitude")
plt.grid(True)
plt.legend()

plt.subplot(4, 1, 4)
plt.plot(t, balance, label='Balance(t)', color='purple')
plt.title("Balance-Verlauf: Sprung von 0 → 1 bei 1s")
plt.xlabel("Zeit (s)")
plt.ylabel("Balance")
plt.grid(True)
plt.legend()

plt.tight_layout()
plt.show()
