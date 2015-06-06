#import <ReactiveCocoa/ReactiveCocoa.h>
#import <MessageUI/MessageUI.h>
#import <StoreKit/SKProduct.h>
#import "SFProductManager.h"
#import "SFSettingsViewController.h"
#import "SFUserDefaultsHelper.h"
#import "SFConstants.h"

@interface SFSettingsViewController ()
@property (nonatomic, strong) SFUserDefaultsHelper *userDefaultsHelper;
@property (nonatomic, strong) SFProductManager *productsManager;
@property (strong, nonatomic) IBOutlet UITableViewCell *writeAReviewCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *tellAFriendCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *tipJarCell;
@property (strong, nonatomic) IBOutlet UILabel *tipJarProductNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *tipJarProductPriceLabel;

@end

@implementation SFSettingsViewController

#pragma mark - Private

// Called when the user purchases the "Remove Ads" in-app purchase
- (void)removeAds {
    // Records an NSUserDefault boolean to ensure that this setting is persistant for multiple launches of the application
    [self.userDefaultsHelper setBoolean:YES forKey:kAdsRemovedUserDefaultBoolean];
}

#pragma mark - UITableViewDataSource Delegate

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.productsManager = [SFProductManager sharedManager];
    
    // Only request product meta-data to display here if the user is able to purchase in-App purchases
    if([self.productsManager canMakePayments]){
        @weakify(self)
        RAC(self.tipJarProductNameLabel, text) = RACObserve(self.productsManager, removeAdsProductLocalizedTitle);
        RAC(self.tipJarProductPriceLabel, text) = [RACObserve(self.productsManager, removeAdsProductLocalizedPrice) map:^id(NSString *price) {
            @strongify(self);
            if (self.productsManager.removeAdsProductPurchased) {
                return NSLocalizedString(@"Purchased", "Indicator that the In-App purchase has been purchased");
            }
            return price;
        }];
    }
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)updateDisplayedSessionInformation:(NSNotification *)notification {
  [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate Methods

// Callback function which is called when a user selects a row of the table view
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
  if(cell == self.tipJarCell) {
      // Begin the payment process for the In-App purchase if it hasn't been bought, and the
      // user is able to pay for purchases
      if ([[SFProductManager sharedManager] canMakePayments] && ![self.userDefaultsHelper getBooleanForKey:kAdsRemovedUserDefaultBoolean]) {
          [[SFProductManager sharedManager] purchaseAdRemovalProduct];
      }
  } else if(cell == self.writeAReviewCell) {
    // Use a compose screen if possible? Or, send the user to the application's Store page
  } else if(cell == self.tellAFriendCell) {
    // Display a pre-composed compose screen to be used to send an e-mail to a friend
    [self displayEmailComposeView];
  }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - SFSettingsViewController Unique Methods

// Displays an e-mail compose view with most information pre-filled in to be sent to
// a friend as an invitation to use the applicaiton
- (void)displayEmailComposeView {
  if ([MFMailComposeViewController canSendMail]) {
      // Initialize and define the content for the mail compose view controller which will be displayed to the user
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    mailer.mailComposeDelegate = self;
    [mailer setSubject:@"An Invitation to try Significant Figures Calculator"];
    NSString *emailBody = @"Hey! I've recently stumbled upon this great application! Want to give it a try?";
    [mailer setMessageBody:emailBody isHTML:NO];
    
    // Show the mail composition view controller
    [self presentViewController:mailer animated:YES completion:nil];
      
  } else {
      // In the event that mail isn't set up on the device, show an alert informing the user of this
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                    message:@"Your device doesn't support sending e-mail"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];
  }
}

@end
