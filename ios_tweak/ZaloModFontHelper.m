//
//  ZaloModFontHelper.m
//  ZaloMod VIP - Bộ chuyển đổi 15 Font chữ nghệ thuật & Chữ To & Màu sắc
//  Thương hiệu: DucLamXNgBao
//

#import "ZaloModFontHelper.h"

@implementation ZaloModFontHelper

+ (unichar)normalizeVietnameseChar:(unichar)c {
    switch (c) {
        case 0x00E0: case 0x00E1: case 0x1EA3: case 0x00E3: case 0x1EA1:
        case 0x0103: case 0x1EB1: case 0x1EAF: case 0x1EB3: case 0x1EB5: case 0x1EB7:
        case 0x00E2: case 0x1EA7: case 0x1EA5: case 0x1EA9: case 0x1EAB: case 0x1EAD:
            return 'a';
        case 0x00C0: case 0x00C1: case 0x1EA2: case 0x00C3: case 0x1EA0:
        case 0x0102: case 0x1EB0: case 0x1EAE: case 0x1EB2: case 0x1EB4: case 0x1EB6:
        case 0x00C2: case 0x1EA6: case 0x1EA4: case 0x1EA8: case 0x1EAA: case 0x1EAC:
            return 'A';
        case 0x0111: return 'd';
        case 0x0110: return 'D';
        case 0x00E8: case 0x00E9: case 0x1EBA: case 0x1EB8: case 0x1EBD:
        case 0x00EA: case 0x1EC1: case 0x1EBF: case 0x1EC3: case 0x1EC5: case 0x1EC7:
            return 'e';
        case 0x00C8: case 0x00C9: case 0x1EB9: case 0x1EBB: case 0x1EBC:
        case 0x00CA: case 0x1EC0: case 0x1EBE: case 0x1EC2: case 0x1EC4: case 0x1EC6:
            return 'E';
        case 0x00EC: case 0x00ED: case 0x1EC9: case 0x0129: case 0x1ECB:
            return 'i';
        case 0x00CC: case 0x00CD: case 0x1EC8: case 0x0128: case 0x1ECA:
            return 'I';
        case 0x00F2: case 0x00F3: case 0x1ECF: case 0x00F5: case 0x1ECD:
        case 0x00F4: case 0x1ED3: case 0x1ED1: case 0x1ED5: case 0x1ED7: case 0x1ED9:
        case 0x01A1: case 0x1EDB: case 0x1EDD: case 0x1EDF: case 0x1EE1: case 0x1EE3:
            return 'o';
        case 0x00D2: case 0x00D3: case 0x1ECE: case 0x00D5: case 0x1ECC:
        case 0x00D4: case 0x1ED2: case 0x1ED0: case 0x1ED4: case 0x1ED6: case 0x1ED8:
        case 0x01A0: case 0x1EDA: case 0x1EDC: case 0x1EDE: case 0x1EE0: case 0x1EE2:
            return 'O';
        case 0x00F9: case 0x00FA: case 0x1EE7: case 0x0169: case 0x1EE5:
        case 0x01B0: case 0x1EEB: case 0x1EED: case 0x1EEF: case 0x1EF1:
            return 'u';
        case 0x00D9: case 0x00DA: case 0x1EE6: case 0x0168: case 0x1EE4:
        case 0x01AF: case 0x1EEA: case 0x1EEC: case 0x1EEE: case 0x1EF0:
            return 'U';
        case 0x1EF3: case 0x00FD: case 0x1EF7: case 0x1EF9: case 0x1EF5:
            return 'y';
        case 0x1EF2: case 0x00DD: case 0x1EF6: case 0x1EF8: case 0x1EF4:
            return 'Y';
        default:
            return c;
    }
}

