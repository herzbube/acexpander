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


// Cocoa
#import <Cocoa/Cocoa.h>

// Forward declarations
@class AceXpanderItem;
@class AceXpanderThread;


// -----------------------------------------------------------------------------
/// @brief The AceXpanderModel class implements the Model role of the design
/// pattern commonly known as Model-View-Controller.
///
/// AceXpanderModel stores the application's working data (the ACE archive
/// files that the user specifies) and knows how to operate on this data
/// (usually this means to expand the archive files).
///
/// In addition, AceXpanderModel implements the following protocols:
/// - @e NSNibAwaking protocol: to do stuff after the class has been loaded and
///   instantiated from the .nib file
/// - @e NSTableDataSource protocol: to provide data for the main table in the
///   GUI (only parts of the informal protocol are implemented)
///
/// @note This class is instantiated when the application's .nib is loaded.
// -----------------------------------------------------------------------------
@interface AceXpanderModel : NSObject
{
@private
  /// @brief The table in the GUI (this variable is an outlet that is
  /// initialized in the .nib)
  NSTableView* m_theTable;

  /// @brief List with AceXpanderItem objects.
  NSMutableArray* m_itemList;

  /// @brief The thread that manages and executes unace commands. The
  /// thread object is created on-demand only, i.e. when the first command is
  /// sent using one of the start...() methods.
  AceXpanderThread* m_commandThread;

  /// @name unace command options
  /// @brief These options modify the behaviour of the various unace commands
  //@{
  bool m_overwriteFiles;
  bool m_extractFullPath;
  bool m_assumeYes;
  bool m_showComments;
  bool m_listVerbosely;
  bool m_usePassword;
  NSString* m_password;
  //@}

  /// @name Other variables
  //@{
  bool m_interactive;
  NSDocumentController* m_theDocumentController;
  //@}
}

/// @name Initializers
//@{
- (id) init;
//@}

/// @name Manipulating items
//@{
- (void) addItemForFile:(NSString*)fileName;
- (void) removeSelectedItems;
- (void) removeAllItems;
- (AceXpanderItem*) itemForFile:(NSString*)fileName;
- (AceXpanderItem*) itemForIndex:(unsigned int)index;
- (void) setAllItemsToState:(int)toState fromState:(int)fromState;
- (void) setAllItemsToState:(int)state;
- (void) setSelectedItemsToState:(int)toState fromState:(int)fromState;
- (void) setSelectedItemsToState:(int)state;
- (bool) haveAllItemsState:(int)state;
- (void) selectItemsWithState:(int)state;
//@}

/// @name Accessor methods for options
//@{
- (bool) overwriteFiles;
- (void) setOverwriteFiles:(bool)overwriteFiles;
- (bool) extractFullPath;
- (void) setExtractFullPath:(bool)extractFullPath;
- (bool) assumeYes;
- (void) setAssumeYes:(bool)assumeYes;
- (bool) showComments;
- (void) setShowComments:(bool)showComments;
- (bool) listVerbosely;
- (void) setListVerbosely:(bool)listVerbosely;
- (bool) usePassword;
- (NSString*) password;
- (void) setUsePassword:(bool)usePassword withPassword:(NSString*)password;
//@}

/// @name Other accessors
//@{
- (bool) interactive;
- (void) setInteractive:(bool)interactive;
//@}

/// @name Starting/stopping commands
//@{
- (bool) startExpandItems;
- (bool) startListItems;
- (bool) startTestItems;
- (void) stopCommand;
- (bool) isCommandRunning;
- (NSString*) unaceVersion;
//@}

/// @name Other methods
//@{
- (void) itemHasChanged:(AceXpanderItem*)item;
- (void) updateMyDefaultsFromUserDefaults;
//@}

@end
