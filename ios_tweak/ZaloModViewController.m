//
//  ZaloModViewController.m
//  ZaloMod VIP - Phiên Bản Đặc Biệt: DucLamXNgBao
//

#import "ZaloModViewController.h"
#import "ZaloFloatingButton.h"

// Keys lưu cấu hình NSUserDefaults
static NSString * const kPrefAntiUndo       = @"ZaloMod_AntiUndo";
static NSString * const kPrefCustomTTL      = @"ZaloMod_CustomTTL";
static NSString * const kPrefCustomTTLUnit  = @"ZaloMod_CustomTTLUnit";  // 0: Tắt, 1: s, 2: h, 3: d
static NSString * const kPrefCustomTTLValue = @"ZaloMod_CustomTTLValue";
static NSString * const kPrefGhostSeen      = @"ZaloMod_GhostSeen";
static NSString * const kPrefHideTyping     = @"ZaloMod_HideTyping";
static NSString * const kPrefBugOriginal    = @"ZaloMod_BugOriginal";
static NSString * const kPrefBugZBusiness   = @"ZaloMod_BugZBusiness";
static NSString * const kPrefBugZLStyle     = @"ZaloMod_BugZLStyle";
static NSString * const kPrefSelectedFont   = @"ZaloMod_SelectedFont";
static NSString * const kPrefCustomFontSize = @"ZaloMod_CustomFontSize";

@interface ZaloModViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIVisualEffectView *blurContainer;
@property (nonatomic, strong) UIView *menuBox;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIScrollView *contentScrollView;

// Tabs
@property (nonatomic, strong) UIView *tabMessagesView;
@property (nonatomic, strong) UIView *tabFontsView;
@property (nonatomic, strong) UIView *tabZBusinessView;
@property (nonatomic, strong) UIView *tabGroupsView;
@property (nonatomic, strong) UIView *tabAdminView;

// Controls
@property (nonatomic, strong) UISegmentedControl *ttlSegment;
@property (nonatomic, strong) UITextField *txtTTLValue;
@property (nonatomic, strong) UILabel *lblTTLSummary;
@property (nonatomic, strong) UILabel *lblCurrentFont;
@property (nonatomic, strong) NSMutableArray<UIButton *> *fontButtons;
@property (nonatomic, strong) UISegmentedControl *fontSizeSegment;
@property (nonatomic, strong) UITextField *txtFontSize;
@property (nonatomic, strong) UILabel *lblFontSizeSummary;
@property (nonatomic, strong) UITextField *txtTargetId;
@property (nonatomic, strong) UITextField *txtMessageContent;
@property (nonatomic, strong) UITextField *txtGroupLinkOrId;
@property (nonatomic, strong) UITextField *txtKickUid;
@property (nonatomic, strong) UITextField *txtBanUid;

@end

@implementation ZaloModViewController

static ZaloModViewController *_sharedMenuVC = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedMenuVC = [[ZaloModViewController alloc] init];
    });
    return _sharedMenuVC;
}

+ (BOOL)isAntiUndoEnabled {
    id val = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefAntiUndo];
    return (val == nil) ? YES : [val boolValue];
}

+ (long long)customTTLMilliseconds {
    NSInteger unit = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefCustomTTLUnit];
    NSInteger val = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefCustomTTLValue];
    if (unit == 0 || val <= 0) {
        NSInteger oldSecs = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefCustomTTL];
        return (oldSecs > 0) ? ((long long)oldSecs * 1000LL) : 0;
    }
    if (unit == 1) return (long long)val * 1000LL;               // s (giây)
    if (unit == 2) return (long long)val * 3600LL * 1000LL;        // h (giờ)
    if (unit == 3) return (long long)val * 86400LL * 1000LL;       // d (ngày)
    return 0;
}

+ (NSInteger)customTTLSeconds {
    return (NSInteger)([self customTTLMilliseconds] / 1000LL);
}

+ (CGFloat)customFontSize {
    CGFloat val = [[NSUserDefaults standardUserDefaults] floatForKey:kPrefCustomFontSize];
    return val > 0 ? val : 0;
}

+ (void)setCustomFontSize:(CGFloat)size {
    [[NSUserDefaults standardUserDefaults] setFloat:size forKey:kPrefCustomFontSize];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isBugZLStyleEnabled {
    id val = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefBugZLStyle];
    return (val == nil) ? YES : [val boolValue];
}

+ (BOOL)isGhostSeenEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kPrefGhostSeen];
}

+ (BOOL)isHideTypingEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kPrefHideTyping];
}

+ (BOOL)isBugOriginalEnabled {
    id val = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefBugOriginal];
    return (val == nil) ? YES : [val boolValue];
}

+ (BOOL)isBugZBusinessEnabled {
    id val = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefBugZBusiness];
    return (val == nil) ? YES : [val boolValue];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.fontButtons = [NSMutableArray array];
    [self setupMainContainer];
    [self setupTabs];
    [self switchTab:0];
}

