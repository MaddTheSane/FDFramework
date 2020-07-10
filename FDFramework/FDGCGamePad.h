//
//  FDGCDeviceGamePad.h
//  FruitzOfDojo
//
//  Created by C.W. Betts on 7/10/20.
//  Copyright © 2020 C.W. Betts. All rights reserved.
//

#ifndef FDGCDeviceGamePad_h
#define FDGCDeviceGamePad_h

#import <FruitzOfDojo/FDHIDDevice.h>

@class GCController;

API_AVAILABLE(macos(10.9))
@interface _FDGCDeviceGamePad : FDHIDDevice
@property (readonly, strong) GCController *controller;
@end

#endif /* FDGCDeviceGamePad_h */
