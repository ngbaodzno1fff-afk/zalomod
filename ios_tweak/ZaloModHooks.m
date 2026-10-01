//
//  ZaloModHooks.m
//  ZaloMod VIP - Runtime Method Swizzling & Tweak Injection
//  Thương hiệu: DucLamXNgBao
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
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
// 4. CHỐNG THU HỒI TIN NHẮN (ANTI-UNDO) - LƯU VÀ HIỂN THỊ NỘI DUNG GỐC
// =========================================================================
static NSMutableDictionary<NSString *, NSString *> *gMessageCache = nil;
static dispatch_queue_t gCacheQueue = nil;

@interface NSObject (ZaloChatEntityHook)
- (id)messageKey;
- (id)messageId;
- (id)getMessageKey;
- (NSString *)_originTextRecallMsg;
- (void)set_originTextRecallMsg:(NSString *)text;
- (long long)ttl;
- (void)setTtl:(long long)ttl;
- (void)setIsOriginal:(int)val;
- (void)setIsPhotoHD:(int)val;
@end

static void hook_ChatEntity_setMessage(id self, SEL _cmd, NSString *msg) {
    if (msg && msg.length > 0) {
        NSString *key = nil;
        if ([self respondsToSelector:@selector(getMessageKey)]) {
            key = [self performSelector:@selector(getMessageKey)];
        }
        if (!key && [self respondsToSelector:@selector(messageId)]) {
            key = [self performSelector:@selector(messageId)];
        }

        BOOL isRecallMsg = [msg containsString:@"Tin nhắn đã được thu hồi"] ||
                           [msg containsString:@"Message recalled"] ||
                           [msg containsString:@"đã thu hồi một tin nhắn"] ||
                           [msg containsString:@"đã thu hồi"];

        if (!isRecallMsg) {
            // Lưu nội dung tin nhắn thật vào bộ nhớ đệm
            if (key) {
                dispatch_barrier_async(gCacheQueue, ^{
                    gMessageCache[key] = msg;
                });
            }
        } else if ([ZaloModViewController isAntiUndoEnabled]) {
            // Khi đối phương bấm Thu hồi, lấy lại nội dung thật đã lưu!
            __block NSString *originalText = nil;
            if (key) {
                dispatch_sync(gCacheQueue, ^{
                    originalText = gMessageCache[key];
                });
            }
            if (!originalText && [self respondsToSelector:@selector(_originTextRecallMsg)]) {
                originalText = [self _originTextRecallMsg];
            }

            if (originalText && originalText.length > 0 && ![originalText containsString:@"Tin nhắn đã được thu hồi"]) {
                msg = [NSString stringWithFormat:@"%@\n(🚫 Đã thu hồi)", originalText];
            } else {
                msg = @"[🚫 Đã thu hồi một tin nhắn]";
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [[ZaloFloatingButton sharedInstance] incrementBadge];
            });
        }
    }

    void (*orig)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))class_getMethodImplementation(objc_getClass("ChatEntity"), sel_registerName("zaloMod_orig_setMessage:"));
    if (orig) {
        orig(self, _cmd, msg);
    }
}

static BOOL hook_ChatEntity_isMessageUndoOrDelete(id self, SEL _cmd) {
    if ([ZaloModViewController isAntiUndoEnabled]) {
        // Trả về NO để Zalo KHÔNG ẩn bubble và KHÔNG xóa nội dung tin nhắn!
        return NO;
    }
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("ChatEntity"), sel_registerName("zaloMod_orig_isMessageUndoOrDelete:"));
    return orig ? orig(self, _cmd) : NO;
}

static void hook_ChatOperationProcessor_processUndoMessage(id self, SEL _cmd, id item) {
    if ([ZaloModViewController isAntiUndoEnabled]) {
        NSLog(@"[DucLamXNgBao] Đã chặn xóa tin nhắn từ lệnh thu hồi của Server!");
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZaloFloatingButton sharedInstance] incrementBadge];
        });
    }
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatOperationProcessor"), sel_registerName("zaloMod_orig_processUndoMessage:"));
    if (orig) {
        orig(self, _cmd, item);
    }
}

// Hook hiển thị nhãn thu hồi trên UI
@interface UILabel (ZaloModAntiUndo)
@end

