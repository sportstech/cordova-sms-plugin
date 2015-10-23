#import "Sms.h"

@implementation Sms
@synthesize callbackID;

// - (CDVPlugin *)initWithWebViewEngine:(CDVWebViewEngineProtocol *)theWebView {
//     self = (Sms *)[super initWithWebViewEngine:theWebView];
//     return self;
// }

- (void)send:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        self.callbackID = command.callbackId;
        
        if(![MFMessageComposeViewController canSendText]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notice"
                                                            message:@"SMS Text not available."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil
                                  ];

            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
            return;
        }
        
        MFMessageComposeViewController *composeViewController = [[MFMessageComposeViewController alloc] init];
        composeViewController.messageComposeDelegate = self;
        
        NSString* body = [command.arguments objectAtIndex:1];
        if (body == (id)[NSNull null] || body.length == 0 ) body = @"Create Message...";
        BOOL replaceLineBreaks = [[command.arguments objectAtIndex:3] boolValue];
        if (replaceLineBreaks) {
            body = [body stringByReplacingOccurrencesOfString: @"\\n" withString: @"\n"];
        }
        [composeViewController setBody:body];
        
        NSArray* recipients = [command.arguments objectAtIndex:0];
        [composeViewController setRecipients:recipients];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.viewController presentViewController:composeViewController animated:YES completion:nil];
        });
    }];
}

#pragma mark - MFMessageComposeViewControllerDelegate Implementation
// Dismisses the composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    // Notifies users about errors associated with the interface
    int webviewResult = 0;
    NSString* message = @"";
    
    switch(result) {
        case MessageComposeResultCancelled:
            webviewResult = 0;
            message = @"Message cancelled.";
            break;
        case MessageComposeResultSent:
            webviewResult = 1;
            message = @"Message sent.";
            break;
        case MessageComposeResultFailed:
            webviewResult = 2;
            message = @"Message failed.";
            break;
        default:
            webviewResult = 3;
            message = @"Unknown error.";
            break;
    }
    
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    
    if(webviewResult == 1) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsString:message];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsString:message];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
    }
}

@end