- (void)setupMainContainer {
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    CGFloat boxW = MIN(screenW - 28, 440);
    CGFloat boxH = MIN(screenH - 90, 620);

    // Hộp menu Liquid Glassmorphism iOS 26
    self.menuBox = [[UIView alloc] initWithFrame:CGRectMake((screenW - boxW) / 2.0, (screenH - boxH) / 2.0, boxW, boxH)];
    self.menuBox.layer.cornerRadius = 26.0;
    self.menuBox.layer.borderColor = [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:0.75].CGColor;
    self.menuBox.layer.borderWidth = 1.8;
    self.menuBox.clipsToBounds = YES;
    
    // Đổ bóng phát sáng Cyan Neon
    self.menuBox.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.75 blue:1.0 alpha:0.85].CGColor;
    self.menuBox.layer.shadowRadius = 20.0;
    self.menuBox.layer.shadowOpacity = 0.9;
    self.menuBox.layer.shadowOffset = CGSizeMake(0, 10);
    [self.view addSubview:self.menuBox];

    // Blur kính mờ cao cấp
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.blurContainer = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.blurContainer.frame = self.menuBox.bounds;
    self.blurContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.menuBox addSubview:self.blurContainer];

    // Header Bar
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, boxW, 64)];
    header.backgroundColor = [[UIColor colorWithRed:0.03 green:0.08 blue:0.16 alpha:0.9] colorWithAlphaComponent:0.85];
    [self.menuBox addSubview:header];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, boxW - 140, 24)];
    titleLabel.text = @"⚡ ZALO VIP MOD PRO";
    titleLabel.textColor = [UIColor colorWithRed:0.2 green:0.9 blue:1.0 alpha:1.0];
    titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    [header addSubview:titleLabel];

    // Watermark góc menu: DucLamXNgBao
    UILabel *lblWatermark = [[UILabel alloc] initWithFrame:CGRectMake(16, 36, boxW - 140, 18)];
    lblWatermark.text = @"✨ DucLamXNgBao • iOS 26 Glass";
    lblWatermark.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0]; // Gold
    lblWatermark.font = [UIFont boldSystemFontOfSize:11.5];
    [header addSubview:lblWatermark];

    // Nút đóng
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(boxW - 48, 14, 36, 36);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    closeBtn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    closeBtn.layer.cornerRadius = 18.0;
    [closeBtn addTarget:self action:@selector(dismissMenu) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:closeBtn];

    // Segmented Navigation Tabs
    NSArray *items = @[@"💬 Tin Nhắn", @"🔤 Font", @"👑 ZBusiness", @"👥 Nhóm", @"👤 Admin"];
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
    self.segmentedControl.frame = CGRectMake(10, 72, boxW - 20, 32);
    self.segmentedControl.selectedSegmentIndex = 0;
    if (@available(iOS 13.0, *)) {
        self.segmentedControl.selectedSegmentTintColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.9];
        [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont boldSystemFontOfSize:11.0]} forState:UIControlStateSelected];
        [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[[UIColor whiteColor] colorWithAlphaComponent:0.75], NSFontAttributeName:[UIFont systemFontOfSize:11.0]} forState:UIControlStateNormal];
    }
    [self.segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    [self.menuBox addSubview:self.segmentedControl];

    // Content Scroll View
    self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 112, boxW, boxH - 112)];
    self.contentScrollView.showsVerticalScrollIndicator = YES;
    self.contentScrollView.alwaysBounceVertical = YES;
    [self.menuBox addSubview:self.contentScrollView];
}

