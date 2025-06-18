import numpy as np
import matplotlib.pyplot as plt

# === Parameter ===
V_ref = 3.3
t_total = 2e-3
samples = 100000

R = 10e3
C = 6.01e-9
tau_rc = R * C               # Bauteilzeitkonstante
tau_adjusted = 1.65e-6       # Slew-Rate-gerechte Zeitkonstante
tau_extra = 72.1046e-6       # Weitere Zeitkonstante aus vorherigem Beispiel

# Zeitachse
t = np.linspace(0, t_total, samples)
dt = t[1] - t[0]

# Eingangssignal (Sprung bei 1 ms)
v_in = np.where(t < 1e-3, 0, V_ref)
start_idx = np.where(t >= 1e-3)[0][0]

# Ausgangssignale
v_out_rc = np.zeros_like(t)
v_out_adjusted = np.zeros_like(t)
v_out_extra = np.zeros_like(t)

# Filterberechnung (alle 1. Ordnung, aber mit unterschiedlichem τ)
for i in range(start_idx + 1, len(t)):
    v_out_rc[i] = v_out_rc[i - 1] + (v_in[i] - v_out_rc[i - 1]) * dt / tau_rc
    v_out_adjusted[i] = v_out_adjusted[i - 1] + (v_in[i] - v_out_adjusted[i - 1]) * dt / tau_adjusted
    v_out_extra[i] = v_out_extra[i - 1] + (v_in[i] - v_out_extra[i - 1]) * dt / tau_extra

# Slew-Rate-Grenzlinie (2 V/µs)
slew_rate = 2  # V/µs
slew_duration_us = V_ref / slew_rate
t_slew_line = np.linspace(0, slew_duration_us * 1e-6, 100)
v_slew_line = t_slew_line * 1e6 * slew_rate
valid = v_slew_line <= V_ref
t_slew_line = t_slew_line[valid]
v_slew_line = v_slew_line[valid]

# === Plot ===
plt.figure(figsize=(12, 5))
plt.plot(t * 1e3, v_in, label='Eingangssignal (3.3 V Rechteck)', color='green')
plt.plot(t * 1e3, v_out_rc, label=f'RC-Filter (τ = {tau_rc*1e6:.2f} µs)', color='orange')
plt.plot(t * 1e3, v_out_extra, label=f'RC-Filter (τ = {tau_extra*1e6:.2f} µs)', color='red')
plt.plot(t * 1e3, v_out_adjusted, label=f'RC-Filter (τ = {tau_adjusted*1e6:.2f} µs, Slew-Rate)', color='blue')
plt.plot((t[start_idx] + t_slew_line) * 1e3, v_slew_line, '--', color='black', label='Slew-Rate-Grenze (2 V/µs)')

plt.xlabel('Zeit in ms', fontsize=12)
plt.ylabel('Spannung in V', fontsize=12)
plt.title('Vergleich: 1. Ordnung Filter mit verschiedenen Zeitkonstanten', fontsize=14)
plt.xlim(0.99, 1.01)
plt.ylim(0, 3.5)
plt.grid(True, linestyle='--', linewidth=0.5)
plt.legend(loc='best', fontsize=10)
plt.tight_layout()
plt.show()
