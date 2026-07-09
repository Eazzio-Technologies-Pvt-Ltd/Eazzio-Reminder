# pyrefly: ignore [missing-import]
import cv2
# pyrefly: ignore [missing-import]
import numpy as np

def analyze_image(path):
    img = cv2.imread(path)
    if img is None:
        print(f"Could not load image at {path}")
        return
    # Find dominant color (excluding pure white/black if needed, but background is most pixels)
    # Let's take the color of the top-right corner pixel as background
    h, w, c = img.shape
    corner_color = img[10, w - 10]
    print(f"Image: {path}")
    print(f"Corner Pixel (BGR): {corner_color}")
    print(f"Corner Pixel (HEX): #{corner_color[2]:02x}{corner_color[1]:02x}{corner_color[0]:02x}")
    
    # Get unique colors and counts
    pixels = img.reshape(-1, 3)
    unique_colors, counts = np.unique(pixels, axis=0, return_counts=True)
    # Sort by counts
    sorted_idx = np.argsort(-counts)
    print("Top 5 dominant colors (BGR):")
    for i in range(min(5, len(sorted_idx))):
        color = unique_colors[sorted_idx[i]]
        count = counts[sorted_idx[i]]
        print(f"Color: #{color[2]:02x}{color[1]:02x}{color[0]:02x} - count: {count}")

analyze_image(r"C:\Users\asus\.gemini\antigravity-ide\brain\01b3eccf-248b-4124-a4dd-05f1806504cd\media__1781447981683.png")
analyze_image(r"C:\Users\asus\.gemini\antigravity-ide\brain\01b3eccf-248b-4124-a4dd-05f1806504cd\media__1781448080931.png")
