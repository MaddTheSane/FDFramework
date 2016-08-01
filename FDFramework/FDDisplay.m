//----------------------------------------------------------------------------------------------------------------------------
//
// "FDDisplay.m"
//
// Written by:	Axel 'awe' Wefers			[mailto:awe@fruitz-of-dojo.de].
//				©2001-2012 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
//----------------------------------------------------------------------------------------------------------------------------

#import "FDDisplay.h"
#import "FDDisplayMode.h"
#import "FDDefines.h"

#import <Cocoa/Cocoa.h>
#include <ApplicationServices/ApplicationServices.h>

//----------------------------------------------------------------------------------------------------------------------------

static NSArray*                         sDisplays           = nil;
static CGDisplayFadeReservationToken    sFadeToken          = kCGDisplayFadeReservationInvalidToken;
static const NSUInteger                 skFadeSteps         = 100;
static const NSUInteger                 skGammaTableSize    = 1024;

//----------------------------------------------------------------------------------------------------------------------------

typedef struct
{
    CGGammaValue		mRed[skGammaTableSize];
    CGGammaValue		mGreen[skGammaTableSize];
    CGGammaValue		mBlue[skGammaTableSize];
    uint32_t            mCount;
} GammaTable;

//----------------------------------------------------------------------------------------------------------------------------

static NSString* getPreferredDisplayName(CGDirectDisplayID displayID)
{
    NSString* name = @"Unknown";
    
    //TODO: 'CGDisplayIOServicePort' is deprecated (but still available) in OS X 10.9
    // I believe something else will come out by the time it is fully deprecated...or
    // Apple will document a way of getting this additional display info while using
    // CoreGraphics.
    io_service_t displayServicePort = CGDisplayIOServicePort(displayID);
    
    if (displayServicePort)
    {
        NSDictionary *displayInfoDict = CFBridgingRelease(IODisplayCreateInfoDictionary(displayServicePort, kIODisplayOnlyPreferredName));
        
        if(displayInfoDict)
        {
            // this array will be populated with the localized names for the display (i.e. names of the
            // display in different languages)
            NSDictionary *namesForDisplay = displayInfoDict[@kDisplayProductName];
            
            if (namesForDisplay) {
                NSString *tempName = namesForDisplay[[NSLocale autoupdatingCurrentLocale].localeIdentifier];
                if (!tempName) {
                    tempName = namesForDisplay[@"en_US"];
                }
                if (tempName) {
                    name = tempName;
                }
            }
        }
        
        IOObjectRelease(displayServicePort);
    }
    
    return name;
}

//----------------------------------------------------------------------------------------------------------------------------

@interface FDDisplayMode ()

- (instancetype) initWithCGDisplayMode: (CGDisplayModeRef) mode;
@property (readonly) CGDisplayModeRef cgDisplayMode;

@end

//----------------------------------------------------------------------------------------------------------------------------

@interface FDDisplay ()


- (instancetype) initWithCGDisplayID: (CGDirectDisplayID) displayId;
- (BOOL) readGammaTable: (GammaTable*) gammaTable;
- (void) applyGamma: (CGGammaValue) gamma withTable: (GammaTable*) gammaTable;

@end

//----------------------------------------------------------------------------------------------------------------------------

@implementation FDDisplay
{
@public
    NSString*           mDisplayName;
    NSArray<FDDisplayMode*>* mDisplayModes;
    FDDisplayMode*      mDisplayModeOriginal;
    CGDirectDisplayID   mCGDisplayId;
    CGGammaValue        mCGGamma;
    GammaTable          mGammaTable;
    BOOL                mCanSetGamma;
}

@synthesize originalMode = mDisplayModeOriginal;
@synthesize gamma = mCGGamma;
@synthesize displayModes = mDisplayModes;

//----------------------------------------------------------------------------------------------------------------------------

+ (NSArray*) displays
{
    if ( sDisplays == nil )
    {
        uint32_t            numDisplays     = 0;
        CGDirectDisplayID*  pDisplays       = NULL;
        BOOL                success         = (CGGetActiveDisplayList (0, NULL, &numDisplays) == CGDisplayNoErr);
        
        if (success == YES)
        {
            success     = (numDisplays > 0);
        }
        
        if (success == YES)
        {
            pDisplays   = malloc (numDisplays * sizeof (CGDirectDisplayID));
            success     = (pDisplays != NULL);
        }
        
        if (success == YES)
        {
            success = (CGGetActiveDisplayList (numDisplays, pDisplays, &numDisplays) == CGDisplayNoErr);
        }
        
        if (success == YES)
        {
            NSMutableArray* displayList = [[NSMutableArray alloc] initWithCapacity: numDisplays];
            
            sDisplays = displayList;
            
            for (uint32_t i = 0; i < numDisplays; ++i)
            {
                [displayList addObject: [[FDDisplay alloc] initWithCGDisplayID: pDisplays[i]]];
            }
        }
        
        if (pDisplays != NULL)
        {
            free (pDisplays);
        }
    }
    
    return sDisplays;
}

