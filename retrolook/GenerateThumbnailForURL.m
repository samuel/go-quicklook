#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include "ql.h"

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize) {
	@autoreleasepool {
        unsigned long dataLen;
        void *data = generateThumbnailForURL((char *)[[(__bridge NSURL *)url absoluteString] UTF8String], &dataLen);
        if (data == nil) {
            // TODO: are the following lines necessary? Maybe if overriding all UTI in plist (public.image)
            // QLThumbnailRequestSetImageAtURL(thumbnail, url, NULL);
            return kQLReturnNoError;
        }
        if (QLThumbnailRequestIsCancelled(thumbnail)) {
            return kQLReturnNoError;
        }

        CFDictionaryRef properties = NULL;
        CFDataRef dataRef = (__bridge CFDataRef)[NSData dataWithBytesNoCopy:data length:dataLen freeWhenDone:YES];
        CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData(dataRef);
        CGImageRef image = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
        QLThumbnailRequestSetImage(thumbnail, image, properties);
        CGImageRelease(image);
	}
    // TODO: are the following lines necessary? Maybe if overriding all UTI in plist (public.image)
    // QLThumbnailRequestSetImageAtURL(thumbnail, url, NULL);
	return kQLReturnNoError;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail) {
}
