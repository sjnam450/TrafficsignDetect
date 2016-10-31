/*****************************************************************************
 *   ViewController.m
 ******************************************************************************
 *   by Kirill Kornyakov and Alexander Shishkov, 13th May 2013
 ******************************************************************************
 *   Chapter 12 of the "OpenCV for iOS" book
 *
 *   Applying Effects to Live Video shows how to process captured
 *   video frames on the fly.
 *
 *   Copyright Packt Publishing 2013.
 *   http://bit.ly/OpenCV_for_iOS_book
 *****************************************************************************/

#import "ViewController.h"
#import <mach/mach_time.h> 
#import <opencv2/nonfree/nonfree.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/features2d/features2d.hpp>



@interface ViewController ()

@end

@implementation ViewController

@synthesize imageView;
@synthesize startCaptureButton;
@synthesize toolbar;
@synthesize videoCamera;

@synthesize sendMessageBtN;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    cv::initModule_nonfree();

    // Initialize camera
    videoCamera = [[CvVideoCamera alloc]
                   initWithParentView:imageView];
    videoCamera.delegate = self;
    videoCamera.defaultAVCaptureDevicePosition =
                                AVCaptureDevicePositionBack;
    videoCamera.defaultAVCaptureSessionPreset =
                                AVCaptureSessionPreset640x480;
    videoCamera.defaultAVCaptureVideoOrientation =
                                AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 30;
    
    isCapturing = NO;
    
    // Load textures
//    UIImage* resImage = [UIImage imageNamed:@"scratches.png"];
//    UIImageToMat(resImage, params.scratches);
//    
//    resImage = [UIImage imageNamed:@"fuzzy_border.png"];
//    UIImageToMat(resImage, params.fuzzyBorder);
    
    filter = NULL;
    prevTime = mach_absolute_time();
    
    img_left = [UIImage imageNamed:@"left.png"];
    img_right = [UIImage imageNamed:@"right.png"];
    img_uturn = [UIImage imageNamed:@"uturn.png"];
    
    

    [self connectToServer:@"192.168.0.4" :10000];

//    [self connectToServer:@"172.20.10.11" :10000];

    
    
    
    //미리 받아둠
    //cv::Mat traffic_position_left;
    //traffic_position_left =  [self cvMatWithImage:img];
    UIImageToMat(img_left, traffic_position_left);
    UIImageToMat(img_right, traffic_position_right);
    UIImageToMat(img_uturn, traffic_position_uturn);
    
    UIImage *returnImg2 = MatToUIImage(traffic_position_left);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image2222.png"];
    
    // Save image.
    //[UIImagePNGRepresentation(returnImg2) writeToFile:filePath atomically:YES];
    
    //[imageView setImage:returnImg2];
    //keypointsleft;
    
    
    //Descriptor matrices
    //cv::Mat descriptors_object;
    
//    cv::SurfFeatureDetector surf(400);
//    
//    cv::Mat objectMat = traffic_position_left;
//    
//    
//    surf.detect(objectMat,keypointsleft);
//    
//    
//    cv::SurfDescriptorExtractor extractor;
//
//    extractor.compute( objectMat, keypointsleft, descriptors_object );
    
    
    
}
- (UIImage*)loadImage
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:
                      @"test.png" ];
    UIImage* image = [UIImage imageWithContentsOfFile:path];
    
    return image;
}

- (NSInteger)supportedInterfaceOrientations
{
    // Only portrait orientation
    return UIInterfaceOrientationMaskPortrait;
}

-(IBAction)sendMessageserver:(id)sender
{
    NSLog(@"SNED TESTMESSAGE");
    [self sendMessage:@"right"];
    
    
}

-(IBAction)startCaptureButtonPressed:(id)sender
{
    [videoCamera start];
    isCapturing = YES;
    
    params.frameSize = cv::Size(videoCamera.imageWidth,
                                videoCamera.imageHeight);
    
//    if (!filter)
//        filter = new RetroFilter(params);
    
    //[self connectToServer:@"192.168.0.6" :10000];
    
    
}

-(IBAction)stopCaptureButtonPressed:(id)sender
{
    [videoCamera stop];
    isCapturing = NO;
    
    [self disconnect];
}

//TODO: may be remove this code
static double machTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /
                          (double)timebase.denom / 1e9;
}

