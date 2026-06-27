# OneStateLogin - Any App

## Features
- Works on ANY iOS app
- Simple UIAlertController login screen
- No ImGui, No Metal
- Pure UIKit

## How to Build

### GitHub Actions (Automatic)
1. Fork this repository
2. Push to main branch
3. Download DEB or DYLIB from Artifacts

### Local Build (Mac)
```bash
export THEOS=~/theos
make clean
make package
```

## How to Use

### Method 1: Install DEB (Jailbreak)
```bash
dpkg -i com.yourname.onestatelogin_1.0.0_iphoneos-arm.deb
```

### Method 2: Inject DYLIB (No Jailbreak)
1. Extract dylib from DEB:
```bash
dpkg-deb -x com.yourname.onestatelogin_1.0.0_iphoneos-arm.deb /tmp/extract
cp /tmp/extract/Library/MobileSubstrate/DynamicLibraries/OneStateLogin.dylib .
```

2. Sign dylib:
```bash
ldid -S OneStateLogin.dylib
```

3. Inject using TrollFools, Esign, or Sideloadly into ANY app

## Default Login
- Username: `admin`
- Password: `123456`

## API Setup
Edit `Tweak.xm` and replace:
```objc
BOOL checkAPI(NSString *username, NSString *password, NSString *deviceID) {
    // Add your API call here
    return [username isEqualToString:@"admin"] && [password isEqualToString:@"123456"];
}
```

## License
MIT - For educational purposes only.
