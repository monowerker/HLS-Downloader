//
//  M3UPlaylist.h
//  HLS Downloader
//
//  Copyright (c) 2013 Daniel Ericsson.
//  Distributed under the terms of 'The MIT License', http://opensource.org/licenses/mit-license.html
//

#import <Foundation/Foundation.h>

@interface M3UPlaylist : NSObject

@property (nonatomic,  readonly, strong) NSArray    *playListItems;
@property (nonatomic, readwrite, strong) NSURL      *URL;

+ (M3UPlaylist *)playListFromURL:(NSURL *)URL;

@end
