import numpy as np
import matplotlib.pyplot as plt

# === Parameter ===
V_max_bits = 0xfff     # 12 Bit Auflösung, entspricht 4095
t_total = 2e-3         # 2 ms Gesamtdauer
samples = 20000        # hohe Auflösung
pwm_freq = 15e3        # PWM-Frequenz
pwm_period = 1 / pwm_freq

# === Counter-Einstellungen ===
counter_max = 0xfff    # 12 Bit Auflösung, entspricht 4095
compare_val = int(counter_max // 2)  # entspricht exakt 50% Duty-Cycle bei 12 Bit Auflösung

# === RC-Komponenten ===
R = 1e3               # 5 kΩ
C = 60.1e-9              # 10 nF
RC = R * C

# === Zeitachse ===
t = np.linspace(0, t_total, samples)
dt = t[1] - t[0]

# === PWM erzeugen anhand Counter-Wert ===
t_pwm = []
v_pwm = []
current_time = 0.0
while current_time < t_total:
    if current_time < 1e-3:
        duty = 0.0
    else:
        duty = compare_val / counter_max
    on_time = pwm_period * duty
    t_pwm.extend([current_time, current_time + on_time, current_time + on_time, current_time + pwm_period])
    v_pwm.extend([V_max_bits, V_max_bits, 0, 0])
    current_time += pwm_period

# === Interpoliertes PWM-Signal ===
v_pwm_interp = np.interp(t, t_pwm, v_pwm)

# === RC-Filterung des PWM-Signals ===
v_out_pwm = np.zeros_like(t)
for i in range(1, len(t)):
    dv = (v_pwm_interp[i] - v_out_pwm[i - 1]) * dt / RC
    v_out_pwm[i] = v_out_pwm[i - 1] + dv

# === Ideales analoges Rechtecksignal (500 Hz) ===
v_analog = np.where(t < 1e-3, 0, V_max_bits * duty)

# === RC-Filterung des analogen Rechtecksignals ===
v_out_analog = np.zeros_like(t)
for i in range(1, len(t)):
    dv = (v_analog[i] - v_out_analog[i - 1]) * dt / RC
    v_out_analog[i] = v_out_analog[i - 1] + dv

# === Stelle finden, an der Differenz zwischen analogem Rechteck und RC-Ausgang 1 LSB beträgt ===
diff = np.abs(v_analog - v_out_analog)
lsb = 1
idx_lsb = np.where(np.abs(diff - lsb) < 0.1)[0]

if idx_lsb.size > 0:
    idx = idx_lsb[0]
    y_lsb = v_out_analog[idx]
    x_lsb = t[idx] * 1e3  # in ms
else:
    idx = None
    y_lsb = None
    x_lsb = None

# === Plot ===
plt.figure(figsize=(12, 5))

# PWM (Hintergrund, transparent)
plt.plot(t * 1e3, v_pwm_interp, label='PWM (15 kHz)', color='blue', alpha=0.3)
plt.plot(t * 1e3, v_out_pwm, label='RC-Ausgang aus PWM', color='red', alpha=0.3)

# Rechteckvorgabe und berechnete RC-Kurve (Vordergrund)
plt.plot(t * 1e3, v_analog, label='Rechtecksignal (analog)', color='green')
plt.plot(t * 1e3, v_out_analog, label='RC-Ausgang aus Rechteck', color='orange')

# Vertikale Linie + Marker bei 1 LSB Differenz
if idx is not None:
    plt.axvline(x=x_lsb, color='black', label='1 LSB Differenz (grün - orange)')
    plt.plot(x_lsb, y_lsb, 'ko', label='1 LSB Punkt')

# Achsenbeschriftung und Titel
plt.xlabel('Zeit (ms)', fontsize=12)
plt.ylabel('Signalwert (Bits)', fontsize=12)
plt.title(f'RC-Ausgänge mit PWM und analogem Rechtecksignal\n'
          f'(R = {R/1e3:.0f} kΩ, C = {C*1e9:.0f} nF, compare = {compare_val}, max = {counter_max})',
          fontsize=14)

# Legende, Gitter, Layout
plt.grid(True, which='both', linestyle='--', linewidth=0.5)
plt.legend(loc='best', fontsize=10)
plt.tight_layout()
plt.show()
