import math
import random
from PIL import Image, ImageDraw, ImageFilter

def create_nebula(width, height):
    img = Image.new("RGBA", (width, height), (7, 10, 22, 255))
    
    # Create soft nebula blobs on separate layers
    nebula_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    nebula_draw = ImageDraw.Draw(nebula_layer)
    
    # Violet / Indigo clusters
    for _ in range(12):
        cx = random.randint(100, width - 100)
        cy = random.randint(100, height - 100)
        rx = random.randint(250, 600)
        ry = random.randint(200, 450)
        alpha = random.randint(18, 45)
        # Deep royal purple / cyan hues
        col = random.choice([
            (60, 20, 110, alpha),
            (20, 60, 130, alpha),
            (10, 120, 150, alpha),
            (80, 30, 90, alpha)
        ])
        nebula_draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)
        
    nebula_layer = nebula_layer.filter(ImageFilter.GaussianBlur(80))
    img = Image.alpha_composite(img, nebula_layer)
    
    # Starfield layer
    star_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    star_draw = ImageDraw.Draw(star_layer)
    
    random.seed(42)
    # 600 tiny stars
    for _ in range(600):
        sx = random.randint(0, width - 1)
        sy = random.randint(0, height - 1)
        brightness = random.randint(100, 255)
        color = random.choice([
            (brightness, brightness, 255, random.randint(120, 220)),
            (brightness, 240, 255, random.randint(120, 220)),
            (255, brightness, 230, random.randint(100, 180)),
        ])
        star_draw.point((sx, sy), fill=color)
        
    # 80 medium glowing stars
    for _ in range(80):
        sx = random.randint(0, width - 1)
        sy = random.randint(0, height - 1)
        r = random.uniform(1.2, 2.5)
        star_draw.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(210, 240, 255, 220))
        # glow
        star_draw.ellipse([sx - r*3, sy - r*3, sx + r*3, sy + r*3], fill=(0, 200, 255, 45))
        
    # 8 bright cross stars
    for _ in range(8):
        sx = random.randint(100, width - 100)
        sy = random.randint(100, height - 100)
        star_draw.ellipse([sx - 3, sy - 3, sx + 3, sy + 3], fill=(255, 255, 255, 255))
        star_draw.line([sx - 12, sy, sx + 12, sy], fill=(100, 220, 255, 160), width=1)
        star_draw.line([sx, sy - 12, sx, sy + 12], fill=(100, 220, 255, 160), width=1)

    img = Image.alpha_composite(img, star_layer)
    return img

def generate_menu_bg():
    width, height = 1920, 1080
    bg = create_nebula(width, height)
    bg.save("asteroid_drift/assets/graphics/menu_bg.png", "PNG")
    print("menu_bg.png generated")


def generate_splash():
    width, height = 1920, 1080
    splash = create_nebula(width, height)
    
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    
    # Large centerpiece asteroids
    asteroids_info = [
        (450, 420, 160, -0.2),
        (1480, 680, 130, 0.5),
        (1350, 280, 80, -0.6),
        (350, 820, 70, 0.4)
    ]
    random.seed(999)
    for ax, ay, ar, rot in asteroids_info:
        pts = []
        num_pts = 12
        for i in range(num_pts):
            ang = rot + i * (2 * math.pi / num_pts)
            dist = ar * random.uniform(0.78, 1.18)
            pts.append((ax + math.cos(ang) * dist, ay + math.sin(ang) * dist))
        draw.polygon(pts, fill=(18, 28, 54, 220), outline=(56, 189, 248, 180), width=3)
        # Inner crater details
        for _ in range(4):
            cx = ax + random.uniform(-ar*0.5, ar*0.5)
            cy = ay + random.uniform(-ar*0.5, ar*0.5)
            cr = random.uniform(8, ar*0.2)
            draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(12, 18, 36, 180), outline=(30, 60, 100, 100))

    # Hero Spaceship in center flying right-up
    # Center position
    sx, sy = 960, 520
    ship_angle = -math.pi / 4.0 # 45 degrees up-right
    
    # Engine plume trail
    for step in range(1, 15):
        trail_dist = step * 18
        tx = sx - math.cos(ship_angle) * trail_dist
        ty = sy - math.sin(ship_angle) * trail_dist
        tr = max(2, 28 - step * 1.8)
        alpha = int(220 * (1.0 - step / 15.0))
        draw.ellipse([tx - tr, ty - tr, tx + tr, ty + tr], fill=(0, 229, 255, alpha))
        draw.ellipse([tx - tr*0.5, ty - tr*0.5, tx + tr*0.5, ty + tr*0.5], fill=(255, 255, 255, alpha))

    # Ship polygon
    ship_pts = [
        (sx + math.cos(ship_angle) * 75, sy + math.sin(ship_angle) * 75), # Nose
        (sx + math.cos(ship_angle + 2.5) * 60, sy + math.sin(ship_angle + 2.5) * 60), # Right wing
        (sx + math.cos(ship_angle + 3.14) * 35, sy + math.sin(ship_angle + 3.14) * 35), # Center engine back
        (sx + math.cos(ship_angle - 2.5) * 60, sy + math.sin(ship_angle - 2.5) * 60), # Left wing
    ]
    draw.polygon(ship_pts, fill=(14, 116, 144, 250), outline=(56, 189, 248, 255), width=4)
    
    # Shield arc around ship
    draw.arc([sx - 100, sy - 100, sx + 100, sy + 100], start=0, end=360, fill=(0, 255, 255, 90), width=3)
    
    splash = Image.alpha_composite(splash, overlay)
    splash.save("asteroid_drift/assets/graphics/splash.png", "PNG")
    print("splash.png generated")

if __name__ == "__main__":
    generate_menu_bg()
    generate_splash()
