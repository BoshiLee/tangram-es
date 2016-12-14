#ifdef PLATFORM_IOS

#import <UIKit/UIKit.h>
#import <utility>
#import <cstdio>
#import <cstdarg>
#import <fstream>
#import <regex>
#import <iostream>

#import "TGMapViewController.h"
#import "TGFontConverter.h"
#import "TGHttpHandler.h"
#import "platform_ios.h"
#import "log.h"

static TGMapViewController* viewController;
static NSBundle* tangramFramework;

void init(TGMapViewController* _controller) {

    viewController = _controller;

    // Get handle to tangram framework
    tangramFramework = [NSBundle bundleWithIdentifier:@"com.mapzen.tangramMap"];
}

void logMsg(const char* fmt, ...) {

    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);

}

void requestRender() {

    [viewController renderOnce];

}

void setContinuousRendering(bool _isContinuous) {

    [viewController setContinuous:_isContinuous];

}

bool isContinuousRendering() {

    return [viewController continuous];

}

std::string resolvePath(const char* path) {

    const char* base = [[[[NSBundle mainBundle] resourceURL] absoluteString] UTF8String];

    return Tangram::Url(path).resolved(base).string();
}

std::string stringFromFile(const char* path) {

    NSURL* url = [NSURL URLWithString: [NSString stringWithUTF8String:path]];
    NSString* str = [NSString stringWithContentsOfFile:[url path]
                                          usedEncoding:NULL
                                                 error:NULL];

    if (str == nil) {
        LOGW("Failed to read file at path: %s\n", [path UTF8String]);
        return std::string();
    }

    return std::string([str UTF8String]);
}

unsigned char* bytesFromFile(const char* path, size_t& size) {

    NSURL* url = [NSURL URLWithString: [NSString stringWithUTF8String:path]];
    NSMutableData* data = [NSMutableData dataWithContentsOfFile:[url path]];

    if (data == nil) {
        LOGW("Failed to read file at path: %s\n", path);
        size = 0;
        return nullptr;
    }

    size = data.length;
    unsigned char* ptr = (unsigned char*)malloc(size);
    [data getBytes:ptr length:size];

    return ptr;
}

unsigned char* loadUIFont(UIFont* _font, size_t* _size) {

    CGFontRef fontRef = CGFontCreateWithFontName((CFStringRef)_font.fontName);

    if (!fontRef) {
        *_size = 0;
        return nullptr;
    }

    unsigned char* data = [TGFontConverter fontDataForCGFont:fontRef size:_size];

    CGFontRelease(fontRef);

    if (!data) {
        LOG("CoreGraphics font failed to decode");

        *_size = 0;
        return nullptr;
    }

    return data;
}

std::vector<FontSourceHandle> systemFontFallbacksHandle() {
    NSArray* fallbacks = [UIFont familyNames];

    std::vector<FontSourceHandle> handles;

    for (id fallback in fallbacks) {

        UIFont* font = [UIFont fontWithName:fallback size:1.0];

        size_t dataSize = 0;
        auto cdata = loadUIFont(font, &dataSize);

        if (!cdata) { continue; }

        FontSourceHandle fontSourceHandle = [cdata, dataSize](size_t* _size) -> unsigned char* {
            *_size = dataSize;

            return cdata;
        };

        handles.push_back(fontSourceHandle);
    }

    return handles;
}

unsigned char* systemFont(const std::string& _name, const std::string& _weight, const std::string& _face, size_t* _size) {

    static std::map<int, CGFloat> weightTraits = {
        {100, UIFontWeightUltraLight},
        {200, UIFontWeightThin},
        {300, UIFontWeightLight},
        {400, UIFontWeightRegular},
        {500, UIFontWeightMedium},
        {600, UIFontWeightSemibold},
        {700, UIFontWeightBold},
        {800, UIFontWeightHeavy},
        {900, UIFontWeightBlack},
    };

    static std::map<std::string, UIFontDescriptorSymbolicTraits> fontTraits = {
        {"italic", UIFontDescriptorTraitItalic},
        {"oblique", UIFontDescriptorTraitItalic},
        {"bold", UIFontDescriptorTraitBold},
        {"expanded", UIFontDescriptorTraitExpanded},
        {"condensed", UIFontDescriptorTraitCondensed},
        {"monospace", UIFontDescriptorTraitMonoSpace},
    };

    UIFont* font = [UIFont fontWithName:[NSString stringWithUTF8String:_name.c_str()] size:1.0];

    if (font == nil) {
        // Get the default system font
        if (_weight.empty()) {
            font = [UIFont systemFontOfSize:1.0];
        } else {
            int weight = std::atoi(_weight.c_str());

            // Default to 400 boldness
            weight = (weight == 0) ? 400 : weight;

            // Map weight value to range [100..900]
            weight = std::min(std::max(100, (int)floor(weight / 100.0 + 0.5) * 100), 900);

            font = [UIFont systemFontOfSize:1.0 weight:weightTraits[weight]];
        }
    }

    if (_face != "normal") {
        UIFontDescriptorSymbolicTraits traits;
        UIFontDescriptor* descriptor = [font fontDescriptor];

        auto it = fontTraits.find(_face);
        if (it != fontTraits.end()) {
            traits = it->second;

            // Create a new descriptor with the symbolic traits
            descriptor = [descriptor fontDescriptorWithSymbolicTraits:traits];

            if (descriptor != nil) {
                font = [UIFont fontWithDescriptor:descriptor size:1.0];
            }
        }
    }

    return loadUIFont(font, _size);
}

bool startUrlRequest(const std::string& _url, UrlCallback _callback) {

    TGHttpHandler* httpHandler = [viewController httpHandler];

    if (!httpHandler) {
        return false;
    }

    DownloadCompletionHandler handler = ^void (NSData* data, NSURLResponse* response, NSError* error) {

        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;

        int statusCode = [httpResponse statusCode];

        std::vector<char> rawDataVec;

        if (error != nil) {

            LOGE("Response \"%s\" with error \"%s\".", response, [error.localizedDescription UTF8String]);

        } else if (statusCode < 200 || statusCode >= 300) {

            LOGE("Unsuccessful status code %d: \"%s\" from: %s",
                statusCode,
                [[NSHTTPURLResponse localizedStringForStatusCode: statusCode] UTF8String],
                [response.URL.absoluteString UTF8String]);
            _callback(std::move(rawDataVec));

        } else {

            int dataLength = [data length];
            rawDataVec.resize(dataLength);
            memcpy(rawDataVec.data(), (char *)[data bytes], dataLength);
            _callback(std::move(rawDataVec));

        }
    };

    NSString* url = [NSString stringWithUTF8String:_url.c_str()];
    [httpHandler downloadRequestAsync:url completionHandler:handler];

    return true;
}

void cancelUrlRequest(const std::string& _url) {

    TGHttpHandler* httpHandler = [viewController httpHandler];

    if (!httpHandler) {
        return;
    }

    NSString* url = [NSString stringWithUTF8String:_url.c_str()];
    [httpHandler cancelDownloadRequestAsync:url];
}

void setCurrentThreadPriority(int priority) {}

void initGLExtensions() {}

#endif //PLATFORM_IOS
