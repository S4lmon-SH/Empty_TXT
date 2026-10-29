#import <Cocoa/Cocoa.h>
#import <FinderSync/FinderSync.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

static BOOL EnableFinderExtension(NSError **error) {
    NSURL *extension = [[NSBundle mainBundle].bundleURL
        URLByAppendingPathComponent:@"Contents/PlugIns/BlankTXTFinder.appex"];
    NSArray<NSArray<NSString *> *> *commands = @[
        @[@"-a", extension.path],
        @[@"-e", @"use", @"-i", @"local.codex.blanktxt.finder"]
    ];
    for (NSArray<NSString *> *arguments in commands) {
        NSTask *task = [NSTask new];
        task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/pluginkit"];
        task.arguments = arguments;
        if (![task launchAndReturnError:error]) return NO;
        [task waitUntilExit];
        if (task.terminationStatus != 0) {
            if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EIO userInfo:nil];
            return NO;
        }
    }
    return YES;
}

static NSURL *CreateBlankTXT(NSURL *folder, NSError **error) {
    if (!folder.isFileURL || (folder.host.length && ![folder.host isEqualToString:@"localhost"])) {
        if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:nil];
        return nil;
    }
    int directory = open(folder.fileSystemRepresentation, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (directory < 0) {
        if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        return nil;
    }
    for (NSUInteger number = 1; number < 1000000; number++) {
        NSString *name = number == 1 ? @"새 텍스트 파일.txt" :
            [NSString stringWithFormat:@"새 텍스트 파일 %lu.txt", (unsigned long)number];
        int file = openat(directory, name.fileSystemRepresentation,
                          O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0666);
        if (file >= 0) {
            close(file);
            close(directory);
            return [folder URLByAppendingPathComponent:name isDirectory:NO];
        }
        int reason = errno;
        if (reason != EEXIST) {
            close(directory);
            if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:reason userInfo:nil];
            return nil;
        }
    }
    close(directory);
    if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EEXIST userInfo:nil];
    return nil;
}

@interface BlankTXTDelegate : NSObject <NSApplicationDelegate>
@property BOOL receivedURL;
@end

@implementation BlankTXTDelegate
- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
    self.receivedURL = YES;
    for (NSURL *url in urls) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        if (![components.scheme isEqualToString:@"codex-blanktxt"] ||
            ![components.host isEqualToString:@"create"]) continue;
        NSString *folderURL = nil;
        for (NSURLQueryItem *item in components.queryItems) {
            if ([item.name isEqualToString:@"directory"]) folderURL = item.value;
        }
        NSError *error = nil;
        NSURL *created = CreateBlankTXT([NSURL URLWithString:folderURL ?: @""], &error);
        if (created) {
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[created]];
        } else {
            [NSApp activateIgnoringOtherApps:YES];
            NSAlert *alert = [NSAlert new];
            alert.messageText = @"빈 TXT 파일을 만들 수 없습니다";
            alert.informativeText = error.localizedDescription ?: @"폴더의 쓰기 권한을 확인해 주세요.";
            [alert runModal];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{ [NSApp terminate:nil]; });
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 300 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if (self.receivedURL) return;
        NSError *registrationError = nil;
        BOOL enabled = EnableFinderExtension(&registrationError);
        [NSApp activateIgnoringOtherApps:YES];
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"빈 TXT 만들기";
        alert.informativeText = enabled
            ? @"Finder 메뉴를 활성화했습니다.\n\n폴더 안의 빈 공간을 우클릭한 다음 ‘빈 TXT 만들기’를 선택하세요."
            : @"Finder 메뉴를 활성화하지 못했습니다.\n\nFinder 확장 설정에서 ‘빈 TXT 만들기’를 켜 주세요.";
        [alert addButtonWithTitle:@"확인"];
        [alert addButtonWithTitle:@"Finder 확장 설정"];
        if ([alert runModal] == NSAlertSecondButtonReturn)
            [FIFinderSyncController showExtensionManagementInterface];
        [NSApp terminate:nil];
    });
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc == 2 && strcmp(argv[1], "--enable") == 0) {
            NSError *error = nil;
            if (EnableFinderExtension(&error)) return 0;
            fprintf(stderr, "%s\n", error.localizedDescription.UTF8String);
            return 1;
        }
        if (argc == 3 && strcmp(argv[1], "--create-in") == 0) {
            NSError *error = nil;
            NSURL *file = CreateBlankTXT([NSURL fileURLWithPath:@(argv[2]) isDirectory:YES], &error);
            if (!file) { fprintf(stderr, "%s\n", error.localizedDescription.UTF8String); return 1; }
            printf("%s\n", file.path.fileSystemRepresentation);
            return 0;
        }
        NSApplication *application = [NSApplication sharedApplication];
        BlankTXTDelegate *delegate = [BlankTXTDelegate new];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
