#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include "ql.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options) {
    @autoreleasepool {
        unsigned long dataLen;
        CFStringRef contentType;
        int ctype;
        dict_pair* properties;
        int propertyCount;
        void *data = generatePreviewForURL((char *)[[(__bridge NSURL *)url absoluteString] UTF8String], &dataLen, &ctype, &properties, &propertyCount);
        if (data == nil) {
            return kQLReturnNoError;
        }

        if (QLPreviewRequestIsCancelled(preview)) {
            return kQLReturnNoError;
        }

        switch (ctype) {
        case CONTENT_TYPE_PNG_IMAGE:
            contentType = kUTTypeImage;
            break;
        case CONTENT_TYPE_PDF:
            contentType = kUTTypePDF;
            break;
        case CONTENT_TYPE_HTML:
            contentType = kUTTypeHTML;
            break;
        case CONTENT_TYPE_XML:
            contentType = kUTTypeXML;
            break;
        case CONTENT_TYPE_PLAIN_TEXT:
            contentType = kUTTypePlainText;
            break;
        case CONTENT_TYPE_RTF:
            contentType = kUTTypeRTF;
            break;
        case CONTENT_TYPE_MOVIE:
            contentType = kUTTypeMovie;
            break;
        case CONTENT_TYPE_AUDIO:
            contentType = kUTTypeAudio;
            break;
        default:
            contentType = kUTTypePlainText;
        }

        CFDictionaryRef qlProperties = NULL;
        if (properties != NULL) {
            if (propertyCount > 0) {
                CFTypeRef *keys = malloc(sizeof(CFTypeRef)*propertyCount);
                CFTypeRef *values = malloc(sizeof(CFTypeRef)*propertyCount);
                for(int i = 0; i < propertyCount; i++) {
                    switch (properties[i].key) {
                    case PREVIEW_PROPERTY_DISPLAY_NAME:
                        keys[i] = kQLPreviewPropertyDisplayNameKey;
                        values[i] = CFStringCreateWithCString(kCFAllocatorDefault, properties[i].string_value, kCFStringEncodingUTF8);
                        free(properties[i].string_value);
                        break;
                    case PREVIEW_PROPERTY_WIDTH:
                        keys[i] = kQLPreviewPropertyWidthKey;
                        values[i] = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &properties[i].int64_value);
                        break;
                    case PREVIEW_PROPERTY_HEIGHT:
                        keys[i] = kQLPreviewPropertyHeightKey;
                        values[i] = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &properties[i].int64_value);
                        break;
                    default:
                        printf("Invalid property key %d\n", properties[i].key);
                        propertyCount--;
                        i--;
                    }
                }
                qlProperties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, propertyCount, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
                for(int i = 0; i < propertyCount; i++) {
                    if (values[i] != NULL) {
                        CFRelease(values[i]);
                    }
                }
                free(keys);
                free(values);
            }
            free(properties);
        }

        CFDataRef dataRef = (__bridge CFDataRef)[NSData dataWithBytesNoCopy:data length:dataLen freeWhenDone:YES];
        if (ctype == CONTENT_TYPE_PNG_IMAGE) {
            CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData(dataRef);
            CGImageRef image = CGImageCreateWithPNGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
            CGSize size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
            CGContextRef ctxt = QLPreviewRequestCreateContext(preview, size, true, qlProperties);
            CGContextDrawImage(ctxt, CGRectMake(0, 0, size.width, size.height), image);
            QLPreviewRequestFlushContext(preview, ctxt);
            CGContextRelease(ctxt);
            CGImageRelease(image);
        } else {
            QLPreviewRequestSetDataRepresentation(preview, dataRef, contentType, qlProperties);
        }
        if (qlProperties != NULL) {
            CFRelease(qlProperties);
        }
    }
    return kQLReturnNoError;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview) {
}
