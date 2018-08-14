#ifndef _QL_H_
#define _QL_H_

#include <stdint.h>

#define CONTENT_TYPE_PLAIN_TEXT 0
#define CONTENT_TYPE_PDF 1
#define CONTENT_TYPE_HTML 2
#define CONTENT_TYPE_XML 3
#define CONTENT_TYPE_RTF 4
#define CONTENT_TYPE_MOVIE 5
#define CONTENT_TYPE_AUDIO 6
#define CONTENT_TYPE_PNG_IMAGE 7

// https://developer.apple.com/documentation/quicklook/quicklook_constants
#define PREVIEW_PROPERTY_DISPLAY_NAME 0 // kQLPreviewPropertyDisplayNameKey
#define PREVIEW_PROPERTY_WIDTH 1 // kQLPreviewPropertyWidthKey
#define PREVIEW_PROPERTY_HEIGHT 2 // kQLPreviewPropertyHeightKey

// #define VALUE_TYPE_UTF8_STRING 0
// #define VALUE_TYPE_INT64 1

typedef struct {
    int key;
    // int value_type;
    char* string_value;
    int64_t int64_value;
} dict_pair;

void *generatePreviewForURL(char *url, unsigned long *outLen, int *contentType, dict_pair **properties, int *propertyCount);
void *generateThumbnailForURL(char *url, unsigned long *outLen);

#endif
