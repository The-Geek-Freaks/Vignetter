<div align="center">
  <h1>🎨 Vignetter for OBS Studio</h1>
  <p>A comprehensive vignette effect filter plugin for OBS Studio with advanced customization options.</p>
  <p>Perfect for streamers, content creators, and professional broadcasters.</p>

  ![Downloads](https://img.shields.io/github/downloads/The-Geek-Freaks/Vignetter/total)
  ![Version](https://img.shields.io/badge/Version-2.0.0-blue)
  ![Python](https://img.shields.io/badge/OBS--Lua-Compatible-green.svg)
  ![OBS](https://img.shields.io/badge/OBS-30.0+-purple.svg)
  ![Windows](https://img.shields.io/badge/Windows-10%2F11-blue)
  ![macOS](https://img.shields.io/badge/macOS-11.0+-silver)
  ![Linux](https://img.shields.io/badge/Linux-Compatible-orange)
  ![License](https://img.shields.io/badge/License-GPLv3-blue.svg)
  [![Discord](https://img.shields.io/discord/397127284114325504?label=Discord&logo=discord)](https://tgf.click/discord)
</div>

<div align="center">
  <img src="docs/banner.png" alt="Vignetter Interface" width="800"/>
</div>

## 📑 Table of Contents
- [✨ Key Features](#-key-features)
- [🎯 Use Cases](#-use-cases)
- [💻 Installation](#-installation)
- [🎨 Presets & Shapes](#-presets--shapes)
- [🛠️ Configuration](#️-configuration)
- [🎮 Usage](#-usage)
- [📸 Examples](#-examples)
- [🔧 Troubleshooting](#-troubleshooting)
- [📄 License](#-license)

## ✨ Key Features

### 🖌️ Advanced Vignette Customization
- **Highly Configurable Effects**: 
  - Adjust intensity, roundness, feathering, and opacity
  - Precise positioning with center X/Y controls
  - Real-time preview for immediate visual feedback
- **Multiple Vignette Shapes**:
  - Classic oval vignette
  - Rectangular with adjustable corner radius
  - Diamond shape for creative effects
  - Star shape for decorative purposes

<div align="center">
  <img src="docs/features-shapes.png" alt="Vignetter Shape Options" width="700"/>
  <p><i>Different shape options available in Vignetter</i></p>
</div>

### 🎨 Creative Color Control
- **Custom Color Options**:
  - Use default darkening effect or choose custom colors
  - RGB color control for precise tint selection
  - Multiple blend modes (Normal, Multiply, Screen, Overlay)
- **Professional Presets**:
  - 16+ built-in presets including Cinematic, Vintage, Horror, and more
  - Creative options like Cyberpunk, Neon Lights, and Retro Gaming
  - Easy switching between different looks

<div align="center">
  <img src="docs/features-colors.png" alt="Vignetter Color Options" width="700"/>
  <p><i>Color customization interface</i></p>
</div>

### ⚙️ Professional Features
- **Advanced Shape Control**:
  - Rotation for dynamic angle adjustment
  - Shape strength for intensity control
  - Aspect ratio adjustment for stretching effects
- **Localization**:
  - Built-in support for English and German
  - Easily expandable to other languages
  - Automatic language detection

## 🎯 Use Cases

### Streaming Setup
- Create professional-looking stream borders
- Add mood and atmosphere to gaming content
- Highlight specific areas of your broadcast
- Create distinct visual styles for different stream segments

<div align="center">
  <img src="docs/usecase-streaming.png" alt="Vignetter in streaming setup" width="700"/>
  <p><i>Example of Vignetter enhancing a gaming stream</i></p>
</div>

### Content Creation
- Add cinematic quality to video productions
- Create nostalgic vintage looks for themed content
- Enhance focus on subjects with targeted vignetting
- Match visual style to branding with custom colors

### Creative Effects
- Design unique overlays with star and diamond shapes
- Create cyberpunk or futuristic aesthetics
- Develop signature looks with custom presets
- Enhance mood with color-tinted vignettes

<div align="center">
  <img src="docs/usecase-creative.png" alt="Creative vignette effects" width="700"/>
  <p><i>Creative vignette effects using different shapes and colors</i></p>
</div>

## 💻 Installation

1. Download the latest release from the [Releases](https://github.com/TheGeekFreaks/Vignetter/releases) page
2. Place the script in your OBS scripts folder:
   - Windows: `%APPDATA%\obs-studio\scripts`
   - macOS: `~/Library/Application Support/obs-studio/scripts`
   - Linux: `~/.config/obs-studio/scripts`
3. In OBS Studio:
   - Go to Tools → Scripts
   - Click the + button
   - Select the downloaded `vignetter.lua` file
   - Add as a filter to any source or scene

<div align="center">
  <img src="docs/installation.png" alt="Vignetter installation" width="700"/>
  <p><i>Installing Vignetter in OBS Studio</i></p>
</div>

### Platform-Specific Notes

#### Windows
- Compatible with Windows 10/11
- OBS Studio 30.0+ recommended
- No additional dependencies required

#### macOS
- Compatible with macOS 11.0 (Big Sur) or higher
- OBS Studio 30.0+ recommended
- No additional dependencies required

#### Linux
- Compatible with most modern distributions
- OBS Studio 30.0+ recommended
- No additional dependencies required

## 🎨 Presets & Shapes

### Built-in Presets
Vignetter includes 16+ professionally designed presets for instant looks:

1. **Cinematic Look**: Film-like widescreen appearance
2. **Sepia Tone**: Warm vintage effect
3. **Oval Vignette**: Traditional photography style
4. **Dramatic Contrast**: Strong vignette with high contrast
5. **Vintage Look**: Faded colors with subtle sepia
6. **Horror/Mystery**: Dark with slight blue tint
7. **Dream Sequence**: Soft with white glow
8. **Focus Vignette**: Highlights specific areas

<div align="center">
  <img src="docs/presets-standard.png" alt="Standard vignette presets" width="700"/>
  <p><i>Standard vignette presets in action</i></p>
</div>

**Creative Presets**:
- **Glowing Borders**: Inverted with golden edges
- **Cyberpunk**: Futuristic with blue tones
- **Split-Toning**: Diamond shape with warm orange
- **Retro Gaming**: Star-shaped purple vignette
- **Old Film**: Strong edge darkening
- **Sunset**: Warm orange tones
- **Duotone**: Blue-green contrast
- **Neon Lights**: Vibrant pink club-like effect

<div align="center">
  <img src="docs/presets-creative.png" alt="Creative vignette presets" width="700"/>
  <p><i>Creative presets for unique visual styles</i></p>
</div>

### Available Shapes
- **Oval**: Traditional rounded vignette
- **Rectangle**: Squared edges with adjustable corners
- **Diamond**: Angular creative effect
- **Star**: Decorative star-shaped pattern

## 🛠️ Configuration

### Basic Settings
1. **Radius Controls**:
   - Inner Radius: Size of visible area (0.0-5.0)
   - Outer Radius: Extension of vignette (0.0-5.0)
   - Opacity: Effect transparency (0.0-1.0)

2. **Position Controls**:
   - Center X/Y: Position of vignette (0.0-1.0)
   - Aspect Ratio: Width/height shape ratio (0.5-2.0)

3. **Shape Options**:
   - Shape Type: Select between oval, rectangle, diamond, or star
   - Shape Strength: Intensity of shape effect (0.5-2.0)
   - Rotation: Angle of the vignette shape (0.0-360.0)

<div align="center">
  <img src="docs/configuration-interface.png" alt="Vignetter configuration interface" width="700"/>
  <p><i>Vignetter's comprehensive configuration interface</i></p>
</div>

### Color Settings
- **Custom Color Toggle**: Enable/disable custom vignette color
- **RGB Controls**: Adjust red, green, and blue components (0.0-1.0)
- **Blend Mode**: Choose between Normal, Multiply, Screen, and Overlay

## 🎮 Usage

1. **Adding the Filter**:
   - In OBS, right-click any source → Filters
   - Click "+" under Effect Filters
   - Select "Vignetter"

<div align="center">
  <img src="docs/usage-add-filter.png" alt="Adding Vignetter as a filter" width="700"/>
  <p><i>Adding Vignetter as a filter in OBS Studio</i></p>
</div>

2. **Quick Setup**:
   - Choose a preset from the dropdown menu
   - Adjust basic parameters as needed
   - Fine-tune color and shape settings

3. **Advanced Customization**:
   - Select vignette shape
   - Adjust position and rotation
   - Set custom color and blend mode
   - Fine-tune radius and opacity

<div align="center">
  <img src="docs/usage-advanced.png" alt="Advanced Vignetter customization" width="700"/>
  <p><i>Advanced customization options in action</i></p>
</div>

## 📸 Examples

Here are some examples of different vignette effects created with the plugin:

<div align="center">
  <img src="docs/example-cinematic.png" alt="Cinematic vignette" width="700"/>
  <p><i>Cinematic vignette preset</i></p>
</div>

<div align="center">
  <img src="docs/example-horror.png" alt="Horror vignette" width="700"/>
  <p><i>Horror/Mystery vignette preset</i></p>
</div>

<div align="center">
  <img src="docs/example-cyberpunk.png" alt="Cyberpunk vignette" width="700"/>
  <p><i>Cyberpunk vignette preset</i></p>
</div>

<div align="center">
  <img src="docs/example-retro.png" alt="Retro Gaming vignette" width="700"/>
  <p><i>Retro Gaming vignette preset with star shape</i></p>
</div>

## 🔧 Troubleshooting

### Common Issues
1. **Filter Not Appearing**:
   - Ensure script is properly installed
   - Check OBS Studio version (30.0+ recommended)
   - Try restarting OBS

2. **Visual Glitches**:
   - Reset parameters to defaults
   - Try a different preset
   - Check for graphics driver updates

3. **Performance Issues**:
   - Reduce complexity of other effects
   - Consider hardware requirements
   - Update to latest OBS version

### Support
- Check the [GitHub Issues](https://github.com/TheGeekFreaks/Vignetter/issues) page
- Join our [Discord](https://tgf.click/discord) for help
- Submit detailed bug reports with OBS logs

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <p> TheGeekFreaks &copy; 2025</p>
  <p>
    <a href="https://tgf.click/discord">Discord</a> &bull;
    <a href="https://github.com/TheGeekFreaks">GitHub</a> &bull;
    <a href="https://www.youtube.com/TheGeekFreaks">YouTube</a>
  </p>
</div>
