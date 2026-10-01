//
//  ZaloModHooks.m
//  ZaloMod VIP - Runtime Method Swizzling & Tweak Injection
//  Thương hiệu: DucLamXNgBao
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "ZaloFloatingButton.h"
#import "ZaloModViewController.h"
#import "ZaloModFontHelper.h"

// =========================================================================
// 1. FLOATING WINDOW (CỤC MENU TRÒN CHẠM XUYÊN THẤU)
// =========================================================================
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
                if (@available(iOS 13.0, *)) {
                    if (scene) {
                        gFloatingWindow = [[ZaloFloatingWindow alloc] initWithWindowScene:scene];
                    } else {
                        gFloatingWindow = [[ZaloFloatingWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                    }
                } else {
                    gFloatingWindow = [[ZaloFloatingWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                }
            } else {
                if (@available(iOS 13.0, *)) {
                    if (scene) {
                        gFloatingWindow.windowScene = scene;
                    }
                }
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
// 2. HELPER SWIZZLING
// =========================================================================
static void swizzleInstanceMethod(Class cls, SEL origSel, SEL swizSel) {
    if (!cls) return;
    Method origMethod = class_getInstanceMethod(cls, origSel);
    Method swizMethod = class_getInstanceMethod(cls, swizSel);
    if (origMethod && swizMethod) {
        if (class_addMethod(cls, origSel, method_getImplementation(swizMethod), method_getTypeEncoding(swizMethod))) {
            class_replaceMethod(cls, swizSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
        } else {
            method_exchangeImplementations(origMethod, swizMethod);
        }
    }
}

// =========================================================================
// 3. FONT HOOK (12 FONT CHỮ NGHỆ THUẬT KHI NHẬP VÀ GỬI TIN NHẮN)
// =========================================================================
@interface UITextView (ZaloModFontHook)
@end

@implementation UITextView (ZaloModFontHook)
- (void)zaloMod_insertText:(NSString *)text {
    NSString *selectedFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"ZaloMod_SelectedFont"];
    if (selectedFont && ![selectedFont isEqualToString:@"Tắt"] && text.length > 0) {
        NSString *converted = [ZaloModFontHelper convertText:text toStyle:selectedFont];
        [self zaloMod_insertText:converted];
    } else {
        [self zaloMod_insertText:text];
    }
}
@end

@interface UITextField (ZaloModFontHook)
@end

@implementation UITextField (ZaloModFontHook)
- (void)zaloMod_insertText:(NSString *)text {
    NSString *selectedFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"ZaloMod_SelectedFont"];
    if (selectedFont && ![selectedFont isEqualToString:@"Tắt"] && text.length > 0) {
        NSString *converted = [ZaloModFontHelper convertText:text toStyle:selectedFont];
        [self zaloMod_insertText:converted];
    } else {
        [self zaloMod_insertText:text];
    }
}
@end

// =========================================================================
// 4. CHỐNG THU HỒI TIN NHẮN (ANTI-UNDO) - GIỮ NGUYÊN NỘI DUNG VÀ BONG BÓNG CHAT
// =========================================================================
static void hook_UndoChatProcessor_updateUndoMessageContent(id self, SEL _cmd, id chat) {
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(object_getClass(self), sel_registerName("zaloMod_orig_updateUndoMessageContent:"));
    if (orig) orig(self, _cmd, chat);

    if ([ZaloModViewController isAntiUndoEnabled] && chat) {
        SEL origRecallSel = sel_registerName("_originTextRecallMsg");
        SEL msgSel = sel_registerName("message");
        SEL setMsgSel = sel_registerName("setMessage:");

        NSString *origText = nil;
        if ([chat respondsToSelector:origRecallSel]) {
            origText = ((id (*)(id, SEL))objc_msgSend)(chat, origRecallSel);
        }
        if (!origText || origText.length == 0) {
            if ([chat respondsToSelector:msgSel]) {
                origText = ((id (*)(id, SEL))objc_msgSend)(chat, msgSel);
            }
        }
        if (!origText || origText.length == 0) {
            origText = @"[Tin nhắn đã gửi]";
        }

        if (origText && origText.length > 0 && ![origText containsString:@"( đã thu hồi )"]) {
            NSString *annotatedMsg = [NSString stringWithFormat:@"%@ ( đã thu hồi )", origText];
            if ([chat respondsToSelector:setMsgSel]) {
                ((void (*)(id, SEL, id))objc_msgSend)(chat, setMsgSel, annotatedMsg);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZaloFloatingButton sharedInstance] incrementBadge];
        });
    }
}

// Hook hiển thị nhãn thu hồi trên UI (an toàn, không đụng vào CoreText calculation)
@interface UILabel (ZaloModAntiUndo)
@end

@implementation UILabel (ZaloModAntiUndo)
- (void)zaloMod_setText:(NSString *)text {
    if ([ZaloModViewController isAntiUndoEnabled] && text && text.length > 0) {
        if ([text containsString:@"Tin nhắn đã được thu hồi"] || [text containsString:@"Message recalled"]) {
            text = [NSString stringWithFormat:@"%@ ( đã chặn thu hồi )", text];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[ZaloFloatingButton sharedInstance] incrementBadge];
            });
        }
    }
    [self zaloMod_setText:text];
}
@end

