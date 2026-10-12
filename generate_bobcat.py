from PIL import Image, ImageDraw

# Create RGBA image
width, height = 800, 500
img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Industrial colors
yellow = (245, 184, 0, 255)       # ORVEXA Industrial Yellow #F5B800
bright_yellow = (255, 210, 63, 255) # Bright Yellow #FFD23F
dark_gray = (37, 43, 47, 255)     # Dark Gray #252B2F
graphite = (21, 25, 28, 255)      # Graphite #15191C
white = (245, 246, 243, 255)      # White #F5F6F3
black = (8, 10, 11, 255)
orange_accent = (230, 90, 20, 255)

# Skid Steer Loader (Bobcat style) drawing relative coordinates
# Main body chassis
draw.rounded_rectangle([250, 200, 580, 380], radius=15, fill=yellow, outline=graphite, width=4)

# Cab enclosure (cabin)
draw.polygon([(340, 110), (480, 110), (520, 210), (320, 210)], fill=dark_gray, outline=yellow, width=3)
# Cab glass window
draw.polygon([(355, 122), (470, 122), (500, 200), (335, 200)], fill=(30, 45, 60, 220))
# Cage bars/mesh
draw.line([(390, 122), (390, 200)], fill=(100, 110, 120, 255), width=3)
draw.line([(430, 122), (430, 200)], fill=(100, 110, 120, 255), width=3)

# Rear engine hood / counterweight
draw.rounded_rectangle([220, 230, 330, 370], radius=10, fill=dark_gray, outline=yellow, width=3)
# ORVEXA text badge on side
draw.rectangle([360, 270, 520, 310], fill=graphite)
draw.text((375, 280), "ORVEXA", fill=yellow, font_size=24)

# Lift arm structure
draw.line([(260, 240), (460, 220)], fill=dark_gray, width=18)
draw.line([(260, 240), (460, 220)], fill=bright_yellow, width=12)
draw.line([(460, 220), (590, 300)], fill=dark_gray, width=18)
draw.line([(460, 220), (590, 300)], fill=bright_yellow, width=12)

# Hydraulic cylinders
draw.line([(340, 260), (450, 210)], fill=(180, 190, 200, 255), width=8)
draw.line([(480, 250), (560, 310)], fill=(180, 190, 200, 255), width=8)

# Front bucket
bucket_pts = [(560, 290), (680, 290), (700, 390), (550, 390)]
draw.polygon(bucket_pts, fill=dark_gray, outline=yellow, width=3)
# Bucket teeth
for x in range(560, 700, 25):
    draw.polygon([(x, 390), (x+12, 390), (x+6, 410)], fill=(150, 150, 150, 255))

# Wheels & Heavy Duty Tires
# Rear Wheel
draw.ellipse([250, 310, 370, 430], fill=black, outline=dark_gray, width=4)
draw.ellipse([275, 335, 345, 405], fill=yellow)
draw.ellipse([295, 355, 325, 385], fill=graphite)
# Front Wheel
draw.ellipse([430, 310, 550, 430], fill=black, outline=dark_gray, width=4)
draw.ellipse([455, 335, 525, 405], fill=yellow)
draw.ellipse([475, 355, 505, 385], fill=graphite)

# Tread details
for angle_offset in range(0, 360, 45):
    import math
    # Rear wheel treads
    rad = math.radians(angle_offset)
    x1 = 310 + math.cos(rad) * 50
    y1 = 370 + math.sin(rad) * 50
    x2 = 310 + math.cos(rad) * 60
    y2 = 370 + math.sin(rad) * 60
    draw.line([(x1, y1), (x2, y2)], fill=(80, 80, 80, 255), width=6)

    # Front wheel treads
    x1 = 490 + math.cos(rad) * 50
    y1 = 370 + math.sin(rad) * 50
    x2 = 490 + math.cos(rad) * 60
    y2 = 370 + math.sin(rad) * 60
    draw.line([(x1, y1), (x2, y2)], fill=(80, 80, 80, 255), width=6)

# Save
img.save("public/images/fleet/bobcat.png")
print("Saved clean bobcat image successfully!")