// Chuyển đổi ký tự đã bị định dạng trước đó về lại ký tự ASCII thường (tránh double encode / hỏng chuỗi)
+ (NSString *)stripStyleFromChar:(NSString *)ch {
    if (!ch || ch.length == 0) return @"";
    if (ch.length == 1) {
        unichar c = [ch characterAtIndex:0];
        // Khoanh tròn Ⓐ..Ⓩ (0x24B6..0x24CF), ⓐ..ⓩ (0x24D0..0x24E9), ⓪..⑨ (0x24EA, 0x2460..0x2468)
        if (c >= 0x24B6 && c <= 0x24CF) return [NSString stringWithFormat:@"%c", (char)('A' + (c - 0x24B6))];
        if (c >= 0x24D0 && c <= 0x24E9) return [NSString stringWithFormat:@"%c", (char)('a' + (c - 0x24D0))];
        if (c >= 0x2460 && c <= 0x2468) return [NSString stringWithFormat:@"%c", (char)('1' + (c - 0x2460))];
        if (c == 0x24EA) return @"0";
        // Fullwidth Pixel 0xFF21..0xFF3A, 0xFF41..0xFF5A
        if (c >= 0xFF21 && c <= 0xFF3A) return [NSString stringWithFormat:@"%c", (char)('A' + (c - 0xFF21))];
        if (c >= 0xFF41 && c <= 0xFF5A) return [NSString stringWithFormat:@"%c", (char)('a' + (c - 0xFF41))];
        if (c >= 0xFF10 && c <= 0xFF19) return [NSString stringWithFormat:@"%c", (char)('0' + (c - 0xFF10))];
        return ch;
    }
    if (ch.length == 2) {
        unichar lead = [ch characterAtIndex:0];
        unichar trail = [ch characterAtIndex:1];
        if (lead >= 0xD800 && lead <= 0xDBFF && trail >= 0xDC00 && trail <= 0xDFFF) {
            uint32_t cp = 0x10000 + ((lead - 0xD800) << 10) + (trail - 0xDC00);
            // Math Bold Sans (Chữ To): 0x1D5D4..0x1D607
            if (cp >= 0x1D5D4 && cp <= 0x1D5ED) return [NSString stringWithFormat:@"%c", (char)('A' + (cp - 0x1D5D4))];
            if (cp >= 0x1D5EE && cp <= 0x1D607) return [NSString stringWithFormat:@"%c", (char)('a' + (cp - 0x1D5EE))];
            // Math Bold Numbers: 0x1D7EC..0x1D7F5
            if (cp >= 0x1D7EC && cp <= 0x1D7F5) return [NSString stringWithFormat:@"%c", (char)('0' + (cp - 0x1D7EC))];
            // Negative Squared Latin (Chữ Đỏ): 0x1F170..0x1F189
            if (cp >= 0x1F170 && cp <= 0x1F189) return [NSString stringWithFormat:@"%c", (char)('A' + (cp - 0x1F170))];
            // Regional Indicators (Chữ Xanh): 0x1F1E6..0x1F1FF
            if (cp >= 0x1F1E6 && cp <= 0x1F1FF) return [NSString stringWithFormat:@"%c", (char)('A' + (cp - 0x1F1E6))];
            // Negative Circled (Khối Đen): 0x1F150..0x1F169
            if (cp >= 0x1F150 && cp <= 0x1F169) return [NSString stringWithFormat:@"%c", (char)('A' + (cp - 0x1F150))];
            // Monospace: 0x1D670..0x1D6A3
            if (cp >= 0x1D670 && cp <= 0x1D689) return [NSString stringWithFormat:@"%c", (char)('A' + (cp - 0x1D670))];
            if (cp >= 0x1D68A && cp <= 0x1D6A3) return [NSString stringWithFormat:@"%c", (char)('a' + (cp - 0x1D68A))];
            // Bold Serif (Retro): 0x1D400..0x1D433
            if (cp >= 0x1D400 && cp <= 0x1D419) return [NSString stringWithFormat:@"%c", (char)('A' + (cp - 0x1D400))];
            if (cp >= 0x1D41A && cp <= 0x1D433) return [NSString stringWithFormat:@"%c", (char)('a' + (cp - 0x1D41A))];
        }
    }
    return ch;
}

