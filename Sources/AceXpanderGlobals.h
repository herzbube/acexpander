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


// -----------------------------------------------------------------------------
// The following line is required so that doxygen documents the global items
// in this file.
/// @file
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
/// @brief Commands understood by AceXpanderThread. See class documentation
/// for more information.
// -----------------------------------------------------------------------------
enum AceXpanderCommand
{
  ExpandCommand   = 0,
  ListCommand     = 1,
  TestCommand     = 2
};


// -----------------------------------------------------------------------------
/// @brief States that an AceXpanderItem can have. See class documentation
/// for more information.
// -----------------------------------------------------------------------------
enum AceXpanderItemState
{
  QueuedState     = 0,   ///< @brief Items with this state are going to be processed
  SkipState       = 1,   ///< @brief Items with this state are not going to be processed
  ProcessingState = 2,   ///< @brief Items with this state are being processed right now
  AbortedState    = 3,   ///< @brief Items whose ProcessingState was aborted
  SuccessState    = 4,   ///< @brief Items whose ProcessingState terminated with success
  FailureState    = 5    ///< @brief Items whose ProcessingState terminated with failure
};


// -----------------------------------------------------------------------------
/// @name Notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Any client that encounters an error condition that it cannot handle
/// properly may post this notification. The user will be presented with a
/// dialog that offers terminating the application, or simply ignoring the
/// error.
static NSString* errorConditionOccurredNotification = @"ErrorConditionOccurred";
/// @brief This notification is posted when an item's standard output or
/// standard error message changes.
static NSString* updateResultWindowNotification = @"UpdateResultWindow";
/// @brief This notification is posted when an item's standard output message
/// changes and its content is detected to be a listing of the archive contents
static NSString* updateContentListDrawerNotification = @"UpdateContentListDrawer";
/// @brief This notification is posted when the model has finished processing
/// the awakeFromNib:() method.
static NSString* modelHasFinishedAwakeFromNibNotification = @"ModelHasFinishedAwakeFromNib";
/// @brief This notification is posted when the command thread starts
/// processing items
static NSString* commandThreadHasStartedNotification = @"CommandThreadHasStarted";
/// @brief This notification is posted when the command thread has stopped
/// processing its items.
static NSString* commandThreadHasStoppedNotification = @"CommandThreadHasStopped";
//@}


// -----------------------------------------------------------------------------
/// @name Constants related to preferences
// -----------------------------------------------------------------------------
//@{
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
//@}


// -----------------------------------------------------------------------------
/// @name Constants related to unace executable
// -----------------------------------------------------------------------------
//@{
static NSString* unaceCmdExtract = @"e";
static NSString* unaceCmdExtractWithFullPath = @"x";
static NSString* unaceCmdList = @"l";
static NSString* unaceCmdListVerbosely = @"v";
static NSString* unaceCmdTest = @"t";
static NSString* unaceSwitchShowComments = @"-c";
static NSString* unaceSwitchOverwriteFiles = @"-o";
static NSString* unaceSwitchUsePassword = @"-p";
static NSString* unaceSwitchAssumeYes = @"-y";
/// @brief This is a pseudo switch - unace does not know "--version"
static NSString* unaceSwitchVersion = @"--version";
//@}


// -----------------------------------------------------------------------------
/// @name Resource file names
// -----------------------------------------------------------------------------
//@{
static NSString* unaceBundledResourceName = @"unace";
static NSString* registrationDomainDefaultsFileName = @"RegistrationDomainDefaults.plist";
// .nib file names
static NSString* preferencesDialogNibName = @"PreferencesDialog";
static NSString* passwordDialogNibName = @"PasswordDialog";
// Text file names
static NSString* gnuGPLFileName = @"COPYING";
static NSString* manualFileName = @"MANUAL";
static NSString* readMeFileName = @"README";
static NSString* changeLogFileName = @"ChangeLog";
static NSString* releasePlanFileName = @"ReleasePlan";
static NSString* toDoFileName = @"TODO";
static NSString* homePageURL = @"http://www.herzbube.ch/drupal/?q=acexpander";
//@}

// -----------------------------------------------------------------------------
/// @name Constants related to main table
// -----------------------------------------------------------------------------
//@{
static NSString* mainColumnIdentifierIcon = @"icon";
static NSString* mainColumnIdentifierFileName = @"fileName";
static NSString* mainColumnIdentifierState = @"state";
//@}

// -----------------------------------------------------------------------------
/// @name Constants related to content table
// -----------------------------------------------------------------------------
//@{
static const NSString* contentColumnIdentifierDate = @"date";
static const NSString* contentColumnIdentifierTime = @"time";
static const NSString* contentColumnIdentifierPacked = @"packed";
static const NSString* contentColumnIdentifierSize = @"size";
static const NSString* contentColumnIdentifierRatio = @"ratio";
static const NSString* contentColumnIdentifierFileName = @"fileName";
//@}
