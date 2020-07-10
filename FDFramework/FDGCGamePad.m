//
//  FDGCGamePad.m
//  FruitzOfDojo
//
//  Created by C.W. Betts on 7/10/20.
//  Copyright © 2020 C.W. Betts. All rights reserved.
//

#import "FDHIDManager.h"
#import "FDHIDInternal.h"
#import "FDDebug.h"
#import "FDDefines.h"
#import "FDGCGamePad.h"

#import <Cocoa/Cocoa.h>
#import <GameController/GameController.h>
#import <CoreHaptics/CoreHaptics.h>

typedef struct CF_BRIDGED_TYPE(id) __IOHIDServiceClient* IOHIDServiceClientRef;
extern CFTypeRef _Nullable IOHIDServiceClientCopyProperty(IOHIDServiceClientRef service, CFStringRef key);

@interface _FDGCDeviceGamePad()
- (instancetype)initWithController:(GCController*)_controller andDevice:(IOHIDDeviceRef)dev;
@property (readwrite, strong) GCController *controller;
@end

@interface _GCCControllerHIDServiceInfo : NSObject
@property(readonly, nonatomic) IOHIDServiceClientRef service;
@end

@interface GCController (Internal)
- (NSArray<_GCCControllerHIDServiceInfo*>*)hidServices;
@end

static void getVendorAndProductIDFromController(GCController *controller, int32_t *vendorId, int32_t *productId)
{
    if ([controller respondsToSelector:@selector(hidServices)]) {
        NSArray<_GCCControllerHIDServiceInfo*>* hidServices = [controller hidServices];

        if (hidServices && [hidServices count] > 0) {
            IOHIDServiceClientRef service = [[hidServices firstObject] service];

            CFNumberRef vendor = (IOHIDServiceClientCopyProperty(service, CFSTR(kIOHIDVendorIDKey)));
            if (vendor) {
                CFNumberGetValue(vendor, kCFNumberSInt32Type, vendorId);
                CFRelease(vendor);
            }

            CFNumberRef product = (IOHIDServiceClientCopyProperty(service, CFSTR(kIOHIDProductIDKey)));
            if (product) {
                CFNumberGetValue(product, kCFNumberSInt32Type, productId);
                CFRelease(product);
            }
        }
    } else {
        *vendorId = -1;
        *productId = -1;
    }
}

@implementation _FDGCDeviceGamePad
- (instancetype)initWithController:(GCController*)_controller andDevice:(IOHIDDeviceRef)dev
{
    if (self = [super initWithDevice:dev deviceDescriptors:NULL]) {
        self.controller = _controller;
        
    }
    return self;
}
+ (nullable FDHIDDevice*) deviceWithDevice: (IOHIDDeviceRef) pDevice
{
    if (@available(macOS 11.0, *)) {
        if ([GCController supportsHIDDevice:pDevice]) {
            int32_t devPID;
            int32_t devVID;
            CFNumberRef vendor = IOHIDDeviceGetProperty(pDevice, CFSTR(kIOHIDVendorIDKey));
            CFNumberRef product = IOHIDDeviceGetProperty(pDevice, CFSTR(kIOHIDProductIDKey));
            CFNumberGetValue(vendor, kCFNumberSInt32Type, &devVID);
            CFNumberGetValue(product, kCFNumberSInt32Type, &devPID);
            for (GCController *controller in GCController.controllers) {
                int32_t gcPID;
                int32_t gcVID;
                getVendorAndProductIDFromController(controller, &gcVID, &gcPID);
                if (gcPID == devPID && gcVID == devPID) {
                    return [[self alloc] initWithController:controller andDevice:pDevice];
                }
            }
        } else {
            return nil;
        }
    } else {
        // Fallback on earlier versions
    }
    return nil;
}
//+ (NSArray<NSDictionary<NSString*,NSNumber*>*>*) matchingDictionaries;



@end
