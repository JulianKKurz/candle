import matplotlib.pyplot as plt
import numpy as np

# Gegebene Messpunkte
voltages = np.array([3.0, 3.5])
currents = np.array([0.12, 0.35])

# Exponentielle Fit-Funktion bestimmen (einfaches Modell)
coeffs = np.polyfit(voltages, np.log(currents), 1)
fit_func = lambda v: np.exp(coeffs[1]) * np.exp(coeffs[0] * v)

# Plot-Daten
v_range = np.linspace(2.5, 5.0, 500)
i_fit = fit_func(v_range)

# Messpunkt bei 5V
v_5 = 5.0
i_5 = fit_func(v_5)

plt.figure(figsize=(8, 5))
plt.plot(v_range, i_fit, label="LED-Kennlinie (exponentiell)", color='blue')
plt.axvline(5.0, color='red', linestyle='--', label="5V-Grenze")
plt.plot(3.0, 0.12, 'o', label="Messpunkt: 3.0 V / 120 mA", color='black')
plt.plot(3.5, 0.35, 'o', label="Messpunkt: 3.5 V / 350 mA", color='black')
plt.plot(v_5, i_5, 'o', label=f"Extrapoliert: 5.0 V / {i_5:.2f} A", color='purple')

plt.title("LED Kennlinie (exponentiell)")
plt.xlabel("Spannung [V]")
plt.ylabel("Strom [A]")
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.show()
