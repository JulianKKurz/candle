import numpy as np
import matplotlib.pyplot as plt

# === Parameter ===
V_max_bits = 0xfff
t_total = 2e-3
samples = 20000
pwm_freq = 15e3
pwm_period = 1 / pwm_freq

counter_max = 0xfff
compare_val = int(counter_max // 2)

R = 1e3
C = 60.1e-9
RC = R * C

t = np.linspace(0, t_total, samples)
dt = t[1] - t[0]

# === PWM erzeugen ===
t_pwm = []
v_pwm = []
current_time = 0.0
while current_time < t_total:
    duty = 0.0 if current_time < 1e-3 else compare_val / counter_max
    on_time = pwm_period * duty
    t_pwm.extend([current_time, current_time + on_time, current_time + on_time, current_time + pwm_period])
    v_pwm.extend([V_max_bits, V_max_bits, 0, 0])
    current_time += pwm_period

v_pwm_interp = np.interp(t, t_pwm, v_pwm)

# === RC-Filterung ===
v_out_pwm = np.zeros_like(t)
for i in range(1, len(t)):
    dv = (v_pwm_interp[i] - v_out_pwm[i - 1]) * dt / RC
    v_out_pwm[i] = v_out_pwm[i - 1] + dv

# === ADC-Messintervalle ===
pwm_adc_freq = 1000
pwm_adc_period = 1 / pwm_adc_freq
pwm_adc_duty = 0.5

adc_intervals = []
current_time = 0.0
while current_time < t_total:
    start = current_time + pwm_adc_period * pwm_adc_duty
    end = current_time + pwm_adc_period
    if start < t_total:
        adc_intervals.append((start, min(end, t_total)))
    current_time += pwm_adc_period

# === ADC-Zeitbasis: 64 MHz / 6 mit 14 Takten pro Messung ===
adc_clk = 64e6 / 6
adc_sample_time = 14 / adc_clk

# === Nur den zweiten ADC-Messbereich anzeigen ===
if len(adc_intervals) >= 2:
    start, end = adc_intervals[1]

    # === RC-Ausgang im Intervall extrahieren (analog) ===
    idx_range = np.where((t >= start) & (t <= end))
    t_range = t[idx_range]
    v_range = v_out_pwm[idx_range]
    v_mean_analog = np.mean(v_range)

    # === ADC-Zeitpunkte & quantisierte Werte ===
    adc_times = []
    current = start
    while current < end:
        adc_times.append(current)
        current += adc_sample_time

    adc_times = np.array(adc_times)
    adc_values = np.interp(adc_times, t, v_out_pwm)
    adc_values = np.round(adc_values).clip(0, V_max_bits)  # 12-Bit Quantisierung

    # === Inkrementeller Mittelwert über ADC-Werte ===
    mean_adc = 0.0
    mean_adc_values = []
    for i, x in enumerate(adc_values, start=1):
        mean_adc += (x - mean_adc) / i
        mean_adc_values.append(mean_adc)

    # === Mittelwert über die diskreten Samples ===
    v_mean_adc = np.mean(adc_values)

    # === Wahrer Mittelwert aus rekonstruierter Treppe ===
    adc_step_durations = np.diff(np.append(adc_times, end))  # Dauer jeder Stufe
    adc_area = np.sum(adc_values * adc_step_durations)       # Fläche unter Treppe
    v_mean_step = adc_area / (end - start)

    # === Plot ===
    fig, ax = plt.subplots(figsize=(10, 3))
    ax.plot(t_range * 1e3, v_range, color='red', label='RC-Ausgang (analog)', alpha=0.4)
    ax.axhline(y=v_mean_analog, color='blue', linestyle='--', label=f'Analog-Mittelwert: {v_mean_analog:.1f} Bits')
    ax.axhline(y=v_mean_adc, color='magenta', linestyle=':', label=f'Mittelwert ADC-Samples: {v_mean_adc:.1f} Bits')
    ax.axhline(y=v_mean_step, color='orange', linestyle='-.', label=f'Stufen-Mittelwert: {v_mean_step:.1f} Bits')
    ax.step(adc_times * 1e3, adc_values, where='post', color='black', linewidth=1, label='ADC-Stufensignal')
    ax.step(adc_times * 1e3, mean_adc_values, where='post', color='green',
            label=f'Mittelwertverlauf (Endwert: {mean_adc:.1f} Bits)', linewidth=1)

    ax.set_xlabel('Zeit (ms)')
    ax.set_ylabel('Signalwert (Bits)')
    ax.set_title('Vergleich: Mittelwerte (analog, ADC, Stufensignal)')
    ax.grid(True, linestyle='--', linewidth=0.5)
    ax.legend(loc='upper right')
    plt.tight_layout()
    plt.show()