+ (NSString *)convertText:(NSString *)text toStyle:(NSString *)style {
    if (!text || text.length == 0) return text;
    if (!style || style.length == 0) return text;

    NSString *lowerStyle = [style lowercaseString];
    if ([lowerStyle isEqualToString:@"tắt"] || [lowerStyle isEqualToString:@"tat"] ||
        [lowerStyle isEqualToString:@"off"] || [lowerStyle isEqualToString:@"none"] ||
        [lowerStyle isEqualToString:@"0"] || [lowerStyle isEqualToString:@"mặc định"] ||
        [lowerStyle isEqualToString:@"default"]) {
        return text;
    }

    NSArray *allStyles = @[
        @"Chữ To", @"Chữ Đỏ", @"Chữ Xanh", @"Khối Đen", @"Khoanh Tròn",
        @"Pixel", @"Vintage", @"Florence", @"Notes", @"Elegant",
        @"Amatic", @"Terminal", @"Retro", @"Young", @"School"
    ];

    BOOL isRandom = [style isEqualToString:@"Random"] || [style isEqualToString:@"Random Màu Font"];

    NSMutableString *result = [NSMutableString stringWithCapacity:text.length * 2];

    // Sử dụng NSStringEnumerationByComposedCharacterSequences đảm bảo KHÔNG BAO GIỜ bị cắt đứt surrogate pair
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        if (!substring || substring.length == 0) return;

        // Đầu tiên giải mã nếu ký tự đã bị biến đổi trước đó
        NSString *baseCh = [self stripStyleFromChar:substring];

        NSString *targetStyle = isRandom ? allStyles[arc4random_uniform((uint32_t)allStyles.count)] : style;
        NSString *styledCh = [self convertSingleChar:baseCh inStyle:targetStyle];
        [result appendString:(styledCh ?: baseCh)];
    }];

    return result.length > 0 ? result : text;
}

