# OneStateLogin - Any App (Fixed)

## Features
- Works on ANY iOS app
- Simple UIAlertController login screen
- Fixed compilation errors

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
