//
//  FDActuator.h
//  FruitzOfDojo
//
//  Created by C.W. Betts on 7/10/20.
//  Copyright © 2020 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FDActuator <NSObject>

@property (readwrite) float intensity;
@property (readwrite) float duration;
@property (readonly, getter=isActive) BOOL active;

- (void) start;
- (void) stop;

@end

NS_ASSUME_NONNULL_END
