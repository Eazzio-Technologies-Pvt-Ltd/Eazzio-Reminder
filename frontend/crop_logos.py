# pyrefly: ignore [missing-import]
import cv2
# pyrefly: ignore [missing-import]
import numpy as np

def make_transparent(img, bg_color_bgr, tolerance=25):
    # Convert BGR to BGRA
    bgra = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA)
    
    # Create mask for background color
    lower_bound = np.array([max(0, c - tolerance) for c in bg_color_bgr])
    upper_bound = np.array([min(255, c + tolerance) for c in bg_color_bgr])
    
    mask = cv2.inRange(img, lower_bound, upper_bound)
    
    # Set alpha channel to 0 where background matches
    bgra[mask > 0, 3] = 0
    
    return bgra

def process():
    image_path = r"C:\Users\asus\.gemini\antigravity-ide\brain\195497f5-159f-486a-a73a-294c130a7320\media__1781627568197.jpg"
    img = cv2.imread(image_path)
    if img is None:
        print("Failed to load image")
        return
        
    h, w, _ = img.shape
    print(f"Loaded image size: {w}x{h}")
    
    # Crop top half (Light Mode Logo)
    top_half = img[0:h//2, 0:w]
    # Crop bottom half (Dark Mode Logo)
    bottom_half = img[h//2:h, 0:w]
    
    # For Light Mode, background is white (typically around [255, 255, 255])
    # Let's read top-left pixel for exact background BGR
    light_bg = top_half[5, 5]
    print(f"Light logo background BGR: {light_bg}")
    logo_light = make_transparent(top_half, light_bg, tolerance=30)
    
    # For Dark Mode, background is navy (e.g. around [51, 17, 10])
    dark_bg = bottom_half[5, 5]
    print(f"Dark logo background BGR: {dark_bg}")
    logo_dark = make_transparent(bottom_half, dark_bg, tolerance=25)
    
    # Crop tightly to the content (remove empty transparent margins for better layout scaling)
    def crop_content(png_img):
        # Find all non-transparent pixels
        alpha = png_img[:, :, 3]
        pts = np.argwhere(alpha > 0)
        if len(pts) == 0:
            return png_img
        y1, x1 = pts.min(axis=0)
        y2, x2 = pts.max(axis=0)
        # Add a small padding of 5 pixels
        h_img, w_img, _ = png_img.shape
        y1 = max(0, y1 - 5)
        x1 = max(0, x1 - 5)
        y2 = min(h_img, y2 + 5)
        x2 = min(w_img, x2 + 5)
        return png_img[y1:y2, x1:x2]

    logo_light_cropped = crop_content(logo_light)
    logo_dark_cropped = crop_content(logo_dark)
    
    # Save the files
    light_out = r"c:\Users\asus\OneDrive\Desktop\eazzio-reminder\frontend\assets\images\logo_light.png"
    dark_out = r"c:\Users\asus\OneDrive\Desktop\eazzio-reminder\frontend\assets\images\logo_dark.png"
    
    cv2.imwrite(light_out, logo_light_cropped)
    cv2.imwrite(dark_out, logo_dark_cropped)
    print("Saved light logo to:", light_out)
    print("Saved dark logo to:", dark_out)

if __name__ == "__main__":
    process()