- (void)setupTabs {
    CGFloat contentW = self.contentScrollView.bounds.size.width;

    // =========================================================================
    // TAB 0: TIN NHẮN, CHỐNG THU HỒI, TTL VÀ ẢNH GỐC HD
    // =========================================================================
    self.tabMessagesView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentW, 700)];
    CGFloat y = 10.0;

    // Switch: Chống thu hồi chuẩn xác: <text> ( đã thu hồi ) / ( đã thu hồi )\n[Ảnh HD]
    y = [self addSwitchRowToView:self.tabMessagesView y:y title:@"Chống thu hồi (Anti-Undo)" subtitle:@"Hiện: 'hello ( đã thu hồi )' hoặc '( đã thu hồi )\nẢnh'" initial:[ZaloModViewController isAntiUndoEnabled] action:@selector(toggleAntiUndo:)];

    // Switch: Bug API Gửi Ảnh Gốc HD (is_original = 1)
    y = [self addSwitchRowToView:self.tabMessagesView y:y title:@"Bug API Gửi Ảnh Gốc HD (is_original = 1)" subtitle:@"Gửi ảnh RAW nguyên bản độ phân giải cao không bị nén" initial:[ZaloModViewController isBugOriginalEnabled] action:@selector(toggleBugOriginal:)];

    // Tự điều chỉnh TTL: s (Giây), h (Giờ), d (Ngày) + nhập thời gian
    UILabel *lblTTL = [[UILabel alloc] initWithFrame:CGRectMake(14, y, contentW - 28, 20)];
    lblTTL.text = @"⏱ Tự điều chỉnh TTL (s: Giây, h: Giờ, d: Ngày):";
    lblTTL.textColor = [UIColor colorWithRed:0.2 green:0.85 blue:1.0 alpha:1.0];
    lblTTL.font = [UIFont boldSystemFontOfSize:12.5];
    [self.tabMessagesView addSubview:lblTTL];
    y += 24;

    NSArray *ttlUnits = @[@"Tắt", @"s (Giây)", @"h (Giờ)", @"d (Ngày)"];
    self.ttlSegment = [[UISegmentedControl alloc] initWithItems:ttlUnits];
    self.ttlSegment.frame = CGRectMake(14, y, contentW - 28, 30);
    [self setupTTLSelection];
    [self.ttlSegment addTarget:self action:@selector(ttlUnitChanged:) forControlEvents:UIControlEventValueChanged];
    [self.tabMessagesView addSubview:self.ttlSegment];
    y += 38;

    CGFloat inputW = contentW - 28 - 96;
    self.txtTTLValue = [self createTextFieldWithPlaceholder:@"Nhập số (vd: 30, 2, 7...)" y:y width:inputW];
    self.txtTTLValue.keyboardType = UIKeyboardTypeNumberPad;
    NSInteger savedVal = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefCustomTTLValue];
    if (savedVal > 0) {
        self.txtTTLValue.text = [NSString stringWithFormat:@"%ld", (long)savedVal];
    }
    [self.txtTTLValue addTarget:self action:@selector(ttlTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.tabMessagesView addSubview:self.txtTTLValue];

    UIButton *btnApplyTTL = [UIButton buttonWithType:UIButtonTypeCustom];
    btnApplyTTL.frame = CGRectMake(14 + inputW + 6, y, 90, 36);
    btnApplyTTL.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0];
    btnApplyTTL.layer.cornerRadius = 8.0;
    [btnApplyTTL setTitle:@"⚡ Lưu TTL" forState:UIControlStateNormal];
    [btnApplyTTL setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnApplyTTL.titleLabel.font = [UIFont boldSystemFontOfSize:12.5];
    [btnApplyTTL addTarget:self action:@selector(actionApplyTTL) forControlEvents:UIControlEventTouchUpInside];
    [self.tabMessagesView addSubview:btnApplyTTL];
    y += 42;

    self.lblTTLSummary = [[UILabel alloc] initWithFrame:CGRectMake(14, y, contentW - 28, 20)];
    self.lblTTLSummary.textColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.5 alpha:1.0];
    self.lblTTLSummary.font = [UIFont boldSystemFontOfSize:12.0];
    [self updateTTLSummaryLabel];
    [self.tabMessagesView addSubview:self.lblTTLSummary];
    y += 28;

    // Switch Ghost Seen & Hide Typing
    y = [self addSwitchRowToView:self.tabMessagesView y:y title:@"Ẩn Đã Xem (Ghost Seen)" subtitle:@"Đọc tin nhắn mà không hiện chữ 'Đã xem'" initial:[ZaloModViewController isGhostSeenEnabled] action:@selector(toggleGhostSeen:)];

    y = [self addSwitchRowToView:self.tabMessagesView y:y title:@"Ẩn Đang Nhập (Hide Typing)" subtitle:@"Không hiện trạng thái đang gõ phím" initial:[ZaloModViewController isHideTypingEnabled] action:@selector(toggleHideTyping:)];

    // Gửi tin nhắn nhanh
    UILabel *lblSend = [[UILabel alloc] initWithFrame:CGRectMake(14, y, contentW - 28, 20)];
    lblSend.text = @"🚀 Gửi tin nhắn (Tự đính kèm Font & TTL):";
    lblSend.textColor = [UIColor colorWithRed:0.2 green:0.85 blue:1.0 alpha:1.0];
    lblSend.font = [UIFont boldSystemFontOfSize:12.5];
    [self.tabMessagesView addSubview:lblSend];
    y += 24;

    self.txtTargetId = [self createTextFieldWithPlaceholder:@"Nhập Group ID hoặc UID người nhận" y:y width:contentW - 28];
    [self.tabMessagesView addSubview:self.txtTargetId];
    y += 40;

    self.txtMessageContent = [self createTextFieldWithPlaceholder:@"Nội dung tin nhắn..." y:y width:contentW - 28];
    [self.tabMessagesView addSubview:self.txtMessageContent];
    y += 44;

    UIButton *btnSend = [self createActionButtonWithTitle:@"🚀 Gửi Tin Nhắn Nhanh" y:y width:contentW - 28 color:[UIColor colorWithRed:0.0 green:0.55 blue:1.0 alpha:1.0]];
    [btnSend addTarget:self action:@selector(actionSendMessage) forControlEvents:UIControlEventTouchUpInside];
    [self.tabMessagesView addSubview:btnSend];
    y += 50;

    self.tabMessagesView.frame = CGRectMake(0, 0, contentW, y + 20);

    // =========================================================================
    // TAB 1: BẢNG FONT CHỮ TYPOGRAPHY & CHỈNH SIZE CHỮ (CHỮ TO)
    // =========================================================================
    self.tabFontsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentW, 560)];
    y = 12.0;

    UILabel *lblFHeader = [[UILabel alloc] initWithFrame:CGRectMake(14, y, contentW - 28, 22)];
    lblFHeader.text = @"🔤 Chọn Font Chữ Typography (Tin nhắn gửi đi sẽ đổi font):";
    lblFHeader.textColor = [UIColor colorWithRed:0.2 green:0.9 blue:1.0 alpha:1.0];
    lblFHeader.font = [UIFont boldSystemFontOfSize:12.5];
    [self.tabFontsView addSubview:lblFHeader];
    y += 28;

    NSArray *row1 = @[@"Tắt", @"Chữ To", @"Random", @"Pixel"];
    NSArray *row2 = @[@"Vintage", @"Florence", @"Notes", @"Elegant"];
    NSArray *row3 = @[@"Amatic", @"Terminal", @"Retro", @"Young"];
    NSArray *row4 = @[@"School"];

    y = [self addFontRowToView:self.tabFontsView y:y label:@"Hàng 1:" fonts:row1];
    y = [self addFontRowToView:self.tabFontsView y:y label:@"Hàng 2:" fonts:row2];
    y = [self addFontRowToView:self.tabFontsView y:y label:@"Hàng 3:" fonts:row3];
    y = [self addFontRowToView:self.tabFontsView y:y label:@"Hàng 4:" fonts:row4];

    NSString *savedFont = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefSelectedFont] ?: @"Tắt";
    self.lblCurrentFont = [[UILabel alloc] initWithFrame:CGRectMake(14, y, contentW - 28, 24)];
    self.lblCurrentFont.text = [NSString stringWithFormat:@"Đang chọn Font: %@", savedFont];
    self.lblCurrentFont.textColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.5 alpha:1.0];
    self.lblCurrentFont.font = [UIFont boldSystemFontOfSize:13.0];
    [self.tabFontsView addSubview:self.lblCurrentFont];
    y += 36;

    // PHẦN CHỈNH SIZE CHỮ Ô NHẬP TIN NHẮN (CHỮ TO)
    UILabel *lblSizeHeader = [[UILabel alloc] initWithFrame:CGRectMake(14, y, contentW - 28, 22)];
    lblSizeHeader.text = @"📏 Chỉnh Kích Thước / Size Chữ Ô Nhập (Chữ To):";
    lblSizeHeader.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0]; // Gold
    lblSizeHeader.font = [UIFont boldSystemFontOfSize:12.5];
    [self.tabFontsView addSubview:lblSizeHeader];
    y += 26;

    NSArray *sizePresets = @[@"Mặc định", @"To (20)", @"Rất To (26)", @"Khổng Lồ (32)"];
    self.fontSizeSegment = [[UISegmentedControl alloc] initWithItems:sizePresets];
    self.fontSizeSegment.frame = CGRectMake(14, y, contentW - 28, 30);
    [self setupFontSizeSelection];
    [self.fontSizeSegment addTarget:self action:@selector(fontSizePresetChanged:) forControlEvents:UIControlEventValueChanged];
    [self.tabFontsView addSubview:self.fontSizeSegment];
    y += 38;

    CGFloat sizeInputW = contentW - 28 - 100;
    self.txtFontSize = [self createTextFieldWithPlaceholder:@"Nhập size (vd: 20, 24, 28, 32...)" y:y width:sizeInputW];
    self.txtFontSize.keyboardType = UIKeyboardTypeNumberPad;
    CGFloat currentSavedSize = [ZaloModViewController customFontSize];
    if (currentSavedSize > 0) {
        self.txtFontSize.text = [NSString stringWithFormat:@"%.0f", currentSavedSize];
    }
    [self.tabFontsView addSubview:self.txtFontSize];

    UIButton *btnApplySize = [UIButton buttonWithType:UIButtonTypeCustom];
    btnApplySize.frame = CGRectMake(14 + sizeInputW + 6, y, 94, 36);
    btnApplySize.backgroundColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.4 alpha:1.0];
    btnApplySize.layer.cornerRadius = 8.0;
    [btnApplySize setTitle:@"⚡ Lưu Size" forState:UIControlStateNormal];
    [btnApplySize setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnApplySize.titleLabel.font = [UIFont boldSystemFontOfSize:12.5];
    [btnApplySize addTarget:self action:@selector(actionApplyFontSize) forControlEvents:UIControlEventTouchUpInside];
    [self.tabFontsView addSubview:btnApplySize];
    y += 42;

    self.lblFontSizeSummary = [[UILabel alloc] initWithFrame:CGRectMake(14, y, contentW - 28, 20)];
    self.lblFontSizeSummary.textColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.5 alpha:1.0];
    self.lblFontSizeSummary.font = [UIFont boldSystemFontOfSize:12.0];
    [self updateFontSizeSummaryLabel];
    [self.tabFontsView addSubview:self.lblFontSizeSummary];
    y += 28;

    self.tabFontsView.frame = CGRectMake(0, 0, contentW, y + 20);

    // =========================================================================
    // TAB 2: BUG TOÀN BỘ ZSTYLES & NHẠC NỀN CHAT / PROFILE + ZBUSINESS PRO
    // =========================================================================
    self.tabZBusinessView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentW, 460)];
    y = 12.0;

    UILabel *lblZBHeader = [[UILabel alloc] initWithFrame:CGRectMake(14, y, contentW - 28, 44)];
    lblZBHeader.numberOfLines = 2;
    lblZBHeader.text = @"👑 Bug Toàn Bộ ZStyles & Hiện Nhạc Nền (Pill Player):\nHiện thanh nhạc Zing MP3 trên cùng (ai cũng thấy) & mở full ZStyle.";
    lblZBHeader.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    lblZBHeader.font = [UIFont boldSystemFontOfSize:12.0];
    [self.tabZBusinessView addSubview:lblZBHeader];
    y += 50;

    y = [self addSwitchRowToView:self.tabZBusinessView y:y title:@"Bug All ZStyles & Nhạc Nền (Pill Player)" subtitle:@"Hiện thanh nhạc Zing MP3 trên đầu chat/profile, mở full gói ZStyle VIP" initial:[ZaloModViewController isBugZLStyleEnabled] action:@selector(toggleBugZLStyle:)];

    y = [self addSwitchRowToView:self.tabZBusinessView y:y title:@"Nhãn ZBusiness Pro Doanh Nghiệp" subtitle:@"Hiển thị tích vàng xác thực ZBusiness trên profile" initial:[ZaloModViewController isBugZBusinessEnabled] action:@selector(toggleBugZBusiness:)];

    self.tabZBusinessView.frame = CGRectMake(0, 0, contentW, y + 20);

    // =========================================================================
    // TAB 3: QUẢN LÝ NHÓM
    // =========================================================================
    self.tabGroupsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentW, 480)];
    y = 12.0;

    self.txtGroupLinkOrId = [self createTextFieldWithPlaceholder:@"Dán link zalo.me/g/... hoặc GID" y:y width:contentW - 28];
    [self.tabGroupsView addSubview:self.txtGroupLinkOrId];
    y += 44;

    UIButton *btnJoin = [self createActionButtonWithTitle:@"➕ Vào Nhóm Ngay (CMD 244)" y:y width:contentW - 28 color:[UIColor colorWithRed:0.1 green:0.7 blue:0.4 alpha:1.0]];
    [btnJoin addTarget:self action:@selector(actionJoinGroup) forControlEvents:UIControlEventTouchUpInside];
    [self.tabGroupsView addSubview:btnJoin];
    y += 48;

    self.txtKickUid = [self createTextFieldWithPlaceholder:@"Nhập UID thành viên cần Đuổi (Kick 228)" y:y width:contentW - 28];
    [self.tabGroupsView addSubview:self.txtKickUid];
    y += 44;

    UIButton *btnKick = [self createActionButtonWithTitle:@"⚠️ Đuổi Thành Viên (Kick 228)" y:y width:contentW - 28 color:[UIColor colorWithRed:0.9 green:0.4 blue:0.1 alpha:1.0]];
    [btnKick addTarget:self action:@selector(actionKickMember) forControlEvents:UIControlEventTouchUpInside];
    [self.tabGroupsView addSubview:btnKick];
    y += 48;

    UIButton *btnLeave = [self createActionButtonWithTitle:@"🚪 Rời Nhóm An Toàn (Silent Leave 225)" y:y width:contentW - 28 color:[UIColor colorWithRed:0.5 green:0.2 blue:0.7 alpha:1.0]];
    [btnLeave addTarget:self action:@selector(actionLeaveGroup) forControlEvents:UIControlEventTouchUpInside];
    [self.tabGroupsView addSubview:btnLeave];
    y += 50;

    self.tabGroupsView.frame = CGRectMake(0, 0, contentW, y + 20);

    // =========================================================================
    // TAB 4: HỒ SƠ ADMIN (DucLamXNgBao & ẢNH 2 HÌNH TRÒN)
    // =========================================================================
    self.tabAdminView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentW, 480)];
    y = 16.0;

    // Ảnh tròn thứ 2
    CGFloat avatarSize = 110.0;
    UIImageView *avatarView = [[UIImageView alloc] initWithFrame:CGRectMake((contentW - avatarSize) / 2.0, y, avatarSize, avatarSize)];
    avatarView.layer.cornerRadius = avatarSize / 2.0;
    avatarView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.9 blue:1.0 alpha:0.9].CGColor;
    avatarView.layer.borderWidth = 2.5;
    avatarView.clipsToBounds = YES;
    avatarView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    avatarView.image = [UIImage imageNamed:@"admin_circle.png"];
    [self.tabAdminView addSubview:avatarView];
    y += avatarSize + 16;

    // Khung Thông Tin Admin theo đúng yêu cầu
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(14, y, contentW - 28, 180)];
    card.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
    card.layer.cornerRadius = 16.0;
    card.layer.borderColor = [UIColor colorWithRed:0.2 green:0.7 blue:1.0 alpha:0.4].CGColor;
    card.layer.borderWidth = 1.0;

    UILabel *lblAdm1 = [[UILabel alloc] initWithFrame:CGRectMake(12, 16, card.bounds.size.width - 24, 26)];
    lblAdm1.text = @"👑 Admin : Nguyễn Đức Lâm";
    lblAdm1.textColor = [UIColor whiteColor];
    lblAdm1.font = [UIFont boldSystemFontOfSize:15.0];
    lblAdm1.textAlignment = NSTextAlignmentCenter;
    [card addSubview:lblAdm1];

    UILabel *lblAdm2 = [[UILabel alloc] initWithFrame:CGRectMake(12, 48, card.bounds.size.width - 24, 26)];
    lblAdm2.text = @"👑 Admin : Nguyễn Hoàng Gia Bảo (ngbao)";
    lblAdm2.textColor = [UIColor colorWithRed:0.2 green:0.9 blue:1.0 alpha:1.0];
    lblAdm2.font = [UIFont boldSystemFontOfSize:15.0];
    lblAdm2.textAlignment = NSTextAlignmentCenter;
    [card addSubview:lblAdm2];

    UILabel *lblBrand = [[UILabel alloc] initWithFrame:CGRectMake(12, 88, card.bounds.size.width - 24, 22)];
    lblBrand.text = @"✨ Thương hiệu: DucLamXNgBao";
    lblBrand.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    lblBrand.font = [UIFont boldSystemFontOfSize:13.5];
    lblBrand.textAlignment = NSTextAlignmentCenter;
    [card addSubview:lblBrand];

    UILabel *lblSubAdm = [[UILabel alloc] initWithFrame:CGRectMake(12, 116, card.bounds.size.width - 24, 46)];
    lblSubAdm.numberOfLines = 2;
    lblSubAdm.text = @"Zalo VIP Mod Pro v26.06.02\nLiquid Glass iOS 26 • Anti-Undo • Custom TTL";
    lblSubAdm.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.65];
    lblSubAdm.font = [UIFont systemFontOfSize:11.5];
    lblSubAdm.textAlignment = NSTextAlignmentCenter;
    [card addSubview:lblSubAdm];

    [self.tabAdminView addSubview:card];
    y += 190;

    self.tabAdminView.frame = CGRectMake(0, 0, contentW, y + 20);
}

