//
//  ZaloModViewController.h
//  ZaloMod - Trình Điều Khiển Menu Tính Năng Toàn Diện
//

#import <UIKit/UIKit.h>

@protocol ZaloModViewControllerDelegate <NSObject>
- (void)modMenuDidDismiss;
@end

@interface ZaloModViewController : UIViewController

@property (nonatomic, weak) id<ZaloModViewControllerDelegate> delegate;

+ (instancetype)sharedInstance;
- (void)showMenuFromViewController:(UIViewController *)parentVC;
- (void)dismissMenu;

// Các hàm kiểm tra trạng thái mod toàn cục
+ (BOOL)isAntiUndoEnabled;
+ (NSInteger)customTTLSeconds;
+ (long long)customTTLMilliseconds;
+ (CGFloat)customFontSize;
+ (void)setCustomFontSize:(CGFloat)size;
+ (NSString *)selectedTextColorName;
+ (void)setSelectedTextColorName:(NSString *)name;
+ (UIColor *)selectedTextColor;
+ (BOOL)isGhostSeenEnabled;
+ (BOOL)isHideTypingEnabled;
+ (BOOL)isBugOriginalEnabled;
+ (BOOL)isBugZBusinessEnabled;
+ (BOOL)isBugZLStyleEnabled;
+ (BOOL)isAdBlockEnabled;
+ (BOOL)isUnlimitedMediaEnabled;
+ (BOOL)isUnlockRBTEnabled;

@end

