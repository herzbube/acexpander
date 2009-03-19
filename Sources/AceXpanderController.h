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
@class AceXpanderModel;
@class AceXpanderPreferences;


// -----------------------------------------------------------------------------
/// @brief The AceXpanderController class implements the Controller role of the
/// design pattern commonly known as Model-View-Controller.
///
/// AceXpanderController reacts to user input in the GUI and controls the
/// program flow resulting from this user input.
///
/// AceXpanderController also implements the role of delegate of the
/// NSApplication main object. In this role it manages the opening of files
/// when the user drags them on a representation of the application in the
/// Finder, such as on the application icon residing in the dock.
///
/// In addition, AceXpanderModel implements the following protocols and
/// interfaces, and has the following responsibilities:
/// - @e NSNibAwaking protocol: to do stuff after the class has been loaded and
///   instantiated from the .nib file
/// - @e NSMenuValidation protocol: for all menu items that have this class set
///   as their target, the method validateMenuItem; is queried to automatically
///   enable or disable those menu items
/// - is the delegate of various NSWindow instances
/// - is the delegate of the main table view
/// - central handling for severe application errors; this class registers
///   with the default notification center for the notification
///   #errorConditionOccurredNotification. Classes may post such a notification
///   if they detect an error they cannot handle
/// - instantiates an AceXpanderPreferences object in the constructor, in order
///   for AceXpanderPreferences to correctly set up the user defaults database
///
/// @note Make sure that this class does not query the user defaults database
/// until after AceXpanderPreferences is instantiated (e.g. do not initialize
/// member variables with values from the user defaults database).
///
/// @note This class is instantiated when the application's .nib is loaded.
// -----------------------------------------------------------------------------
@interface AceXpanderController : NSObject
{
@private
  /// @name Outlets
  /// @brief These variables are outlets and therefore initialized in the .nib
  //@{
  // --- from MainMenu.nib
  AceXpanderModel* m_theModel;
  NSWindow* m_mainWindow;
  NSTableView* m_theTable;
  NSTableView* m_theContentListTable;
  NSDrawer* m_theContentListDrawer;
  NSButton* m_cancelButton;
  NSButton* m_expandButton;
  NSProgressIndicator* m_progressIndicator;
  NSWindow* m_resultWindow;
  NSTextView* m_stdoutTextView;
  NSTextView* m_stderrTextView;
  NSWindow* m_textViewWindow;
  NSTextView* m_textView;
  NSMenuItem* m_requeueMenuItem;
  NSMenuItem* m_unqueueMenuItem;
  NSMenuItem* m_removeMenuItem;
  NSMenuItem* m_expandMenuItem;
  NSMenuItem* m_listContentMenuItem;
  NSMenuItem* m_testIntegrityMenuItem;
  NSMenuItem* m_overwriteFilesMenuItem;
  NSMenuItem* m_extractFullPathMenuItem;
  NSMenuItem* m_assumeYesMenuItem;
  NSMenuItem* m_showCommentsMenuItem;
  NSMenuItem* m_listVerboselyMenuItem;
  NSMenuItem* m_usePasswordMenuItem;
  NSMenuItem* m_showMainWindowMenuItem;
  NSMenuItem* m_showResultWindowMenuItem;
  NSMenuItem* m_homepageMenuItem;
  NSMenuItem* m_showInfoInFinderMenuItem;
  NSMenuItem* m_revealInFinderMenuItem;
  NSMenuItem* m_rememberMyDefaultsMenuItem;
  NSMenuItem* m_forgetMyDefaultsMenuItem;
  // --- from PasswordDialog.nib
  NSPanel* m_passwordDialog;
  NSSecureTextField* m_passwordTextField;
  //@}
  
  /// @name Other variables
  //@{
  AceXpanderPreferences* m_thePreferences;
  NSUserDefaults* m_userDefaults;
  BOOL m_passwordDialogCancelClicked;
  BOOL m_myDefaultsHaveChanged;
  //@}
}

/// @name Initializers
//@{
- (id) init;
//@}

@end
