//
//  ZaloModHooks.m
//  ZaloMod VIP - Runtime Method Swizzling & Tweak Injection
//  Thương hiệu: DucLamXNgBao
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "ZaloFloatingButton.h"
#import "ZaloModViewController.h"

@interface ZaloFloatingWindow : UIWindow
@end

@implementation ZaloFloatingWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self || hitView == self.rootViewController.view) {
        return nil; // Cho phép chạm xuyên thấu xuống Zalo!
    }
    return hitView;
}
@end

static ZaloFloatingWindow *gFloatingWindow = nil;

@interface ZaloModManager : NSObject <ZaloFloatingButtonDelegate, ZaloModViewControllerDelegate>
+ (instancetype)sharedManager;
- (void)setupFloatingButton;
@end

@implementation ZaloModManager

+ (instancetype)sharedManager {
    static ZaloModManager *mgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[ZaloModManager alloc] init];
    });
    return mgr;
}

- (void)setupFloatingButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (gFloatingWindow && !gFloatingWindow.hidden && [ZaloFloatingButton sharedInstance].superview) {
                return;
            }

            UIWindowScene *scene = nil;
            if (@available(iOS 13.0, *)) {
                for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
                    if ([s isKindOfClass:[UIWindowScene class]]) {
                        scene = (UIWindowScene *)s;
                        if (s.activationState == UISceneActivationStateForegroundActive) {
                            break;
                        }
                    }
                }
            }

            if (!gFloatingWindow) {
                if (scene && @available(iOS 13.0, *)) {
                    gFloatingWindow = [[ZaloFloatingWindow alloc] initWithWindowScene:scene];
                } else {
                    gFloatingWindow = [[ZaloFloatingWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                }
            } else if (scene && @available(iOS 13.0, *)) {
                gFloatingWindow.windowScene = scene;
            }

            gFloatingWindow.windowLevel = UIWindowLevelAlert + 1000.0;
            gFloatingWindow.backgroundColor = [UIColor clearColor];
            gFloatingWindow.hidden = NO;

            if (!gFloatingWindow.rootViewController) {
                UIViewController *rootVC = [[UIViewController alloc] init];
                rootVC.view.backgroundColor = [UIColor clearColor];
                rootVC.view.userInteractionEnabled = YES;
                gFloatingWindow.rootViewController = rootVC;
            }

            ZaloFloatingButton *bubble = [ZaloFloatingButton sharedInstance];
            bubble.delegate = self;
            if (bubble.superview != gFloatingWindow.rootViewController.view) {
                [bubble removeFromSuperview];
                [gFloatingWindow.rootViewController.view addSubview:bubble];
            }
            [bubble show];

            NSLog(@"[DucLamXNgBao] Đã khởi tạo Cục Menu Tròn Zalo VIP Mod thành công!");
        } @catch (NSException *exception) {
            NSLog(@"[DucLamXNgBao] Exception initializing floating button: %@", exception);
        }
    });
}

#pragma mark - ZaloFloatingButtonDelegate
- (void)floatingButtonDidTap:(id)sender {
    UIViewController *rootVC = gFloatingWindow.rootViewController;
    if (!rootVC) return;

    ZaloModViewController *menuVC = [ZaloModViewController sharedInstance];
    menuVC.delegate = self;
    [menuVC showMenuFromViewController:rootVC];
}

- (void)modMenuDidDismiss {
}

@end

// =========================================================================
// RUNTIME METHOD HOOKING (Anti-Undo, Bug Original, Bug ZBusiness, TTL)
// =========================================================================

// Hook 1: Anti-Undo với định dạng chuẩn yêu cầu:
// Text: "<text> ( đã thu hồi )" | Ảnh: "( đã thu hồi )\n[Ảnh HD]"
static void (*orig_deleteMessage)(id self, SEL _cmd, id msg, BOOL onlyMe);
static void hook_deleteMessage(id self, SEL _cmd, id msg, BOOL onlyMe) {
    if ([ZaloModViewController isAntiUndoEnabled]) {
        NSLog(@"[DucLamXNgBao Anti-Undo] Chặn xóa tin nhắn, giữ lại nội dung gốc!");
        
        // Cập nhật text theo đúng format
        if ([msg respondsToSelector:@selector(messageText)]) {
            NSString *curText = [msg performSelector:@selector(messageText)];
            if (curText && ![curText containsString:@"( đã thu hồi )"]) {
                NSString *newText = [NSString stringWithFormat:@"%@ ( đã thu hồi )", curText];
                if ([msg respondsToSelector:@selector(setMessageText:)]) {
                    [msg performSelector:@selector(setMessageText:) withObject:newText];
                }
            }
        } else if ([msg respondsToSelector:@selector(isPhotoMessage)] && [[msg performSelector:@selector(isPhotoMessage)] boolValue]) {
            // Tin nhắn ảnh: hiện "( đã thu hồi )\n[Ảnh HD]"
            if ([msg respondsToSelector:@selector(setCaption:)]) {
                [msg performSelector:@selector(setCaption:) withObject:@"( đã thu hồi )\n[Ảnh HD]"];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZaloFloatingButton sharedInstance] incrementBadge];
        });
        return; // Không cho xóa khỏi database hay UI!
    }
    if (orig_deleteMessage) {
        orig_deleteMessage(self, _cmd, msg, onlyMe);
    }
}

