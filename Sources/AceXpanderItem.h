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
// herzbube@herzbube.ch
// -----------------------------------------------------------------------------


// Cocoa
#import <Cocoa/Cocoa.h>

// Forward declarations
@class AceXpanderModel;


// -----------------------------------------------------------------------------
/// @class AceXpanderItem
///
/// @brief The AceXpanderItem class represents an ACE archive in the file
/// system and, at the same time, a row in the table of archives in the
/// application's GUI.
///
/// It is responsible for notifying others if its state changes (exceptions
/// are construction/destruction):
/// - whenever anything changes that is displayed in the main window table,
///   it invokes the model's AceXpanderModel::itemHasChanged:() method
/// - whenever anything changes that is displayed in the result window,
///   it posts an "UpdateResultWindowNotification" notification
/// - whenever anything changes that is displayed in the content list drawer,
///   it posts an "UpdateContentListDrawerNotification" notification
///
/// An AceXpanderItem always has one of the following states (from among the
/// #AceXpanderItemState enumeration):
///  - #QueuedState: This is the initial state when the item is created. An item
///    may also re-enter this state if it was previously in state #SkipState,
///    #AbortedState, #SuccessState or #FailureState. When the item list is
///    processed, every item in the list that has this state is processed.
///  - #SkipState: When the item list is processed, items with this state are
///    ignored
///  - #ProcessingState: When the application starts processing an item, the
///    item is moved from #QueuedState to this state.
///  - #AbortedState: When an item is in the state #ProcessingState and the
///    processing is stopped forcefully, the item moves to this state
///  - #SuccessState: When the application successfully finishes processing an
///    item, the item moves to this state.
///  - #FailureState: as with #SuccessState, but an error occurred during
///    processing
///
/// AceXpanderItem implements the following protocols:
/// - @e NSTableDataSource protocol: to provide data for the content list drawer
///   (only part of the informal protocol are implemented)
// -----------------------------------------------------------------------------
@interface AceXpanderItem : NSObject
{
@private
  /// @name Attributes of the file item
  //@{
  NSString* m_fileName;
  NSImage* m_icon;
  //@}

  /// @name Attributes of the unace execution state
  //@{
  int m_state;
  NSString* m_messageStdout;
  NSString* m_messageStderr;
  //@}

  /// @brief List with AceXpanderContentItem objects.
  NSMutableArray* m_contentItemList;

  /// @brief The model that this item cooperates with.
  AceXpanderModel* m_theModel;
}

/// @name Initializers
//@{
- (id) initWithFile:(NSString*)fileName model:(AceXpanderModel*)theModel;
//@}

/// @name Accessors
//@{
- (NSString*) fileName;
- (void) setFileName:(NSString*)aFileName;
- (NSImage*) icon;
- (int) state;
- (NSString*) stateAsString;
- (void) setState:(int)state;
- (NSString*) messageStdout;
- (void) setMessageStdout:(NSString*)aMessage containsListing:(BOOL)containsListing;
- (NSString*) messageStderr;
- (void) setMessageStderr:(NSString*)aMessage;
- (void) setMessageStdout:(NSString*)anStdoutMessage messageStderr:(NSString*)anStderrMessage containsListing:(BOOL)containsListing;
- (NSColor*) backgroundColor;
- (NSColor*) textColor;
//@}

/// @name Other methods
//@{
+ (NSString*) stringForState:(int)state;
//@}

@end
