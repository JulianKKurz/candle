import numpy as np
import matplotlib.pyplot as plt

# Gamma-Wert
gamma = 2.2

# Lineare Helligkeit (physikalisch)
L = np.linspace(0, 1, 256)

# Gamma-Kodierung: Wahrgenommene Helligkeit
B_encode = L ** (1 / gamma)

# Plot erstellen
plt.figure(figsize=(8, 6))

# Gamma-Kodierung (B = L^(1/γ))
plt.plot(L, B_encode, color='orange', label='Gamma-Kodierung (B = L^(1/γ))', linewidth=2)

# Gamma-Dekodierung (L = B^γ)
plt.plot(B_encode, L, linestyle='--', color='orangered', label='Gamma-Dekodierung (L = B^γ)', linewidth=2)

# Achsentitel und Haupttitel
plt.title('Gamma-Korrektur: Wahrnehmung vs. Realität')
plt.xlabel('Lineare Helligkeit (L) – physikalisch')
plt.ylabel('Wahrgenommene Helligkeit (B)')

# Gitter und Legende
plt.grid(True)
plt.legend()

# Layout anpassen und Plot anzeigen
plt.tight_layout()
plt.show()
