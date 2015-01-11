// TerminalKeyboard.m
// MobileTerminal

#import "TerminalKeyboard.h"
#import "UITextInputBase.h"

static const int kControlCharacter = 0x2022;

// This text field is the first responder that intercepts keyboard events and
// copy and paste events.
@interface TerminalKeyInput : UITextInputBase
{
@private
  TerminalKeyboard* keyboard;  
  NSData* backspaceData;

  // UIKeyInput
  UITextAutocapitalizationType autocapitalizationType;
  UITextAutocorrectionType autocorrectionType;
  BOOL enablesReturnKeyAutomatically;
  UIKeyboardAppearance keyboardAppearance;
  UIKeyboardType keyboardType;
  UIReturnKeyType returnKeyType;
  BOOL secureTextEntry;
}

@property (nonatomic, retain) TerminalKeyboard* keyboard;

// https://github.com/hbang/NewTerm/blob/master/Classes/Terminal/TerminalKeyboard.h
@property (nonatomic) BOOL controlKeyMode;
@property (copy) void(^controlKeyChanged)();

// UIKeyInput
@property (nonatomic) UITextAutocapitalizationType autocapitalizationType;
@property (nonatomic) UITextAutocorrectionType autocorrectionType;
@property (nonatomic) BOOL enablesReturnKeyAutomatically;
@property (nonatomic) UIKeyboardAppearance keyboardAppearance;
@property (nonatomic) UIKeyboardType keyboardType;
@property (nonatomic) UIReturnKeyType returnKeyType;
@property (nonatomic, getter=isSecureTextEntry) BOOL secureTextEntry;
@end

@implementation TerminalKeyInput

@synthesize keyboard;
@synthesize autocapitalizationType;
@synthesize autocorrectionType;
@synthesize enablesReturnKeyAutomatically;
@synthesize keyboardAppearance;
@synthesize keyboardType;
@synthesize returnKeyType;
@synthesize secureTextEntry;
@synthesize controlKeyMode;
@synthesize controlKeyChanged;

- (id)init:(TerminalKeyboard*)theKeyboard
{
  self = [super init];
  if (self != nil) {
    keyboard = theKeyboard;
    [self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self setEnablesReturnKeyAutomatically:NO];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"BlackOrWhite"])
        [self setKeyboardAppearance:UIKeyboardAppearanceDark];
    else
        [self setKeyboardAppearance:UIKeyboardAppearanceLight];
      
      if ([[NSUserDefaults standardUserDefaults] boolForKey:@"KeyboardTypeURL"])
        [self setKeyboardType:UIKeyboardTypeURL];
      else
        [self setKeyboardType:UIKeyboardTypeASCIICapable];
      
    [self setReturnKeyType:UIReturnKeyDefault];
    [self setSecureTextEntry:NO];

    // Data to send in response to a backspace.  This is created now so it is
    // not re-allocated on ever backspace event.
    backspaceData = [[NSData alloc] initWithBytes:"\x7F" length:1];    
    controlKeyMode = FALSE;
  }
  return self;
}

- (void)deleteBackward
{
  [[keyboard inputDelegate] receiveKeyboardInput:backspaceData];
}

- (BOOL)hasText
{
  // Make sure that the backspace key always works
  return YES;
}

- (void)insertText:(NSString *)input
{
    int len = 0;
    //char *chr_len = (char *)[input UTF8String];
    
    int size = [input lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
    char chars[size];
    
    //char str[size]; Secret...
    //[input getCString:str maxLength:size encoding:NSUTF8StringEncoding];
    
    // First character is always space (that we set)
    unichar c = [input characterAtIndex:0];
    
if (input.length == 1 && [input canBeConvertedToEncoding:NSASCIIStringEncoding]) {
  if (controlKeyMode) {
    controlKeyMode = NO;
    // Convert the character to a control key with the same ascii name (or
    // just use the original character if not in the acsii range)
    if (c < 0x60 && c > 0x40) {
      // Uppercase (and a few characters nearby, such as escape)
      c -= 0x40;
    } else if (c < 0x7B && c > 0x60) {
      // Lowercase
      c -= 0x60;
    }
      if (controlKeyChanged) controlKeyChanged();
  } else {
    if (c == kControlCharacter) {
      // Control character was pressed.  The next character will be interpred
      // as a control key.
      controlKeyMode = YES;
      return;
    } else if (c == 0x0a) {
      // Convert newline to a carraige return
      c = 0x0d;
    }
      if (controlKeyChanged) controlKeyChanged();
  }
    chars[0] = c;
    len = 1;
} else {
    for (int i = 0; i < input.length; i++, len++) {
        unichar str_c = [input characterAtIndex:i];
        chars[i] = str_c;
    }
}
  // Re-encode as UTF8
    NSString* encoded = [[NSString alloc] initWithBytes:chars
                                                 length:len
                                               encoding:NSUTF8StringEncoding];
  NSData* data = [encoded dataUsingEncoding:NSUTF8StringEncoding];
  [[keyboard inputDelegate] receiveKeyboardInput:data];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  if (action == @selector(copy:)) {
    // Only show the copy menu if we actually have any data selected
    NSMutableData* data = [NSMutableData  dataWithCapacity:0];
    [[keyboard inputDelegate] fillDataWithSelection:data];
    return [data length] > 0;
  }
  if (action == @selector(paste:)) {
    // Only paste if the board contains plain text
    return [[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
  }
  return NO;
}

- (void)copy:(id)sender
{
  NSMutableData* data = [NSMutableData  dataWithCapacity:0];
  [[keyboard inputDelegate] fillDataWithSelection:data];
  UIPasteboard* pb = [UIPasteboard generalPasteboard];
  pb.string = [[NSString alloc] initWithData:data 
                                    encoding:NSUTF8StringEncoding];
}

- (void)paste:(id)sender
{
  UIPasteboard* pb = [UIPasteboard generalPasteboard];
  if (![pb containsPasteboardTypes:UIPasteboardTypeListString]) {
    return;
  }
  NSData* data = [pb.string dataUsingEncoding:NSUTF8StringEncoding];
  [[keyboard inputDelegate] receiveKeyboardInput:data];
}

- (BOOL)becomeFirstResponder
{
  [super becomeFirstResponder];
  return YES;
}

- (BOOL)canBecomeFirstResponder
{
  return YES;
}

@end


@implementation TerminalKeyboard

@synthesize inputDelegate;

- (id)init
{
  self = [super init];
  if (self != nil) {
    [self setOpaque:YES];  
    _inputTextField = [[TerminalKeyInput alloc] init:self];
    [self addSubview:_inputTextField];
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  // Nothing to see here
}

- (BOOL)becomeFirstResponder
{
  // XXX
  return [_inputTextField becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
  return [_inputTextField resignFirstResponder];
}
  
- (void)dealloc {
  [_inputTextField release];
  [super dealloc];
}

@end
