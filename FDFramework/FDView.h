//----------------------------------------------------------------------------------------------------------------------------
//
// "FDView.h"
//
// Written by:	Axel 'awe' Wefers			[mailto:awe@fruitz-of-dojo.de].
//				©2001-2012 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
//----------------------------------------------------------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>

//----------------------------------------------------------------------------------------------------------------------------

@interface FDView : NSView

- (instancetype) initWithFrame: (NSRect) frameRect;

@property (nonatomic, retain) NSCursor *cursor;
@property BOOL vsync;

@property (readonly, strong) NSOpenGLContext *openGLContext;

@end

//----------------------------------------------------------------------------------------------------------------------------
