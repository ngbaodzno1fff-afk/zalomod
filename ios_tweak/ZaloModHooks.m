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
// 1. FLOATING WINDOW (CỤC MENU TRÒN CHẠM XUYÊN THẤU - AN TOÀN TRÊN MỌI PHIÊN BẢN IOS)
// =========================================================================
@interface ZaloFloatingWindow : UIWindow
@end

@implementation ZaloFloatingWindow
- (BOOL)canBecomeKeyWindow {
    return NO; // Tuyệt đối không chiếm quyền Key Window của Zalo
}

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

            UIWindowScene *activeScene = nil;
            if (@available(iOS 13.0, *)) {
                for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                        activeScene = (UIWindowScene *)scene;
                        break;
                    }
                }
                if (!activeScene) {
                    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                        if ([scene isKindOfClass:[UIWindowScene class]]) {
                            activeScene = (UIWindowScene *)scene;
                            break;
                        }
                    }
                }
            }

            if (!gFloatingWindow) {
                if (@available(iOS 13.0, *)) {
                    if (activeScene) {
                        gFloatingWindow = [[ZaloFloatingWindow alloc] initWithWindowScene:activeScene];
                    } else {
                        // Nếu Scene chưa sẵn sàng, chờ 0.5s rồi thử lại an toàn
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [[ZaloModManager sharedManager] setupFloatingButton];
                        });
                        return;
                    }
                } else {
                    gFloatingWindow = [[ZaloFloatingWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                }
            } else if (@available(iOS 13.0, *)) {
                if (activeScene && gFloatingWindow.windowScene != activeScene) {
                    gFloatingWindow.windowScene = activeScene;
                }
            }

            gFloatingWindow.windowLevel = UIWindowLevelAlert + 1000.0;
            gFloatingWindow.backgroundColor = [UIColor clearColor];

            if (!gFloatingWindow.rootViewController) {
                UIViewController *rootVC = [[UIViewController alloc] init];
                rootVC.view.backgroundColor = [UIColor clearColor];
                rootVC.view.userInteractionEnabled = YES;
                gFloatingWindow.rootViewController = rootVC;
            }

            gFloatingWindow.hidden = NO;

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
// 2. HELPER SWIZZLING AN TOÀN
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
// 3. FONT HOOK (12 FONT CHỮ NGHỆ THUẬT, CHỮ TO, CHỮ MÀU, RANDOM MÀU KHI GỬI)
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
// 4. CHỐNG THU HỒI TIN NHẮN (ANTI-UNDO) - CHUẨN XÁC, GIỮ NGUYÊN NỘI DUNG GỐC
// =========================================================================
static void hook_ChatOperationProcessor_processUndoMessage(id self, SEL _cmd, id item) {
    if ([ZaloModViewController isAntiUndoEnabled]) {
        NSLog(@"[DucLamXNgBao Anti-Undo] Đã chặn lệnh thu hồi tin nhắn từ Server!");
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZaloFloatingButton sharedInstance] incrementBadge];
        });
        return; // KHÔNG THỰC THI LỆNH XÓA/THU HỒI -> Tin nhắn được giữ nguyên vẹn 100%!
    }
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatOperationProcessor"), sel_registerName("zaloMod_orig_processUndoMessage:"));
    if (orig) {
        orig(self, _cmd, item);
    }
}

static void hook_ChatOperationProcessor_processUpdateUndo(id self, SEL _cmd, id chat) {
    if ([ZaloModViewController isAntiUndoEnabled]) {
        @try {
            SEL msgSel = sel_registerName("message");
            SEL setMsgSel = sel_registerName("setMessage:");
            if ([chat respondsToSelector:msgSel] && [chat respondsToSelector:setMsgSel]) {
                NSString *cur = ((id (*)(id, SEL))objc_msgSend)(chat, msgSel);
                if (cur && cur.length > 0 && ![cur containsString:@"( đã thu hồi )"]) {
                    NSString *annotated = [NSString stringWithFormat:@"%@ ( đã thu hồi )", cur];
                    ((void (*)(id, SEL, id))objc_msgSend)(chat, setMsgSel, annotated);
                }
            }
        } @catch (NSException *e) {}
        return; // Chặn cập nhật trạng thái xóa vào ChatEntity!
    }
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatOperationProcessor"), sel_registerName("zaloMod_orig_processUpdateUndo:"));
    if (orig) {
        orig(self, _cmd, chat);
    }
}

