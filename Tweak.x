#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "../YTVideoOverlay/Header.h"
#import "../YTVideoOverlay/Init.x"
#import "../YouTubeHeader/YTColor.h"
#import "../YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h"
#import "../YouTubeHeader/YTMainAppControlsOverlayView.h"
#import "../YouTubeHeader/MLFormat.h"
#import "../YouTubeHeader/YTIFormatStream.h"
#import "../YouTubeHeader/YTIShareVideoEndpoint.h"

#define TweakKey @"YouTimeStamp"

@interface YTMainAppControlsOverlayView (YouTimeStamp)
@property (retain, nonatomic) YTQTMButton *timestampButton;
@property (nonatomic, strong) YTLabel *currentTimeLabel;
@property (nonatomic, copy) NSString *videoShareURL;
@property (nonatomic, assign) YTPlayerViewController *playerViewController;
- (AVPlayer *)getPlayer;
- (void)didPressYouTimeStamp:(id)arg;
- (void)shareURLWithTimestamp:(NSString *)timestamp;
- (void)copyURLToClipboard:(NSString *)modifiedURL;
- (void)copyModifiedURLToClipboard:(NSString *)originalURL withTimeFromAVPlayer:(AVPlayer *)player;
- (NSString *)getCurrentTimeFromAVPlayer:(AVPlayer *)player;
@end

@interface YTInlinePlayerBarContainerView (YouTimeStamp)
@property (retain, nonatomic) YTQTMButton *timestampButton;
@property (nonatomic, strong) YTLabel *currentTimeLabel;
@property (nonatomic, copy) NSString *videoShareURL;
@property (nonatomic, assign) YTPlayerViewController *playerViewController;
- (AVPlayer *)getPlayer;
- (void)didPressYouTimeStamp:(id)arg;
- (void)shareURLWithTimestamp:(NSString *)timestamp;
- (void)copyURLToClipboard:(NSString *)modifiedURL;
- (void)copyModifiedURLToClipboard:(NSString *)originalURL withTimeFromAVPlayer:(AVPlayer *)player;
- (NSString *)getCurrentTimeFromAVPlayer:(AVPlayer *)player;
@end

@interface YTMainAppVideoPlayerOverlayViewController (YouTimeStamp)
@property (nonatomic, copy) NSString *videoID;
- (NSString *)generateModifiedURLWithTimestamp:(NSString *)timestamp;
@end

@interface YTPlayerViewController (YouTimeStamp)
@property (nonatomic, assign) CGFloat currentVideoMediaTime;
@property (nonatomic, assign) NSString *currentVideoID;
@end

// For displaying snackbars - @theRealfoxster
@interface YTHUDMessage : NSObject
+ (id)messageWithText:(id)text;
- (void)setAction:(id)action;
@end

@interface GOOHUDMessageAction : NSObject
- (void)setTitle:(NSString *)title;
- (void)setHandler:(void (^)(id))handler;
@end

@interface GOOHUDManagerInternal : NSObject
- (void)showMessageMainThread:(id)message;
+ (id)sharedInstance;
@end
//

NSBundle *YouTimeStampBundle() {
    NSLog(@"bhackel - YouTimeStampBundle called");
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:TweakKey ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:ROOT_PATH_NS(@"/Library/Application Support/%@.bundle"), TweakKey]];
    });
    return bundle;
}

static UIImage *timestampImage(NSString *qualityLabel) {
    return [%c(QTMIcon) tintImage:[UIImage imageNamed:[NSString stringWithFormat:@"Timestamp@%@", qualityLabel] inBundle: YouTimeStampBundle() compatibleWithTraitCollection:nil] color:[%c(YTColor) white1]];
}

%group Top

%hook YTMainAppControlsOverlayView

%property (retain, nonatomic) YTQTMButton *timestampButton;

- (id)initWithDelegate:(id)delegate {
    NSLog(@"bhackel - initWithDelegate: called");
    self = %orig;
    self.timestampButton = [self createButton:TweakKey accessibilityLabel:@"Copy Timestamp" selector:@selector(didPressYouTimeStamp:)];
    return self;
}

- (id)initWithDelegate:(id)delegate autoplaySwitchEnabled:(BOOL)autoplaySwitchEnabled {
    NSLog(@"bhackel - initWithDelegate:autoplaySwitchEnabled: called");
    self = %orig;
    self.timestampButton = [self createButton:TweakKey accessibilityLabel:@"Copy Timestamp" selector:@selector(didPressYouTimeStamp:)];
    return self;
}

- (YTQTMButton *)button:(NSString *)tweakId {
    NSLog(@"bhackel - button: called");
    return [tweakId isEqualToString:TweakKey] ? self.timestampButton : %orig;
}

