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
+ (BOOL)isGhostSeenEnabled;
+ (BOOL)isHideTypingEnabled;
+ (BOOL)isBugOriginalEnabled;
+ (BOOL)isBugZBusinessEnabled;
+ (BOOL)isBugZLStyleEnabled;

@end
