//----------------------------------------------------------------------------------------------------------------------------
//
// "FDHIDActuator.h"
//
// Written by:	Axel 'awe' Wefers			[mailto:awe@fruitz-of-dojo.de].
//				©2001-2012 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
//----------------------------------------------------------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>
#import <FruitzOfDojo/FDActuator.h>

//----------------------------------------------------------------------------------------------------------------------------

@interface FDHIDActuator : NSObject <FDActuator>

@property float intensity;
@property float duration;
@property (readonly, getter=isActive) BOOL active;

- (void) start;
- (void) stop;

@end

//----------------------------------------------------------------------------------------------------------------------------