@implementation UILabel (ZaloModAntiUndo)
- (void)zaloMod_setText:(NSString *)text {
    if ([ZaloModViewController isAntiUndoEnabled] && text && text.length > 0) {
        if ([text containsString:@"Tin nhắn đã được thu hồi"] || [text containsString:@"Message recalled"]) {
            text = @"[🚫 Đã thu hồi]";
            dispatch_async(dispatch_get_main_queue(), ^{
                [[ZaloFloatingButton sharedInstance] incrementBadge];
            });
        }
    }
    [self zaloMod_setText:text];
}
@end

// =========================================================================
// 5. MỞ KHÓA GỬI ẢNH GỐC (ORIGINAL) & BẬT CHẾ ĐỘ RAW HD KHÔNG CẦN ZCLOUD
// =========================================================================
// Hook QualityPickerViewController (Bottom sheet chọn chế độ gửi: Original, HD, Tiêu chuẩn)
static BOOL hook_enableShowOriginPhoto(id self, SEL _cmd) {
    return YES; // Cho phép chọn Original luôn luôn!
}

static NSInteger hook_originalBadgeType(id self, SEL _cmd) {
    return 0; // Xóa bỏ yêu cầu trả phí zCloud!
}

static id hook_originalBadge(id self, SEL _cmd) {
    return nil; // Xóa chữ "zCloud" bên cạnh nhãn Original!
}

// Hook RichMessageContent (Ép gửi ảnh ở độ nét Gốc & HD)
static BOOL hook_RichMessageContent_isOriginal(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) {
        return YES;
    }
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("RichMessageContent"), sel_registerName("zaloMod_orig_isOriginal:"));
    return orig ? orig(self, _cmd) : NO;
}

static BOOL hook_RichMessageContent_isPhotoHD(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) {
        return YES;
    }
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("RichMessageContent"), sel_registerName("zaloMod_orig_isPhotoHD:"));
    return orig ? orig(self, _cmd) : NO;
}

// =========================================================================
// 6. GỬI TIN NHẮN TỰ XÓA TTL (TIME-TO-LIVE) & TỰ ĐỘNG GẮN GỬI ẢNH GỐC
// =========================================================================
static void hook_sendChat_checkUpload(id self, SEL _cmd, id chat, BOOL check) {
    // 1. Gán TTL nếu bật tính năng
    NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
    if (ttlSecs > 0 && [chat respondsToSelector:@selector(setTtl:)]) {
        [chat setTtl:(long long)ttlSecs];
        NSLog(@"[DucLamXNgBao] Đã gán TTL: %ld giây vào tin nhắn!", (long)ttlSecs);
    }

    // 2. Ép gửi Original nếu bật tính năng
    if ([ZaloModViewController isBugOriginalEnabled]) {
        if ([chat respondsToSelector:@selector(setIsOriginal:)]) {
            [chat setIsOriginal:1];
        }
        if ([chat respondsToSelector:@selector(setIsPhotoHD:)]) {
            [chat setIsPhotoHD:1];
        }
    }

    void (*orig)(id, SEL, id, BOOL) = (void (*)(id, SEL, id, BOOL))class_getMethodImplementation(objc_getClass("ZAChatSendingManager"), sel_registerName("zaloMod_orig_sendChat_checkUpload:"));
    if (orig) orig(self, _cmd, chat, check);
}

static void hook_sendChat_destinations(id self, SEL _cmd, id chat, id dests, BOOL check, BOOL wait) {
    NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
    if (ttlSecs > 0 && [chat respondsToSelector:@selector(setTtl:)]) {
        [chat setTtl:(long long)ttlSecs];
        NSLog(@"[DucLamXNgBao] Đã gán TTL: %ld giây vào tin nhắn!", (long)ttlSecs);
    }

    if ([ZaloModViewController isBugOriginalEnabled]) {
        if ([chat respondsToSelector:@selector(setIsOriginal:)]) {
            [chat setIsOriginal:1];
        }
        if ([chat respondsToSelector:@selector(setIsPhotoHD:)]) {
            [chat setIsPhotoHD:1];
        }
    }

    void (*orig)(id, SEL, id, id, BOOL, BOOL) = (void (*)(id, SEL, id, id, BOOL, BOOL))class_getMethodImplementation(objc_getClass("ZAChatSendingManager"), sel_registerName("zaloMod_orig_sendChat_destinations:"));
    if (orig) orig(self, _cmd, chat, dests, check, wait);
}

