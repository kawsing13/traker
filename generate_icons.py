from PIL import Image
import os

logo_path = r'c:\Users\jonat\StudioProjects\traker\assets\images\geckotech_logo.png'
base_dir = r'c:\Users\jonat\StudioProjects\traker\android\app\src\main\res'

print(f"Loading image from: {logo_path}")
img = Image.open(logo_path).convert('RGBA')
print(f"Original image size: {img.size}")

sizes = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192
}

for density, size in sizes.items():
    target_dir = os.path.join(base_dir, f'mipmap-{density}')
    os.makedirs(target_dir, exist_ok=True)
    
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    output_path = os.path.join(target_dir, 'ic_launcher.png')
    resized.save(output_path, 'PNG')
    print(f"Created: {output_path}")

print("All icon sizes created successfully!")
