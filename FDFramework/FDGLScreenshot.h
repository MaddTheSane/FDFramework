//----------------------------------------------------------------------------------------------------------------------------
//
// "FDGLScreenshot.h" - Save screenshots (of the current OpenGL context) to various image formats.
//
// Written by:	Axel 'awe' Wefers			[mailto:awe@fruitz-of-dojo.de].
//				©2001-2011 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
//----------------------------------------------------------------------------------------------------------------------------

#import <FruitzOfDojo/FDScreenshot.h>

//----------------------------------------------------------------------------------------------------------------------------

NS_ASSUME_NONNULL_BEGIN

@interface FDGLScreenshot : FDScreenshot

- (instancetype) init UNAVAILABLE_ATTRIBUTE;

+ (BOOL) writeToFile: (NSString*) path ofType: (NSBitmapImageFileType) fileType;
+ (BOOL) writeToBMP: (NSString*) path;
+ (BOOL) writeToGIF: (NSString*) path;
+ (BOOL) writeToJPEG: (NSString*) path;
+ (BOOL) writeToPNG: (NSString*) path;
+ (BOOL) writeToTIFF: (NSString*) path;

@end

NS_ASSUME_NONNULL_END

//----------------------------------------------------------------------------------------------------------------------------
