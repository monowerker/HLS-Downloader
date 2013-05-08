//
//  HDSegmentsDownloader.h
//  HLS Downloader
//
//  Copyright (c) 2013 Daniel Ericsson.
//  Distributed under the terms of 'The MIT License', http://opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>

@interface HDSegmentsDownloader : NSObject

@property (nonatomic, readwrite, strong) NSOperationQueue   *downloadQueue;
@property (nonatomic, readwrite,   copy) NSURL              *targetURL;
@property (nonatomic, readwrite, strong) NSArray            *segmentURLs;

- (void)start;
- (void)stop;

@end
