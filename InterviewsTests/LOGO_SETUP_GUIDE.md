# Adding App Logo to iOS Project

## Logo Location
Source: `../interview-tools/public/logo.png`

## Steps to Add Logo to Xcode

### 1. Prepare Logo Assets

For iOS apps, you need multiple sizes. Here are the required dimensions for an app icon:

| Size | Purpose | Filename |
|------|---------|----------|
| 1024x1024 | App Store | AppIcon-1024.png |
| 180x180 | iPhone @3x | AppIcon-180.png |
| 120x120 | iPhone @2x | AppIcon-120.png |
| 87x87 | iPhone @3x Settings | AppIcon-87.png |
| 80x80 | iPhone @2x Spotlight | AppIcon-80.png |
| 60x60 | iPhone @1x Settings | AppIcon-60.png |
| 58x58 | iPhone @2x Settings | AppIcon-58.png |
| 40x40 | iPhone @1x Spotlight | AppIcon-40.png |

### 2. Generate Icon Sizes

#### Option A: Use Online Tool
1. Go to https://appicon.co or https://www.appicon.build
2. Upload your `logo.png`
3. Download the iOS icon set
4. Extract the zip file

#### Option B: Use Command Line (ImageMagick)
```bash
cd ../interview-tools/public

# Install ImageMagick if needed
brew install imagemagick

# Generate all required sizes
convert logo.png -resize 1024x1024 AppIcon-1024.png
convert logo.png -resize 180x180 AppIcon-180.png
convert logo.png -resize 120x120 AppIcon-120.png
convert logo.png -resize 87x87 AppIcon-87.png
convert logo.png -resize 80x80 AppIcon-80.png
convert logo.png -resize 60x60 AppIcon-60.png
convert logo.png -resize 58x58 AppIcon-58.png
convert logo.png -resize 40x40 AppIcon-40.png
```

#### Option C: Use Xcode Asset Generator Script

Create this script as `generate_icons.sh`:

```bash
#!/bin/bash

SOURCE="../interview-tools/public/logo.png"
OUTPUT_DIR="./AppIcons"

mkdir -p "$OUTPUT_DIR"

# Generate all sizes
sips -z 1024 1024 "$SOURCE" --out "$OUTPUT_DIR/AppIcon-1024.png"
sips -z 180 180 "$SOURCE" --out "$OUTPUT_DIR/AppIcon-180.png"
sips -z 120 120 "$SOURCE" --out "$OUTPUT_DIR/AppIcon-120.png"
sips -z 87 87 "$SOURCE" --out "$OUTPUT_DIR/AppIcon-87.png"
sips -z 80 80 "$SOURCE" --out "$OUTPUT_DIR/AppIcon-80.png"
sips -z 60 60 "$SOURCE" --out "$OUTPUT_DIR/AppIcon-60.png"
sips -z 58 58 "$SOURCE" --out "$OUTPUT_DIR/AppIcon-58.png"
sips -z 40 40 "$SOURCE" --out "$OUTPUT_DIR/AppIcon-40.png"

echo "✅ Icons generated in $OUTPUT_DIR"
```

Run it:
```bash
chmod +x generate_icons.sh
./generate_icons.sh
```

### 3. Add to Xcode Asset Catalog

#### Using Xcode GUI:

1. **Open Xcode project**
   - Open `Interviews.xcodeproj`

2. **Open Assets Catalog**
   - In Project Navigator, find `Assets.xcassets`
   - Click on it

3. **Find or Create AppIcon**
   - Look for "AppIcon" in the left sidebar
   - If it doesn't exist, right-click → New Image Set → rename to "AppIcon"
   - Make sure it's configured as "iOS App Icon"

4. **Drag and Drop Icons**
   - Drag each icon to its corresponding slot
   - Match the size labels in Xcode with your generated files

5. **Verify**
   - All slots should be filled (no empty boxes)
   - No warnings should appear

#### Using Finder (Faster):

1. Navigate to your Xcode project folder:
   ```bash
   cd path/to/Interviews/Interviews/Assets.xcassets
   ```

2. Find or create `AppIcon.appiconset` folder

3. Create/edit `Contents.json`:
   ```json
   {
     "images" : [
       {
         "filename" : "AppIcon-40.png",
         "idiom" : "iphone",
         "scale" : "2x",
         "size" : "20x20"
       },
       {
         "filename" : "AppIcon-60.png",
         "idiom" : "iphone",
         "scale" : "3x",
         "size" : "20x20"
       },
       {
         "filename" : "AppIcon-58.png",
         "idiom" : "iphone",
         "scale" : "2x",
         "size" : "29x29"
       },
       {
         "filename" : "AppIcon-87.png",
         "idiom" : "iphone",
         "scale" : "3x",
         "size" : "29x29"
       },
       {
         "filename" : "AppIcon-80.png",
         "idiom" : "iphone",
         "scale" : "2x",
         "size" : "40x40"
       },
       {
         "filename" : "AppIcon-120.png",
         "idiom" : "iphone",
         "scale" : "3x",
         "size" : "40x40"
       },
       {
         "filename" : "AppIcon-120.png",
         "idiom" : "iphone",
         "scale" : "2x",
         "size" : "60x60"
       },
       {
         "filename" : "AppIcon-180.png",
         "idiom" : "iphone",
         "scale" : "3x",
         "size" : "60x60"
       },
       {
         "filename" : "AppIcon-1024.png",
         "idiom" : "ios-marketing",
         "scale" : "1x",
         "size" : "1024x1024"
       }
     ],
     "info" : {
       "author" : "xcode",
       "version" : 1
     }
   }
   ```

