import matplotlib.pyplot as plt

# === 1. Shunt-Widerstandswert ===
shunt_resistance = 5  # Ohm

# === 2. Messwerte MIT LED ===
ccr_led_extended = [700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200]  # CCR-Werte
volt_led_extended_mV = [0, 0, 4.7, 13.7, 31.2, 71, 127, 246, 320, 370, 340]     # Spannungen (mV)
current_led_extended_mA = [(v / 1000) / shunt_resistance * 1000 for v in volt_led_extended_mV]  # Strom in mA

# === 3. Messwerte OHNE LED (nur Widerstand) ===
ccr_no_led_final_corrected = [700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200]
volt_no_led_final_corrected_mV = [0, 0, 5.6, 18, 40, 87, 176, 361, 726, 996, 1142]
current_no_led_final_corrected_mA = [(v / 1000) / shunt_resistance * 1000 for v in volt_no_led_final_corrected_mV]

# === 4. Plot-Erstellung ===
plt.figure(figsize=(8, 5))

# LED-Kurve
plt.plot(ccr_led_extended, current_led_extended_mA, marker='o', linestyle='-', color='b', label='LED in Reihe zum Shunt')

# Widerstandskurve
plt.plot(ccr_no_led_final_corrected, current_no_led_final_corrected_mA, marker='x', linestyle='--', color='orange', label='Nur Shunt (Referenzmessung)')

# Titel und Achsenbeschriftungen (wissenschaftlich korrekt)
plt.title("Strommessung eines Kanals", fontsize=13)
plt.xlabel("PWM-Steuerwert (CCR, 12 Bit)", fontsize=12)
plt.ylabel(r"Strom durch Shunt $I = \frac{U_\mathrm{Shunt}}{R_\mathrm{Shunt}}$ in mA", fontsize=12)

# Gitter und Legende
plt.grid(True)
plt.legend(loc='best', fontsize=10)
plt.tight_layout()

# Plot anzeigen
plt.show()
