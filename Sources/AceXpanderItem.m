// -----------------------------------------------------------------------------
// AceXpander - a Mac OS X graphical user interface to the unace command line utility
//
// Copyright (C) 2004 Patrick Näf
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// To view the GNU General Public License, please choose the menu item
// Help:GNU General Public License, or see the file COPYING inside the
// application bundle.
//
// The author of this program can be contacted by email at
// acexpander@herzbube.ch
// -----------------------------------------------------------------------------


// Project includes
#import "AceXpanderItem.h"
#import "AceXpanderContentItem.h"
#import "AceXpanderModel.h"
#import "AceXpanderGlobals.h"


/// @brief This category declares private methods for the AceXpanderItem class. 
@interface AceXpanderItem(Private)
- (id) init;
- (void) dealloc;
- (void) parseMessageStdout;
- (int) numberOfRowsInTableView:(NSTableView*)aTableView;
- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex;
- (void) updateIcon;
@end


@implementation AceXpanderItem

// -----------------------------------------------------------------------------
/// @brief This initializer always returns @e nil.
// -----------------------------------------------------------------------------
- (id) init
{
  // Invoke designated initializer, which will always return nil
  return [self initWithFile:nil model:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes an AceXpanderItem object representing the file named
/// @a fileName. The AceXpanderItem object cooperates with @ theModel.
///
/// If either of the arguments is @e nil, the AceXpanderItem cannot be
/// initialized and this method returns @e nil.
///
/// @note This is the designated initializer of AceXpanderItem.
// -----------------------------------------------------------------------------
- (id) initWithFile:(NSString*)aFileName model:(AceXpanderModel*)theModel
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  else if (! aFileName)
  {
    NSString* errorDescription = @"The file name specified for AceXpanderItem::initWithFile:model:() is nil.";
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification object:errorDescription];
    [self release];
    return nil;
  }
  else if (! theModel)
  {
    NSString* errorDescription = @"The AceXpanderModel instance specified for AceXpanderItem::initWithFile:model:() is nil.";
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification object:errorDescription];
    [self release];
    return nil;
  }

  // Do ***NOT*** retain the model, otherwise we get a "retain cycle" (i.e.
  // the model retains this item, and this item retains the model)
  m_theModel = theModel;
  m_contentItemList = [[NSMutableArray array] retain];
  m_state = QueuedState;

  // Do not invoke setFileName; we don't want any notifications to be posted
  // during initialization
  m_fileName = [aFileName retain];
  // Have to update the icon ourselves because we don't use setFileName
  [self updateIcon];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this AceXpanderItem object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // When the array is deallocated, it releases all items for us
  if (m_contentItemList)
    [m_contentItemList autorelease];
  if (m_fileName)
    [m_fileName autorelease];
  if (m_messageStdout)
    [m_messageStdout autorelease];
  if (m_messageStderr)
    [m_messageStderr autorelease];
  if (m_icon)
    [m_icon autorelease];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns the name of the file that this AceXpanderItem represents.
