//----------------------------------------------------------------------------------------------------------------------------
//
// "FDHIDDevice.m"
//
// Written by:	Axel 'awe' Wefers			[mailto:awe@fruitz-of-dojo.de].
//				©2001-2012 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
//----------------------------------------------------------------------------------------------------------------------------

#import "FDHIDDevice.h"
#import "FDHIDActuator.h"
#import "FDHIDInternal.h"
#import "FDDebug.h"
#import "FDDefines.h"

#import <Cocoa/Cocoa.h>
#include <IOKit/hidsystem/IOHIDLib.h>
#include <IOKit/hid/IOHIDLib.h>

//----------------------------------------------------------------------------------------------------------------------------

@interface FDHIDManager ()

- (void) pushEvent: (const FDHIDEvent*) pEvent;

@end

//----------------------------------------------------------------------------------------------------------------------------

@interface FDHIDDevice ()

+ (NSDictionary*) matchingDictionarForUsageMap: (const FDHIDUsageToDevice*) pUsageMap;

- (uint32_t) getDevicePropertyForKey: (CFStringRef) pKey;
- (NSString*) getDevicePropertyStringForKey: (CFStringRef) pKey;

@end

//----------------------------------------------------------------------------------------------------------------------------

@implementation FDHIDDevice
@synthesize delegate = mDelegate;
@synthesize actuator = mActuator;
@synthesize vendorName = mVendorName;
@synthesize productName = mProductName;
@synthesize iohidDeviceRef = mpIOHIDDevice;

+ (NSDictionary*) matchingDictionarForUsageMap: (const FDHIDUsageToDevice*) pUsageMap
{
    FD_ASSERT (pUsageMap);
    
    NSString*   pageKey     = @kIOHIDPrimaryUsagePageKey;
    NSString*   usageKey    = @kIOHIDPrimaryUsageKey;
    NSNumber*   pageVal     = @(pUsageMap->mUsagePage);
    NSNumber*   usageVal    = @(pUsageMap->mUsage);
    
    return @{pageKey: pageVal, usageKey: usageVal};
}

//----------------------------------------------------------------------------------------------------------------------------

+ (NSArray*) matchingDictionaries: (const FDHIDUsageToDevice*) pUsageMap withCount: (NSUInteger) numUsages
{
    FD_ASSERT (pUsageMap);
    
    NSMutableArray* dictionaries = [NSMutableArray arrayWithCapacity: numUsages];
    
    for (NSUInteger i = 0; i < numUsages; ++i)
    {
        [dictionaries addObject: [FDHIDDevice matchingDictionarForUsageMap: &(pUsageMap[i])]];
    }
    
    return dictionaries;
}

//----------------------------------------------------------------------------------------------------------------------------

+ (FDHIDDevice*) deviceWithDevice: (IOHIDDeviceRef) pDevice
                         usageMap: (const FDHIDUsageToDevice*) pUsageMap
                            count: (NSUInteger) numUsages
{
    FD_ASSERT (pDevice);
    FD_ASSERT (pUsageMap);
    
    FDHIDDevice* device = nil;
    
    for (NSUInteger i = 0; i < numUsages; ++i)
    {
        if (IOHIDDeviceConformsTo (pDevice, pUsageMap[i].mUsagePage, pUsageMap[i].mUsage))
        {
            device = [[[self class] alloc] initWithDevice: pDevice deviceDescriptors: pUsageMap[i].mDeviceDesc];
            
            break;
        }
    }
    
    return device;
}

//----------------------------------------------------------------------------------------------------------------------------

- (instancetype) initWithDevice: (IOHIDDeviceRef) pDevice deviceDescriptors: (const FDHIDDeviceDesc*) pDeviceDesc
{
    self = [super init];
    
    if (self != nil)
    {
        if (pDeviceDesc != nil)
        {
            mpIOHIDDevice   = pDevice;
            
            mVendorName     = [self getDevicePropertyStringForKey: CFSTR (kIOHIDManufacturerKey)];
            mProductName    = [self getDevicePropertyStringForKey: CFSTR (kIOHIDProductKey)];
            
            FDLog (@"Found %@ by %@\n", mProductName, mVendorName);
            
            const uint32_t vendorId  = [self getDevicePropertyForKey: CFSTR (kIOHIDVendorIDKey)];
            const uint32_t productId = [self getDevicePropertyForKey: CFSTR (kIOHIDProductIDKey)];
            
            while (1)
            {
                if ((pDeviceDesc->mVendorId == -1) && (pDeviceDesc->mProductId == -1))
                {
                    break;
                }
                
                if ((pDeviceDesc->mVendorId == vendorId) && (pDeviceDesc->mProductId == productId))
                {
                    break;
                }
                
                ++pDeviceDesc;
            }
            
            mpDeviceDesc    = pDeviceDesc;            
            mActuator       = [[FDHIDActuator alloc] initWithDevice: self];
        }
        else
        {
            return nil;
        }
    }
    
    return self;
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) dealloc
{
    FDLog (@"Lost %@ by %@\n", self.productName, self.vendorName);
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) pushEvent: (const FDHIDEvent*) pEvent
{
    if (mDelegate != nil)
    {
        [mDelegate pushEvent: pEvent];
    }
}