// Hook 2: Bug API is_original = 1 (Gửi ảnh gốc RAW HD)
static BOOL (*orig_isOriginalPhoto)(id self, SEL _cmd);
static BOOL hook_isOriginalPhoto(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) {
        return YES; // Bắt buộc is_original = 1
    }
    return orig_isOriginalPhoto ? orig_isOriginalPhoto(self, _cmd) : YES;
}

// Hook 3: Bug ZBusiness Pro & ZLStyle (Client-Side Spoofing)
static BOOL (*orig_isBusinessAccount)(id self, SEL _cmd);
static BOOL hook_isBusinessAccount(id self, SEL _cmd) {
    if ([ZaloModViewController isBugZBusinessEnabled]) {
        return YES; // Hiện nhãn Doanh Nghiệp ZBusiness Pro
    }
    return orig_isBusinessAccount ? orig_isBusinessAccount(self, _cmd) : NO;
}

static id (*orig_businessPackageName)(id self, SEL _cmd);
static id hook_businessPackageName(id self, SEL _cmd) {
    if ([ZaloModViewController isBugZBusinessEnabled]) {
        return @"ZBusiness Pro (Xác Thực Doanh Nghiệp)";
    }
    return orig_businessPackageName ? orig_businessPackageName(self, _cmd) : nil;
}

// Hook 4: Tự động gán Custom TTL vào mọi tin nhắn gửi đi
static NSInteger (*orig_messageTTL)(id self, SEL _cmd);
static NSInteger hook_messageTTL(id self, SEL _cmd) {
    NSInteger customTTL = [ZaloModViewController customTTLSeconds];
    if (customTTL > 0) {
        return customTTL; // Tự động có TTL
    }
    return orig_messageTTL ? orig_messageTTL(self, _cmd) : 0;
}

// =========================================================================
// SIRIKIT ENTITLEMENT BYPASS (Chống văng app 100% khi Sideload qua ESign/Scarlet)
// Lỗi gốc: "Use of the class [INPreferences] requires com.apple.developer.siri"
// =========================================================================
@interface FakeIntentsBypass : NSObject
+ (id)sharedPreferences;
+ (id)sharedVocabulary;
+ (id)siriLanguageCode;
@end

@implementation FakeIntentsBypass
+ (id)sharedPreferences { return nil; }
+ (id)sharedVocabulary { return nil; }
+ (id)siriLanguageCode { return @"vi-VN"; }
+ (void)requestSiriAuthorization:(void(^)(NSInteger status))handler {
    if (handler) handler(0);
}
@end

static void swizzleClassMethod(Class origClass, SEL origSel, Class fakeClass, SEL fakeSel) {
    if (!origClass || !fakeClass) return;
    Method origMethod = class_getClassMethod(origClass, origSel);
    Method fakeMethod = class_getClassMethod(fakeClass, fakeSel);
    if (origMethod && fakeMethod) {
        method_exchangeImplementations(origMethod, fakeMethod);
        NSLog(@"[DucLamXNgBao Hook] Successfully swizzled %@ to bypass entitlement check!", NSStringFromSelector(origSel));
    }
}

static void patchSiriKitCrash(void) {
    @try {
        Class prefClass = objc_getClass("INPreferences");
        if (prefClass) {
            swizzleClassMethod(prefClass, @selector(sharedPreferences), [FakeIntentsBypass class], @selector(sharedPreferences));
            swizzleClassMethod(prefClass, @selector(siriLanguageCode), [FakeIntentsBypass class], @selector(siriLanguageCode));
            swizzleClassMethod(prefClass, @selector(requestSiriAuthorization:), [FakeIntentsBypass class], @selector(requestSiriAuthorization:));
        }

        Class vocabClass = objc_getClass("INVocabulary");
        if (vocabClass) {
            swizzleClassMethod(vocabClass, @selector(sharedVocabulary), [FakeIntentsBypass class], @selector(sharedVocabulary));
        }
        NSLog(@"[DucLamXNgBao Hook] Đã vá lỗi com.apple.developer.siri (Chống văng app hoàn toàn)!");
    } @catch (NSException *e) {
        NSLog(@"[DucLamXNgBao Hook] Siri bypass error: %@", e);
    }
}

// Constructor Tweak
__attribute__((constructor))
static void initZaloModVIP(void) {
    // 1. Vá lỗi SiriKit ngay lập tức trước khi Zalo khởi tạo để chống văng app
    patchSiriKitCrash();

    NSLog(@"[DucLamXNgBao] Initializing Zalo VIP Mod Menu (iOS 26 Liquid Glass)...");

    void (^setupBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[ZaloModManager sharedManager] setupFloatingButton];
        });
    };

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:setupBlock];

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:setupBlock];

    if (@available(iOS 13.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserverForName:UISceneDidActivateNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:setupBlock];
    }

    // Fallback timers đảm bảo nút tròn luôn xuất hiện
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
}