+ (NSString *)convertSingleChar:(NSString *)ch inStyle:(NSString *)style {
    if (!ch || ch.length == 0) return ch;
    if (ch.length != 1) return ch; // Chỉ xử lý đơn ký tự ASCII cơ bản

    unichar rawC = [ch characterAtIndex:0];
    unichar c = [self normalizeVietnameseChar:rawC];

    // Chữ To (Bold Sans-Serif Capitals)
    if ([style isEqualToString:@"Chữ To"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D5D4 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D5D4 + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7EC + (c - '0')];
        if (c == ' ') return @" ";
        return ch;
    }

    // Chữ Đỏ (Negative Squared Latin - Hộp Đỏ Nổi Bật)
    if ([style isEqualToString:@"Chữ Đỏ"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1F170 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1F170 + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7EC + (c - '0')];
        if (c == ' ') return @" ";
        return ch;
    }

    // Chữ Xanh (Regional Indicator Symbol - Khối Xanh Lam)
    if ([style isEqualToString:@"Chữ Xanh"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1F1E6 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1F1E6 + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7EC + (c - '0')];
        if (c == ' ') return @" ";
        return ch;
    }

    // Khối Đen (Negative Circled Latin - Nút Tròn Đen)
    if ([style isEqualToString:@"Khối Đen"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1F150 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1F150 + (c - 'a')];
        if (c >= '1' && c <= '9') return [NSString stringWithFormat:@"%C", (unichar)(0x2776 + (c - '1'))];
        if (c == '0') return @"⓿";
        if (c == ' ') return @" ";
        return ch;
    }

    // Khoanh Tròn (Circled Latin)
    if ([style isEqualToString:@"Khoanh Tròn"]) {
        if (c >= 'A' && c <= 'Z') return [NSString stringWithFormat:@"%C", (unichar)(0x24B6 + (c - 'A'))];
        if (c >= 'a' && c <= 'z') return [NSString stringWithFormat:@"%C", (unichar)(0x24D0 + (c - 'a'))];
        if (c >= '1' && c <= '9') return [NSString stringWithFormat:@"%C", (unichar)(0x2460 + (c - '1'))];
        if (c == '0') return @"⓪";
        if (c == ' ') return @" ";
        return ch;
    }

    // Pixel (Fullwidth)
    if ([style isEqualToString:@"Pixel"]) {
        if (c >= 'A' && c <= 'Z') return [NSString stringWithFormat:@"%C", (unichar)(0xFF21 + (c - 'A'))];
        if (c >= 'a' && c <= 'z') return [NSString stringWithFormat:@"%C", (unichar)(0xFF41 + (c - 'a'))];
        if (c >= '0' && c <= '9') return [NSString stringWithFormat:@"%C", (unichar)(0xFF10 + (c - '0'))];
        if (c == ' ') return @"　";
        return ch;
    }

    // Young (Small Caps)
    if ([style isEqualToString:@"Young"]) {
        static NSDictionary *smallCaps = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            smallCaps = @{
                @"a":@"ᴀ", @"b":@"ʙ", @"c":@"ᴄ", @"d":@"ᴅ", @"e":@"ᴇ", @"f":@"ғ",
                @"g":@"ɢ", @"h":@"ʜ", @"i":@"ɪ", @"j":@"ᴊ", @"k":@"ᴋ", @"l":@"ʟ",
                @"m":@"ᴍ", @"n":@"ɴ", @"o":@"ᴏ", @"p":@"ᴘ", @"q":@"ǫ", @"r":@"ʀ",
                @"s":@"s", @"t":@"ᴛ", @"u":@"ᴜ", @"v":@"ᴠ", @"w":@"ᴡ", @"x":@"x",
                @"y":@"ʏ", @"z":@"ᴢ"
            };
        });
        NSString *low = [[NSString stringWithCharacters:&c length:1] lowercaseString];
        return smallCaps[low] ?: ch;
    }

    // Terminal (Monospace)
    if ([style isEqualToString:@"Terminal"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D670 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D68A + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7F6 + (c - '0')];
        return ch;
    }

    // Retro (Bold Serif)
    if ([style isEqualToString:@"Retro"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D400 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D41A + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7CE + (c - '0')];
        return ch;
    }

    // School (Bold Sans-Serif)
    if ([style isEqualToString:@"School"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D5D4 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D5EE + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7EC + (c - '0')];
        return ch;
    }

    // Amatic (Sans-Serif Italic)
    if ([style isEqualToString:@"Amatic"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D608 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D622 + (c - 'a')];
        return ch;
    }

    // Notes (Double-Struck)
    if ([style isEqualToString:@"Notes"]) {
        if (c == 'C') return @"ℂ";
        if (c == 'H') return @"ℍ";
        if (c == 'N') return @"ℕ";
        if (c == 'P') return @"ℙ";
        if (c == 'Q') return @"ℚ";
        if (c == 'R') return @"ℝ";
        if (c == 'Z') return @"ℤ";
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D538 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D552 + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7D8 + (c - '0')];
        return ch;
    }

    // Florence (Bold Fraktur)
    if ([style isEqualToString:@"Florence"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D56C + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D586 + (c - 'a')];
        return ch;
    }

    // Vintage (Fraktur)
    if ([style isEqualToString:@"Vintage"]) {
        if (c == 'C') return @"ℭ";
        if (c == 'H') return @"ℌ";
        if (c == 'I') return @"ℑ";
        if (c == 'R') return @"ℜ";
        if (c == 'Z') return @"ℨ";
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D504 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D51E + (c - 'a')];
        return ch;
    }

    // Elegant (Script / Cursive)
    if ([style isEqualToString:@"Elegant"]) {
        if (c == 'B') return @"ℬ";
        if (c == 'E') return @"ℰ";
        if (c == 'F') return @"ℱ";
        if (c == 'H') return @"ℋ";
        if (c == 'I') return @"ℐ";
        if (c == 'L') return @"ℒ";
        if (c == 'M') return @"ℳ";
        if (c == 'R') return @"ℛ";
        if (c == 'e') return @"ℯ";
        if (c == 'g') return @"ℊ";
        if (c == 'o') return @"ℴ";
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D49C + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D4B6 + (c - 'a')];
        return ch;
    }

    return ch;
}

+ (NSString *)surrogatePairForCodePoint:(uint32_t)codePoint {
    if (codePoint < 0x10000) {
        return [NSString stringWithFormat:@"%C", (unichar)codePoint];
    }
    uint32_t val = codePoint - 0x10000;
    unichar lead = (unichar)((val >> 10) + 0xD800);
    unichar trail = (unichar)((val & 0x3FF) + 0xDC00);
    unichar pair[2] = { lead, trail };
    return [NSString stringWithCharacters:pair length:2];
}

@end
