//
//  FDGCActuator.m
//  FruitzOfDojo
//
//  Created by C.W. Betts on 7/10/20.
//  Copyright © 2020 C.W. Betts. All rights reserved.
//

#import "FDGCActuator.h"
#import "FDHIDInternal.h"
#import "FDDebug.h"
#import "FDDefines.h"

#import <GameController/GameController.h>
#import <CoreHaptics/CoreHaptics.h>

@implementation FDGCActuator

- (BOOL)isActive
{
    // TODO: write!
    return YES;
}

@synthesize duration;

@synthesize intensity;

- (void)start {
    [engine startAndReturnError:NULL];
}

- (void)stop {
    [engine stopWithCompletionHandler:NULL];
}

- (nullable instancetype) initWithDevice: (_FDGCDeviceGamePad*) device
{
    if (self = [super init]) {
        engine = [device.controller.haptics createEngineWithLocality:GCHapticsLocalityDefault];
        if (engine == nil) {
            return nil;
        }
    }
    return self;
}
@end
