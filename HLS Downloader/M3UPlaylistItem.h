//
//  M3UPlaylistItem.h
//  HLS Downloader
//
//  Copyright (c) 2013 Daniel Ericsson.
//  Distributed under the terms of 'The MIT License', http://opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>
// -- Models
#import "M3UPlaylist.h"

@interface M3UPlaylistItem : NSObject

@property (nonatomic, readwrite, strong) NSURL          *URL;
@property (nonatomic, readwrite, assign) NSInteger      duration;
@property (nonatomic, readwrite, assign) NSInteger      bandwidth;
@property (nonatomic, readwrite, strong) NSString       *resolution;
@property (nonatomic, readwrite, strong) NSString       *codecs;
@property (nonatomic, readwrite, assign) NSInteger      segementCount;
@property (nonatomic,  readonly, strong) M3UPlaylist    *segmentPlaylist;

extern NSString *const SSColumnIdentifierCodec;
extern NSString *const SSColumnIdentifierResolution;
extern NSString *const SSColumnIdentifierBandwith;
extern NSString *const SSColumnIdentifierLocation;
extern NSString *const SSColumnIdentifierSegmentCount;

@end
