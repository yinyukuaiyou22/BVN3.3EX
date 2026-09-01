#!/data/data/com.termux/files/usr/bin/sh
# ============================================================
# BVN3.3EX APK 打包脚本 - Termux 环境
# 用法: 在 Termux 终端执行: sh /sdcard/BVN3.3EX-master/tools/script/pack_termux.sh
# ============================================================
set -e

BVN_HOME="/sdcard/BVN3.3EX-master"
SDK_HOME="$BVN_HOME/flex4.16.1-air51.0.1.1"
ADT_JAR="$SDK_HOME/lib/adt.jar"
CERT="$SDK_HOME/bin/mycert.p12"
CERT_PASS="yinyu7798"
TEST_DIR="$BVN_HOME/tools/Test"
OUTPUT="$TEST_DIR/bvn.apk"

echo "========================================"
echo "  BVN3.3EX APK 打包 — Termux 环境"
echo "========================================"
echo ""

# Step 1: 安装依赖
echo "[1/5] 安装 Termux 依赖..."
pkg update -y -qq 2>/dev/null
pkg install -y aapt openjdk-17 wget 2>&1 | tail -5
echo "  [OK] aapt + openjdk-17 + wget"
echo ""

# Step 2: 下载 android.jar (platform-33)
echo "[2/5] 检查 android.jar..."
PLATFORM_DIR="$BVN_HOME/android-platform-33"
mkdir -p "$PLATFORM_DIR"
if [ ! -f "$PLATFORM_DIR/android.jar" ]; then
    echo "  正在下载 platform-33_r03.zip (~20MB)..."
    wget -q --show-progress -O /tmp/platform_33.zip \
        "https://dl.google.com/android/repository/platform-33_r03.zip"
    unzip -q -o /tmp/platform_33.zip "android.jar" -d "$PLATFORM_DIR/"
    rm -f /tmp/platform_33.zip
    echo "  [OK] android.jar 下载完成"
else
    echo "  [OK] android.jar 已存在"
fi
echo ""

# Step 3: 确认 launch.swf
echo "[3/5] 确认 launch.swf..."
if [ ! -f "$TEST_DIR/launch.swf" ]; then
    echo "  [FAIL] launch.swf 不存在! 请先编译"
    exit 1
fi
du -h "$TEST_DIR/launch.swf" | awk '{print "  [OK] launch.swf ("$1")"}'
echo ""

# Step 4: 部署 aapt
echo "[4/5] 部署 aapt..."
cp -f "$(which aapt)" "$SDK_HOME/lib/android/bin/aapt"
chmod +x "$SDK_HOME/lib/android/bin/aapt"
echo "  [OK] aapt -> SDK"
echo ""

# Step 5: ADT 打包
echo "[5/5] ADT 打包 APK..."
cd "$TEST_DIR"
java -jar "$ADT_JAR" \
    -package \
    -target apk-captive-runtime \
    -arch armv8 \
    -storetype pkcs12 \
    -keystore "$CERT" \
    -storepass "$CERT_PASS" \
    -platformsdk "$PLATFORM_DIR" \
    "$OUTPUT" \
    application.xml \
    launch.swf \
    2>&1

echo ""
if [ -f "$OUTPUT" ]; then
    echo "========================================"
    du -h "$OUTPUT" | awk '{print "  APK 打包成功: "$2" ("$1")"}'
    echo "  输出: $OUTPUT"
    echo "========================================"
else
    echo "========================================"
    echo "  [FAIL] APK 打包失败!"
    echo "========================================"
    exit 1
fi