4. Copy all generated PNG files into `AppIcon.appiconset` folder

### 4. Add Logo as Image Asset (for use in app UI)

If you want to use the logo **inside** the app (not just as app icon):

1. **In Xcode:**
   - Open `Assets.xcassets`
   - Right-click → New Image Set
   - Name it "Logo"

2. **Add Images:**
   - @1x: Drag original logo or 1x size
   - @2x: Drag 2x size (double resolution)
   - @3x: Drag 3x size (triple resolution)

3. **Use in SwiftUI:**
   ```swift
   Image("Logo")
       .resizable()
       .scaledToFit()
       .frame(width: 100, height: 100)
   ```

### 5. Verify Installation

1. **Build and Run:**
   ```bash
   Cmd + R
   ```

2. **Check Home Screen:**
   - Look at the app icon on the simulator/device
   - Should show your logo instead of default Xcode icon

3. **Check Asset Catalog:**
   - No warnings in Xcode
   - All icon slots filled

---

## Quick Command to Do Everything

Save this as `setup_logo.sh`:

```bash
#!/bin/bash

echo "🎨 Setting up app logo..."

# Source and destination
SOURCE="../interview-tools/public/logo.png"
ASSET_DIR="./Interviews/Assets.xcassets/AppIcon.appiconset"

# Check if source exists
if [ ! -f "$SOURCE" ]; then
    echo "❌ Error: Logo file not found at $SOURCE"
    exit 1
fi

# Create asset directory if needed
mkdir -p "$ASSET_DIR"

# Generate all icon sizes using sips (built into macOS)
echo "📐 Generating icon sizes..."
sips -z 1024 1024 "$SOURCE" --out "$ASSET_DIR/AppIcon-1024.png"
sips -z 180 180 "$SOURCE" --out "$ASSET_DIR/AppIcon-180.png"
sips -z 120 120 "$SOURCE" --out "$ASSET_DIR/AppIcon-120.png"
sips -z 87 87 "$SOURCE" --out "$ASSET_DIR/AppIcon-87.png"
sips -z 80 80 "$SOURCE" --out "$ASSET_DIR/AppIcon-80.png"
sips -z 60 60 "$SOURCE" --out "$ASSET_DIR/AppIcon-60.png"
sips -z 58 58 "$SOURCE" --out "$ASSET_DIR/AppIcon-58.png"
sips -z 40 40 "$SOURCE" --out "$ASSET_DIR/AppIcon-40.png"

# Create Contents.json
cat > "$ASSET_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon-40.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-60.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-58.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-87.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-80.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-120.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-120.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-180.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Logo setup complete!"
echo "📱 Open Xcode and build the project to see your new app icon"
```

Run it:
```bash
chmod +x setup_logo.sh
./setup_logo.sh
```

---

## Troubleshooting

### Issue: "Asset validation failed"
**Solution:** Make sure all images are exactly the right size and PNG format

### Issue: "Logo appears blurry"
**Solution:** Ensure you're providing @2x and @3x versions for retina displays

### Issue: "Icon doesn't update on device"
**Solution:** 
1. Delete app from device/simulator
2. Clean build folder (Cmd + Shift + K)
3. Rebuild and install

### Issue: "Alpha channel warning"
**Solution:** App icons cannot have transparency. Remove alpha channel:
```bash
convert logo.png -alpha off logo_no_alpha.png
```

---

## Best Practices

1. ✅ **Use vector if possible** - Start with SVG or high-res PNG (at least 1024x1024)
2. ✅ **No transparency** - App icons must be opaque
3. ✅ **Square design** - iOS will apply rounded corners automatically
4. ✅ **Safe margins** - Keep important elements away from edges
5. ✅ **Test on device** - Check how it looks on actual home screen
6. ✅ **Test in different contexts** - Spotlight, Settings, App Store

---

## Where Your Logo Will Appear

- 📱 **Home Screen** - Main app icon
- 🔍 **Spotlight Search** - When user searches
- ⚙️ **Settings** - In Settings app
- 🏪 **App Store** - Product page
- 📲 **Notifications** - If you send push notifications
- 🔄 **App Switcher** - When multitasking

Make sure it looks good at all sizes! 🎨
