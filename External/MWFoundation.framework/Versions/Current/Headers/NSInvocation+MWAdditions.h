//
//  NSInvocation+MWAdditions.h
//  MWFoundation
//
//  Created by Daniel Ericsson on 2013-04-28.
//  Copyright (c) 2013 Monowerks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (MWAdditions)

+ (id)invocationWithTarget:(NSObject*)targetObject selector:(SEL)selector;
+ (id)invocationWithClass:(Class)targetClass selector:(SEL)selector;
+ (id)invocationWithProtocol:(Protocol*)targetProtocol selector:(SEL)selector;

@end