//----------------------------------------------------------------------------------------------------------------------------

+ (FDDisplay*) mainDisplay
{
    FDDisplay*  mainDisplay = nil;
    
    for (FDDisplay* display in [FDDisplay displays])
    {
        if (display.mainDisplay == YES)
        {
            mainDisplay = display;
            break;
        }
    }
    
    return mainDisplay;
}


//----------------------------------------------------------------------------------------------------------------------------

+ (void) fadeOutAllDisplays: (float) seconds
{
    if (sFadeToken == kCGDisplayFadeReservationInvalidToken)
    {
        if (CGAcquireDisplayFadeReservation (kCGMaxDisplayReservationInterval, &sFadeToken) == kCGErrorSuccess)
        {
            const float     interval    = ((float) seconds) / ((float) skFadeSteps);
            NSArray*        displays    = [FDDisplay displays];
            
            for (NSUInteger i = 0; i < skFadeSteps; ++i)
            {
                const CGGammaValue  fade        = 1.0f - (((float) i) * interval);
                NSEnumerator*       displayEnum = [displays objectEnumerator];
                FDDisplay*          display     = nil;
                
                while ((display = [displayEnum nextObject]) != nil)
                {
                    [display applyGamma: (fade * display->mCGGamma) withTable: &(display->mGammaTable)];
                }
                
                usleep (1000000 * interval);
            }
        }
    }
}

//----------------------------------------------------------------------------------------------------------------------------

+ (void) fadeInAllDisplays: (float) seconds
{
    if ( sFadeToken != kCGDisplayFadeReservationInvalidToken )
    {
        const float     interval    = ((float) seconds) / ((float) skFadeSteps);
        NSArray*        displays    = [FDDisplay displays];
        
        for (NSUInteger i = 0; i < skFadeSteps; ++i)
        {
            const CGGammaValue  fade        = ((float) i) * interval;
            NSEnumerator*       displayEnum = [displays objectEnumerator];
            FDDisplay*          display     = nil;
            
            while ((display = [displayEnum nextObject]) != nil)
            {
                [display applyGamma: (fade * display->mCGGamma) withTable: &(display->mGammaTable)];
            }
            
            usleep (1000000 * interval);
        }
        
        CGReleaseDisplayFadeReservation (sFadeToken);
        
        sFadeToken = kCGDisplayFadeReservationInvalidToken;
    }
}

//----------------------------------------------------------------------------------------------------------------------------

+ (void) captureAllDisplays
{
    CGDisplayHideCursor (CGMainDisplayID());
    CGCaptureAllDisplays ();
}

//----------------------------------------------------------------------------------------------------------------------------

+ (void) releaseAllDisplays
{
    CGReleaseAllDisplays ();
    CGDisplayShowCursor (CGMainDisplayID());
}

//----------------------------------------------------------------------------------------------------------------------------

+ (BOOL) isAnyDisplayCaptured
{
    BOOL isAnyCaptured = NO;
    
    for (FDDisplay* display in [FDDisplay displays])
    {
        isAnyCaptured = display.captured;
        
        if (isAnyCaptured == YES)
        {
            break;
        }
    }
    
    return isAnyCaptured;
}

//----------------------------------------------------------------------------------------------------------------------------

- (instancetype) init
{
    self = [super init];
    
    if (self != nil)
    {
        [self doesNotRecognizeSelector: _cmd];
    }
    
    return nil;
}

//----------------------------------------------------------------------------------------------------------------------------