- (UIImage *)buttonImage:(NSString *)tweakId {
    NSLog(@"bhackel - buttonImage: called");
    return [tweakId isEqualToString:TweakKey] ? timestampImage(@"3") : %orig;
}

- (void)didPressYouTimeStamp {
    NSLog(@"bhackel - Button Pressed");
    YTPlayerViewController *playerViewController = [self playerViewController];
    if (playerViewController) {
        NSLog(@"bhackel - Player View Controller Found");
        // Get the current time of the video
        CGFloat currentTime = playerViewController.currentVideoMediaTime;
        NSInteger timeInterval = (NSInteger)currentTime;

        NSLog(@"bhackel - Current Time: %f", currentTime);

        // Create a link using the video ID and the timestamp
        if (playerViewController.currentVideoID) {
            NSLog(@"bhackel - Video ID Found");
            NSString *videoId = [NSString stringWithFormat:@"https://youtu.be/%@", playerViewController.currentVideoID];
            NSLog(@"bhackel - Video ID: %@", videoId);
            NSString *timestampString = [NSString stringWithFormat:@"?t=%.0ld", (long)timeInterval];
            NSLog(@"bhackel - Timestamp String: %@", timestampString);
            NSString *modifiedURL = [videoId stringByAppendingString:timestampString];
            NSLog(@"bhackel - Modified URL: %@", modifiedURL);

            // Copy the link to clipboard
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            [pasteboard setString:modifiedURL];
            NSLog(@"bhackel - URL Copied to Clipboard");
            // Show a snackbar to inform the user
            [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:@"URL copied to clipboard"]];

        } else {
            NSLog(@"No video ID available");
        }
    } else {
        NSLog(@"View controller not found");
    }
}

%end

// %hook YTMainAppVideoPlayerOverlayViewController

// - (NSString *)generateModifiedURLWithTimestamp:(NSString *)timestamp {
//     NSString *videoId = [NSString stringWithFormat:@"http://youtu.be/%@", self.videoID];
//     NSString *timestampString = [NSString stringWithFormat:@"&t=%@", timestamp];
//     return [videoId stringByAppendingString:timestampString];
// }

// %end

%end

// %group Bottom

// %hook YTInlinePlayerBarContainerView

// %property (retain, nonatomic) YTQTMButton *timestampButton;

// - (id)init {
//     self = %orig;
//     self.timestampButton = [self createButton:TweakKey accessibilityLabel:@"Copy Timestamp" selector:@selector(didPressYouTimeStamp:)];
//     return self;
// }

// - (YTQTMButton *)button:(NSString *)tweakId {
//     return [tweakId isEqualToString:TweakKey] ? self.timestampButton : %orig;
// }

// - (UIImage *)buttonImage:(NSString *)tweakId {
//     return [tweakId isEqualToString:TweakKey] ? timestampImage(@"3") : %orig;
// }

// %new(v@:@)
// - (void)didPressYouTimeStamp {
//     YTPlayerViewController *playerViewController = [self playerViewController];
//     if (playerViewController) {
//         // Get the current time of the video
//         CGFloat currentTime = playerViewController.currentVideoMediaTime;
//         NSInteger timeInterval = (NSInteger)currentTime;

//         // Create a link using the video ID and the timestamp
//         if (playerViewController.currentVideoID) {
//             NSString *videoId = [NSString stringWithFormat:@"https://youtu.be/%@", playerViewController.currentVideoID];
//             NSString *timestampString = [NSString stringWithFormat:@"?t=%.0ld", (long)timeInterval];
//             NSString *modifiedURL = [videoId stringByAppendingString:timestampString];

//             // Copy the link to clipboard
//             UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
//             [pasteboard setString:modifiedURL];
//             // Show a snackbar to inform the user
//             [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:@"URL copied to clipboard"]];

//         } else {
//             NSLog(@"No video ID available");
//         }
//     } else {
//         NSLog(@"View controller not found");
//     }
// }

// - (void)copyURLToClipboard:(NSString *)modifiedURL {
//     UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
//     [pasteboard setString:modifiedURL];
// }

// %end

// %hook YTMainAppVideoPlayerOverlayViewController

// - (NSString *)generateModifiedURLWithTimestamp:(NSString *)timestamp {
//     NSString *videoId = [NSString stringWithFormat:@"http://youtu.be/%@", self.videoID];
//     NSString *timestampString = [NSString stringWithFormat:@"&t=%@", timestamp];
//     return [videoId stringByAppendingString:timestampString];
// }

// %end

// %end

%ctor {
    initYTVideoOverlay(TweakKey);
    %init(Top);
    // %init(Bottom);
}
