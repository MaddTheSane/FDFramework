//----------------------------------------------------------------------------------------------------------------------------
//
// "FDHIDDevice.h"
//
// Written by:	Axel 'awe' Wefers			[mailto:awe@fruitz-of-dojo.de].
//				©2001-2012 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
//----------------------------------------------------------------------------------------------------------------------------

#import <FruitzOfDojo/FDHIDActuator.h>

#import <Cocoa/Cocoa.h>

//----------------------------------------------------------------------------------------------------------------------------

NS_ASSUME_NONNULL_BEGIN

@interface FDHIDDevice : NSObject

@property (readonly) SInt32 vendorId;
@property (readonly) SInt32 productId;

@property (readonly, copy) NSString *vendorName;
@property (readonly, copy) NSString *productName;
@property (readonly, copy) NSString *deviceType;

@property (readonly) BOOL hasActuator;
@property (readonly, strong, nullable) FDHIDActuator *actuator;

@end

NS_ASSUME_NONNULL_END

//----------------------------------------------------------------------------------------------------------------------------
