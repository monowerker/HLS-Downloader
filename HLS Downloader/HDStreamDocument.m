//
//  HDStreamDocument.m
//  HLS Downloader
//
//  Copyright (c) 2013 Daniel Ericsson.
//  Distributed under the terms of 'The MIT License', http://opensource.org/licenses/mit-license.html
//

#import "HDStreamDocument.h"
// Models
#import "M3UPlaylist.h"
#import "M3UPlaylistItem.h"
// Controllers
#import "HDSegmentsDownloader.h"
// Utils
#import <MWBase/MWBase.h>
#import <MWFoundation/MWFoundation.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@interface HDStreamDocument ()

@property (nonatomic, readwrite, strong) M3UPlaylist                    *indexPlaylist;
@property (nonatomic, readwrite, strong) NSOperationQueue               *opQueue;
@property (nonatomic, readwrite, strong) HDSegmentsDownloader           *downloader;
@property (nonatomic, readwrite,   weak) IBOutlet NSTableView           *tableView;

@property (nonatomic, readwrite, assign) IBOutlet NSWindow              *openURLSheet;
@property (nonatomic, readwrite,   weak) IBOutlet NSProgressIndicator   *sheetSpinner;
@property (nonatomic, readwrite,   weak) IBOutlet NSTextField           *sheetURLField;
@property (nonatomic, readwrite, assign) IBOutlet NSWindow              *progressSheet;
@property (nonatomic, readwrite,   weak) IBOutlet NSProgressIndicator   *progressBar;
@property (nonatomic, readwrite,   weak) IBOutlet NSTextField           *progressUpdateTextField;

@property (nonatomic, readwrite, assign) IBOutlet NSWindow              *completedSheet;
@property (nonatomic, readwrite,   weak) IBOutlet NSTextField           *completedTextField;

@property (nonatomic, readwrite, assign) BOOL createNewDocOnActivate;

@end

@implementation HDStreamDocument


#pragma mark - Lifecycle

- (void)awakeFromNib {
    self.createNewDocOnActivate = YES;
    self.downloader = [[HDSegmentsDownloader alloc] init];
    self.opQueue = [[NSOperationQueue alloc] init];
    
    [self updateProgressWith:0. ofMax:0.];
}

- (NSString *)windowNibName {
    return @"HDStreamDocument";
}


#pragma mark - Accessors

- (void)setIndexPlaylist:(M3UPlaylist *)indexPlaylist {
    if (_indexPlaylist) {
        [_indexPlaylist removeAllObservers];
    }
    _indexPlaylist = indexPlaylist;

    __weak HDStreamDocument *weakSelf = self;
    [self.indexPlaylist addObserver:self keyPath:@"playListItems" options:NSKeyValueObservingOptionNew block:
     ^(MAKVONotification *notification) {
         HDStreamDocument *strongSelf = weakSelf;
         dispatch_async(dispatch_get_main_queue(), ^{
             [strongSelf.windowForSheet setTitle:[strongSelf.indexPlaylist.URL absoluteString]];
             [strongSelf.tableView reloadData];
             if (strongSelf.openURLSheet) {
                 [NSApp endSheet:strongSelf.openURLSheet];
                 [strongSelf.openURLSheet close];
             }
         });
     }];
}


#pragma mark - Actions

- (IBAction)fetch:(id)sender {
    NSString    *URLString = [self.sheetURLField.stringValue stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL       *URL       = [NSURL URLWithString:URLString];

    // -- Check that the scheme is valid
    if ([[URL scheme] isEqualToString:@"http"] || [[URL scheme] isEqualToString:@"https"]) {
        [self.sheetSpinner startAnimation:self];
        self.indexPlaylist = [M3UPlaylist playListFromURL:URL];
    }
}

- (IBAction)download:(id)sender {
    M3UPlaylistItem *selectedItem = [self.indexPlaylist.playListItems objectAtIndex:[self.tableView selectedRow]];

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.prompt = NSLS(@"Download", @"Download");
    savePanel.canCreateDirectories  = YES;
    savePanel.allowedFileTypes = @[ @"ts" ];
    savePanel.allowsOtherFileTypes = NO;

    [savePanel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result) {
        switch (result) {
            case NSFileHandlingPanelOKButton: {
                // -- Take us through the runloop one more time before popping the new sheet and kicking off download.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSApp beginSheet:self.progressSheet
                       modalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
                    NSInvocation *downloadInvocation = [self downloadInvocationForItem:selectedItem toURL:savePanel.URL];
                    NSInvocationOperation *downloadOp = [[NSInvocationOperation alloc] initWithInvocation:downloadInvocation];
                    [self.opQueue addOperation:downloadOp];
                });
                break;
            } case NSFileHandlingPanelCancelButton: {
                break;
            } default: {
                break;
            }
        }
    }];
}

- (IBAction)cancelFetch:(id)sender {
    [NSApp endSheet:self.openURLSheet];
    [self.openURLSheet close];
}

- (IBAction)cancelDownload:(id)sender {
    [self.downloader stop];
    [NSApp endSheet:self.progressSheet];
    [self.progressSheet close];
}