// Hook JSON API dự phòng
@interface NSJSONSerialization (ZaloModHook)
@end

@implementation NSJSONSerialization (ZaloModHook)
+ (NSData *)zaloMod_dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [obj mutableCopy];
        BOOL modified = NO;

        if ([ZaloModViewController isBugOriginalEnabled]) {
            if (dict[@"thumb"] || dict[@"photo"] || dict[@"photo_url"] || dict[@"total_size"] || dict[@"width"] || dict[@"height"] || dict[@"media"]) {
                dict[@"is_original"] = @(1);
                if ([dict[@"media"] isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *media = [dict[@"media"] mutableCopy];
                    media[@"is_original"] = @(1);
                    dict[@"media"] = media;
                }
                modified = YES;
            }
        }

        NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
        if (ttlSecs > 0) {
            if (dict[@"text"] || dict[@"msg"] || dict[@"cmsg"] || dict[@"cmsg_id"] || dict[@"content"] || dict[@"quote"]) {
                dict[@"ttl"] = @(ttlSecs);
                dict[@"ttl_sec"] = @(ttlSecs);
                dict[@"ttl_ms"] = @(ttlSecs * 1000);
                modified = YES;
            }
        }

        if (modified) {
            return [self zaloMod_dataWithJSONObject:dict options:opt error:error];
        }
    }
    return [self zaloMod_dataWithJSONObject:obj options:opt error:error];
}
@end

// =========================================================================
// 7. NATIVE ZALO BUSINESS ACCOUNT HOOK (CHUẨN CHÍNH HÃNG, KHÔNG ĐÈ CHỮ)
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

