// Part of MeasurementKit <https://measurement-kit.github.io/>.
// MeasurementKit is free software. See AUTHORS and LICENSE for more
// information on the copying conditions.

#import "ResultViewController.h"

@interface ResultViewController ()

@end

@implementation ResultViewController
@synthesize content, testName;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(testName, nil);
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"view_log", nil);
    [self loadScreen];
}

-(void) loadScreen{

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController* userController = [[WKUserContentController alloc] init];

    // Here we sanitize the content. Note: order matters.
    content = [content stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    content = [content stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];

    NSString* MeasurementJSON = [NSString stringWithFormat:@"\n var MeasurementJSON = {  \n"
                                 "get: function() {  \n"
                                 "return "
                                 "'%s';"
                                 "   } \n"
                                 "};", [content UTF8String]]; // Cast to c type string

    WKUserScript* userScript = [[WKUserScript alloc]initWithSource:MeasurementJSON
                                                     injectionTime: WKUserScriptInjectionTimeAtDocumentStart
                                                  forMainFrameOnly:NO];
    [userController addUserScript:userScript];
    configuration.userContentController = userController;
    
    NSString *pathToHtml = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSString *htmlData = [NSString stringWithContentsOfFile:pathToHtml encoding:NSUTF8StringEncoding error:NULL];

    CGRect frame = self.view.frame;
    frame.size.height -= 64;

    //BUG FIX: when alloc the second time the webview goes under top bar
    /*if (self.webView != nil) {
        [self.webView removeFromSuperview];
        //frame.origin.y +=64;
        frame.size.height -= 64;
    }*/
    
    self.webView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    [self.webView loadHTMLString:htmlData baseURL: [NSURL fileURLWithPath:pathToHtml]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    //if it is the first call allow, else deny and open browser
    NSURLRequest *request = navigationAction.request;
    if (!openBrowser){
        decisionHandler(WKNavigationActionPolicyAllow);
        openBrowser = true;
    }
    else {
        decisionHandler(WKNavigationActionPolicyCancel);
        openURL = [request URL];
        NSString *url = [[request URL] absoluteString];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"open_url_alert", @"") message:url delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"") otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
        [alert show];

    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:openURL];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //This screen is hidden for the moment
    if ([[segue identifier] isEqualToString:@"toLog"]){
        LogViewController *vc = (LogViewController * )segue.destinationViewController;
        [vc setLog_file:self.log_file];
    }
}

@end
