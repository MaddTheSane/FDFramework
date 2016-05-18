//----------------------------------------------------------------------------------------------------------------------------
//
// "FDPreferences.h"
//
// Written by:	Axel 'awe' Wefers			[mailto:awe@fruitz-of-dojo.de].
//				©2001-2012 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
//----------------------------------------------------------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>

//----------------------------------------------------------------------------------------------------------------------------

NS_ASSUME_NONNULL_BEGIN

@interface FDPreferences : NSObject

- (instancetype) init UNAVAILABLE_ATTRIBUTE;

+ (FDPreferences*) sharedPrefs;

- (void) registerDefaults: (NSDictionary<NSString*,id>*) dictionary;
- (void) registerDefaultObject: (NSObject*) object forKey: (NSString*) key;

- (void) setObject: (nullable id) object forKey: (NSString*) key;

- (BOOL) boolForKey: (NSString*) key;
- (NSInteger) integerForKey: (NSString*) key;
- (nullable NSString*) stringForKey: (NSString*) key;
- (nullable NSArray*) arrayForKey: (NSString*) key;

- (BOOL) synchronize;

@end

NS_ASSUME_NONNULL_END

//----------------------------------------------------------------------------------------------------------------------------