// Dọn dẹp triệt để các subview fake cũ để không bao giờ bị đè chữ lên Bio/Status hoặc Nhật ký
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
// 8. SIRIKIT ENTITLEMENT BYPASS (Chống văng app khi Sideload qua ESign/Scarlet)
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
// 9. KÍCH HOẠT TOÀN BỘ HOOKS
// =========================================================================
static void installAllZaloModHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[DucLamXNgBao] Đang cài đặt Hook tối ưu cho Zalo Mod VIP...");

        // Khởi tạo hàng đợi cache tin nhắn Anti-Undo
        gMessageCache = [NSMutableDictionary dictionary];
        gCacheQueue = dispatch_queue_create("com.duclam.zalomod.cacheQueue", DISPATCH_QUEUE_CONCURRENT);

        // 1. Hook Font Chữ
        swizzleInstanceMethod([UITextView class], @selector(insertText:), @selector(zaloMod_insertText:));
        swizzleInstanceMethod([UITextField class], @selector(insertText:), @selector(zaloMod_insertText:));

        // 2. Hook Anti-Undo trên ChatEntity & ChatOperationProcessor
        Class chatEntityCls = objc_getClass("ChatEntity");
        if (chatEntityCls) {
            Method setMsgM = class_getInstanceMethod(chatEntityCls, sel_registerName("setMessage:"));
            if (setMsgM) {
                IMP origImp = method_getImplementation(setMsgM);
                class_addMethod(chatEntityCls, sel_registerName("zaloMod_orig_setMessage:"), origImp, method_getTypeEncoding(setMsgM));
                method_setImplementation(setMsgM, (IMP)hook_ChatEntity_setMessage);
                NSLog(@"[DucLamXNgBao] Hook ChatEntity setMessage: thành công!");
            }

            Method undoCheckM = class_getInstanceMethod(chatEntityCls, sel_registerName("isMessageUndoOrDelete"));
            if (undoCheckM) {
                IMP origImp = method_getImplementation(undoCheckM);
                class_addMethod(chatEntityCls, sel_registerName("zaloMod_orig_isMessageUndoOrDelete:"), origImp, method_getTypeEncoding(undoCheckM));
                method_setImplementation(undoCheckM, (IMP)hook_ChatEntity_isMessageUndoOrDelete);
                NSLog(@"[DucLamXNgBao] Hook ChatEntity isMessageUndoOrDelete thành công!");
            }
        }

        Class chatOpProcCls = objc_getClass("ChatOperationProcessor");
        if (chatOpProcCls) {
            Method undoProcM = class_getInstanceMethod(chatOpProcCls, sel_registerName("_processUndoMessageWithOperationItem:"));
            if (undoProcM) {
                IMP origImp = method_getImplementation(undoProcM);
                class_addMethod(chatOpProcCls, sel_registerName("zaloMod_orig_processUndoMessage:"), origImp, method_getTypeEncoding(undoProcM));
                method_setImplementation(undoProcM, (IMP)hook_ChatOperationProcessor_processUndoMessage);
                NSLog(@"[DucLamXNgBao] Hook ChatOperationProcessor _processUndoMessage thành công!");
            }
        }

        swizzleInstanceMethod([UILabel class], @selector(setText:), @selector(zaloMod_setText:));

        // 3. Hook TTL vào ZAChatSendingManager
        Class sendMgrCls = objc_getClass("ZAChatSendingManager");
        if (sendMgrCls) {
            Method m1 = class_getInstanceMethod(sendMgrCls, sel_registerName("sendChat:checkUpload:"));
            if (m1) {
                IMP orig = method_getImplementation(m1);
                class_addMethod(sendMgrCls, sel_registerName("zaloMod_orig_sendChat_checkUpload:"), orig, method_getTypeEncoding(m1));
                method_setImplementation(m1, (IMP)hook_sendChat_checkUpload);
                NSLog(@"[DucLamXNgBao] Hook ZAChatSendingManager sendChat:checkUpload: thành công!");
            }

            Method m2 = class_getInstanceMethod(sendMgrCls, sel_registerName("sendChat:toDestinations:checkUpload:isWaitingSend:"));
            if (m2) {
                IMP orig = method_getImplementation(m2);
                class_addMethod(sendMgrCls, sel_registerName("zaloMod_orig_sendChat_destinations:"), orig, method_getTypeEncoding(m2));
                method_setImplementation(m2, (IMP)hook_sendChat_destinations);
                NSLog(@"[DucLamXNgBao] Hook ZAChatSendingManager sendChat:toDestinations:... thành công!");
            }
        }

        // 4. Hook Mở khóa Gửi Ảnh Gốc Original (QualityPickerViewController & RichMessageContent)
        Class pickerVCCls = objc_getClass("_TtC19CommFeatureBusiness27QualityPickerViewController") ?: objc_getClass("QualityPickerViewController");
        if (pickerVCCls) {
            Method mShow = class_getInstanceMethod(pickerVCCls, sel_registerName("enableShowOriginPhoto"));
            if (mShow) method_setImplementation(mShow, (IMP)hook_enableShowOriginPhoto);

            Method mBadgeType = class_getInstanceMethod(pickerVCCls, sel_registerName("originalBadgeType"));
            if (mBadgeType) method_setImplementation(mBadgeType, (IMP)hook_originalBadgeType);

            Method mBadge = class_getInstanceMethod(pickerVCCls, sel_registerName("originalBadge"));
            if (mBadge) method_setImplementation(mBadge, (IMP)hook_originalBadge);

            NSLog(@"[DucLamXNgBao] Đã mở khóa chọn ảnh Original không cần zCloud!");
        }

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
            NSLog(@"[DucLamXNgBao] Hook RichMessageContent isOriginal/isPhotoHD thành công!");
        }

        // 5. Hook Native Business Account (ProfileEntity, BuddyEntity, BALabelInfo, FlowManagers)
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

        // 6. Hook dọn dẹp view cũ trên UIViewController
        swizzleInstanceMethod([UIViewController class], @selector(viewDidAppear:), @selector(zaloMod_viewDidAppear:));

        // 7. Hook JSON API
        Method origJSON = class_getClassMethod([NSJSONSerialization class], @selector(dataWithJSONObject:options:error:));
        Method swizJSON = class_getClassMethod([NSJSONSerialization class], @selector(zaloMod_dataWithJSONObject:options:error:));
        if (origJSON && swizJSON) {
            method_exchangeImplementations(origJSON, swizJSON);
        }

        NSLog(@"[DucLamXNgBao] HOÀN TẤT KÍCH HOẠT HOOKS SIÊU CẤP VIP!");
    });
}

// Constructor Tweak
__attribute__((constructor))
static void initZaloModVIP(void) {
    patchSiriKitCrash();

    // Kích hoạt runtime hooks tối ưu
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
