import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import FuncFormatter

# Definitionsbereich
x = np.linspace(100, 10000, 200)

# Initial- und Stückkosten
initial_chip = 10000
initial_platine = 100
initial_srilanka = 200

fixed_chip = 0.50
fixed_platine = 0.03 * 16 * 2 * 2
fixed_srilanka = 1.36

# Preisverläufe
price_chip = initial_chip / x + fixed_chip
price_platine = initial_platine / x + fixed_platine
price_srilanka = initial_srilanka / x + fixed_srilanka

# Schnittpunkte
ix_chip_platine = np.argmin(np.abs(price_chip - price_platine))
ix_chip_sri = np.argmin(np.abs(price_chip - price_srilanka))
ix_platine_sri = np.argmin(np.abs(price_platine - price_srilanka))

# Koordinaten der Schnittpunkte
x_chip_platine = x[ix_chip_platine]
x_chip_sri = x[ix_chip_sri]
x_platine_sri = x[ix_platine_sri]

y_chip_platine = price_chip[ix_chip_platine]
y_chip_sri = price_chip[ix_chip_sri]
y_platine_sri = price_platine[ix_platine_sri]

# Euro-Formatter
def euro_format(x, pos):
    return f"{x:.2f} €"

euro_formatter = FuncFormatter(euro_format)

# Plot
fig, axs = plt.subplots(3, 1, figsize=(10, 11), sharex=True)

# Sri Lanka
axs[0].plot(x, price_srilanka, label=f"Standard-Filament ({initial_srilanka} € + {fixed_srilanka:.2f} €/Stk)", color="tab:green")
axs[0].axvline(x=x_chip_sri, color="tab:blue", linestyle="--", label="Break-even mit Chip on Glass")
axs[0].axvline(x=x_platine_sri, color="tab:orange", linestyle="--", label="Break-even mit Platine")
axs[0].plot(x_chip_sri, price_srilanka[ix_chip_sri], 'o', color='red')
axs[0].plot(x_platine_sri, price_srilanka[ix_platine_sri], 'o', color='red')
axs[0].set_title("Gesamtkosten pro Stück: Standardisiertes LED-Filament (Sri Lanka)")
axs[0].set_ylabel("Preis pro Stück")
axs[0].yaxis.set_major_formatter(euro_formatter)
axs[0].grid(True, axis="y")
axs[0].legend()

# Platine
axs[1].plot(x, price_platine, label=f"Platine ({initial_platine} € + {fixed_platine:.2f} €/Stk)", color="tab:orange")
axs[1].axvline(x=x_chip_platine, color="tab:blue", linestyle="--", label="Break-even mit Chip on Glass")
axs[1].axvline(x=x_platine_sri, color="tab:green", linestyle="--", label="Break-even mit Sri Lanka")
axs[1].plot(x_chip_platine, price_platine[ix_chip_platine], 'o', color='red')
axs[1].plot(x_platine_sri, price_platine[ix_platine_sri], 'o', color='red')
axs[1].set_title("Gesamtkosten pro Stück: Platine")
axs[1].set_ylabel("Preis pro Stück")
axs[1].yaxis.set_major_formatter(euro_formatter)
axs[1].grid(True, axis="y")
axs[1].legend()

# Chip-on-Glass
axs[2].plot(x, price_chip, label=f"Chip on Glass ({initial_chip} € + {fixed_chip:.2f} €/Stk)", color="tab:blue")
axs[2].axvline(x=x_chip_platine, color="tab:orange", linestyle="--", label="Break-even mit Platine")
axs[2].axvline(x=x_chip_sri, color="tab:green", linestyle="--", label="Break-even mit Sri Lanka")
axs[2].plot(x_chip_platine, price_chip[ix_chip_platine], 'o', color='red')
axs[2].plot(x_chip_sri, price_chip[ix_chip_sri], 'o', color='red')
axs[2].set_title("Gesamtkosten pro Stück: Chip on Glass")
axs[2].set_xlabel("Stückzahl")
axs[2].set_ylabel("Preis pro Stück")
axs[2].yaxis.set_major_formatter(euro_formatter)
axs[2].grid(True, axis="y")
axs[2].legend()

plt.tight_layout()
plt.show()