// Hàm thêm 1 hàng font gồm 4 nút
- (CGFloat)addFontRowToView:(UIView *)parent y:(CGFloat)y label:(NSString *)rowLabel fonts:(NSArray<NSString *> *)fonts {
    CGFloat w = parent.bounds.size.width;
    CGFloat pad = 12.0;
    CGFloat btnW = (w - pad * 2 - 24) / 4.0;

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(pad, y, 60, 20)];
    lbl.text = rowLabel;
    lbl.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    lbl.font = [UIFont boldSystemFontOfSize:11.5];
    [parent addSubview:lbl];
    y += 22;

    NSString *savedFont = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefSelectedFont] ?: @"Tắt";
    for (NSInteger i = 0; i < fonts.count; i++) {
        NSString *fn = fonts[i];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(pad + i * (btnW + 8), y, btnW, 30);
        btn.layer.cornerRadius = 8.0;
        [btn setTitle:fn forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];

        if ([fn isEqualToString:savedFont]) {
            btn.backgroundColor = [UIColor colorWithRed:0.0 green:0.55 blue:1.0 alpha:1.0];
        } else {
            btn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
        }

        [btn addTarget:self action:@selector(fontButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [parent addSubview:btn];
        [self.fontButtons addObject:btn];
    }
    return y + 36;
}

- (void)fontButtonTapped:(UIButton *)sender {
    NSString *fn = [sender titleForState:UIControlStateNormal];
    [[NSUserDefaults standardUserDefaults] setObject:fn forKey:kPrefSelectedFont];
    [[NSUserDefaults standardUserDefaults] synchronize];

    for (UIButton *b in self.fontButtons) {
        if ([b isEqual:sender]) {
            b.backgroundColor = [UIColor colorWithRed:0.0 green:0.55 blue:1.0 alpha:1.0];
        } else {
            b.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
        }
    }
    self.lblCurrentFont.text = [NSString stringWithFormat:@"Đang chọn Font: %@", fn];
    [self showToast:[NSString stringWithFormat:@"🔤 Đã chọn Font: %@", fn]];
}

- (CGFloat)addSwitchRowToView:(UIView *)parent y:(CGFloat)y title:(NSString *)title subtitle:(NSString *)sub initial:(BOOL)val action:(SEL)act {
    CGFloat w = parent.bounds.size.width;
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(12, y, w - 24, 52)];
    row.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.07];
    row.layer.cornerRadius = 12.0;

    UILabel *lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 6, w - 90, 20)];
    lblTitle.text = title;
    lblTitle.textColor = [UIColor whiteColor];
    lblTitle.font = [UIFont boldSystemFontOfSize:13.0];
    [row addSubview:lblTitle];

    UILabel *lblSub = [[UILabel alloc] initWithFrame:CGRectMake(12, 26, w - 90, 18)];
    lblSub.text = sub;
    lblSub.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.65];
    lblSub.font = [UIFont systemFontOfSize:10.5];
    [row addSubview:lblSub];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(w - 24 - 60, 10, 51, 31)];
    sw.on = val;
    sw.onTintColor = [UIColor colorWithRed:0.0 green:0.65 blue:1.0 alpha:1.0];
    [sw addTarget:self action:act forControlEvents:UIControlEventValueChanged];
    [row addSubview:sw];

    [parent addSubview:row];
    return y + 58;
}

