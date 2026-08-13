#!/bin/bash
set -euo pipefail

# ---- Paths (env-driven, no hardcoding) ----
LIBAVIF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Android NDK: prefer ANDROID_NDK_HOME, else ANDROID_SDK_HOME/ndk/<dir>
if [ -n "${ANDROID_NDK_HOME:-}" ]; then
  NDK="$ANDROID_NDK_HOME"
elif [ -n "${ANDROID_SDK_HOME:-}" ]; then
  NDK="$ANDROID_SDK_HOME/ndk/"*
else
  echo "ERROR: set ANDROID_NDK_HOME (or ANDROID_SDK_HOME) before running." >&2
  exit 1
fi

# toolchains/llvm/prebuilt/<platform-abi> is supplied by the user via PATH
# (see README.md). Derive it from PATH instead of hardcoding.
TOOLCHAIN="$(echo "$PATH" | tr ':' '\n' | grep 'toolchains/llvm/prebuilt' | head -n1 | sed 's#/bin$##')"
if [ -z "$TOOLCHAIN" ]; then
  echo "ERROR: add the NDK prebuilt toolchain to PATH (export PATH=\"\$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/<platform-abi>/bin:\$PATH\")." >&2
  exit 1
fi

ANDROID_PLATFORM="android-21"
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

OUT_DIR="$LIBAVIF_ROOT/android/jniLibs"

# ---- Clean ----
rm -rf "$LIBAVIF_ROOT/android/build" "$OUT_DIR"

for abi in "${ABIS[@]}"; do
  echo "=== Building libavif.so for $abi ==="

  BUILD_DIR="$LIBAVIF_ROOT/android/build/$abi"
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"

  cmake -S "$LIBAVIF_ROOT" -B "$BUILD_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$abi" \
    -DANDROID_PLATFORM="$ANDROID_PLATFORM" \
    -DANDROID_STL="c++_static" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DAVIF_CODEC_DAV1D=ON \
    -DAVIF_CODEC_AOM=OFF \
    -DAVIF_CODEC_LIBGAV1=OFF \
    -DAVIF_CODEC_RAV1E=OFF \
    -DAVIF_LIBYUV=OFF \
    -DAVIF_BUILD_APPS=OFF \
    -DAVIF_BUILD_TESTS=OFF

  cmake --build "$BUILD_DIR" -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"

  mkdir -p "$OUT_DIR/$abi"
  cp "$BUILD_DIR/libavif.so" "$OUT_DIR/$abi/libavif.so"
  echo "  -> $OUT_DIR/$abi/libavif.so"
done

# ---- Cleanup temp build folder ----
rm -rf "$LIBAVIF_ROOT/android/build"

echo "=== Done. Output: $OUT_DIR ==="
