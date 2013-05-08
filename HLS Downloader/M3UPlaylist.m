//
//  M3UPlaylist.m
//  HLS Downloader
//
//  Copyright (c) 2013 Daniel Ericsson.
//  Distributed under the terms of 'The MIT License', http://opensource.org/licenses/mit-license.html
//

#import "M3UPlaylist.h"
// Models
#import "M3UPlaylistItem.h"
// Utils
#import <AFNetworking/AFNetworking.h>
#import <MWBase/MWBase.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@interface M3UPlaylist ()

@property (nonatomic, readwrite, strong) NSString       *rawPlaylist;
@property (nonatomic, readwrite, strong) NSMutableArray *headerLines;
@property (nonatomic, readwrite, strong) NSArray        *playListLines;
@property (nonatomic, readwrite, strong) NSArray        *playListItems;

@end

@implementation M3UPlaylist

+ (M3UPlaylist *)playListFromURL:(NSURL *)URL {
    M3UPlaylist *playlist = [[M3UPlaylist alloc] init];    
    playlist.URL = URL;
    [playlist setPlayListFromURL:URL];

    return playlist;
}


#pragma mark - Accessors

- (void)setRawPlaylist:(NSString *)rawPlaylist {
    _rawPlaylist = rawPlaylist;
    self.playListLines = [_rawPlaylist componentsSeparatedByString:@"\n"];
    self.playListItems = [self playListItemsFromPlayListLines:self.playListLines];
}


#pragma mark - URL Fetching

- (void)setPlayListFromURL:(NSURL *)URL {
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:URL];
    
    __weak M3UPlaylist *weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue currentQueue] completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *error) {
         M3UPlaylist *strongSelf = weakSelf;
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode < 299) {
             strongSelf.rawPlaylist = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
         } else {
             MWLog(@"HTTP response code: %d", statusCode);
             [[NSAlert alertWithError:error] runModal];
         }
     }];
}


#pragma mark - "Parsing"

- (NSArray *)playListItemsFromPlayListLines:(NSArray *)playListLines {
    __block M3UPlaylistItem *currentItem;
    __block NSUInteger lastConsumedURLIdx;
    NSMutableArray *items = [[NSMutableArray alloc] init];

    [playListLines enumerateObjectsUsingBlock:^(id line, NSUInteger idx, BOOL *stop) {        
        if (idx == lastConsumedURLIdx) {
            return;
        }
        
        // -- Index Playlist
        if ([line rangeOfString:@"#EXT-X-STREAM-INF" options:(NSAnchoredSearch)].location != NSNotFound)  {
            currentItem             = [[M3UPlaylistItem alloc] init];
            currentItem.bandwidth   = [M3UPlaylist bandWidthInHeaderLine:line];
            currentItem.codecs      = [M3UPlaylist codecsInHeaderLine:line];
            currentItem.resolution  = [M3UPlaylist resolutionInHeaderLine:line];
            
            lastConsumedURLIdx      = idx+1;
            NSURL *URL              = [M3UPlaylist URLInLocationLine:[playListLines objectAtIndex:lastConsumedURLIdx]];
            currentItem.URL         = [NSURL URLWithString:[URL absoluteString] relativeToURL:self.URL];
            MWLog(@"%@", currentItem.URL);
            [items addObject:currentItem];
        }

        // -- Segment Playlist
        if ([line rangeOfString:@"#EXTINF" options:(NSAnchoredSearch)].location != NSNotFound)  {
            currentItem             = [[M3UPlaylistItem alloc] init];
            currentItem.bandwidth   = [M3UPlaylist bandWidthInHeaderLine:line];
            currentItem.codecs      = [M3UPlaylist codecsInHeaderLine:line];
            currentItem.resolution  = [M3UPlaylist resolutionInHeaderLine:line];
            
            lastConsumedURLIdx      = idx+1;
            NSURL *URL              = [M3UPlaylist URLInLocationLine:[playListLines objectAtIndex:lastConsumedURLIdx]];
            currentItem.URL         = [NSURL URLWithString:[URL absoluteString] relativeToURL:self.URL];
            MWLog(@"%@", currentItem.URL);
            [items addObject:currentItem];
        }
    }];
    
    MWLog(@"mormor");
    return items;
}

+ (NSString *)codecsInHeaderLine:(NSString *)headerLine {
    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"(?<=CODECS=\")(.*?)(?=\")"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    NSRange matchRange = [regEx rangeOfFirstMatchInString:headerLine options:0 range:NSMakeRange(0, headerLine.length)];
    
    if (matchRange.location != NSNotFound) {
        return [headerLine substringWithRange:matchRange];
    } else {
        return nil;
    }
}

+ (NSInteger)durationInHeaderLine:(NSString *)headerLine {
    return 0;
}

+ (NSInteger)bandWidthInHeaderLine:(NSString *)headerLine {
    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"(?<=BANDWIDTH=)(\\d*)(?=,)"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];

    NSRange matchRange = [regEx rangeOfFirstMatchInString:headerLine options:0 range:NSMakeRange(0, headerLine.length)];

    if (matchRange.location != NSNotFound) {
        return [[headerLine substringWithRange:matchRange] integerValue];
    } else {
        return -1;
    }
}

+ (NSString *)resolutionInHeaderLine:(NSString *)headerLine {
    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"(?<=RESOLUTION=)(\\w*)(?=,)"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];

    NSRange matchRange = [regEx rangeOfFirstMatchInString:headerLine options:0 range:NSMakeRange(0, headerLine.length)];

    if (matchRange.location != NSNotFound) {
        return [headerLine substringWithRange:matchRange];
    } else {
        return nil;
    }
}

+ (NSURL *)URLInLocationLine:(NSString *)locationLine {
    return [NSURL URLWithString:[locationLine stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

@end