- (UITextField *)createTextFieldWithPlaceholder:(NSString *)ph y:(CGFloat)y width:(CGFloat)w {
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(14, y, w, 36)];
    tf.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    tf.textColor = [UIColor whiteColor];
    tf.font = [UIFont systemFontOfSize:13.0];
    tf.layer.cornerRadius = 8.0;
    tf.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 36)];
    tf.leftViewMode = UITextFieldViewModeAlways;
    tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:ph attributes:@{NSForegroundColorAttributeName:[[UIColor whiteColor] colorWithAlphaComponent:0.45]}];
    tf.delegate = self;
    return tf;
}

- (UIButton *)createActionButtonWithTitle:(NSString *)title y:(CGFloat)y width:(CGFloat)w color:(UIColor *)bgColor {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(14, y, w, 40);
    btn.backgroundColor = bgColor;
    btn.layer.cornerRadius = 10.0;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:13.5];
    return btn;
}

- (void)setupTTLSelection {
    NSInteger unit = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefCustomTTLUnit];
    if (unit >= 0 && unit <= 3) {
        self.ttlSegment.selectedSegmentIndex = unit;
    } else {
        self.ttlSegment.selectedSegmentIndex = 0;
    }
}

- (void)setupFontSizeSelection {
    CGFloat cur = [ZaloModViewController customFontSize];
    if (cur <= 0) {
        self.fontSizeSegment.selectedSegmentIndex = 0;
    } else if (fabs(cur - 20.0) < 0.5) {
        self.fontSizeSegment.selectedSegmentIndex = 1;
    } else if (fabs(cur - 26.0) < 0.5) {
        self.fontSizeSegment.selectedSegmentIndex = 2;
    } else if (fabs(cur - 32.0) < 0.5) {
        self.fontSizeSegment.selectedSegmentIndex = 3;
    } else {
        self.fontSizeSegment.selectedSegmentIndex = UISegmentedControlNoSegment;
    }
}