- (instancetype) initWithCGDisplayID: (CGDirectDisplayID) displayId
{
    self = [super init];
    
    if (self != nil)
    {
        NSMutableString     *displayName     = [getPreferredDisplayName(displayId) mutableCopy];
        CGDisplayModeRef    originalMode    = CGDisplayCopyDisplayMode (displayId);
        getPreferredDisplayName(displayId);
        
        if (CGDisplayIsMain (displayId) == YES)
        {
            [displayName appendString:@" (Main)"];
        }
        else
        {
            [displayName appendFormat:@" (%lu)", (unsigned long) sDisplays.count];
        }
        
        if (CGDisplayIsBuiltin (displayId) == YES)
        {
            [displayName appendString:@" (built in)"];
        }
        
        if (originalMode)
        {
            mDisplayModeOriginal = [[FDDisplayMode alloc] initWithCGDisplayMode: originalMode];
            
            CGDisplayModeRelease (originalMode);
        }
        
        // filter and sort displaymodes
        CFArrayRef  modes = CGDisplayCopyAllDisplayModes (displayId, NULL);
        
        if (modes != NULL)
        {
            const CFIndex   numModes    = CFArrayGetCount (modes);
            NSMutableArray* modeList    = [[NSMutableArray alloc] initWithCapacity: numModes];
            
            for (CFIndex i = 0; i < numModes; ++i)
            {
                CGDisplayModeRef    mode            = (CGDisplayModeRef) CFArrayGetValueAtIndex (modes, i);
                FDDisplayMode*      displayMode     = [[FDDisplayMode alloc] initWithCGDisplayMode: mode];
                
                if (displayMode != nil)
                {
                    NSUInteger          bitsPerPixel    = displayMode.bitsPerPixel;
                    BOOL                isValid         = (bitsPerPixel == 32) || (bitsPerPixel == 16);
                    
                    if (isValid == YES)
                    {
                        NSEnumerator*   modeEnum = [modeList objectEnumerator];
                        FDDisplayMode*  curMode  = nil;
                        
                        while ((isValid == YES) && (curMode = [modeEnum nextObject]))
                        {
                            isValid = ![displayMode isEqualTo: curMode];
                        }
                    }
                    
                    if (isValid == YES)
                    {
                        [modeList addObject: displayMode];
                    }
                }
            }
            
            CFRelease (modes);
            
            [modeList sortUsingSelector: @selector (compare:)];
            
            mDisplayModes = [modeList copy];
        }
        
        mDisplayName    = [displayName copy];
        mCGDisplayId    = displayId;
        mCGGamma        = 1.0f;
        mCanSetGamma    = [self readGammaTable: &mGammaTable];
    }
    
    return self;
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) dealloc
{
    [self setGamma: 1.0f update: YES];
    [self setDisplayMode: mDisplayModeOriginal];
}

//----------------------------------------------------------------------------------------------------------------------------

- (FDDisplayMode*) displayMode
{
    CGDisplayModeRef    cgDisplayMode   = CGDisplayCopyDisplayMode (mCGDisplayId);
    FDDisplayMode*      currentMode     = nil;
    
    if (cgDisplayMode != NULL)
    {
        currentMode = [[FDDisplayMode alloc] initWithCGDisplayMode: cgDisplayMode];
        
        CGDisplayModeRelease (cgDisplayMode);
    }
    
    return currentMode;
}

//----------------------------------------------------------------------------------------------------------------------------

- (NSString*) description
{
    return mDisplayName;
}

//----------------------------------------------------------------------------------------------------------------------------

- (NSRect) frame
{
    const CGRect    main = CGDisplayBounds (CGMainDisplayID ());
    const CGRect    rect = CGDisplayBounds (mCGDisplayId);

    return NSMakeRect (rect.origin.x, main.size.height - rect.origin.y - rect.size.height, rect.size.width, rect.size.height);
}

//----------------------------------------------------------------------------------------------------------------------------

- (BOOL) isMainDisplay
{
    return CGDisplayIsMain (mCGDisplayId);
}

//----------------------------------------------------------------------------------------------------------------------------

- (BOOL) isBuiltinDisplay
{
    return CGDisplayIsBuiltin (mCGDisplayId);
}

//----------------------------------------------------------------------------------------------------------------------------

- (BOOL) isCaptured
{
    return CGDisplayIsCaptured (mCGDisplayId);
}

//----------------------------------------------------------------------------------------------------------------------------