// Macros for time measurements
#if 1
  #define TS(name) int64 t_##name = cv::getTickCount()
  #define TE(name) printf("TIMER_" #name ": %.2fms\n", \
    1000.*((cv::getTickCount() - t_##name) / cv::getTickFrequency()))
#else
  #define TS(name)
  #define TE(name)
#endif

- (void)processImage:(cv::Mat&)image
{
    

    
    //cv::Mat traffic_position_left;
    cv::Mat hsv_image;
    cv::Mat dst;
    cv::Mat grayforsurf;
    
    cv::cvtColor(image, hsv_image, cv::COLOR_BGR2HSV);
    
     	// Threshold the HSV image, keep only the red pixels
    cv::Mat lower_red_hue_range;
    cv::Mat upper_red_hue_range;
    
    
    cv::inRange(hsv_image, cv::Scalar(0, 100, 100), cv::Scalar(10, 255, 255), lower_red_hue_range);
    cv::inRange(hsv_image, cv::Scalar(160, 100, 100), cv::Scalar(179, 255, 255), upper_red_hue_range);

    cv::Mat red_hue_image;
    cv::addWeighted(lower_red_hue_range, 1.0, upper_red_hue_range, 1.0, 0.0, red_hue_image);

    std::vector<cv::Vec3f> circles_red;
    cv::HoughCircles(red_hue_image, circles_red, CV_HOUGH_GRADIENT, 1, red_hue_image.rows/8, 100, 20, 10, 50);
    //std::cout << "red" <<circles_red.size()<<std::endl;
    
    
    cv::Mat green_hue_range;
    cv::inRange(hsv_image, cv::Scalar(45, 100, 100), cv::Scalar(75, 255, 255), green_hue_range);
    
    
    std::vector<cv::Vec3f> circles_green;
    cv::HoughCircles(green_hue_range, circles_green, CV_HOUGH_GRADIENT, 1, green_hue_range.rows/8, 100, 20, 0, 0);
    //std::cout << "green "<<circles_green.size()<<std::endl;

    
    
    
    if (circles_green.size() > 0) {
       [self sendMessage:@"front"];
        NSLog(@"green\n");
    }
    
    else if (circles_red.size() > 0) {
         [self sendMessage:@"stop"];
        NSLog(@"red\n");
    }
    

    

    
    
    
    cv::Mat  gray_match, gray_left, gray_right, gray_uturn;
//    
//    
    int    match_method = CV_TM_CCOEFF_NORMED;
    
    cv::cvtColor(image, gray_match, cv::COLOR_BGR2GRAY);
    cv::cvtColor(traffic_position_left, gray_left, cv::COLOR_BGR2GRAY);
    cv::cvtColor(traffic_position_right, gray_right, cv::COLOR_BGR2GRAY);
    cv::cvtColor(traffic_position_uturn, gray_uturn, cv::COLOR_BGR2GRAY);
    
    cv::Mat resultMat(gray_match.rows - gray_left.rows + 1, gray_match.cols - gray_left.cols + 1, CV_32FC1);
    cv::Mat resultMat_right(gray_match.rows - gray_right.rows + 1, gray_match.cols - gray_right.cols + 1, CV_32FC1);
    cv::Mat resultMat_uturn(gray_match.rows - gray_uturn.rows + 1, gray_match.cols - gray_uturn.cols + 1, CV_32FC1);
    
    double minVal_left; double maxVal_left;
    double minVal_right; double maxVal_right;
    double minVal_uturn; double maxVal_uturn;
    cv::Point minLoc_left, maxLoc_left, matchLoc_left;
    cv::Point minLoc_right, maxLoc_right, matchLoc_right;
    cv::Point minLoc_uturn, maxLoc_uturn, matchLoc_uturn;


    cv::matchTemplate(gray_match, gray_left, resultMat, match_method);
    cv::matchTemplate(gray_match, gray_right, resultMat_right, match_method);
    cv::matchTemplate(gray_match, gray_uturn, resultMat_uturn, match_method);
    
    //cv::threshold(resultMat, resultMat, 0.7, 1., CV_THRESH_TOZERO);
    
    
    //normalize( resultMat, resultMat, 0, 1, cv::NORM_MINMAX, -1, cv::Mat() );
//    
    cv::minMaxLoc(resultMat, &minVal_left, &maxVal_left, &minLoc_left, &maxLoc_left, cv::Mat() );
    cv::minMaxLoc(resultMat_right, &minVal_right, &maxVal_right, &minLoc_right, &maxLoc_right, cv::Mat() );
    cv::minMaxLoc(resultMat_uturn, &minVal_uturn, &maxVal_uturn, &minLoc_uturn, &maxLoc_uturn, cv::Mat() );
    
    
    if( match_method  == CV_TM_SQDIFF || match_method == CV_TM_SQDIFF_NORMED )  matchLoc_left = minLoc_left;
    else matchLoc_left = maxLoc_left;

    //printf("max value_left : %f\n", maxVal_left);
    printf("max value_right : %f\n", maxVal_right);
    printf("max value_uturn : %f\n", maxVal_uturn);
    ////[self sendMessage:@"left"];
    

//    cv::rectangle(
//                  image,
//                  matchLoc_left,
//                  cv::Point(matchLoc_left.x + traffic_position_left.cols  , matchLoc_left.y + traffic_position_left.rows),
//                  CV_RGB(255,0,0),
//                  3);
//    
//    cv::rectangle(
//                  image,
//                  matchLoc_left,
//                  cv::Point(matchLoc_right.x + traffic_position_right.cols  , matchLoc_right.y + traffic_position_right.rows),
//                  CV_RGB(0,255,0),
//                  3);
//    
//    cv::rectangle(
//                  image,
//                  matchLoc_uturn,
//                  cv::Point(matchLoc_uturn.x + traffic_position_uturn.cols  , matchLoc_uturn.y + traffic_position_uturn.rows),
//                  CV_RGB(0,0,255),
//                  3);

    
    
    
    uint64_t currTime = mach_absolute_time();
    double timeInSeconds = machTimeToSecs(currTime - prevTime);
    prevTime = currTime;
    double fps = 1.0 / timeInSeconds;
    NSString* fpsString =
    [NSString stringWithFormat:@"FPS = %3.2f", fps];
    cv::putText(image, [fpsString UTF8String],
                cv::Point(30, 30), cv::FONT_HERSHEY_COMPLEX_SMALL,
                0.8, cv::Scalar::all(255));
    
    if(maxVal_left >= 0.65) [self sendMessage:@"left"];
    else if(maxVal_right >= 0.65) [self sendMessage:@"right"];
//    else if(maxVal_uturn >= 0.7) {
//        [self sendMessage:@"uturn"];
//    }
    
//    else
//    {
//        [self sendMessage:@"front"];
//    }
    
 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (isCapturing)
    {
        [videoCamera stop];
        
    }
    [self disconnect];
}

- (void)dealloc
{
    videoCamera.delegate = nil;
}

//socket

- (void) sendMessage:(NSString *)message {
    
    NSString *response  = [NSString stringWithFormat:@"%@\n", message];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    //- (NSInteger)write:(const uint8_t *)buffer maxLength:(NSUInteger)len;
    const uint8_t *a = (const uint8_t*)[data bytes];
    [outputStream write:a maxLength:[data length]];
    //[outputStream write:[data bytes] maxLength:[data length]];
    
}

- (void) messageReceived:(NSString *)message {
    
    [messages addObject:message];
    
    //_dataRecievedTextView.text = message;
    //NSLog(@"%@", message);
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    //NSLog(@"stream event %lu", streamEvent);

   //  NSLog(@"stream event %lu", streamEvent);

    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            NSLog(@"connected");
            break;
        case NSStreamEventHasBytesAvailable:
            
            if (theStream == inputStream)
            {
                uint8_t buffer[1024];
                NSInteger len;
                
                while ([inputStream hasBytesAvailable])
                {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0)
                    {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output)
                        {
                            //NSLog(@"server said: %@", output);
                            [self messageReceived:output];
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            //NSLog(@"Stream has space available now");
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"%@",[theStream streamError].localizedDescription);
            break;
            
        case NSStreamEventEndEncountered:
            
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            NSLog(@"disconnected");
            NSLog(@"close stream");
            break;
        default:
            NSLog(@"Unknown event");
    }
    
}

- (void)connectToServer:(NSString*)ip :(int)port {
    
    NSLog(@"Setting up connection to %@ : %i", ip, port);
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef) ip, port, &readStream, &writeStream);
    
    messages = [[NSMutableArray alloc] init];
    
    [self open];
}

- (void)disconnect {
    
    [self close];
}

- (void)open {
    
    NSLog(@"Opening streams.");
    
    outputStream = (__bridge NSOutputStream *)writeStream;
    inputStream = (__bridge NSInputStream *)readStream;
    
    [outputStream setDelegate:self];
    [inputStream setDelegate:self];
    
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [outputStream open];
    [inputStream open];
    
    //_connectedLabel.text = @"Connected";
}

- (void)close {
    NSLog(@"Closing streams.");
    [inputStream close];
    [outputStream close];
    [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
    inputStream = nil;
    outputStream = nil;
    
    //_connectedLabel.text = @"Disconnected";
}


- (cv::Mat)cvMatWithImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


@end