// =========================================================================
// 5. MỞ KHÓA GỬI ẢNH GỐC & HD (TỰ ĐỘNG GỬI ORIGINAL KHÔNG CẦN MUA ZCLOUD)
// =========================================================================
static void markChatAsOriginalIfPhoto(id chat) {
    if (!chat || ![ZaloModViewController isBugOriginalEnabled]) return;
    @try {
        BOOL isPhoto = NO;
        if ([chat respondsToSelector:sel_registerName("isPhoto")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isPhoto"))) {
            isPhoto = YES;
        } else if ([chat respondsToSelector:sel_registerName("isPhotoType")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isPhotoType"))) {
            isPhoto = YES;
        } else if ([chat respondsToSelector:sel_registerName("isPhotoAttachment")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isPhotoAttachment"))) {
            isPhoto = YES;
        } else if ([chat respondsToSelector:sel_registerName("isPhotoHD")]) {
            isPhoto = YES;
        }
        if (isPhoto) {
            if ([chat respondsToSelector:sel_registerName("setIsOriginal:")]) {
                ((void (*)(id, SEL, long long))objc_msgSend)(chat, sel_registerName("setIsOriginal:"), 1);
            }
            if ([chat respondsToSelector:sel_registerName("setIsPhotoHD:")]) {
                ((void (*)(id, SEL, BOOL))objc_msgSend)(chat, sel_registerName("setIsPhotoHD:"), YES);
            }
            if ([chat respondsToSelector:sel_registerName("set_isOrigin:")]) {
                ((void (*)(id, SEL, BOOL))objc_msgSend)(chat, sel_registerName("set_isOrigin:"), YES);
            }
        }
    } @catch (NSException *e) {}
}

static BOOL hook_enableShowOriginPhoto(id self, SEL _cmd) {
    return YES;
}

static NSInteger hook_originalBadgeType(id self, SEL _cmd) {
    return 0;
}

static id hook_originalBadge(id self, SEL _cmd) {
    return nil;
}

static NSInteger hook_currentQuality_original(id self, SEL _cmd) {
    return [ZaloModViewController isBugOriginalEnabled] ? 2 : 1;
}

static float hook_originalCompressQuality(id self, SEL _cmd) {
    return 1.0f; // 100% chất lượng ảnh gốc
}

static BOOL hook_allowRememberQuality(id self, SEL _cmd) {
    return YES;
}

static long long hook_maxOriginalLimit(id self, SEL _cmd) {
    return 100LL * 1024LL * 1024LL; // 100 MB
}

static BOOL hook_RichMessageContent_isOriginal(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) return YES;
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("RichMessageContent"), sel_registerName("zaloMod_orig_isOriginal:"));
    return orig ? orig(self, _cmd) : YES;
}

static BOOL hook_RichMessageContent_isPhotoHD(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) return YES;
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("RichMessageContent"), sel_registerName("zaloMod_orig_isPhotoHD:"));
    return orig ? orig(self, _cmd) : YES;
}

