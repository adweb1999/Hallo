// Tweak.xm - OneStateLogin (زر يعمل + رسائل واضحة)

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
    self.loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 410, self.view.bounds.size.width-80, 100)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:self.statusLabel];
}

- (void)loginTapped {
    NSString *username = [self.usernameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (username.length == 0 || password.length == 0) {
        self.statusLabel.textColor = [UIColor redColor];
        self.statusLabel.text = @"❌ يرجى ملء اسم المستخدم وكلمة المرور";
        return;
    }
    
    self.loginButton.enabled = NO;
    self.statusLabel.textColor = [UIColor yellowColor];
    self.statusLabel.text = @"🔄 جاري الاتصال بالخادم...";
    
    // اختبار أولي
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        self.statusLabel.textColor = [UIColor greenColor];
        self.statusLabel.text = @"✅ الزر يعمل!\nجاري محاولة الاتصال...";
        
        // محاولة الاتصال الحقيقية
        [self performRealLogin:username password:password];
    });
}

- (void)performRealLogin:(NSString *)username password:(NSString *)password {
    NSURL *url = [NSURL URLWithString:JSON_BIN_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:MASTER_KEY forHTTPHeaderField:@"X-Master-Key"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.statusLabel.textColor = [UIColor redColor];
                self.statusLabel.text = [NSString stringWithFormat:@"❌ خطأ اتصال:\n%@", error.localizedDescription];
                self.loginButton.enabled = YES;
                return;
            }
            
            if (!data) {
                self.statusLabel.text = @"❌ لا يوجد رد من الخادم";
                self.loginButton.enabled = YES;
                return;
            }
            
            self.statusLabel.textColor = [UIColor greenColor];
            self.statusLabel.text = @"✅ تم الاتصال بنجاح!\n(سيتم إكمال التحقق قريباً)";
            self.loginButton.enabled = YES;
        });
    }];
    [task resume];
}

@end

// ==================== HOOKS ====================
static UIWindow *getKeyWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) if (w.isKeyWindow) return w;
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

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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
    NSLog(@"[OneStateLogin] Button Test Version Loaded");
}
