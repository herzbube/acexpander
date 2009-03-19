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
#import "AceXpanderPreferences.h"
#import "AceXpanderController.h"

// Constants
static NSString* registrationDomainDefaultsFileName = @"RegistrationDomainDefaults.plist";
static NSString* preferencesDialogNibName = @"PreferencesDialog";

/// @brief This category declares private methods for the AceXpanderPreferences
/// class. 
@interface AceXpanderPreferences(Private)
/// @name Deallocation
//@{
- (void) dealloc;
//@}
/// @name Open/close dialog
//@{
- (void) preferencesDialogOKClicked:(id)sender;
- (void) preferencesDialogCancelClicked:(id)sender;
//@}
/// @name Writing to/reading from GUI
//@{
- (void) writeDefaultsToGUI;
- (void) readDefaultsFromGUI;
- (void) readDefaultsFromCheckbox:(NSButton*)checkbox forKey:(NSString*)key;
//@}
/// @name Action methods, setting executable
//@{
- (void) setExecutableToBundled:(id)sender;
- (void) setExecutableChooseLocation:(id)sender;
- (void) updateExecutablePathButton:(NSString*)previousExecutablePath;
//@}
/// @name Action methods, setting destination folder
//@{
- (void) setDestinationSameAsArchive:(id)sender;
- (void) setDestinationAskWhenExpanding:(id)sender;
- (void) setDestinationChooseFolder:(id)sender;
- (void) updateDestinationFolderButton:(NSString*)previousDestinationFolderType;
//@}
/// @name Action methods, related to QuitAfterExpand
//@{
- (void) startExpandingAfterLaunchButtonClicked:(id)sender;
- (void) quitAfterExpandButtonClicked:(id)sender;
//@}
/// @name Action methods, related to LookIntoFolders
//@{
- (void) lookIntoFoldersButtonClicked:(id)sender;
//@}
/// @name Other methods
//@{
- (void) loadDefaultsToRegistrationDomain;
- (void) enableButton:(NSButton*)enableButton dependingOnOtherButton:(NSButton*)dependButton;
- (void) enableButtonHierarchy:(NSArray*)buttons;
//@}
@end


@implementation AceXpanderPreferences

// -----------------------------------------------------------------------------
/// @brief Initializes an AceXpanderPreferences object.
///
/// @note This is the designated initializer of AceXpanderPreferences.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  m_preferencesDialogCancelClicked = false;
  m_userDefaults = [[NSUserDefaults standardUserDefaults] retain];
  if (nil == m_userDefaults)
  {
    NSString* errorDescription = @"Shared user defaults instance is null."; 
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification object:errorDescription];
    [self release];
    return nil;
  }
  [self loadDefaultsToRegistrationDomain];

  // Return 
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this AceXpanderPreferences object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (m_userDefaults)
    [m_userDefaults autorelease];
  if (m_executablePath)
    [m_executablePath autorelease];
  if (m_destinationFolderType)
    [m_destinationFolderType autorelease];
  if (m_destinationFolder)
    [m_destinationFolder autorelease];
  /// @todo Release outlets, too? If yes, do we need to retain them in
  /// awakeFromNib:(), or are they retained automatically when they are set?
