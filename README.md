# OneStateLogin - Any App

## Features
- Works on ANY iOS app
- Simple UIAlertController login screen
- No ImGui, No Metal

## Files
- `Makefile` - Build config
- `Tweak.xm` - Main code (in root folder)
- `control` - Package info

## Build
```bash
export THEOS=~/theos
make clean
make package
```

## Default Login
- Username: `admin`
- Password: `123456`
