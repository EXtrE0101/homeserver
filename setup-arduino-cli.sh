#!/bin/bash
# ==============================================================================
#  SHODH LABS — Arduino CLI Master Installer & Board Cores Provisioner
# ==============================================================================
set -e

echo "=============================================================================="
echo "⚡ INSTALLING & CONFIGURING ARDUINO-CLI FOR SHODH LABS (PICODEHUB)"
echo "=============================================================================="

# 1. Download and install arduino-cli globally
echo "📥 [1/6] Downloading latest official arduino-cli binary..."
sudo curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sudo BINDIR=/usr/local/bin sh
sudo chmod +x /usr/local/bin/arduino-cli

echo "✓ arduino-cli version: $(arduino-cli version)"

# 2. Configure USB Serial Port Permissions for Hardware Flashing
echo "🔌 [2/6] Configuring USB serial device permissions (dialout/tty)..."
sudo usermod -a -G dialout,tty extre0101 2>/dev/null || true
sudo usermod -a -G dialout,tty pi 2>/dev/null || true
sudo usermod -a -G dialout,tty www-data 2>/dev/null || true

# 3. Initialize Arduino CLI Configuration & Additional Board URLs
echo "⚙️  [3/6] Initializing board index registries..."
arduino-cli config init --overwrite 2>/dev/null || true

# Set additional Board URLs for ESP32, ESP8266, and Raspberry Pi Pico RP2040
arduino-cli config add board_manager.additional_urls https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json 2>/dev/null || true
arduino-cli config add board_manager.additional_urls https://arduino.esp8266.com/stable/package_esp8266com_index.json 2>/dev/null || true
arduino-cli config add board_manager.additional_urls https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json 2>/dev/null || true

# 4. Update Core Index
echo "🔄 [4/6] Updating board indexes..."
arduino-cli core update-index

# 5. Install Primary Microcontroller Cores
echo "📦 [5/6] Installing Microcontroller Cores (AVR, ESP32, ESP8266, RP2040)..."
echo "  • Installing Arduino AVR (Uno, Nano, Mega)..."
arduino-cli core install arduino:avr

echo "  • Installing ESP32 (Espressif IoT Module, NodeMCU-32S, ESP32-CAM)..."
arduino-cli core install esp32:esp32 || true

echo "  • Installing ESP8266 (NodeMCU v2/v3, Wemos D1)..."
arduino-cli core install esp8266:esp8266 || true

echo "  • Installing Raspberry Pi Pico (RP2040)..."
arduino-cli core install rp2040:rp2040 || true

# 6. Install Common IoT & Sensor Libraries
echo "📚 [6/6] Installing standard IoT sensor libraries..."
arduino-cli lib install "DHT sensor library" 2>/dev/null || true
arduino-cli lib install "Adafruit Unified Sensor" 2>/dev/null || true
arduino-cli lib install "Adafruit GFX Library" 2>/dev/null || true
arduino-cli lib install "Adafruit SSD1306" 2>/dev/null || true
arduino-cli lib install "SparkFun MAX3010x Pulse and Proximity Sensor Library" 2>/dev/null || true
arduino-cli lib install "ESP32Servo" 2>/dev/null || true

# Symlink to Site 1 bin folder if it exists
if [ -d "/var/www/site1" ]; then
    sudo mkdir -p /var/www/site1/bin
    sudo ln -sf /usr/local/bin/arduino-cli /var/www/site1/bin/arduino-cli
    sudo chown -R pi:pi /var/www/site1/bin 2>/dev/null || sudo chown -R $USER:$USER /var/www/site1/bin
fi

echo "=============================================================================="
echo "🎉 ARDUINO-CLI PROVISIONING COMPLETED SUCCESSFULLY!"
echo "=============================================================================="
echo "• Binary Location:      /usr/local/bin/arduino-cli"
echo "• Installed Cores:"
arduino-cli core list
echo "• Connected Hardware Devices:"
arduino-cli board list
echo "=============================================================================="
