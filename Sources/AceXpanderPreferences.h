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

// Constant values for the defaults
static NSString* bundledExecutablePath = @"<bundled>";
static NSString* destinationFolderTypeSameAsArchive = @"SameAsArchive";
static NSString* destinationFolderTypeAskWhenExpanding = @"AskWhenExpanding";
static NSString* destinationFolderTypeFixedLocation = @"FixedLocation";
// Keys for the defaults
static NSString* mainWindowFrameNameKey = @"MainWindow";
static NSString* resultWindowFrameNameKey = @"ResultWindow";
static NSString* quitAppWhenMainWindowIsClosedKey = @"QuitAppWhenMainWindowIsClosed";
static NSString* showResultWindowKey = @"ShowResultWindow";
static NSString* executablePathKey = @"ExecutablePath";
static NSString* startExpandingAfterLaunchKey = @"StartExpandingAfterLaunch";
static NSString* quitAfterExpandKey = @"QuitAfterExpand";
static NSString* alwaysQuitAfterExpandKey = @"AlwaysQuitAfterExpand";
static NSString* destinationFolderTypeKey = @"DestinationFolderType";
static NSString* destinationFolderKey = @"DestinationFolder";
static NSString* createSurroundingFolderKey = @"CreateSurroundingFolder";
static NSString* lookIntoFoldersKey = @"LookIntoFolders";
static NSString* treatAllFilesAsArchivesKey = @"TreatAllFilesAsArchives";
static NSString* optionDefaultsRememberedKey = @"OptionDefaultsRemembered";
static NSString* overwriteFilesOptionKey = @"OverwriteFilesOption";
static NSString* extractWithFullPathOptionKey = @"ExtractWithFullPathOption";
static NSString* assumeYesOptionKey = @"AssumeYesOption";
static NSString* showCommentsOptionKey = @"ShowCommentsOption";
static NSString* listVerboselyOptionKey = @"ListVerboselyOption";


// -----------------------------------------------------------------------------
/// @brief The AceXpanderPreferences class is a mini-controller for the user
/// Preferences dialog. It is also responsible to set up defaults in the
/// NSRegistration domain.
// -----------------------------------------------------------------------------
@interface AceXpanderPreferences : NSObject
{
@private
  // The shared defaults object
  NSUserDefaults* m_userDefaults;
  // The preferences dialog
  NSWindow* m_preferencesDialog;
  // These variables are outlets and therefore initialized in the .nib
  NSButton* m_quitAppWhenMainWindowIsClosedButton;
  NSPopUpButton* m_executablePathButton;
  NSButton* m_startExpandingAfterLaunchButton;
  NSButton* m_quitAfterExpandButton;
  NSButton* m_alwaysQuitAfterExpandButton;
  NSPopUpButton* m_destinationFolderButton;
  NSButton* m_createSurroundingFolderButton;
  NSButton* m_lookIntoFoldersButton;
  NSButton* m_treatAllFilesAsArchivesButton;
  // Other variables
  BOOL m_preferencesDialogCancelClicked;
  NSString* m_executablePath;   // Stores the entire path
  NSString* m_destinationFolderType;
  NSString* m_destinationFolder;   // Stores the entire path
}

/// @name Initializers
//@{
- (id) init;
//@}
/// @name Open/close dialog
//@{
- (void) showPreferencesDialog;
//@}

@end
