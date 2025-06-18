import numpy as np
import matplotlib.pyplot as plt

# Parameter
V_pwm = 3.3
D_5 = 0.05
f_pwm = 64000000 / 0xFFF
T_pwm = 1 / f_pwm
R = 194.3
C = 100e-9
tau = R * C

# Zeitachse
n_periods = 500
dt = T_pwm / 100
t = np.arange(0, n_periods * T_pwm, dt)
t_1ms_index = np.searchsorted(t, 1e-3)

# PWM-Signal bei 5 % Duty Cycle
pwm_signal_5 = ((t % T_pwm) < (D_5 * T_pwm)).astype(float) * V_pwm

# GS-Spannung mit RC-Tiefpass berechnen (Euler-Verfahren)
v_out_5 = np.zeros_like(t)
for i in range(1, len(t)):
    dv = (pwm_signal_5[i-1] - v_out_5[i-1]) / tau
    v_out_5[i] = v_out_5[i-1] + dv * dt

# Invertierte Helligkeit (0 V = weiß, 3.3 V = schwarz)
brightness_fullrange_5 = np.clip(v_out_5 / 3.3, 0, 1)

# Plot erzeugen
fig, axs = plt.subplots(3, 1, sharex=True, figsize=(10, 7))

# Plot 1: PWM-Steuersignal (rot)
axs[0].plot(t[:t_1ms_index] * 1e6, pwm_signal_5[:t_1ms_index], color='red')
axs[0].axhline(3.3, color='gray', linestyle='--', alpha=0.5)
axs[0].text(t[10] * 1e6, 3.38, "Referenzspannung (3.3 V)", color='gray', fontsize=9)
axs[0].axhline(0.5, color='black', linestyle='--', alpha=0.5)
axs[0].text(t[10] * 1e6, 0.58, "kleinste Gate Threshold Voltage (0.5 V)", color='black', fontsize=9)
axs[0].set_title(f"PWM-Steuerspannung ({round(D_5*100)} % Tastgrad)")
axs[0].set_ylabel("Spannung (V)")
axs[0].set_ylim(0, 3.6)
axs[0].grid(True)

# Plot 2: Gefilterte GS-Spannung (grün)
axs[1].plot(t[:t_1ms_index] * 1e6, v_out_5[:t_1ms_index], color='green')
axs[1].axhline(3.3, color='gray', linestyle='--', alpha=0.5)
axs[1].text(t[10] * 1e6, 3.38, "Referenzspannung (3.3 V)", color='gray', fontsize=9)
axs[1].axhline(0.5, color='black', linestyle='--', alpha=0.5)
axs[1].text(t[10] * 1e6, 0.58, "kleinste Gate Threshold Voltage (0.5 V)", color='black', fontsize=9)
axs[1].set_title("Gefilterte GS-Spannung (RC-Glied: R = 194.3 Ω, C = 100 nF)")
axs[1].set_ylabel("GS-Spannung (V)")
axs[1].set_ylim(0, 3.6)
axs[1].grid(True)

# Plot 3: Invertierter Helligkeitsverlauf
for i in range(1, t_1ms_index):
    gray_val = brightness_fullrange_5[i]  # 0 = weiß, 1 = schwarz
    axs[2].axvspan(t[i-1] * 1e6, t[i] * 1e6, color=(gray_val, gray_val, gray_val), alpha=1.0)

axs[2].set_title("Ausgangshelligkeit (schwarz = 0,0 V, weiß = 3,3 V)")
axs[2].set_ylabel("Helligkeit")
axs[2].set_xlabel("Zeit (µs)")
axs[2].set_yticks([])
axs[2].set_ylim(0, 1)
axs[2].grid(False)

plt.tight_layout()
plt.show()
