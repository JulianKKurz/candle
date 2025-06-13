import pandas as pd
import matplotlib.pyplot as plt
import os

# === 1. Relativer Pfad zur Datei ===
dateiname = "5ohms_compare_710.xls"
pfad = os.path.join(os.path.dirname(__file__), dateiname)

# === 2. Datei einlesen (Excel mit Komma als Dezimaltrennzeichen) ===
df = pd.read_excel(pfad, skiprows=4, header=None, decimal=",")

# === 3. Spalten sinnvoll benennen ===
df.columns = ["Messpunkt", "Spannung (V)"]

# === 4. Plot erstellen ===
plt.figure(figsize=(8, 4))
plt.plot(df["Messpunkt"], df["Spannung (V)"], marker='o')
plt.title("Strommessung CH1 (aus 5ohms_compare_710.xls)")
plt.xlabel("Messpunkt")
plt.ylabel("Spannung (V)")
plt.grid(True)
plt.tight_layout()
plt.show()