- (void)fontSizePresetChanged:(UISegmentedControl *)sender {
    CGFloat chosenSize = 0;
    switch (sender.selectedSegmentIndex) {
        case 0: chosenSize = 0; break; // Mặc định
        case 1: chosenSize = 20.0; break;
        case 2: chosenSize = 26.0; break;
        case 3: chosenSize = 32.0; break;
        default: break;
    }
    [ZaloModViewController setCustomFontSize:chosenSize];
    if (chosenSize > 0) {
        self.txtFontSize.text = [NSString stringWithFormat:@"%.0f", chosenSize];
    } else {
        self.txtFontSize.text = @"";
    }
    [self updateFontSizeSummaryLabel];
    [self showToast:[NSString stringWithFormat:@"Đã đặt cỡ chữ: %@", chosenSize > 0 ? [NSString stringWithFormat:@"%.0f px (Chữ To)", chosenSize] : @"Mặc định"]];
}

- (void)actionApplyFontSize {
    [self.view endEditing:YES];
    CGFloat size = [self.txtFontSize.text floatValue];
    if (size > 0 && size < 10) size = 10;
    if (size > 60) size = 60;
    [ZaloModViewController setCustomFontSize:size];
    [self setupFontSizeSelection];
    [self updateFontSizeSummaryLabel];
    if (size > 0) {
        [self showToast:[NSString stringWithFormat:@"✅ Đã lưu cỡ chữ: %.0f px (Chữ To)", size]];
    } else {
        [self showToast:@"⚪ Đã đưa cỡ chữ về Mặc định"];
    }
}

