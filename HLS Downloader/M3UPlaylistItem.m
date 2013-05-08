//
//  M3UPlaylistItem.m
//  HLS Downloader
//
//  Copyright (c) 2013 Daniel Ericsson.
//  Distributed under the terms of 'The MIT License', http://opensource.org/licenses/mit-license.html
//

#import "M3UPlaylistItem.h"

NSString *const SSColumnIdentifierCodec = @"Codec";
NSString *const SSColumnIdentifierResolution = @"Resolution";
NSString *const SSColumnIdentifierBandwith = @"Bandwidth";
NSString *const SSColumnIdentifierLocation = @"Playlist Location";
NSString *const SSColumnIdentifierSegmentCount = @"Segments";

@interface M3UPlaylistItem ()

@property (nonatomic, readwrite, strong) M3UPlaylist *segmentPlaylist;

@end

@implementation M3UPlaylistItem


#pragma mark - Accessors

- (M3UPlaylist *)segmentPlaylist {
    if (!_segmentPlaylist) {
        _segmentPlaylist = [M3UPlaylist playListFromURL:self.URL];  
    }

    return _segmentPlaylist;
}


#pragma mark - KVC

- (id)valueForUndefinedKey:(NSString *)key {
    if ([key isEqualToString:SSColumnIdentifierCodec]) {
        return self.codecs;
    } else if([key isEqualToString:SSColumnIdentifierResolution]) {
        return self.resolution;
    } else if([key isEqualToString:SSColumnIdentifierBandwith]) {
        return [[NSNumber numberWithInteger:self.bandwidth] stringValue];
    } else if ([key isEqualToString:SSColumnIdentifierLocation]) {
        return [self.URL absoluteString];
    } else if ([key isEqualToString:SSColumnIdentifierSegmentCount]) {
        return [[NSNumber numberWithInteger:self.segementCount] stringValue];
    }

    return [super valueForUndefinedKey:key];
}

@end
