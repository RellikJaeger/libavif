# `libavif` Android build

## Clone this branch from this repo

```Shell
git clone -b android --depth 1 https://github.com/RellikJaeger/libavif
cd libavif
```

## Setup build environment

Example:

```Shell
export ANDROID_SDK_HOME="/path/to/android-sdk"
export ANDROID_NDK_HOME="$ANDROID_SDK_HOME/ndk/<version>"
export PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/<platform-abi>/bin":$PATH
```

## Build for all supported Android architectures

Example:

```Shell
./build-all.sh
```

## Outputs

JNI Libs (Shared Object files) to embed in the Android project:

```Shell
jniLibs
├── arm64-v8a
│   └── libavif.so
├── armeabi-v7a
│   └── libavif.so
├── x86
│   └── libavif.so
└── x86_64
    └── libavif.so
```

## Copy the `jniLibs` folder and paste it into the Android project

```Shell
example/app/src/main/jniLibs/
├── arm64-v8a
│   └── libavif.so
├── armeabi-v7a
│   └── libavif.so
├── x86
│   └── libavif.so
└── x86_64
    └── libavif.so
```

## Configure `example/app/build.gradle`

```Groovy
android {
    // ...
    ndk {
      // Specifies the ABI configurations of your native
      // libraries Gradle should build and package with your app.
      abiFilters 'x86', 'x86_64', 'armeabi-v7a', 'arm64-v8a'
    }

    sourceSets {
        main {
            jniLibs.srcDirs = ['src/main/jniLibs']
        }
    }
    // ...
}
```

## Use the shared libraries

You can now use the pre-built shared libraries in your Android application. The libraries will be automatically packaged into the APK during the build process. To load and use the shared libraries in your code, use the System.loadLibrary() method. For example:

```Java
static {
    System.loadLibrary("avif");
}
```