//----------------------------------------------------------------------------------------------------------------------------

- (SInt32) vendorId
{
    return mpDeviceDesc->mVendorId;
}

//----------------------------------------------------------------------------------------------------------------------------

- (SInt32) productId
{
    return mpDeviceDesc->mProductId;
}

//----------------------------------------------------------------------------------------------------------------------------

- (NSString*) deviceType
{
    return NSStringFromClass ([self class]);
}

//----------------------------------------------------------------------------------------------------------------------------

- (uint32_t) getDevicePropertyForKey: (CFStringRef) pKey
{
    IOHIDDeviceRef  pDevice     = self.iohidDeviceRef;
	BOOL            success     = (pDevice != nil);
	CFTypeRef       pProperty   = NULL;
    SInt32          value       = -1;
    
    if (success)
    {
        pProperty   = IOHIDDeviceGetProperty (pDevice, pKey);
        success     = (pProperty != NULL);
    }
    
    if (success)
    {
        success = (CFNumberGetTypeID() == CFGetTypeID (pProperty));
    }
    
    if (success)
    {
        success = CFNumberGetValue ((CFNumberRef) pProperty, kCFNumberSInt32Type, &value);
    }
    else
    {
        value = -1;
    }
    
	return value;
}

//----------------------------------------------------------------------------------------------------------------------------

- (NSString*) getDevicePropertyStringForKey: (CFStringRef) pKey
{
    IOHIDDeviceRef  pDevice     = self.iohidDeviceRef;
    BOOL            success     = (pDevice != nil);
    CFTypeRef       pProperty   = nil;
    NSString*       string      = nil;
    
    if (success)
    {
        pProperty   = IOHIDDeviceGetProperty (pDevice, pKey);
        success     = (pProperty != NULL);
    }
        
    if (success)
    {
        success = (CFStringGetTypeID() == CFGetTypeID (pProperty));
    }
    
    if (success)
    {
        string = (__bridge NSString*) pProperty;
    }
            
    return string;
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) handleInput: (IOHIDValueRef) pValue
{
    IOHIDElementRef         pElement    = IOHIDValueGetElement (pValue);
    const uint32_t          type        = IOHIDElementGetType (pElement);
    const FDHIDElementMap*  pElements   = self.elementMap;
    const uint32_t          typeOffset  = type - pElements[0].mType;

    if (typeOffset < self.elementCount)
    {
        pElements = &(pElements[typeOffset]);
        
        FD_ASSERT (pElements->mType == type);
        
        if (pElements->mpButtons)
        {
            const uint32_t  usage       = IOHIDElementGetUsage (pElement);
            const uint32_t  usageOffset = usage - pElements->mpButtons[0].mUsage;
            
            if (usageOffset < pElements->mNumButtons)
            {
                const FDHIDButtonMap*   pButton = &(pElements->mpButtons[usageOffset]);
                
                FD_ASSERT (pButton->mUsage == usage);
                
                if (pButton->mpEventHandler)
                {
                    pButton->mpEventHandler (self, pButton->mButton, pValue, pElement);
                }
            }
        }
    }
}

//----------------------------------------------------------------------------------------------------------------------------

- (FDHIDElementMap*) elementMap
{
    return mpDeviceDesc->mpElements;
}

//----------------------------------------------------------------------------------------------------------------------------

- (NSUInteger) elementCount
{
    return mpDeviceDesc->mNumElements;
}

//----------------------------------------------------------------------------------------------------------------------------

- (void) flush
{
}

- (BOOL) hasActuator;
{
    return [self actuator] != nil;
}

//----------------------------------------------------------------------------------------------------------------------------

@end

//----------------------------------------------------------------------------------------------------------------------------
