/*****************************************************************************
 *   ViewController.h
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


#import <UIKit/UIKit.h>
#import <opencv2/highgui/ios.h> 
#import <opencv2/nonfree/nonfree.hpp>
#include <opencv2/features2d/features2d.hpp>
#import "CvEffects/RetroFilter.hpp"

@interface ViewController : UIViewController<CvVideoCameraDelegate, NSStreamDelegate>
{
    CvVideoCamera* videoCamera;
    BOOL isCapturing;
    RetroFilter::Parameters params;
    cv::Ptr<RetroFilter> filter;
    uint64_t prevTime;
    
    UIImage *img_left, *img_right, *img_uturn;
    
    
    //for socket
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    NSInputStream   *inputStream;
    NSOutputStream  *outputStream;
    
    NSMutableArray  *messages;
    
    std::vector<cv::KeyPoint> keypointsleft;
    cv::Mat descriptors_object;
    cv::Mat traffic_position_left, traffic_position_right, traffic_position_uturn;
}

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@property (nonatomic, strong) IBOutlet UIToolbar* toolbar;
@property (nonatomic, weak) IBOutlet
    UIBarButtonItem* startCaptureButton;
@property (nonatomic, weak) IBOutlet
    UIBarButtonItem* stopCaptureButton;

@property (nonatomic, weak) IBOutlet
UIBarButtonItem* sendMessageBtN;


-(IBAction)startCaptureButtonPressed:(id)sender;
-(IBAction)stopCaptureButtonPressed:(id)sender;

@end
