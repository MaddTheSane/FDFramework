//----------------------------------------------------------------------------------------------------------------------------
//
// "FDLinkView.m" - Provides an URL style link button.
//
// Written by:	Axel 'awe' Wefers			[mailto:awe@fruitz-of-dojo.de].
//				©2001-2012 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
//----------------------------------------------------------------------------------------------------------------------------

#import "FDLinkView.h"

//----------------------------------------------------------------------------------------------------------------------------

@interface FDLinkView ()


- (void) initFontAttributes;
- (NSDictionary*) fontAttributesWithColor: (NSColor*) color;

@end

//----------------------------------------------------------------------------------------------------------------------------

@implementation FDLinkView
{
@private
    NSString*       mDisplayString;
    NSURL*          mURL;
    NSDictionary* 	mFontAttributesBlue;
    NSDictionary* 	mFontAttributesRed;
    BOOL			mMouseIsDown;
}

//----------------------------------------------------------------------------------------------------------------------------

- (instancetype) initWithFrame: (NSRect) frameRect
{
    self = [super initWithFrame: frameRect];
	
    if (self != nil)
    {
        [self initFontAttributes];
        [self resetCursorRects];
    }
    
    return self;
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) initFontAttributes
{
    mFontAttributesRed  = [self fontAttributesWithColor: [NSColor redColor]];
    mFontAttributesBlue = [self fontAttributesWithColor: [NSColor blueColor]];
}

//----------------------------------------------------------------------------------------------------------------------------

- (NSDictionary *) fontAttributesWithColor: (NSColor *) color
{
    NSArray* keys = @[NSFontAttributeName,
                     NSForegroundColorAttributeName,
                     NSUnderlineStyleAttributeName];
    
    NSArray* objects = @[[NSFont systemFontOfSize: [NSFont systemFontSize]],
                        color,
                        @(NSSingleUnderlineStyle)];
    
    return [[NSDictionary alloc] initWithObjects: objects forKeys: keys];
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) dealloc
{
    [mDisplayString release];
    [mURL release];
    [mFontAttributesRed release];
    [mFontAttributesBlue release];

    [super dealloc];
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) setURL: (NSURL*) url displayString: (NSString*) displayString
{
    [mDisplayString release];
    [mURL release];
    
    if (displayString == nil)
    {
        displayString = url.absoluteString;
    }

    mDisplayString  = [displayString retain];
    mURL            = [url retain];
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) setURL: (NSURL*) url
{
    [self setURL: url displayString: nil];
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) drawRect: (NSRect) rect
{
    if (mDisplayString != nil)
    {
        if (mMouseIsDown == YES)
        {
            [mDisplayString drawAtPoint: NSZeroPoint withAttributes: mFontAttributesRed];
        }
        else
        {
            [mDisplayString drawAtPoint: NSZeroPoint withAttributes: mFontAttributesBlue];
        }
    }
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) mouseDown: (NSEvent*) event;
{
    if (mDisplayString != nil)
    {
        NSEvent*    nextEvent = nil;
        NSPoint 	location;
        
        mMouseIsDown = YES;
        
        [self setNeedsDisplay:YES];

        nextEvent = [NSApp nextEventMatchingMask: NSLeftMouseUpMask
                                       untilDate: [NSDate distantFuture]
                                          inMode: NSEventTrackingRunLoopMode
                                         dequeue: YES];
        location = [self convertPoint: nextEvent.locationInWindow fromView: nil];
        
        if (NSMouseInRect (location, self.bounds, NO))
        {
            [[NSWorkspace sharedWorkspace] openURL: mURL];
        }
        
        mMouseIsDown = NO;
        
        [self setNeedsDisplay:YES];
    }
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) resetCursorRects
{
    if (mDisplayString != nil)
    {
        NSCursor* cursor = [NSCursor pointingHandCursor];
        
        [cursor setOnMouseEntered: YES];
        
        [self addCursorRect: self.bounds cursor: cursor];
    }
}

@end

//----------------------------------------------------------------------------------------------------------------------------