- (BOOL) hasFSAA
{
    GLint               maxSampleBuffers    = 0;
    GLint               maxSamples          = 0;
    GLint               numRenderers        = 0;
    CGLRendererInfoObj  rendererInfo        = { 0 };
    CGOpenGLDisplayMask displayMask         = CGDisplayIDToOpenGLDisplayMask (mCGDisplayId);
    CGLError            err                 = CGLQueryRendererInfo (displayMask, &rendererInfo, &numRenderers);
    
    if (err == kCGErrorSuccess)
    {
        for (GLint i = 0; i < numRenderers; ++i)
        {
            GLint numSampleBuffers = 0;
            
            err = CGLDescribeRenderer (rendererInfo, i, kCGLRPMaxSampleBuffers, &numSampleBuffers);
            
            if ((err == kCGErrorSuccess) && (numSampleBuffers > 0))
            {
                GLint numSamples = 0;
                
                err = CGLDescribeRenderer (rendererInfo, i, kCGLRPMaxSamples, &numSamples);
            
                if ((err == kCGErrorSuccess) && (numSamples > maxSamples))
                {
                    maxSamples          = numSamples;
                    maxSampleBuffers    = numSampleBuffers;
                }
            }
        }
        
        CGLDestroyRendererInfo (rendererInfo);
    }
    
    // NOTE: we could return the max number of samples at this point, but unfortunately there is a bug
    //       with the ATI Radeon/PCI drivers: We would return 4 instead of 8. So we assume that the
    //       max samples are always 8 if we have sample buffers and max samples is greater than 1.

    return (maxSampleBuffers > 0) && (maxSamples > 1);
}

//----------------------------------------------------------------------------------------------------------------------------

- (BOOL) setDisplayMode: (FDDisplayMode*) displayMode;
{
    return CGDisplaySetDisplayMode (mCGDisplayId, displayMode.cgDisplayMode, NULL) == kCGErrorSuccess;
}

//----------------------------------------------------------------------------------------------------------------------------

- (BOOL) readGammaTable: (GammaTable*) gammaTable
{
    CGError err = CGGetDisplayTransferByTable (mCGDisplayId,
                                               FD_SIZE_OF_ARRAY (gammaTable->mRed),
                                               &(gammaTable->mRed[0]),
                                               &(gammaTable->mGreen[0]),
                                               &(gammaTable->mBlue[0]),
                                               &(gammaTable->mCount));
    
    return err == kCGErrorSuccess;
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) applyGamma: (CGGammaValue) gamma withTable: (GammaTable*) gammaTable
{
    if (mCanSetGamma == YES)
    {
        GammaTable  newTable;
        
        for (NSUInteger i = 0; i < gammaTable->mCount; ++i)
        {
            newTable.mRed[i]   = gamma * gammaTable->mRed[i];
            newTable.mGreen[i] = gamma * gammaTable->mGreen[i];
            newTable.mBlue[i]  = gamma * gammaTable->mBlue[i];
        }
        
        CGSetDisplayTransferByTable (mCGDisplayId, gammaTable->mCount, newTable.mRed, newTable.mGreen, newTable.mBlue);
    }
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) setGamma: (float) gamma update: (BOOL) doUpdate 
{
    if (self.captured)
    {
        if (mCGGamma != gamma)
        {
            mCGGamma = gamma;

            if (doUpdate == YES)
            {
                [self applyGamma: gamma withTable: &mGammaTable];
            }
         }
    }
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) fadeOutDisplay: (float) seconds
{
    if (sFadeToken == kCGDisplayFadeReservationInvalidToken)
    {
        if (CGAcquireDisplayFadeReservation (kCGMaxDisplayReservationInterval, &sFadeToken) == kCGErrorSuccess)
        {
            const float interval = ((float) seconds) / ((float) skFadeSteps);
            
            for (NSUInteger i = 0; i < skFadeSteps; ++i)
            {
                const CGGammaValue fade = (1.0f - (((float) i) * interval)) * mCGGamma;
                
                [self applyGamma: fade withTable: &mGammaTable];
                
                usleep (1000000 * interval);
            }
        }
    }
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) fadeInDisplay: (float) seconds
{
    if (sFadeToken != kCGDisplayFadeReservationInvalidToken)
    {
        const float interval = ((float) seconds) / ((float) skFadeSteps);
        
        for (NSUInteger i = 0; i < skFadeSteps; ++i)
        {
            const CGGammaValue fade = ((float) i) * interval * mCGGamma;
            
            [self applyGamma: fade withTable: &mGammaTable];

            usleep (1000000 * interval);
        }
        
        CGReleaseDisplayFadeReservation (sFadeToken);
        
        sFadeToken = kCGDisplayFadeReservationInvalidToken;
    }
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) captureDisplay
{
    if (self.captured == NO)
    {
        CGDisplayCapture (mCGDisplayId);
    }
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) releaseDisplay
{
    if (self.captured == YES)
    {
        CGDisplayRelease (mCGDisplayId);
    }
}

@end

//----------------------------------------------------------------------------------------------------------------------------