// =========================================================================
// 5. MỞ KHÓA GỬI ẢNH GỐC & HD (KHÔNG BỊ BẮT MUA ZCLOUD)
// =========================================================================
// Hook QualityPickerViewController (Bảng chọn chế độ gửi ảnh)
static BOOL hook_enableShowOriginPhoto(id self, SEL _cmd) {
    return YES; // Cho phép hiển thị nút Original!
}

static NSInteger hook_originalBadgeType(id self, SEL _cmd) {
    return 0; // Bỏ huy hiệu khóa zCloud!
}

static id hook_originalBadge(id self, SEL _cmd) {
    return nil; // Xóa chữ zCloud!
}

// =========================================================================
// 5b. HOOK TỰ ĐỘNG GÁN TTL (24H, 1H, 5P,...) VÀO TIN NHẮN (CHUẨN MILLISECONDS)
// =========================================================================
static id hook_syncMessageWithCurrentDisappearingTTLIfNeed(id self, SEL _cmd, id chat) {
    id (*orig)(id, SEL, id) = (id (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatDataManager"), sel_registerName("zaloMod_orig_syncMessageWithCurrentDisappearingTTLIfNeed:"));
    id result = orig ? orig(self, _cmd, chat) : chat;
    if (!result) result = chat;

    NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
    if (ttlSecs > 0) {
        long long ttlMs = (long long)ttlSecs * 1000LL;
        SEL setTtlSel = sel_registerName("setTtl:");
        if ([result respondsToSelector:setTtlSel]) {
            ((void (*)(id, SEL, long long))objc_msgSend)(result, setTtlSel, ttlMs);
        }
        if (chat != result && [chat respondsToSelector:setTtlSel]) {
            ((void (*)(id, SEL, long long))objc_msgSend)(chat, setTtlSel, ttlMs);
        }
    }
    return result;
}

static BOOL hook_attachTTLValueForMessageIfNeed(id self, SEL _cmd, id chat) {
    BOOL (*orig)(id, SEL, id) = (BOOL (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatDataManager"), sel_registerName("zaloMod_orig_attachTTLValueForMessageIfNeed:"));
    BOOL res = orig ? orig(self, _cmd, chat) : NO;

    NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
    if (ttlSecs > 0 && chat) {
        long long ttlMs = (long long)ttlSecs * 1000LL;
        SEL setTtlSel = sel_registerName("setTtl:");
        if ([chat respondsToSelector:setTtlSel]) {
            ((void (*)(id, SEL, long long))objc_msgSend)(chat, setTtlSel, ttlMs);
        }
        return YES;
    }
    return res;
}

// Chống tin nhắn bị đếm ngược quá nhanh hoặc tự xóa trước khi đủ thời gian
static BOOL hook_ChatEntity_isExpiredMessage(id self, SEL _cmd) {
    long long ttl = 0;
    SEL ttlSel = sel_registerName("ttl");
    if ([self respondsToSelector:ttlSel]) {
        ttl = ((long long (*)(id, SEL))objc_msgSend)(self, ttlSel);
    }
    if (ttl <= 0) return NO;

    // Tự động scale nếu ttl bị gán theo giây thay vì milliseconds
    if (ttl > 0 && ttl < 1000) {
        ttl = ttl * 1000LL;
        SEL setTtlSel = sel_registerName("setTtl:");
        if ([self respondsToSelector:setTtlSel]) {
            ((void (*)(id, SEL, long long))objc_msgSend)(self, setTtlSel, ttl);
        }
    }

    double createTime = 0;
    SEL tsSel = sel_registerName("ts");
    if ([self respondsToSelector:tsSel]) {
        createTime = ((double (*)(id, SEL))objc_msgSend)(self, tsSel);
    }
    if (createTime <= 0) {
        SEL timeSel = sel_registerName("time");
        if ([self respondsToSelector:timeSel]) {
            createTime = ((double (*)(id, SEL))objc_msgSend)(self, timeSel) * 1000.0;
        }
    }

    if (createTime > 0 && ttl > 0) {
        double nowMs = [[NSDate date] timeIntervalSince1970] * 1000.0;
        double expireAtMs = createTime + (double)ttl;
        if (nowMs < expireAtMs) {
            return NO; // Chưa đủ thời gian hết hạn -> Giữ nguyên tin nhắn!
        }
    }

    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("ChatEntity"), sel_registerName("zaloMod_orig_isExpiredMessage"));
    return orig ? orig(self, _cmd) : NO;
}

@interface NSJSONSerialization (ZaloModTTL)
@end

@implementation NSJSONSerialization (ZaloModTTL)
+ (NSData *)zaloMod_dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
        NSMutableDictionary *dict = nil;
        if (ttlSecs > 0) {
            dict = [obj mutableCopy];
            if (dict[@"text"] || dict[@"msg"] || dict[@"cmsg"] || dict[@"content"]) {
                long long ttlMs = (long long)ttlSecs * 1000LL;
                dict[@"ttl"] = @(ttlMs);
                dict[@"ttl_sec"] = @(ttlSecs);
                dict[@"ttl_server"] = @(ttlMs);
            }
        }
        if ([ZaloModViewController isBugOriginalEnabled]) {
            if (!dict) dict = [obj mutableCopy];
            if (dict[@"hd"] || dict[@"photo"] || dict[@"image"] || dict[@"thumb"]) {
                dict[@"is_original"] = @(1);
            }
        }
        if (dict) {
            return [self zaloMod_dataWithJSONObject:dict options:opt error:error];
        }
    }
    return [self zaloMod_dataWithJSONObject:obj options:opt error:error];
}
@end

// =========================================================================
// 6. NATIVE ZALO BUSINESS ACCOUNT HOOK (CHUẨN CHÍNH HÃNG 100%, KHÔNG ĐÈ CHỮ)
// =========================================================================
static BOOL hook_alwaysTrue(id self, SEL _cmd) {
    return [ZaloModViewController isBugZBusinessEnabled];
}

static BOOL hook_checkUserIsBusinessAccount(id self, SEL _cmd, id user) {
    return [ZaloModViewController isBugZBusinessEnabled];
}

static id hook_titleBadge(id self, SEL _cmd) {
    return [ZaloModViewController isBugZBusinessEnabled] ? @"Business" : nil;
}

static id hook_textColorBadge(id self, SEL _cmd) {
    return [ZaloModViewController isBugZBusinessEnabled] ? [UIColor colorWithRed:0.29 green:0.64 blue:0.89 alpha:1.0] : nil;
}

static id hook_backgroundColorBadge(id self, SEL _cmd) {
    return [ZaloModViewController isBugZBusinessEnabled] ? [UIColor colorWithRed:0.05 green:0.20 blue:0.29 alpha:0.95] : nil;
}

// Dọn dẹp triệt để các subview thừa cũ trên UIViewController
@interface UIViewController (ZaloModCleanupOldViews)
@end

@implementation UIViewController (ZaloModCleanupOldViews)
- (void)zaloMod_viewDidAppear:(BOOL)animated {
    [self zaloMod_viewDidAppear:animated];

    // Xóa bỏ tất cả subview tag 888999 (view fake Business cũ) và 777666 (sticker snowman)
    UIView *oldBadge = [self.view viewWithTag:888999];
    if (oldBadge) [oldBadge removeFromSuperview];

    UIView *oldSticker = [self.view viewWithTag:777666];
    if (oldSticker) [oldSticker removeFromSuperview];
}
@end

// =========================================================================
// 7. SIRIKIT ENTITLEMENT BYPASS (Chống văng app khi Sideload qua ESign/Scarlet)
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

static void patchSiriKitCrash(void) {
    @try {
        Class prefClass = objc_getClass("INPreferences");
        if (prefClass) {
            Method m1 = class_getClassMethod(prefClass, @selector(sharedPreferences));
            Method m2 = class_getClassMethod([FakeIntentsBypass class], @selector(sharedPreferences));
            if (m1 && m2) method_exchangeImplementations(m1, m2);

            Method m3 = class_getClassMethod(prefClass, @selector(siriLanguageCode));
            Method m4 = class_getClassMethod([FakeIntentsBypass class], @selector(siriLanguageCode));
            if (m3 && m4) method_exchangeImplementations(m3, m4);
        }

        Class vocabClass = objc_getClass("INVocabulary");
        if (vocabClass) {
            Method v1 = class_getClassMethod(vocabClass, @selector(sharedVocabulary));
            Method v2 = class_getClassMethod([FakeIntentsBypass class], @selector(sharedVocabulary));
            if (v1 && v2) method_exchangeImplementations(v1, v2);
        }
    } @catch (NSException *e) {
        NSLog(@"[DucLamXNgBao] Siri bypass error: %@", e);
    }
}

// =========================================================================
// 8. KÍCH HOẠT TOÀN BỘ HOOKS (AN TOÀN TUYỆT ĐỐI, KHÔNG PHÁ HỎNG GIAO DIỆN CHAT)
// =========================================================================
static void installAllZaloModHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[DucLamXNgBao] Đang cài đặt Hook chuẩn xác cho Zalo Mod VIP...");

        // 1. Hook Font Chữ vào ô nhập liệu
        swizzleInstanceMethod([UITextView class], @selector(insertText:), @selector(zaloMod_insertText:));
        swizzleInstanceMethod([UITextField class], @selector(insertText:), @selector(zaloMod_insertText:));

        // 2. Hook Anti-Undo trên UndoChatProcessor (Giữ nguyên nội dung, hiện nhãn 'đã thu hồi' rõ ràng)
        Class undoProcCls = objc_getClass("UndoChatProcessor");
        if (undoProcCls) {
            Class metaCls = object_getClass(undoProcCls);
            Method mUndo = class_getClassMethod(undoProcCls, sel_registerName("updateUndoMessageContent:"));
            if (mUndo && metaCls) {
                IMP origImp = method_getImplementation(mUndo);
                class_addMethod(metaCls, sel_registerName("zaloMod_orig_updateUndoMessageContent:"), origImp, method_getTypeEncoding(mUndo));
                method_setImplementation(mUndo, (IMP)hook_UndoChatProcessor_updateUndoMessageContent);
                NSLog(@"[DucLamXNgBao] Hook UndoChatProcessor updateUndoMessageContent thành công!");
            }
        }

        swizzleInstanceMethod([UILabel class], @selector(setText:), @selector(zaloMod_setText:));

        // 3. Mở khóa giao diện chọn ảnh Original (QualityPickerViewController)
        Class pickerVCCls = objc_getClass("_TtC19CommFeatureBusiness27QualityPickerViewController") ?: objc_getClass("QualityPickerViewController");
        if (pickerVCCls) {
            Method mShow = class_getInstanceMethod(pickerVCCls, sel_registerName("enableShowOriginPhoto"));
            if (mShow) method_setImplementation(mShow, (IMP)hook_enableShowOriginPhoto);

            Method mBadgeType = class_getInstanceMethod(pickerVCCls, sel_registerName("originalBadgeType"));
            if (mBadgeType) method_setImplementation(mBadgeType, (IMP)hook_originalBadgeType);

            Method mBadge = class_getInstanceMethod(pickerVCCls, sel_registerName("originalBadge"));
            if (mBadge) method_setImplementation(mBadge, (IMP)hook_originalBadge);

            Method mAllowed = class_getInstanceMethod(pickerVCCls, sel_registerName("isOriginAllowed:"));
            if (mAllowed) method_setImplementation(mAllowed, (IMP)hook_enableShowOriginPhoto);

            NSLog(@"[DucLamXNgBao] Đã mở khóa chọn ảnh Original không cần zCloud!");
        }

        // 4. Hook Native Business Account (ProfileEntity, BuddyEntity, BALabelInfo, FlowManagers)
        Class profEntityCls = objc_getClass("ProfileEntity");
        if (profEntityCls) {
            Method m = class_getInstanceMethod(profEntityCls, sel_registerName("isBusinessAccount"));
            if (m) method_setImplementation(m, (IMP)hook_alwaysTrue);
        }

        Class buddyEntityCls = objc_getClass("BuddyEntity");
        if (buddyEntityCls) {
            Method m = class_getInstanceMethod(buddyEntityCls, sel_registerName("isBusinessAccount"));
            if (m) method_setImplementation(m, (IMP)hook_alwaysTrue);
        }

        Class profFlowCls = objc_getClass("ProfileFlowManager");
        if (profFlowCls) {
            Method m = class_getInstanceMethod(profFlowCls, sel_registerName("checkUserIsBusinessAccount:"));
            if (m) method_setImplementation(m, (IMP)hook_checkUserIsBusinessAccount);
        }

        Class friendFlowCls = objc_getClass("FriendFlowManager");
        if (friendFlowCls) {
            Method m = class_getInstanceMethod(friendFlowCls, sel_registerName("checkUserIsBusinessAccount:"));
            if (m) method_setImplementation(m, (IMP)hook_checkUserIsBusinessAccount);
        }

        Class baInfoCls = objc_getClass("_TtC6CORBiz11BALabelInfo") ?: objc_getClass("CORBiz11BALabelInfo");
        if (baInfoCls) {
            Method m1 = class_getInstanceMethod(baInfoCls, sel_registerName("hasTitleBadge"));
            if (m1) method_setImplementation(m1, (IMP)hook_alwaysTrue);

            Method m2 = class_getInstanceMethod(baInfoCls, sel_registerName("titleBadge"));
            if (m2) method_setImplementation(m2, (IMP)hook_titleBadge);

            Method m3 = class_getInstanceMethod(baInfoCls, sel_registerName("textColorBadge"));
            if (m3) method_setImplementation(m3, (IMP)hook_textColorBadge);

            Method m4 = class_getInstanceMethod(baInfoCls, sel_registerName("backgroundColorBadge"));
            if (m4) method_setImplementation(m4, (IMP)hook_backgroundColorBadge);

            NSLog(@"[DucLamXNgBao Hook] Đã kích hoạt nhãn Business chuẩn Native trong Zalo!");
        }

        // 5. Hook TTL vào ChatDataManager, ChatEntity & NSJSONSerialization (Chuẩn Milliseconds)
        Class chatDataMgrCls = objc_getClass("ChatDataManager");
        if (chatDataMgrCls) {
            Method mSync = class_getInstanceMethod(chatDataMgrCls, sel_registerName("syncMessageWithCurrentDisappearingTTLIfNeed:"));
            if (mSync) {
                IMP orig = method_getImplementation(mSync);
                class_addMethod(chatDataMgrCls, sel_registerName("zaloMod_orig_syncMessageWithCurrentDisappearingTTLIfNeed:"), orig, method_getTypeEncoding(mSync));
                method_setImplementation(mSync, (IMP)hook_syncMessageWithCurrentDisappearingTTLIfNeed);
                NSLog(@"[DucLamXNgBao] Hook ChatDataManager syncMessageWithCurrentDisappearingTTL thành công!");
            }

            Method mAttach = class_getInstanceMethod(chatDataMgrCls, sel_registerName("attachTTLValueForMessageIfNeed:"));
            if (mAttach) {
                IMP orig = method_getImplementation(mAttach);
                class_addMethod(chatDataMgrCls, sel_registerName("zaloMod_orig_attachTTLValueForMessageIfNeed:"), orig, method_getTypeEncoding(mAttach));
                method_setImplementation(mAttach, (IMP)hook_attachTTLValueForMessageIfNeed);
                NSLog(@"[DucLamXNgBao] Hook ChatDataManager attachTTLValueForMessageIfNeed thành công!");
            }
        }

        // Hook ChatEntity isExpiredMessage (Chống đếm giây nhanh / tự mất tin nhắn sớm)
        Class chatEntityCls = objc_getClass("ChatEntity");
        if (chatEntityCls) {
            Method mExpired = class_getInstanceMethod(chatEntityCls, sel_registerName("isExpiredMessage"));
            if (mExpired) {
                IMP orig = method_getImplementation(mExpired);
                class_addMethod(chatEntityCls, sel_registerName("zaloMod_orig_isExpiredMessage"), orig, method_getTypeEncoding(mExpired));
                method_setImplementation(mExpired, (IMP)hook_ChatEntity_isExpiredMessage);
                NSLog(@"[DucLamXNgBao] Hook ChatEntity isExpiredMessage (Chống đếm nhanh/mất sớm) thành công!");
            }
        }

        Method origJSON = class_getClassMethod([NSJSONSerialization class], @selector(dataWithJSONObject:options:error:));
        Method swizJSON = class_getClassMethod([NSJSONSerialization class], @selector(zaloMod_dataWithJSONObject:options:error:));
        if (origJSON && swizJSON) {
            method_exchangeImplementations(origJSON, swizJSON);
        }

        // 6. Dọn dẹp view cũ trên UIViewController
        swizzleInstanceMethod([UIViewController class], @selector(viewDidAppear:), @selector(zaloMod_viewDidAppear:));

        NSLog(@"[DucLamXNgBao] HOÀN TẤT KÍCH HOẠT HOOKS - SIÊU MƯỢT, TIN NHẮN CHUẨN ĐẸP!");
    });
}

// Constructor Tweak
__attribute__((constructor))
static void initZaloModVIP(void) {
    patchSiriKitCrash();

    // Kích hoạt runtime hooks chuẩn
    installAllZaloModHooks();

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

    // Fallback timers
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
}