//  if (m_preferencesDialog)
//    [m_preferencesDialog autorelease];
//  if (m_quitAppWhenMainWindowIsClosedButton)
//    [m_quitAppWhenMainWindowIsClosedButton autorelease];
//  if (m_executablePathButton)
//    [m_executablePathButton autorelease];
//  if (m_startExpandingAfterLaunchButton)
//    [m_startExpandingAfterLaunchButton autorelease];
//  if (m_quitAfterExpandButton)
//    [m_quitAfterExpandButton autorelease];
//  if (m_alwaysQuitAfterExpandButton)
//    [m_alwaysQuitAfterExpandButton autorelease];
//  if (m_destinationFolderButton)
//    [m_destinationFolderButton autorelease];
//  if (m_createSurroundingFolderButton)
//    [m_createSurroundingFolderButton autorelease];
//  if (m_lookIntoFoldersButton)
//    [m_lookIntoFoldersButton autorelease];
//  if (m_treatAllFilesAsArchivesButton)
//    [m_treatAllFilesAsArchivesButton autorelease];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Opens the user preferences dialog and displays it to the user.
// -----------------------------------------------------------------------------
- (void) showPreferencesDialog
{
  // Load the .nib if not yet done. m_preferencesDialog is an outlet
  // and is set, together with all the other outlets, when the .nib is loaded.
  // This works because
  // - we tell loadNibNamed that this object (self) is the owner of the .nib
  // - and in the .nib the "file's owner" is set to be an AceXpanderPreferences
  //   object
  if (nil == m_preferencesDialog)
  {
    [NSBundle loadNibNamed:preferencesDialogNibName owner:self];
    if (! m_preferencesDialog)
    {
      // Notify the error handler that an error has occurred
      NSString* errorDescription = @"m_preferencesDialog is still unset after loading the preferences dialog .nib";
      [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification
                                                          object:errorDescription];
      return;
    }
  }

  // Configure the GUI with values read from the defaults
  [self writeDefaultsToGUI];

  // Prepare and run the dialog. The sheet is not attached to any window, it
  // is simply run as a modal window
  NSApplication* theApp = [NSApplication sharedApplication];
  if (! theApp)
    return;
  [theApp beginSheet:m_preferencesDialog modalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:nil];
  [theApp runModalForWindow:m_preferencesDialog];

  // -------------------------------------------------
  // --- At this point the modal dialog is running ---
  // -------------------------------------------------

  // Clean up and close the dialog
  [theApp endSheet:m_preferencesDialog];
  // Remove dialog from screen
  [m_preferencesDialog orderOut:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user clicking the "ok" button in the user preferences
/// dialog.
///
/// Closes the dialog and writes the current settings in the dialog to the user
/// defaults. See readDefaultsFromGUI:() for details.
// -----------------------------------------------------------------------------
- (void) preferencesDialogOKClicked:(id)sender
{
  [self readDefaultsFromGUI];
  m_preferencesDialogCancelClicked = false;
  [[NSApplication sharedApplication] stopModal];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user clicking the "cancel" button in the user
/// preferences dialog.
///
/// Closes the dialog and discards the current settings in the dialog.
// -----------------------------------------------------------------------------
- (void) preferencesDialogCancelClicked:(id)sender
{
  m_preferencesDialogCancelClicked = true;
  [[NSApplication sharedApplication] stopModal];
}

// -----------------------------------------------------------------------------
/// @brief Initializes all GUI elements in the user preferences dialog with
/// values from the user defaults.
// -----------------------------------------------------------------------------
- (void) writeDefaultsToGUI
{
  if (! m_userDefaults)
    return;

  // ------------------------------------------------------------
  // QuitAppWhenMainWindowIsClosed
  if ([m_userDefaults boolForKey:quitAppWhenMainWindowIsClosedKey])
    [m_quitAppWhenMainWindowIsClosedButton setState:NSOnState];
  else
    [m_quitAppWhenMainWindowIsClosedButton setState:NSOffState];

  // ------------------------------------------------------------
  // ExecutablePath
  if (m_executablePath)
    [m_executablePath autorelease];
  m_executablePath = [m_userDefaults stringForKey:executablePathKey];
  if (m_executablePath)
    [m_executablePath retain];
  [self updateExecutablePathButton:nil];

  // ------------------------------------------------------------
  // DestinationFolderType + DestinationFolder
  if (m_destinationFolderType)
    [m_destinationFolderType autorelease];
  m_destinationFolderType = [m_userDefaults stringForKey:destinationFolderTypeKey];
  if (m_destinationFolderType)
    [m_destinationFolderType retain];

  if (m_destinationFolder)
    [m_destinationFolder autorelease];
  m_destinationFolder = [m_userDefaults stringForKey:destinationFolderKey];
  if (m_destinationFolder)
    [m_destinationFolder retain];
 
  [self updateDestinationFolderButton:nil];

  // ------------------------------------------------------------
  // StartExpandingAfterLaunch + QuitAfterExpand + AlwaysQuitAfterExpand
  if ([m_userDefaults boolForKey:startExpandingAfterLaunchKey])
    [m_startExpandingAfterLaunchButton setState:NSOnState];
  else
    [m_startExpandingAfterLaunchButton setState:NSOffState];

  if ([m_userDefaults boolForKey:quitAfterExpandKey])
    [m_quitAfterExpandButton setState:NSOnState];
  else
    [m_quitAfterExpandButton setState:NSOffState];

  if ([m_userDefaults boolForKey:alwaysQuitAfterExpandKey])
    [m_alwaysQuitAfterExpandButton setState:NSOnState];
  else
    [m_alwaysQuitAfterExpandButton setState:NSOffState];

  NSMutableArray* buttons = [NSMutableArray array];
  [buttons addObject:m_startExpandingAfterLaunchButton];
  [buttons addObject:m_quitAfterExpandButton];
  [buttons addObject:m_alwaysQuitAfterExpandButton];
  [self enableButtonHierarchy:buttons];

  // ------------------------------------------------------------
  // CreateSurroundingFolder
  if ([m_userDefaults boolForKey:createSurroundingFolderKey])
    [m_createSurroundingFolderButton setState:NSOnState];
  else
    [m_createSurroundingFolderButton setState:NSOffState];
  
  // ------------------------------------------------------------
  // LookIntoFolders + TreatAllFilesAsArchives
  if ([m_userDefaults boolForKey:lookIntoFoldersKey])
    [m_lookIntoFoldersButton setState:NSOnState];
  else
    [m_lookIntoFoldersButton setState:NSOffState];
  
  if ([m_userDefaults boolForKey:treatAllFilesAsArchivesKey])
    [m_treatAllFilesAsArchivesButton setState:NSOnState];
  else
    [m_treatAllFilesAsArchivesButton setState:NSOffState];

  [buttons removeAllObjects];
  [buttons addObject:m_lookIntoFoldersButton];
  [buttons addObject:m_treatAllFilesAsArchivesButton];
  [self enableButtonHierarchy:buttons];
}

// -----------------------------------------------------------------------------
/// @brief Reads values from all GUI elements in the user preferences dialog
/// and writes these values to the user defaults in the application domain.
///
/// @note User defaults are only written if their new value is different from
/// the value already stored in the user defaults. The effect of this is that
/// if the user never changes a default's value from the value stored in the
/// NSRegistration domain, the default is never written to the application
/// domain. As soon as the user changes the default's value for the first time,
/// it is written to the application domain. It remains there, even if the user
/// changes its value back to the value stored in the NSRegistration domain.
// -----------------------------------------------------------------------------
- (void) readDefaultsFromGUI
{
  if (! m_userDefaults)
    return;

  // ------------------------------------------------------------
  // QuitAppWhenMainWindowIsClosed
  [self readDefaultsFromCheckbox:m_quitAppWhenMainWindowIsClosedButton forKey:quitAppWhenMainWindowIsClosedKey];

  // ------------------------------------------------------------
  // ExecutablePath
  // The full path is stored in m_executablePath, not the GUI)
  [m_userDefaults setObject:m_executablePath forKey:executablePathKey];

  // ------------------------------------------------------------
  // StartExpandingAfterLaunch
  [self readDefaultsFromCheckbox:m_startExpandingAfterLaunchButton forKey:startExpandingAfterLaunchKey];

  // ------------------------------------------------------------
  // DestinationFolderType + DestinationFolder
  // The full path is stored in m_destinationFolder, not the GUI)
  [m_userDefaults setObject:m_destinationFolderType forKey:destinationFolderTypeKey];
  [m_userDefaults setObject:m_destinationFolder forKey:destinationFolderKey];

  // ------------------------------------------------------------
  // QuitAfterExpand + AlwaysQuitAfterExpand
  [self readDefaultsFromCheckbox:m_quitAfterExpandButton forKey:quitAfterExpandKey];
  [self readDefaultsFromCheckbox:m_alwaysQuitAfterExpandButton forKey:alwaysQuitAfterExpandKey];

  // ------------------------------------------------------------
  // CreateSurroundingFolder
  [self readDefaultsFromCheckbox:m_createSurroundingFolderButton forKey:createSurroundingFolderKey];

  // ------------------------------------------------------------
  // LookIntoFolders + TreatAllFilesAsArchives
  [self readDefaultsFromCheckbox:m_lookIntoFoldersButton forKey:lookIntoFoldersKey];
  [self readDefaultsFromCheckbox:m_treatAllFilesAsArchivesButton forKey:treatAllFilesAsArchivesKey];
}

// -----------------------------------------------------------------------------
/// @brief Reads the value from checkbox @a checkbox in the user preferences
/// dialog and writes the value to the user defaults under key @key.
///
/// @note The value is written only if it differs from the value already stored
/// in the user defaults.
// -----------------------------------------------------------------------------
- (void) readDefaultsFromCheckbox:(NSButton*)checkbox forKey:(NSString*)key
{
  if (! checkbox || ! key || ! m_userDefaults)
    return;

  BOOL checked;
  int state = [checkbox state];
  if (NSOnState == state)
    checked = true;
  else
    checked = false;

  if (checked != [m_userDefaults boolForKey:key])
    [m_userDefaults setBool:checked forKey:key];
}

// -----------------------------------------------------------------------------
/// @brief Sets the "unace" executable path to a dummy default value which
/// indicates that the bundled version of unace will be used.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) setExecutableToBundled:(id)sender
{
  NSString* previousExecutablePath = m_executablePath;

  if (m_executablePath)
    [m_executablePath autorelease];
  m_executablePath = bundledExecutablePath;
  if (m_executablePath)
    [m_executablePath retain];

  [self updateExecutablePathButton:previousExecutablePath];
}

// -----------------------------------------------------------------------------
/// @brief Displays an open panel that lets the user navigate the file system
/// in order to choose the "unace" executable that she wants to use.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) setExecutableChooseLocation:(id)sender
{
  NSString* previousExecutablePath = m_executablePath;

  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  if (! openPanel)
    return;
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setCanChooseDirectories:NO];
  NSString* directory = nil;
  NSString* selectedFile = nil;
  NSArray* fileTypes = nil;
  int iResult = [openPanel runModalForDirectory:directory file:selectedFile types:fileTypes];
  if (NSOKButton == iResult)
  {
    if (m_executablePath)
      [m_executablePath autorelease];
    // We trust the panel to return at least one item so that we don't have
    // to check the array size
    m_executablePath = (NSString*)[[openPanel filenames] objectAtIndex:0];
    if (m_executablePath)
      [m_executablePath retain];
  }

  // Update the button: the user's action selected a menu item -> this
  // must be undone even if the user clicked "cancel" on the open panel
  [self updateExecutablePathButton:previousExecutablePath];
}

// -----------------------------------------------------------------------------
/// @brief Updates the popup button used for selecting an "unace" executable to
/// display the currently selected executable.
///
/// If the popup button's menu is closed, the button should still display the
/// currently selected executable. For this purpose, this method updates the
/// top-most menu item to reflect the currently selected executable - the
/// top-most menu item is the one that the button displays when the menu is
/// closed.
///
/// @note This is an internal helper method, not an action method.
// -----------------------------------------------------------------------------
- (void) updateExecutablePathButton:(NSString*)previousExecutablePath
{
  if (! m_executablePathButton)
    return;

  // If the previous path did not point to the bundled executable, we need to
  // remove the two menu items that were created to display the custom path
  if (previousExecutablePath &&
      ! [previousExecutablePath isEqualToString:bundledExecutablePath])
  {
    [m_executablePathButton removeItemAtIndex:0];
    [m_executablePathButton removeItemAtIndex:0];
  }
  
  if ([m_executablePath isEqualToString:bundledExecutablePath])
    [m_executablePathButton selectItemAtIndex:0];
  else
  {
    [[m_executablePathButton menu] insertItem:[NSMenuItem separatorItem] atIndex:0];
    [m_executablePathButton insertItemWithTitle:[m_executablePath lastPathComponent] atIndex:0];
    [m_executablePathButton selectItemAtIndex:0];
    /// @todo make the following code work! With this code, the image displayed
    /// when the popup menu is closed is far too big!
    // NSMenuItem menuItem = m_destinationFolderButton.itemAtIndex(0);
    // menuItem.setImage(new NSFileWrapper(m_destinationFolder, false).icon());
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets the destination folder to SameAsArchive.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) setDestinationSameAsArchive:(id)sender
{
  NSString* previousDestinationFolderType = m_destinationFolderType;

  if (m_destinationFolderType)
    [m_destinationFolderType autorelease];
  m_destinationFolderType = destinationFolderTypeSameAsArchive;
  if (m_destinationFolderType)
    [m_destinationFolderType retain];

  if (m_destinationFolder)
    [m_destinationFolder autorelease];
  m_destinationFolder = @"";
  if (m_destinationFolder)
    [m_destinationFolder retain];

  [self updateDestinationFolderButton:previousDestinationFolderType];
}

// -----------------------------------------------------------------------------
/// @brief Sets the destination folder to AskWhenExpanding.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) setDestinationAskWhenExpanding:(id)sender
{
  NSString* previousDestinationFolderType = m_destinationFolderType;

  if (m_destinationFolderType)
    [m_destinationFolderType autorelease];
  m_destinationFolderType = destinationFolderTypeAskWhenExpanding;
  if (m_destinationFolderType)
    [m_destinationFolderType retain];

  if (m_destinationFolder)
    [m_destinationFolder autorelease];
  m_destinationFolder = @"";
  if (m_destinationFolder)
    [m_destinationFolder retain];

  [self updateDestinationFolderButton:previousDestinationFolderType];
}

// -----------------------------------------------------------------------------
/// @brief Displays an open panel that lets the user navigate the file system
/// in order to choose an explicit destination folder.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) setDestinationChooseFolder:(id)sender
{
  NSString* previousDestinationFolderType = m_destinationFolderType;

  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  if (! openPanel)
    return;
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setCanChooseFiles:NO];
  [openPanel setCanChooseDirectories:YES];
  NSString* directory = nil;
  NSString* selectedFile = nil;
  NSArray* fileTypes = nil;
  int iResult = [openPanel runModalForDirectory:directory file:selectedFile types:fileTypes];
  if (NSOKButton == iResult)
  {
    if (m_destinationFolderType)
      [m_destinationFolderType autorelease];
    m_destinationFolderType = destinationFolderTypeFixedLocation;
    if (m_destinationFolderType)
      [m_destinationFolderType retain];

    if (m_destinationFolder)
      [m_destinationFolder autorelease];
    // We trust the panel to return at least one item so that we don't have
    // to check the array size
    m_destinationFolder = (NSString*)[[openPanel filenames] objectAtIndex:0];
    if (m_destinationFolder)
      [m_destinationFolder retain];
  }

  // Update the button: the user's action selected a menu item -> this
  // must be undone even if the user clicked "cancel" on the open panel
  [self updateDestinationFolderButton:previousDestinationFolderType];
}

// -----------------------------------------------------------------------------
/// @brief Updates the popup button used for selecting the destination folder to
/// display the currently selected destination folder.
///
/// If the popup button's menu is closed, the button should still display the
/// currently selected destination folder. For this purpose, this method updates
/// the top-most menu item to reflect the currently selected destination
/// folder - the top-most menu item is the one that the button displays when
/// the menu is closed.
///
/// @note This is an internal helper method, not an action method.
// -----------------------------------------------------------------------------
- (void) updateDestinationFolderButton:(NSString*)previousDestinationFolderType
{
  if (! m_destinationFolderButton)
    return;

  // If the previous type was "fixed location" we need to remove
  // the two menu items that were created to display that location
  if (previousDestinationFolderType &&
      [previousDestinationFolderType isEqualToString:destinationFolderTypeFixedLocation])
  {
    [m_destinationFolderButton removeItemAtIndex:0];
    [m_destinationFolderButton removeItemAtIndex:0];
  }

  if ([m_destinationFolderType isEqualToString:destinationFolderTypeSameAsArchive])
    [m_destinationFolderButton selectItemAtIndex:0];
  else if ([m_destinationFolderType isEqualToString:destinationFolderTypeAskWhenExpanding])
    [m_destinationFolderButton selectItemAtIndex:1];
  else if ([m_destinationFolderType isEqualToString:destinationFolderTypeFixedLocation])
  {
    [[m_destinationFolderButton menu] insertItem:[NSMenuItem separatorItem] atIndex:0];
    [m_destinationFolderButton insertItemWithTitle:[m_destinationFolder lastPathComponent] atIndex:0];
    [m_destinationFolderButton selectItemAtIndex:0];
    /// @todo make the following code work! With this code, the image displayed
    /// when the popup menu is closed is far too big!
    // NSMenuItem menuItem = m_destinationFolderButton.itemAtIndex(0);
    // menuItem.setImage(new NSFileWrapper(m_destinationFolder, false).icon());
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the "Start expanding after launch" button being clicked.
///
/// Enables/disables other buttons that depend on the checked/unchecked state
/// of the button that triggered this method.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) startExpandingAfterLaunchButtonClicked:(id)sender
{
  NSMutableArray* buttons = [NSMutableArray array];
  [buttons addObject:m_startExpandingAfterLaunchButton];
  [buttons addObject:m_quitAfterExpandButton];
  [buttons addObject:m_alwaysQuitAfterExpandButton];
  [self enableButtonHierarchy:buttons];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the "Quit after expand" button being clicked.
///
/// Enables/disables other buttons that depend on the checked/unchecked state
/// of the button that triggered this method.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) quitAfterExpandButtonClicked:(id)sender
{
  NSMutableArray* buttons = [NSMutableArray array];
  [buttons addObject:m_startExpandingAfterLaunchButton];
  [buttons addObject:m_quitAfterExpandButton];
  [buttons addObject:m_alwaysQuitAfterExpandButton];
  [self enableButtonHierarchy:buttons];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the "Look into folders" button being clicked.
///
/// Enables/disables other buttons that depend on the checked/unchecked state
/// of the button that triggered this method.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) lookIntoFoldersButtonClicked:(id)sender
{
  NSMutableArray* buttons = [NSMutableArray array];
  [buttons addObject:m_lookIntoFoldersButton];
  [buttons addObject:m_treatAllFilesAsArchivesButton];
  [self enableButtonHierarchy:buttons];
}

// -----------------------------------------------------------------------------
/// @brief Reads the user defaults for the NSRegistration domain from a file
/// inside the application bundle.
// -----------------------------------------------------------------------------
- (void) loadDefaultsToRegistrationDomain
{
  if (! m_userDefaults)
    return;
  NSBundle* mainBundle = [NSBundle mainBundle];
  if (! mainBundle)
    return;

  @try
  {
    NSString* defaultsPathName = [mainBundle pathForResource:registrationDomainDefaultsFileName ofType:nil];
    if (nil == defaultsPathName)
    {
      NSString* reason = [[[NSString stringWithString:@"The defaults file\n\n"]
        stringByAppendingString:registrationDomainDefaultsFileName]
        stringByAppendingString:@"\n\ncould not be found in the resources of the application bundle."];
      @throw [NSException exceptionWithName:@"AceXpanderException" reason:reason userInfo:nil];
    }

    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (! [fileManager fileExistsAtPath:defaultsPathName isDirectory:&isDirectory])
    {
      NSString* reason = [[[NSString stringWithString:@"The defaults file\n\n"]
        stringByAppendingString:defaultsPathName]
        stringByAppendingString:@"\n\ndoes not exist."];
      @throw [NSException exceptionWithName:@"AceXpanderException" reason:reason userInfo:nil];
    }

    if (! [fileManager isReadableFileAtPath:defaultsPathName])
    {
      NSString* reason = [[NSString stringWithString:@"No read access to defaults file\n\n"]
        stringByAppendingString:defaultsPathName];
      @throw [NSException exceptionWithName:@"AceXpanderException" reason:reason userInfo:nil];
    }

    NSData* defaultsXMLData = [NSData dataWithContentsOfFile:defaultsPathName];
    id defaultsObject = [NSPropertyListSerialization propertyListFromData:defaultsXMLData
                                                         mutabilityOption:NSPropertyListImmutable
                                                                   format:nil
                                                         errorDescription:nil];
    // Did we get a valid property list?
    if (nil == defaultsObject)
    {
      NSString* reason = [[NSString stringWithString:@"A property list could not be generated from the defaults file\n\n"]
        stringByAppendingString:defaultsPathName];
      @throw [NSException exceptionWithName:@"AceXpanderException" reason:reason userInfo:nil];
    }

    // We hope that "defaultsObject" - if it is not nil- is an NSDictionary.
    // Last time I checked with NSStringFromClass([defaultsObject class]), the
    // type was NSCFDictionary. CFDictionary is a "core foundation" (=carbon)
    // type that is documented to be toll-free bridged with NSDictionary, so
    // in theory it should be no problem to simply cast "defaultsObject" to
    // NSDictionary.
    [m_userDefaults registerDefaults:(NSDictionary*)defaultsObject];
  }
  @catch(NSException* exception)
  {
    // Notify the error handler that an error has occurred
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification
                                                        object:[exception reason]];
  }
}

// -----------------------------------------------------------------------------
/// @brief Enables/disables the first button @a enableButton if the second
/// button @a dependButton is checked/unchecked.
// -----------------------------------------------------------------------------
- (void) enableButton:(NSButton*)enableButton dependingOnOtherButton:(NSButton*)dependButton
{
  if (! enableButton || ! dependButton)
    return;

  BOOL checked;
  int state = [dependButton state];
  if (NSOnState == state)
    checked = true;
  else
    checked = false;

  [enableButton setEnabled:checked];
}

// -----------------------------------------------------------------------------
/// @brief Enables/disables buttons in a sequence of buttons @a buttons that
/// are depending on their predecessor's checked/unchecked state.
///
/// Beginning with the first button in the @a buttons array, the checked state
/// of the buttons in the array is tested. If the state is "on", the next button
/// in the array is enabled and tested. If the state is "off", @e all subsequent
/// buttons in the array are disabled.
///
/// @note The first button in the array is always enabled.
// -----------------------------------------------------------------------------
- (void) enableButtonHierarchy:(NSArray*)buttons
{
  if (! buttons)
    return;

  // The first button is always enabled
  BOOL enable = true;

  NSEnumerator* enumerator = [buttons objectEnumerator];
  NSButton* iterButton;
  while (iterButton = (NSButton*)[enumerator nextObject])
  {
    [iterButton setEnabled:enable];
    // As soon as the first button is disabled, we don't check the
    // button state anymore
    if (! enable)
      continue;
    // The first unchecked button will disable all subsequent buttons
    int state = [iterButton state];
    if (NSOffState == state)
      enable = false;
  }
}

@end
