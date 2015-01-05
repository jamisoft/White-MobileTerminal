// PreferencesViewController.m
// MobileTerminal

#import "PreferencesViewController.h"
#import "RotationController.h"

@implementation PreferencesViewController

@synthesize navigationController;
@synthesize menuSettingsController;
@synthesize gestureSettingsController;
@synthesize fontSettingsController;
@synthesize themeSettingsController;
@synthesize aboutController;

#pragma mark -
#pragma mark Initialization

- (void)viewDidLoad
{
  [super viewDidLoad];
  sections = [[NSMutableArray alloc] init];
  controllers = [[NSMutableArray alloc] init];
  [sections addObject:@"Shortcut Menu"];
  [sections addObject:@"Gestures"];
  [sections addObject:@"Themes"];
  [sections addObject:@"Fonts"];
  [sections addObject:@"About"];
  [controllers addObject:menuSettingsController];
  [controllers addObject:gestureSettingsController];
  [controllers addObject:themeSettingsController];
  [controllers addObject:fontSettingsController];
  [controllers addObject:aboutController];
    
  self.navigationItem.title = @"Top";
    
  /* Delete cell separator */
  //self.tableView.SeparatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)dealloc
{
  [super dealloc];
  [sections dealloc];
  [controllers dealloc];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [sections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSUInteger index = [indexPath indexAtPosition:1];  
  NSString* itemTitle = [sections objectAtIndex:index];
  
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:itemTitle] autorelease];
    cell.textLabel.text = itemTitle;
    if ([controllers objectAtIndex:index] != nil) {
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.tableView.backgroundColor = [UIColor whiteColor]; // Background Color
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSUInteger index = [indexPath indexAtPosition:1];  
  UIViewController* itemController = [controllers objectAtIndex:index];
  [self.navigationController pushViewController:itemController animated:YES];
  itemController.navigationItem.title = [sections objectAtIndex:index];
}

@end

