#import <Cocoa/Cocoa.h>
#import <FinderSync/FinderSync.h>

static NSImage *DocumentMenuIcon(void) {
    NSImage *symbol = [NSImage imageWithSystemSymbolName:@"doc.badge.plus" accessibilityDescription:nil];
    symbol = [symbol imageWithSymbolConfiguration:
        [NSImageSymbolConfiguration configurationWithPointSize:16 weight:NSFontWeightRegular]];
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(16, 16)];
    NSAppearance *appearance = NSApp.effectiveAppearance ?: NSAppearance.currentDrawingAppearance;
    [appearance performAsCurrentDrawingAppearance:^{
        [image lockFocus];
        NSRect bounds = NSMakeRect(0, 0, 16, 16);
        [symbol drawInRect:bounds fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
        [NSColor.labelColor setFill];
        NSRectFillUsingOperation(bounds, NSCompositingOperationSourceIn);
        [image unlockFocus];
    }];
    // Finder Sync transfers a raster image and loses SF Symbol template
    // rendering. Resolve the semantic color anew each time the menu opens.
    image.template = NO;
    return image;
}

@interface BlankTXTFinder : FIFinderSync
@end

@implementation BlankTXTFinder
- (instancetype)init {
    self = [super init];
    if (self) {
        // Menu callbacks only: no directory enumeration, file reads, or badges.
        [FIFinderSyncController defaultController].directoryURLs =
            [NSSet setWithObject:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
    }
    return self;
}
- (NSMenu *)menuForMenuKind:(FIMenuKind)kind {
    // The original folder Quick Action remains available for folder icons.
    if (kind != FIMenuKindContextualMenuForContainer) return nil;
    NSURL *folder = [[FIFinderSyncController defaultController] targetedURL];
    if (!folder.isFileURL) return nil;
    NSMenu *menu = [NSMenu new];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"빈 TXT 만들기"
                                                action:@selector(createBlankTXT:) keyEquivalent:@""];
    item.target = self;
    item.image = DocumentMenuIcon();
    [menu addItem:item];
    return menu;
}
- (void)createBlankTXT:(NSMenuItem *)item {
    NSURL *folder = [[FIFinderSyncController defaultController] targetedURL];
    if (!folder.isFileURL) return;
    NSURLComponents *command = [NSURLComponents new];
    command.scheme = @"codex-blanktxt";
    command.host = @"create";
    command.queryItems = @[[NSURLQueryItem queryItemWithName:@"directory" value:folder.absoluteString]];
    // Address this extension's containing app explicitly, so an old build or
    // another URL-handler registration can never receive the command.
    NSURL *host = [NSBundle bundleForClass:self.class].bundleURL;
    for (NSUInteger level = 0; level < 3; level++) host = host.URLByDeletingLastPathComponent;
    NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
    configuration.activates = NO;
    [[NSWorkspace sharedWorkspace] openURLs:@[command.URL]
                      withApplicationAtURL:host
                             configuration:configuration
                         completionHandler:^(NSRunningApplication *application, NSError *error) {
        if (error) NSLog(@"BlankTXT could not open its file creation helper: %@", error);
    }];
}
@end
