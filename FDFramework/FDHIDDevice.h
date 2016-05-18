//----------------------------------------------------------------------------------------------------------------------------
//
// "FDHIDDevice.h"
//
// Written by:	Axel 'awe' Wefers			[mailto:awe@fruitz-of-dojo.de].
//				©2001-2012 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
//----------------------------------------------------------------------------------------------------------------------------

#import "FDHIDActuator.h"

#import <Cocoa/Cocoa.h>

//----------------------------------------------------------------------------------------------------------------------------

@interface FDHIDDevice : NSObject
{
}

- (NSUInteger) vendorId;
- (NSUInteger) productId;

- (NSString*) vendorName;
- (NSString*) productName;
- (NSString*) deviceType;

- (BOOL) hasActuator;
- (FDHIDActuator*)  actuator;

@end

//----------------------------------------------------------------------------------------------------------------------------
