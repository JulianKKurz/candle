import cv2
import numpy as np
import os

img_path = r"C:\Users\z004v3vh\candle\Python\gamma-linear\julian.jpg"
folder = os.path.dirname(img_path)
filename = os.path.splitext(os.path.basename(img_path))[0]

def srgb_to_linear(img):
    img = img.astype(np.float32) / 255.0
    threshold = 0.04045
    linear = np.where(img <= threshold, img / 12.92, ((img + 0.055) / 1.055) ** 2.4)
    return np.clip(linear * 255.0, 0, 255).astype(np.uint8)

img_bgr = cv2.imread(img_path)
img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
img_linear = srgb_to_linear(img_rgb)

linear_path = os.path.join(folder, f"{filename}_linear.png")
cv2.imwrite(linear_path, cv2.cvtColor(img_linear, cv2.COLOR_RGB2BGR))
