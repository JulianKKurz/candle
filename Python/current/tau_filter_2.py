import numpy as np
from scipy.optimize import fsolve

# Werte
t = 0.0005  # s
V_ratio = 4094 / 4095  # ≈ 0.99975586

# Gleichung definieren
def f(tau):
    return 1 - (1 + t / tau) * np.exp(-t / tau) - V_ratio

# Startwert raten (z. B. 100 us = 0.0001 s)
tau_start = 1e-4

# Lösung berechnen
tau_solution = fsolve(f, tau_start)[0]

# Ergebnis in Mikrosekunden
print(tau_solution * 1e6)
