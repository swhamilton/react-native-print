//  Created by Christopher Dro on 9/4/15.
// Modifed by Scott hamilton on 5/1/17

#import "RNPrint.h"
#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTUIManager.h>
#import <React/RCTUtils.h>

#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad

@interface RNPrint () <UIPrinterPickerControllerDelegate>
@end

@implementation RNPrint

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}


RCT_EXPORT_METHOD(print:(NSString *)filePath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    NSData *printData = [NSData dataWithContentsOfFile:filePath];
    UIPrintInteractionController *printInteractionController = [UIPrintInteractionController sharedPrintController];
    printInteractionController.delegate = self;
    
    // Create printing info
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = [filePath lastPathComponent];
    printInfo.duplex = UIPrintInfoDuplexLongEdge;
    
    printInteractionController.printInfo = printInfo;
    printInteractionController.showsPageRange = YES;
    printInteractionController.printingItem = printData;
    
    // Completion handler
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if (!completed && error) {
            NSLog(@"Printing could not complete because of error: %@", error);
            reject(RCTErrorUnspecified, nil, RCTErrorWithMessage(error.description));
        } else {
            resolve(completed ? printInfo.jobName : nil);
        }
    };
    
    [printInteractionController presentAnimated:YES completionHandler:completionHandler];
}

RCT_EXPORT_METHOD(selectPrinter:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    
    // Create the printer controller
    UIPrinterPickerController *printPicker = [UIPrinterPickerController printerPickerControllerWithInitiallySelectedPrinter:nil];
    
    // Create the react native view controller (so we can attach our printer selection popup to a view on iPads
    UIViewController *controller = RCTPresentedViewController();
    
    // Get screen size for positioning the dialog (on iPads)
    CGRect ScreenSize=[[UIScreen mainScreen] bounds];
    NSInteger dialogWidth = 100;
    NSInteger dialogHeight = 100;
    NSInteger width = ScreenSize.size.width;
    NSInteger height = ScreenSize.size.height;
    NSInteger xPos = (width / 2) - (dialogWidth/2);
    NSInteger yPos = (height / 2) - (dialogHeight/2);
    CGRect rect = CGRectMake(xPos, yPos, dialogWidth, dialogHeight);
    
    // Declare the completion block when the user has either picked a printer or canceled
    void (^completion)(UIPrinterPickerController *, BOOL, NSError *) = ^(UIPrinterPickerController *printerPicker, BOOL userDidSelect, NSError *error)
    {
        if (userDidSelect)
        {
            //User selected the item in the UIPrinterPickerController and got the printer details.
            [UIPrinterPickerController printerPickerControllerWithInitiallySelectedPrinter:printerPicker.selectedPrinter];
            
            //Here you will get the printer and printer details.ie,
            // printerPicker.selectedPrinter, printerPicker.selectedPrinter.displayName, printerPicker.selectedPrinter.URL etc. So you can display the printer name in your label text or button title.
            
            NSLog(@"%@", printerPicker.selectedPrinter.displayName);
            NSDictionary *printerInfo = @{
                                          @"name" : printerPicker.selectedPrinter.displayName,
                                          @"url" : userDidSelect ? printerPicker.selectedPrinter.URL.absoluteString: nil};
            
            resolve(userDidSelect ?printerInfo: nil);
            
        }
    };
    
    
    if ( IDIOM == IPAD ) {
        /* Device is iPad */
        [printPicker presentFromRect:(CGRect)rect inView:(UIView *)controller.view animated:YES completionHandler:
         completion];
        
    } else {
        /* Device is iPhone/iPod */
        [printPicker presentAnimated:YES completionHandler:completion];
        
    }
    
    
}

RCT_EXPORT_METHOD(printWithoutDialog:(NSString *)filePath
                  printerLocation: (NSString *)printerLocation
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    NSData *printData = [NSData dataWithContentsOfFile:filePath];
    UIPrintInteractionController *printInteractionController = [UIPrintInteractionController sharedPrintController];
    printInteractionController.delegate = self;
    
    // Create printer from URL
    NSURL *printerURL = [NSURL URLWithString:printerLocation];
    UIPrinter *printer = [UIPrinter printerWithURL:printerURL];
    
    // Create printing info
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = [filePath lastPathComponent];
    printInfo.duplex = UIPrintInfoDuplexLongEdge;
    
    printInteractionController.printInfo = printInfo;
    printInteractionController.showsPageRange = YES;
    printInteractionController.printingItem = printData;
    
    [printInteractionController printToPrinter:printer completionHandler:^(UIPrintInteractionController *controller, BOOL isPrinted, NSError *error) {
        if (isPrinted) {
            resolve(isPrinted ? @"Printed!" : nil);
        } else {
            NSLog(@"Printing could not complete because of error: %@", error);
            reject(RCTErrorUnspecified, nil, RCTErrorWithMessage(error.description));
        }
    }];

}


#pragma mark - UIPrintInteractionControllerDelegate

-(UIViewController*)printInteractionControllerParentViewController:(UIPrintInteractionController*)printInteractionController  {
    UIViewController *result = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (result.presentedViewController) {
        result = result.presentedViewController;
    }
    return result;
}

-(void)printInteractionControllerWillDismissPrinterOptions:(UIPrintInteractionController*)printInteractionController {}

-(void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController*)printInteractionController {}

-(void)printInteractionControllerWillPresentPrinterOptions:(UIPrintInteractionController*)printInteractionController {}

-(void)printInteractionControllerDidPresentPrinterOptions:(UIPrintInteractionController*)printInteractionController {}

-(void)printInteractionControllerWillStartJob:(UIPrintInteractionController*)printInteractionController {}

-(void)printInteractionControllerDidFinishJob:(UIPrintInteractionController*)printInteractionController {}

@end
