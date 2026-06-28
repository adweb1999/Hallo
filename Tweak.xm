// Tweak.xm - OneStateLogin (Forced + Fixed)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==================== CONFIG ====================
#define JSON_BIN_URL @"https://api.jsonbin.io/v3/b/6a4071d6f5f4af5e293b11e4/latest"
#define MASTER_KEY @"$2a$10$0Z3J8lUjgst.0aESOMXKukNSTXEjRAcTUwzYeV5RS8r6N4HDCbg6"

// ==================== LOGIN CONTROLLER ====================
@interface OneStateLoginViewController : UIViewController
@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation OneStateLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 60)];
    title.text = @"OneState Login";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:32];
    title.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:title];
    
    self.usernameField = [[UITextField alloc] initWithFrame:CGRectMake(40, 200, self.view.bounds.size.width-80, 50)];
    self.usernameField.placeholder = @"اسم المستخدم";
    self.usernameField.borderStyle = UITextBorderStyleRoundedRect;
    self.usernameField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.usernameField];
    
    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(40, 270, self.view.bounds.size.width-80, 50)];
    self.passwordField.placeholder = @"كلمة المرور";
    self.passwordField.secureTextEntry = YES;
    self.passwordField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.passwordField];
    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton.frame = CGRectMake(40, 340, self.view.bounds.size.width-80, 55);
    [self.loginButton setTitle:@"تسجيل الدخول" forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor systemBlueColor];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 410, self.view.bounds.size.width-80, 80)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    [self.view addSubview:self.statusLabel];
}

- (void)loginTapped {
    self.statusLabel.textColor = [UIColor yellowColor];
    self.statusLabel.text = @"جاري التحقق...";
    self.loginButton.enabled = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        self.statusLabel.textColor = [UIColor greenColor];
        self.statusLabel.text = @"✅ تم تسجيل الدخول (اختبار)";
    });
}

@end

// ==================== SAFE KEY WINDOW ====================
static UIWindow *getKeyWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) return window;
                }
            }
        }
        return nil;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [[UIApplication sharedApplication] keyWindow];
#pragma clang diagnostic pop
    }
}

// ==================== FORCED HOOKS ====================
%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.6 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *kw = getKeyWindow();
        if (kw) {
            OneStateLoginViewController *vc = [[OneStateLoginViewController alloc] init];
            vc.view.frame = kw.bounds;
            [kw addSubview:vc.view];
            [kw bringSubviewToFront:vc.view];
        }
    });
}
%end

%ctor {
    %init;
    NSLog(@"[OneStateLogin] Forced Stable Version Loaded");
}
