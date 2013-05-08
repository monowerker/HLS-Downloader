//
//  HDSegmentsDownloader.m
//  HLS Downloader
//
//  Copyright (c) 2013 Daniel Ericsson.
//  Distributed under the terms of 'The MIT License', http://opensource.org/licenses/mit-license.html
//

#import "HDSegmentsDownloader.h"
// Utils
#import <MWBase/MWBase.h>
#import <AFNetworking/AFNetworking.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@interface HDSegmentsDownloader ()

@property (nonatomic, readonly) NSOutputStream *outputStream;
@property (nonatomic, readwrite, assign) BOOL reportErrors;

@end

@implementation HDSegmentsDownloader

@synthesize outputStream = _outputStream;


#pragma mark - Public methods

- (void)start {
    self.reportErrors = YES;
    [self.downloadQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];

    for (NSURL *URL in self.segmentURLs) {
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL
                                                      cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                  timeoutInterval:10.];

        AFHTTPRequestOperation *requestOp = [[AFHTTPRequestOperation alloc] initWithRequest:request];

        requestOp.outputStream = [NSOutputStream outputStreamWithURL:self.targetURL append:YES];

        [requestOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            MWLog(@"completed: %@", operation.request.URL);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            MWLog(@"failed: %@", operation.request.URL);
            if (self.reportErrors) {
                [[NSAlert alertWithError:error] runModal];
            }
        }];

        [self.downloadQueue addOperation:requestOp];
    }
}

- (void)stop {
    self.reportErrors = NO;
    [self removeAllObservers];
    [self.downloadQueue cancelAllOperations];
    self.targetURL = nil;
    self.segmentURLs = nil;
}


#pragma mark - Accessors

- (NSOperationQueue *)downloadQueue {
    if(!_downloadQueue) {
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.maxConcurrentOperationCount = 1;
    }

    return _downloadQueue;
}


#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    MWLog(@"%d", eventCode);
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    id changeValue = [change valueForKey:NSKeyValueChangeNewKey];
    MWLog(@"%@", changeValue);

    if ([changeValue isEqual:[NSNumber numberWithInt:0]]) {
        [self.outputStream close];
    }
}

@end