- (void)updateFontSizeSummaryLabel {
    CGFloat cur = [ZaloModViewController customFontSize];
    if (cur > 0) {
        self.lblFontSizeSummary.text = [NSString stringWithFormat:@"✅ Cỡ chữ hiện tại: %.0f px (Chữ To)", cur];
        self.lblFontSizeSummary.textColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.5 alpha:1.0];
    } else {
        self.lblFontSizeSummary.text = @"⚪ Cỡ chữ hiện tại: Mặc định (Theo hệ thống Zalo)";
        self.lblFontSizeSummary.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    }
}

- (void)segmentChanged:(UISegmentedControl *)sender {
    [self switchTab:sender.selectedSegmentIndex];
}

- (void)switchTab:(NSInteger)idx {
    [self.tabMessagesView removeFromSuperview];
    [self.tabFontsView removeFromSuperview];
    [self.tabZBusinessView removeFromSuperview];
    [self.tabGroupsView removeFromSuperview];
    [self.tabAdminView removeFromSuperview];

    UIView *targetView = nil;
    if (idx == 0) targetView = self.tabMessagesView;
    else if (idx == 1) targetView = self.tabFontsView;
    else if (idx == 2) targetView = self.tabZBusinessView;
    else if (idx == 3) targetView = self.tabGroupsView;
    else if (idx == 4) targetView = self.tabAdminView;

    if (targetView) {
        [self.contentScrollView addSubview:targetView];
        self.contentScrollView.contentSize = targetView.frame.size;
    }
}

- (void)toggleAntiUndo:(UISwitch *)s {
    [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kPrefAntiUndo];
    [self showToast:s.isOn ? @"✅ BẬT Anti-Undo: <tin nhắn> ( đã thu hồi )" : @"❌ TẮT Anti-Undo"];
}

- (void)toggleBugOriginal:(UISwitch *)s {
    [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kPrefBugOriginal];
    [self showToast:s.isOn ? @"⚡ BẬT Bug is_original = 1 (Ảnh Gốc HD)" : @"❌ TẮT Gửi Ảnh Gốc"];
}

- (void)toggleBugZBusiness:(UISwitch *)s {
    [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kPrefBugZBusiness];
    [self showToast:s.isOn ? @"👑 BẬT Nhãn ZBusiness Pro (Client-Side)" : @"❌ TẮT Nhãn ZBusiness"];
}

- (void)toggleBugZLStyle:(UISwitch *)s {
    [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kPrefBugZLStyle];
    [self showToast:s.isOn ? @"👑 BẬT Bug All ZStyles & Hiện Nhạc Nền (Pill Player)" : @"❌ TẮT Bug ZStyles"];
}

- (void)toggleGhostSeen:(UISwitch *)s {
    [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kPrefGhostSeen];
    [self showToast:s.isOn ? @"👻 BẬT Ẩn Đã Xem" : @"👁 TẮT Ẩn Đã Xem"];
}

- (void)toggleHideTyping:(UISwitch *)s {
    [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kPrefHideTyping];
    [self showToast:s.isOn ? @"🤫 BẬT Ẩn Đang Nhập" : @"⌨️ TẮT Ẩn Đang Nhập"];
}