- (IBAction)okCompleted:(id)sender {
    [self.downloader stop];
    [NSApp endSheet:self.completedSheet];
    [self.completedSheet close];
}

- (IBAction)showCompletedInFinder:(id)sender {
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[self.downloader.targetURL]];
    [NSApp endSheet:self.completedSheet];
    [self.completedSheet close];
}

- (IBAction)openLocation:(id)sender {
    [NSApp beginSheet:self.openURLSheet
       modalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

#pragma mark - Private methods

- (void)updateProgressWith:(double)progress ofMax:(double)maxValue {
    if (maxValue == 0. && progress == 0.) {
        [self.progressBar setIndeterminate:YES];
        self.progressUpdateTextField.stringValue = @"Starting download...";
        [self.progressBar startAnimation:self];
    } else {
        if (progress == self.progressBar.maxValue) {
            // -- Download finished, remove progressSheet and pop completedSheet.
            NSString *fileName = [self.downloader.targetURL lastPathComponent];
            self.completedTextField.stringValue = [NSString stringWithFormat:@"Download of %@ complete.", fileName];
            [NSApp endSheet:self.progressSheet];
            [self.progressSheet close];
            [NSApp beginSheet:self.completedSheet
               modalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];

            return;
        }

        [self.progressBar setIndeterminate:NO];
        self.progressBar.maxValue = maxValue;
        self.progressBar.doubleValue = progress+1;
        self.progressUpdateTextField.stringValue =
        [NSString stringWithFormat:@"Downloading segment %0.f of %0.f...", progress+1, self.progressBar.maxValue];
    }
}

- (void)downloadSegmentsForItem:(M3UPlaylistItem *)item toURL:(NSURL *)fileURL {
    NSMutableArray *segmentURLs = [[NSMutableArray alloc] init];

    __weak M3UPlaylistItem *weakItem = item;
    __weak HDStreamDocument *weakSelf = self;
    [item.segmentPlaylist addObserver:self keyPath:@"playListItems" options:NSKeyValueObservingOptionNew block:
     ^(MAKVONotification *notification) {
         M3UPlaylistItem *strongItem = weakItem;
         HDStreamDocument *strongSelf = weakSelf;
         for (M3UPlaylistItem *playListItem in strongItem.segmentPlaylist.playListItems) {
             [segmentURLs addObject:playListItem.URL];
         }

         strongSelf.downloader.targetURL = fileURL;
         strongSelf.downloader.segmentURLs = segmentURLs;

         [strongSelf.downloader.downloadQueue addObserver:self keyPath:@"operationCount" options:NSKeyValueObservingOptionNew block:
          ^(MAKVONotification *notification) {
              double newValue = [[notification newValue] doubleValue];
              double progress = self.downloader.segmentURLs.count - newValue;
              
              [self updateProgressWith:progress ofMax:self.downloader.segmentURLs.count];
         }];
         
         [strongSelf.downloader start];
     }];
}

- (NSInvocation *)downloadInvocationForItem:(M3UPlaylistItem *)item toURL:(NSURL *)fileURL {
    SEL downloadSelector = @selector(downloadSegmentsForItem:toURL:);
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:downloadSelector];
    NSInvocation *downloadInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];

    [downloadInvocation setTarget:self];
    [downloadInvocation setSelector:downloadSelector];
    [downloadInvocation setArgument:&item atIndex:2];
    [downloadInvocation setArgument:&fileURL atIndex:3];

    return downloadInvocation;
}


#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return self.indexPlaylist.playListItems.count;
}


#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    M3UPlaylistItem *cellItem = [self.indexPlaylist.playListItems objectAtIndex:row];
    
    id value = [cellItem valueForKey:tableColumn.identifier];
    if (value) {
        cellView.textField.stringValue = value;
    } else {
        cellView.textField.stringValue = @"-";
    }

    return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView sizeToFitWidthOfColumn:(NSInteger)column {
    CGFloat widestWidth = 0.f;
    NSString *columnIdentifier = [[[tableView tableColumns] objectAtIndex:column] identifier];

    for (M3UPlaylistItem *item in self.indexPlaylist.playListItems) {
        NSString        *text   = [item valueForKey:columnIdentifier];
        NSDictionary    *attrs  = @{ NSFontAttributeName: [NSFont systemFontOfSize:14.0] };
        NSSize          size    = [text sizeWithAttributes:attrs];
        CGFloat         width   = size.width;

        if (widestWidth < width) {
            widestWidth = width;
        }
    }
    
    return widestWidth;
}


#pragma mark - NSWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)notification {
    if (!self.indexPlaylist && self.createNewDocOnActivate && notification.object == [self windowForSheet]) {
        // -- delay for windows appear animation before we pop the sheet.
        int64_t delayInMilliSeconds = 200;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (delayInMilliSeconds * NSEC_PER_MSEC));
        __weak HDStreamDocument *weakSelf = self;
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            HDStreamDocument *strongSelf = weakSelf;
            [NSApp beginSheet:strongSelf.openURLSheet
               modalForWindow:[strongSelf windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];

            strongSelf.createNewDocOnActivate = NO;
        });
    }
}

@end