// =========================================================================
// 6. HELPER KIỂM TRA TIN NHẮN DO MÌNH GỬI ĐI & GÁN TTL THEO GIÂY CHUẨN XÁC
// =========================================================================
static BOOL isMessageFromMe(id chat) {
    if (!chat || ![chat isKindOfClass:[NSObject class]]) return NO;
    @try {
        if ([chat respondsToSelector:sel_registerName("isMyMessage")]) {
            long long val = ((long long (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isMyMessage"));
            return (val != 0);
        }
        if ([chat respondsToSelector:sel_registerName("isOutgoing")]) {
            long long val = ((long long (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isOutgoing"));
            return (val != 0);
        }
        if ([chat respondsToSelector:sel_registerName("isSenderMe")]) {
            long long val = ((long long (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isSenderMe"));
            return (val != 0);
        }
    } @catch (NSException *e) {}
    return NO;
}

static void attachTTLToOutgoingChatIfNeed(id chat) {
    if (!chat) return;
    NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
    if (ttlSecs > 0) {
        SEL setTtlSel = sel_registerName("setTtl:");
        if ([chat respondsToSelector:setTtlSel]) {
            ((void (*)(id, SEL, long long))objc_msgSend)(chat, setTtlSel, (long long)ttlSecs);
        }
    }
    markChatAsOriginalIfPhoto(chat);
}

// Hook ZAChatSendingManager: Gửi tin nhắn tự động kèm TTL và tự động gửi ảnh Original
static void hook_sendChat_checkUpload(id self, SEL _cmd, id chat, BOOL check) {
    if (isMessageFromMe(chat)) {
        attachTTLToOutgoingChatIfNeed(chat);
    }
    void (*orig)(id, SEL, id, BOOL) = (void (*)(id, SEL, id, BOOL))class_getMethodImplementation(objc_getClass("ZAChatSendingManager"), sel_registerName("zaloMod_orig_sendChat_checkUpload:"));
    if (orig) orig(self, _cmd, chat, check);
}

static void hook_sendChat_destinations(id self, SEL _cmd, id chat, id dests, BOOL check, BOOL wait) {
    if (isMessageFromMe(chat)) {
        attachTTLToOutgoingChatIfNeed(chat);
    }
    void (*orig)(id, SEL, id, id, BOOL, BOOL) = (void (*)(id, SEL, id, id, BOOL, BOOL))class_getMethodImplementation(objc_getClass("ZAChatSendingManager"), sel_registerName("zaloMod_orig_sendChat_destinations:"));
    if (orig) orig(self, _cmd, chat, dests, check, wait);
}

// Hook ChatDataManager: Gán TTL vào tin nhắn của mình
static id hook_syncMessageWithCurrentDisappearingTTLIfNeed(id self, SEL _cmd, id chat) {
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatDataManager"), sel_registerName("zaloMod_orig_syncMessageWithCurrentDisappearingTTLIfNeed:"));
    id result = chat;
    if (orig) {
        result = ((id (*)(id, SEL, id))orig)(self, _cmd, chat);
    }
    if (!result) result = chat;

    if (isMessageFromMe(result) || isMessageFromMe(chat)) {
        attachTTLToOutgoingChatIfNeed(result);
        if (chat != result) attachTTLToOutgoingChatIfNeed(chat);
    }
    return result;
}

static BOOL hook_attachTTLValueForMessageIfNeed(id self, SEL _cmd, id chat) {
    BOOL (*orig)(id, SEL, id) = (BOOL (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatDataManager"), sel_registerName("zaloMod_orig_attachTTLValueForMessageIfNeed:"));
    BOOL res = orig ? orig(self, _cmd, chat) : NO;
    if (isMessageFromMe(chat)) {
        attachTTLToOutgoingChatIfNeed(chat);
        res = YES;
    }
    return res;
}

// =========================================================================
// 7. NATIVE ZALO BUSINESS ACCOUNT HOOK (CHUẨN CHÍNH HÃNG 100%, KHÔNG ĐÈ CHỮ)
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

// =========================================================================
// 8. BUG ALL ZSTYLES & PROFILE (AN TOÀN TUYỆT ĐỐI, KHÔNG TRẢ DICTIONARY LỖI)
// =========================================================================
static BOOL hook_zstyleAlwaysTrue(id self, SEL _cmd) {
    return [ZaloModViewController isBugZLStyleEnabled];
}

static NSInteger hook_zstylePackageIdVIP(id self, SEL _cmd) {
    return [ZaloModViewController isBugZLStyleEnabled] ? 1 : 0;
}

static long long hook_zeroPrice(id self, SEL _cmd) {
    return 0;
}

static BOOL hook_isZStyleSubscribed(id self, SEL _cmd, id userId) {
    return [ZaloModViewController isBugZLStyleEnabled];
}

static NSInteger hook_getZStylePackageId(id self, SEL _cmd, id userId) {
    return [ZaloModViewController isBugZLStyleEnabled] ? 1 : 0;
}

// =========================================================================
// 9. KÍCH HOẠT TOÀN BỘ HOOKS (SIÊU ỔN ĐỊNH, KHÔNG CRASH)
// =========================================================================
static void installAllZaloModHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[DucLamXNgBao] Đang cài đặt Hook chuẩn xác cho Zalo Mod VIP...");

        // 1. Hook Font Chữ vào ô nhập liệu
        swizzleInstanceMethod([UITextView class], @selector(insertText:), @selector(zaloMod_insertText:));
        swizzleInstanceMethod([UITextField class], @selector(insertText:), @selector(zaloMod_insertText:));

        // 2. Hook Anti-Undo trên ChatOperationProcessor (Chặn lệnh xóa từ Server, giữ nguyên tin nhắn thật)
        Class chatOpProcCls = objc_getClass("ChatOperationProcessor");
        if (chatOpProcCls) {
            Method undoProcM = class_getInstanceMethod(chatOpProcCls, sel_registerName("_processUndoMessageWithOperationItem:"));
            if (undoProcM) {
                IMP origImp = method_getImplementation(undoProcM);
                class_addMethod(chatOpProcCls, sel_registerName("zaloMod_orig_processUndoMessage:"), origImp, method_getTypeEncoding(undoProcM));
                method_setImplementation(undoProcM, (IMP)hook_ChatOperationProcessor_processUndoMessage);
                NSLog(@"[DucLamXNgBao] Hook ChatOperationProcessor _processUndoMessage thành công!");
            }

            Method updateUndoM = class_getInstanceMethod(chatOpProcCls, sel_registerName("_processUpdateUndoWithChatEntity:"));
            if (updateUndoM) {
                IMP origImp = method_getImplementation(updateUndoM);
                class_addMethod(chatOpProcCls, sel_registerName("zaloMod_orig_processUpdateUndo:"), origImp, method_getTypeEncoding(updateUndoM));
                method_setImplementation(updateUndoM, (IMP)hook_ChatOperationProcessor_processUpdateUndo);
                NSLog(@"[DucLamXNgBao] Hook ChatOperationProcessor _processUpdateUndo thành công!");
            }
        }

        // 3. Mở khóa giao diện và cấu hình gửi ảnh Original & HD không bị nén
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

            Method mCurQ = class_getInstanceMethod(pickerVCCls, sel_registerName("currentQuality"));
            if (mCurQ) method_setImplementation(mCurQ, (IMP)hook_currentQuality_original);

            NSLog(@"[DucLamXNgBao] Đã mở khóa chọn ảnh Original không cần zCloud!");
        }

        // Cấu hình ZCFQualityPickerConfig cho phép gửi ảnh Original mặc định
        Class qpConfigCls = objc_getClass("_TtC15CommFeatureBase22ZCFQualityPickerConfig") ?: objc_getClass("ZCFQualityPickerConfig");
        if (qpConfigCls) {
            Method mSendOrig = class_getClassMethod(qpConfigCls, sel_registerName("enableSendOriginal"));
            if (mSendOrig) method_setImplementation(mSendOrig, (IMP)hook_alwaysTrue);

            Method mBadge = class_getClassMethod(qpConfigCls, sel_registerName("originalBadge"));
            if (mBadge) method_setImplementation(mBadge, (IMP)hook_originalBadge);

            Method mRem = class_getClassMethod(qpConfigCls, sel_registerName("allowRememberQuality"));
            if (mRem) method_setImplementation(mRem, (IMP)hook_allowRememberQuality);

            Method mQuality = class_getClassMethod(qpConfigCls, sel_registerName("originalCompressQuality"));
            if (mQuality) method_setImplementation(mQuality, (IMP)hook_originalCompressQuality);
        }

        // Cấu hình ZSharedData bỏ giới hạn dung lượng ảnh gốc
        Class zSharedCls = objc_getClass("ZSharedData");
        if (zSharedCls) {
            Method mSetting = class_getInstanceMethod(zSharedCls, sel_registerName("settingOriginalPhotoQuality"));
            if (mSetting) method_setImplementation(mSetting, (IMP)hook_alwaysTrue);

            Method mLimitSize = class_getInstanceMethod(zSharedCls, sel_registerName("limitOriginalPhotoSize"));
            if (mLimitSize) method_setImplementation(mLimitSize, (IMP)hook_maxOriginalLimit);

            Method mLimitDim = class_getInstanceMethod(zSharedCls, sel_registerName("limitOriginalPhotoDimension"));
            if (mLimitDim) method_setImplementation(mLimitDim, (IMP)hook_maxOriginalLimit);

            Method mRemHD = class_getInstanceMethod(zSharedCls, sel_registerName("enableRememberHD"));
            if (mRemHD) method_setImplementation(mRemHD, (IMP)hook_alwaysTrue);
        }

        // Hook ZAChatSendingManager: Gửi tin nhắn tự động kèm TTL và tự động gửi ảnh Original
        Class sendMgrCls = objc_getClass("ZAChatSendingManager");
        if (sendMgrCls) {
            Method m1 = class_getInstanceMethod(sendMgrCls, sel_registerName("sendChat:checkUpload:"));
            if (m1) {
                IMP orig = method_getImplementation(m1);
                class_addMethod(sendMgrCls, sel_registerName("zaloMod_orig_sendChat_checkUpload:"), orig, method_getTypeEncoding(m1));
                method_setImplementation(m1, (IMP)hook_sendChat_checkUpload);
            }
            Method m2 = class_getInstanceMethod(sendMgrCls, sel_registerName("sendChat:toDestinations:checkUpload:isWaitingSend:"));
            if (m2) {
                IMP orig = method_getImplementation(m2);
                class_addMethod(sendMgrCls, sel_registerName("zaloMod_orig_sendChat_destinations:"), orig, method_getTypeEncoding(m2));
                method_setImplementation(m2, (IMP)hook_sendChat_destinations);
            }
            NSLog(@"[DucLamXNgBao] Hook ZAChatSendingManager tự động gửi ảnh Original thành công!");
        }

        // Hook RichMessageContent: Gán cờ Original/PhotoHD cho ảnh gửi đi
        Class richContentCls = objc_getClass("RichMessageContent");
        if (richContentCls) {
            Method mOrig = class_getInstanceMethod(richContentCls, sel_registerName("isOriginal"));
            if (mOrig) {
                IMP orig = method_getImplementation(mOrig);
                class_addMethod(richContentCls, sel_registerName("zaloMod_orig_isOriginal:"), orig, method_getTypeEncoding(mOrig));
                method_setImplementation(mOrig, (IMP)hook_RichMessageContent_isOriginal);
            }
            Method mHD = class_getInstanceMethod(richContentCls, sel_registerName("isPhotoHD"));
            if (mHD) {
                IMP orig = method_getImplementation(mHD);
                class_addMethod(richContentCls, sel_registerName("zaloMod_orig_isPhotoHD:"), orig, method_getTypeEncoding(mHD));
                method_setImplementation(mHD, (IMP)hook_RichMessageContent_isPhotoHD);
            }
        }

        // 4. Hook Native Business Account (ProfileEntity, BuddyEntity, BALabelInfo, FlowManagers)
        Class profEntityCls = objc_getClass("ProfileEntity");
        if (profEntityCls) {
            Method m = class_getInstanceMethod(profEntityCls, sel_registerName("isBusinessAccount"));
            if (m) method_setImplementation(m, (IMP)hook_alwaysTrue);

            Method mZStyle = class_getInstanceMethod(profEntityCls, sel_registerName("isZStyle"));
            if (mZStyle) method_setImplementation(mZStyle, (IMP)hook_zstyleAlwaysTrue);

            Method mZUser = class_getInstanceMethod(profEntityCls, sel_registerName("isZStyleUser"));
            if (mZUser) method_setImplementation(mZUser, (IMP)hook_zstyleAlwaysTrue);

            Method mPaid = class_getInstanceMethod(profEntityCls, sel_registerName("isPaidZStyle"));
            if (mPaid) method_setImplementation(mPaid, (IMP)hook_zstyleAlwaysTrue);

            Method mPkg = class_getInstanceMethod(profEntityCls, sel_registerName("zstylePackageId"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_zstylePackageIdVIP);

            Method mPkgIvar = class_getInstanceMethod(profEntityCls, sel_registerName("_zstylePackageId"));
            if (mPkgIvar) method_setImplementation(mPkgIvar, (IMP)hook_zstylePackageIdVIP);
        }

        Class buddyEntityCls = objc_getClass("BuddyEntity");
        if (buddyEntityCls) {
            Method m = class_getInstanceMethod(buddyEntityCls, sel_registerName("isBusinessAccount"));
            if (m) method_setImplementation(m, (IMP)hook_alwaysTrue);

            Method mZStyle = class_getInstanceMethod(buddyEntityCls, sel_registerName("isZStyle"));
            if (mZStyle) method_setImplementation(mZStyle, (IMP)hook_zstyleAlwaysTrue);

            Method mZUser = class_getInstanceMethod(buddyEntityCls, sel_registerName("isZStyleUser"));
            if (mZUser) method_setImplementation(mZUser, (IMP)hook_zstyleAlwaysTrue);

            Method mPaid = class_getInstanceMethod(buddyEntityCls, sel_registerName("isPaidZStyle"));
            if (mPaid) method_setImplementation(mPaid, (IMP)hook_zstyleAlwaysTrue);

            Method mPkg = class_getInstanceMethod(buddyEntityCls, sel_registerName("zstylePackageId"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_zstylePackageIdVIP);

            Method mPkgIvar = class_getInstanceMethod(buddyEntityCls, sel_registerName("_zstylePackageId"));
            if (mPkgIvar) method_setImplementation(mPkgIvar, (IMP)hook_zstylePackageIdVIP);
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

        // 4b. Hook All ZStyles (ProfileLegacyUtils, SocialFeatureSetting, StickersBottomSheetPackInfo)
        Class legacyUtilsCls = objc_getClass("ProfileLegacyUtils");
        if (legacyUtilsCls) {
            Method mSub = class_getClassMethod(legacyUtilsCls, sel_registerName("isZStyleSubscribed:"));
            if (mSub) method_setImplementation(mSub, (IMP)hook_isZStyleSubscribed);

            Method mPkg = class_getClassMethod(legacyUtilsCls, sel_registerName("getZStylePackageId:"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_getZStylePackageId);

            Method mSub2 = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_isSubscribeZStyle:"));
            if (mSub2) method_setImplementation(mSub2, (IMP)hook_isZStyleSubscribed);

            Method mSub3 = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_isZStyleSubscribed:"));
            if (mSub3) method_setImplementation(mSub3, (IMP)hook_isZStyleSubscribed);

            Method mPkg2 = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_getZStylePackageId:"));
            if (mPkg2) method_setImplementation(mPkg2, (IMP)hook_getZStylePackageId);

            Method mFrame = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_isEnabledZStyleAvatarFrame"));
            if (mFrame) method_setImplementation(mFrame, (IMP)hook_zstyleAlwaysTrue);

            Method mFrameType = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_isEnabledFrameTypeForProfileUIType:"));
            if (mFrameType) method_setImplementation(mFrameType, (IMP)hook_zstyleAlwaysTrue);

            NSLog(@"[DucLamXNgBao] Hook ProfileLegacyUtils ZStyle thành công!");
        }

        Class socialSettingCls = objc_getClass("SocialFeatureSetting");
        if (socialSettingCls) {
            Method m1 = class_getClassMethod(socialSettingCls, sel_registerName("isEnabledZStyleAvatarFrame"));
            if (m1) method_setImplementation(m1, (IMP)hook_zstyleAlwaysTrue);

            Method m2 = class_getClassMethod(socialSettingCls, sel_registerName("isEnabledZStyleNameCard"));
            if (m2) method_setImplementation(m2, (IMP)hook_zstyleAlwaysTrue);

            Method m3 = class_getClassMethod(socialSettingCls, sel_registerName("enableStoryMusic"));
            if (m3) method_setImplementation(m3, (IMP)hook_zstyleAlwaysTrue);

            Method m4 = class_getClassMethod(socialSettingCls, sel_registerName("enableSwithProfileUI"));
            if (m4) method_setImplementation(m4, (IMP)hook_zstyleAlwaysTrue);

            Method m5 = class_getClassMethod(socialSettingCls, sel_registerName("isEnabledFrameType:"));
            if (m5) method_setImplementation(m5, (IMP)hook_zstyleAlwaysTrue);
            NSLog(@"[DucLamXNgBao] Hook SocialFeatureSetting ZStyle thành công!");
        }

        // Hook StickersBottomSheetPackInfo: Mở khóa mua tất cả frame/sticker/theme ZStyle
        Class stickerPackCls = objc_getClass("_TtC19CommFeatureBusiness27StickersBottomSheetPackInfo") ?: objc_getClass("StickersBottomSheetPackInfo");
        if (stickerPackCls) {
            Method mPaid = class_getInstanceMethod(stickerPackCls, sel_registerName("isPaidZStyle"));
            if (mPaid) method_setImplementation(mPaid, (IMP)hook_zstyleAlwaysTrue);

            Method mOwned = class_getInstanceMethod(stickerPackCls, sel_registerName("isOwned"));
            if (mOwned) method_setImplementation(mOwned, (IMP)hook_zstyleAlwaysTrue);

            Method mPurchased = class_getInstanceMethod(stickerPackCls, sel_registerName("isPurchased"));
            if (mPurchased) method_setImplementation(mPurchased, (IMP)hook_zstyleAlwaysTrue);

            Method mZUser = class_getInstanceMethod(stickerPackCls, sel_registerName("isZStyleUser"));
            if (mZUser) method_setImplementation(mZUser, (IMP)hook_zstyleAlwaysTrue);

            Method mFree = class_getInstanceMethod(stickerPackCls, sel_registerName("isfree"));
            if (mFree) method_setImplementation(mFree, (IMP)hook_zstyleAlwaysTrue);

            Method mPrice = class_getInstanceMethod(stickerPackCls, sel_registerName("price"));
            if (mPrice) method_setImplementation(mPrice, (IMP)hook_zeroPrice);

            Method mZPrice = class_getInstanceMethod(stickerPackCls, sel_registerName("zStylePrice"));
            if (mZPrice) method_setImplementation(mZPrice, (IMP)hook_zeroPrice);

            Method mOrigPrice = class_getInstanceMethod(stickerPackCls, sel_registerName("originalPrice"));
            if (mOrigPrice) method_setImplementation(mOrigPrice, (IMP)hook_zeroPrice);
        }

        // 5. Hook TTL vào ChatDataManager
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

        NSLog(@"[DucLamXNgBao] HOÀN TẤT KÍCH HOẠT HOOKS - BẢN FIX CRASH HOÀN HẢO!");
    });
}

// Constructor Tweak
__attribute__((constructor))
static void initZaloModVIP(void) {
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

    // Fallback timers an toàn
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
}