- (void)ttlUnitChanged:(UISegmentedControl *)s {
    [[NSUserDefaults standardUserDefaults] setInteger:s.selectedSegmentIndex forKey:kPrefCustomTTLUnit];
    [self updateTTLSummaryLabel];
    if (s.selectedSegmentIndex == 0) {
        [self showToast:@"⏱ Đã tắt tự hủy TTL"];
    } else {
        [self showToast:self.lblTTLSummary.text];
    }
}

- (void)ttlTextChanged:(UITextField *)tf {
    NSInteger val = [tf.text integerValue];
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:kPrefCustomTTLValue];
    [self updateTTLSummaryLabel];
}

- (void)saveCurrentTTL {
    NSInteger unit = self.ttlSegment.selectedSegmentIndex;
    NSInteger val = [self.txtTTLValue.text integerValue];
    [[NSUserDefaults standardUserDefaults] setInteger:unit forKey:kPrefCustomTTLUnit];
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:kPrefCustomTTLValue];
    [self updateTTLSummaryLabel];
}

- (void)updateTTLSummaryLabel {
    long long ms = [ZaloModViewController customTTLMilliseconds];
    NSInteger unit = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefCustomTTLUnit];
    NSInteger val = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefCustomTTLValue];

    if (unit == 0 || val <= 0) {
        self.lblTTLSummary.text = @"⏱ Tự hủy TTL: ĐÃ TẮT";
        self.lblTTLSummary.textColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.4 alpha:1.0];
    } else {
        NSString *uName = @"";
        if (unit == 1) uName = [NSString stringWithFormat:@"%ld giây", (long)val];
        else if (unit == 2) uName = [NSString stringWithFormat:@"%ld giờ", (long)val];
        else if (unit == 3) uName = [NSString stringWithFormat:@"%ld ngày", (long)val];

        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSString *msStr = [f stringFromNumber:@(ms)];
        self.lblTTLSummary.text = [NSString stringWithFormat:@"⏱ Đang gán TTL: %@ (%@ ms)", uName, msStr];
        self.lblTTLSummary.textColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.5 alpha:1.0];
    }
}

- (void)actionApplyTTL {
    [self.view endEditing:YES];
    [self saveCurrentTTL];
    long long ms = [ZaloModViewController customTTLMilliseconds];
    if (ms > 0) {
        [self showToast:[NSString stringWithFormat:@"✅ %@", self.lblTTLSummary.text]];
    } else {
        [self showToast:@"⏱ Đã tắt tự hủy TTL"];
    }
}

- (void)actionSendMessage {
    NSString *tid = self.txtTargetId.text;
    NSString *msg = self.txtMessageContent.text;
    if (!tid.length || !msg.length) {
        [self showToast:@"⚠️ Hãy nhập đủ Target ID và Nội dung"];
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZaloModSendMessageNotification" object:nil userInfo:@{@"targetId":tid, @"text":msg}];
    [self showToast:[NSString stringWithFormat:@"🚀 Đang gửi tin đến %@", tid]];
}

- (void)actionJoinGroup {
    NSString *link = self.txtGroupLinkOrId.text;
    if (!link.length) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZaloModJoinGroupNotification" object:nil userInfo:@{@"link":link}];
    [self showToast:@"🔗 Đang gửi yêu cầu vào nhóm..."];
}

- (void)actionKickMember {
    NSString *uid = self.txtKickUid.text;
    if (!uid.length) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZaloModKickMemberNotification" object:nil userInfo:@{@"uid":uid}];
    [self showToast:[NSString stringWithFormat:@"🚫 Đã gửi lệnh đuổi UID %@", uid]];
}

- (void)actionLeaveGroup {
    NSString *gid = self.txtGroupLinkOrId.text;
    if (!gid.length) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZaloModLeaveGroupNotification" object:nil userInfo:@{@"groupId":gid}];
    [self showToast:[NSString stringWithFormat:@"🚪 Đang rời nhóm %@", gid]];
}

- (void)showToast:(NSString *)msg {
    UILabel *toast = [[UILabel alloc] init];
    toast.text = msg;
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
    toast.font = [UIFont boldSystemFontOfSize:12.5];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.layer.cornerRadius = 14.0;
    toast.layer.borderColor = [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:0.8].CGColor;
    toast.layer.borderWidth = 1.0;
    toast.clipsToBounds = YES;

    CGSize sz = [msg sizeWithAttributes:@{NSFontAttributeName:toast.font}];
    CGFloat w = MIN(sz.width + 36, self.menuBox.bounds.size.width - 32);
    toast.frame = CGRectMake((self.menuBox.bounds.size.width - w) / 2.0, self.menuBox.bounds.size.height - 56, w, 30);
    toast.alpha = 0.0;
    [self.menuBox addSubview:toast];

    [UIView animateWithDuration:0.2 animations:^{ toast.alpha = 1.0; } completion:^(BOOL f) {
        [UIView animateWithDuration:0.25 delay:1.5 options:0 animations:^{ toast.alpha = 0.0; } completion:^(BOOL f) {
            [toast removeFromSuperview];
        }];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf {
    [tf resignFirstResponder];
    return YES;
}

- (void)showMenuFromViewController:(UIViewController *)parentVC {
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [parentVC presentViewController:self animated:YES completion:nil];
}

- (void)dismissMenu {
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(modMenuDidDismiss)]) {
            [self.delegate modMenuDidDismiss];
        }
    }];
}

@end