// -----------------------------------------------------------------------------
- (NSString*) fileName
{
  if (m_fileName)
    return [[m_fileName retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Sets the name of the file that this AceXpanderItem represents.
///
/// Invoking this method resets the state of this AceXpanderItem to #QueuedState
/// and generally lets the item appear as if it had been initialized right after
/// object creation.
// -----------------------------------------------------------------------------
- (void) setFileName:(NSString*)aFileName
{
  if (m_fileName == aFileName)
    return;
  if (m_fileName)
    [m_fileName autorelease];
  if (aFileName)
    m_fileName = [aFileName retain];
  else
    m_fileName = nil;
  [self updateIcon];

  // If this AceXpanderItem represents a different file, its internal state
  // is reset to Queued and it loses all memory to the previous file
  m_state = QueuedState;
  if (m_contentItemList)
    [m_contentItemList removeAllObjects];
  if (m_messageStdout)
  {
    [m_messageStdout autorelease];
    m_messageStdout = nil;
  }
  if (m_messageStderr)
  {
    [m_messageStderr autorelease];
    m_messageStderr = nil;
  }

  // Notify others that state has changed
  if (m_theModel)
    [m_theModel itemHasChanged:self];
  NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter postNotificationName:updateResultWindowNotification object:nil];
  [defaultCenter postNotificationName:updateContentListDrawerNotification object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Returns an icon that can be used to represent this AceXpanderItem.
// -----------------------------------------------------------------------------
- (NSImage*) icon
{
  if (m_icon)
    return [[m_icon retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the state of this AceXpanderItem (see #AceXpanderItemState)
// -----------------------------------------------------------------------------
- (int) state
{
  return m_state;
}

// -----------------------------------------------------------------------------
/// @brief Returns the state of this AceXpanderItem as a string.
// -----------------------------------------------------------------------------
- (NSString*) stateAsString
{
  return [AceXpanderItem stringForState:m_state];
}

// -----------------------------------------------------------------------------
/// @brief Returns the string representation of @a state. It is expected that
/// @a state is an element from the enumeration AceXpanderItemState.
// -----------------------------------------------------------------------------
+ (NSString*) stringForState:(int)state
{
  switch (state)
  {
    case QueuedState:
      return @"Queued";
    case SkipState:
      return @"Skip";
    case ProcessingState:
      return @"Processing";
    case AbortedState:
      return @"Aborted";
    case SuccessState:
      return @"Success";
    case FailureState:
      return @"Failure";
    default:
      return @"Undefined";
  }
}

// -----------------------------------------------------------------------------
/// @brief Changes the state of this AceXpanderItem to @a state.
// -----------------------------------------------------------------------------
- (void) setState:(int)state
{
  if (QueuedState != state && SkipState != state && ProcessingState != state
      && AbortedState != state && SuccessState != state && FailureState != state)
  {
    NSString* errorDescription = [NSString stringWithFormat:@"Unsupported state %d", state];
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification object:errorDescription];
    return;
  }
  m_state = state;

  [m_theModel itemHasChanged:self];
}

// -----------------------------------------------------------------------------
/// @brief Returns the standard output message of the most recent command that
/// operated on this AceXpanderItem.
///
/// Returns @e nil if no command has operated on this AceXpanderItem.
// -----------------------------------------------------------------------------
- (NSString*) messageStdout
{
  if (m_messageStdout)
    return [[m_messageStdout retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Sets the standard output message of the most recent command that
/// operated on this AceXpanderItem.
///
/// @a containsListing is true if @a aMessage contains a listing of the
/// archive's contents.
// -----------------------------------------------------------------------------
- (void) setMessageStdout:(NSString*)aMessage containsListing:(BOOL)containsListing;
{
  if (m_messageStdout == aMessage)
    return;
  if (m_messageStdout)
    [m_messageStdout autorelease];
  if (aMessage)
    m_messageStdout = [aMessage retain];
  else
    m_messageStdout = nil;

  if (containsListing)
    [self parseMessageStdout];

  [[NSNotificationCenter defaultCenter] postNotificationName:updateResultWindowNotification object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Returns the standard error message of the most recent command that
/// operated on this AceXpanderItem.
///
/// Returns @e nil if no command has operated on this AceXpanderItem.
// -----------------------------------------------------------------------------
- (NSString*) messageStderr
{
  if (m_messageStderr)
    return [[m_messageStderr retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Sets the standard error message of the most recent command that
/// operated on this AceXpanderItem.
// -----------------------------------------------------------------------------
- (void) setMessageStderr:(NSString*)aMessage
{
  if (m_messageStderr == aMessage)
    return;
  if (m_messageStderr)
    [m_messageStderr autorelease];
  if (aMessage)
    m_messageStderr = [aMessage retain];
  else
    m_messageStderr = nil;

  [[NSNotificationCenter defaultCenter] postNotificationName:updateResultWindowNotification object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Sets both the standard output and error message of the most recent
/// command that operated on this AceXpanderItem.
///
/// This is a convenience method that can be used so that only one notification
/// is posted instead of two, if the messages were set independently.
///
/// @a containsListing is true if @a anStdoutMessage contains a listing of the
/// archive's contents.
// -----------------------------------------------------------------------------
- (void) setMessageStdout:(NSString*)anStdoutMessage messageStderr:(NSString*)anStderrMessage containsListing:(BOOL)containsListing;
{
  if (m_messageStdout == anStdoutMessage && m_messageStderr == anStderrMessage)
    return;
  if (m_messageStdout != anStdoutMessage)
  {
    if (m_messageStdout)
      [m_messageStdout autorelease];
    if (anStdoutMessage)
      m_messageStdout = [anStdoutMessage retain];
    else
      m_messageStdout = nil;
    if (containsListing)
      [self parseMessageStdout];
  }
  if (m_messageStderr != anStderrMessage)
  {
    if (m_messageStderr)
      [m_messageStderr autorelease];
    if (anStderrMessage)
      m_messageStderr = [anStderrMessage retain];
    else
      m_messageStderr = nil;
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:updateResultWindowNotification object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Parses the currently set stdout message string and tries to determine
/// if it contains a listing of the archive contents.
///
/// If a listing appears to be present, the listing is parsed and for each line
/// of content an AceXpanderContentItem object is created and appended to
/// #m_contentItemList.
///
/// @note This is an internal helper method that should not be invoked by
/// clients.
// -----------------------------------------------------------------------------
- (void) parseMessageStdout
{
  if (! m_contentItemList)
    return;

  // Clear the array, this deallocates all objects within
  [m_contentItemList removeAllObjects];

  // If we have a message, parse it and fill m_contentItemList.
  // If there is no message, m_contentItemList remains empty
  if (m_messageStdout)
  {
    bool bMessageContainsListing = false;
    int iLeadInLines = 3;
    NSCharacterSet* whiteSpaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];

    NSEnumerator* enumerator = [[m_messageStdout componentsSeparatedByString:@"\n"] objectEnumerator];
    id anObject;
    while (anObject = [enumerator nextObject])
    {
      NSString* messageLine = (NSString*)anObject;
      // As long as we don't know whether or not the message contains
      // a listing of the archive contents, we go on looking for
      // a trigger line
      if (! bMessageContainsListing)
      {
        if ([messageLine hasPrefix:@"Contents of archive"])
          bMessageContainsListing = true;
      }
      // OK, now we know that the message contains a listing, but we
      // still have to skip a number of lead-in lines
      else if (iLeadInLines > 0)
        iLeadInLines--;
      // OK, everything from now on is a content line
      else
      {
        // A line starting like this marks the end of the listing
        if ([messageLine hasPrefix:@"listed:"])
          break;
        NSString* trimmedMessageLine = [messageLine stringByTrimmingCharactersInSet:whiteSpaceCharacterSet];
        // Ignore empty lines 
        if (0 == [trimmedMessageLine length])
          continue;
        // Create an AceXpanderContentItem that parses the content line
        AceXpanderContentItem* contentItem = [[AceXpanderContentItem alloc] initWithLine:trimmedMessageLine];
        // We want the array to retain and release the object for us -> decrease
        // the retain count by 1 (was set to 1 by alloc/init)
        [contentItem autorelease];
        [m_contentItemList addObject:contentItem];
      }
    }
  }

  // Send notification that updates the content list drawer, if it is visible
  // and displays the content of this AceXpanderItem
  [[NSNotificationCenter defaultCenter] postNotificationName:updateContentListDrawerNotification object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of lines that this AceXpanderItem provides for
/// @a aTableView.
///
/// This method implements a part of the NSTableDataSource protocol.
// -----------------------------------------------------------------------------
- (int) numberOfRowsInTableView:(NSTableView*)aTableView
{
  if (m_contentItemList)
    return [m_contentItemList count];
  else
    return 0;
}

// -----------------------------------------------------------------------------
/// @brief Returns a value for a cell in table @a aTableView which is located
/// at @a aTableColumn and @a rowIndex.
///
/// This method implements a part of the NSTableDataSource protocol.
// -----------------------------------------------------------------------------
- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex;
{
  if (! m_contentItemList || ! aTableColumn)
    return nil;
  AceXpanderContentItem* contentItem = (AceXpanderContentItem*)[m_contentItemList objectAtIndex:rowIndex];
  if (! contentItem)
    return nil;
  id columnIdentifier = [aTableColumn identifier];

  if ([columnIdentifier isEqual:contentColumnIdentifierDate])
    return [contentItem date];
  else if ([columnIdentifier isEqual:contentColumnIdentifierTime])
    return [contentItem time];
  else if ([columnIdentifier isEqual:contentColumnIdentifierPacked])
    return [contentItem packed];
  else if ([columnIdentifier isEqual:contentColumnIdentifierSize])
    return [contentItem size];
  else if ([columnIdentifier isEqual:contentColumnIdentifierRatio])
    return [contentItem ratio];
  else if ([columnIdentifier isEqual:contentColumnIdentifierFileName])
    return [contentItem fileName];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Updates the internally used icon to reflect the file that this
/// AceXpanderItem currently represents.
///
/// @note This is an internal helper method that should not be invoked by
/// clients.
// -----------------------------------------------------------------------------
- (void) updateIcon
{
  if (m_icon)
  {
    [m_icon autorelease];
    m_icon = nil;
  }

  if (m_fileName)
  {
    NSFileWrapper* wrapper = [[NSFileWrapper alloc] initWithPath:m_fileName];
    if (wrapper)
    {
      m_icon = [[wrapper icon] retain];
      // Release the wrapper - we created it using an init... method, therefore
      // we are its owner according to Cocoa object ownership policy
      [wrapper release];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the background color that should be used to display this
/// item in its current state.
// -----------------------------------------------------------------------------
- (NSColor*) backgroundColor
{
  switch (m_state)
  {
    case QueuedState:
      return [NSColor blueColor];
    case SkipState:
      return [NSColor lightGrayColor];
    case ProcessingState:
      return [NSColor blueColor];
    case AbortedState:
      return [NSColor yellowColor];
    case SuccessState:
      return [NSColor greenColor];
    case FailureState:
      return [NSColor redColor];
    default:
      return [NSColor redColor];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the text (foreground) color that should be used to display this
/// item in its current state.
// -----------------------------------------------------------------------------
- (NSColor*) textColor
{
  switch (m_state)
  {
    case QueuedState:
      return [NSColor whiteColor];
    case SkipState:
      return [NSColor blackColor];
    case ProcessingState:
      return [NSColor whiteColor];
    case AbortedState:
      return [NSColor blackColor];
    case SuccessState:
      return [NSColor blackColor];
    case FailureState:
      return [NSColor whiteColor];
    default:
      return [NSColor redColor];
  }
}

@end
