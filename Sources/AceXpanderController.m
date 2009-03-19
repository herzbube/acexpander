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
#import "AceXpanderController.h"
#import "AceXpanderModel.h"
#import "AceXpanderPreferences.h"
#import "AceXpanderItem.h"
#import "AceXpanderGlobals.h"


/// @brief This category declares private methods for the AceXpanderController
/// class. 
@interface AceXpanderController(Private)
- (void) dealloc;

/// @name NSNibAwaking protocol
//@{
- (void) awakeFromNib;
//@}

/// @name NSApplication delegate
//@{
- (BOOL) application:(NSApplication*)theApplication openFile:(NSString*)fileName;
- (void) applicationDidFinishLaunching:(NSNotification*)aNotification;
- (void) applicationWillTerminate:(NSNotification*)aNotification;
//@}

/// @name NSWindow delegate
//@{
- (void) windowWillClose:(NSNotification*)aNotification;
- (void) windowDidBecomeMain:(NSNotification*)aNotification;
//@}

/// @name NSMenuValidation protocol
//@{
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem;
//@}

/// @name NSTableView delegate
//@{
- (void) tableViewSelectionDidChange:(NSNotification*)aNotification;
//@}

/// @name Action methods for items in "Edit" menu
//@{
- (void) queueAllItems:(id)sender;
- (void) queueItems:(id)sender;
- (void) unqueueAllItems:(id)sender;
- (void) unqueueItems:(id)sender;
- (void) removeAllItems:(id)sender;
- (void) removeItems:(id)sender;
//@}

/// @name Action methods for items in "Commands" menu
//@{
- (void) expandItems:(id)sender;
- (void) listItems:(id)sender;
- (void) testItems:(id)sender;
//@}

/// @name Action methods for items in application menu
//@{
- (void) showPreferencesDialog:(id)sender;
- (void) showUnaceVersion:(id)sender;
//@}

/// @name Action methods for items in "File" menu
//@{
- (void) showOpenDialog:(id)sender;
- (void) showFinderInfo:(id)sender;
- (void) revealInFinder:(id)sender;
//@}

/// @name Action methods for items in "Help" menu
//@{
- (void) showGPL:(id)sender;
- (void) showManual:(id)sender;
- (void) showReadme:(id)sender;
- (void) showChangeLog:(id)sender;
- (void) showReleasePlan:(id)sender;
- (void) showToDo:(id)sender;
- (void) gotoHomepage:(id)sender;
//@}

/// @name Action methods for items in "Window" menu
//@{
- (void) showMainWindow:(id)sender;
- (void) showResultWindow:(id)sender;
//@}

/// @name Action methods for items in "Options" menu
//@{
- (void) toggleAssumeYes:(id)sender;
- (void) toggleExtractFullPath:(id)sender;
- (void) toggleListVerbosely:(id)sender;
- (void) toggleShowComments:(id)sender;
- (void) toggleOverwriteFiles:(id)sender;
- (void) rememberMyDefaults:(id)sender;
- (void) forgetMyDefaults:(id)sender;
//@}

/// @name Action methods related to managing the password dialog
//@{
- (void) toggleUsePassword:(id)sender;
- (void) passwordDialogOKClicked:(id)sender;
- (void) passwordDialogCancelClicked:(id)sender;
//@}

/// @name Action methods, other
//@{
- (void) cancelCommand:(id)sender;
//@}

/// @name Notification handlers
//@{
- (void) commandThreadHasStarted;
- (void) commandThreadHasStopped;
- (void) errorConditionOccurred:(NSNotification*)aNotification;
- (void) updateResultWindow;
- (void) updateContentListDrawer;
- (void) awakeFromNibAfterModel;
//@}

/// @name Other methods
//@{
- (void) updateGUI;
- (void) setMenuItem:(NSMenuItem*)item state:(BOOL)newState;
- (void) showTextFileInWindow:(NSString*)fileName;
- (void) registerForNotifications;
//@}
@end

@implementation AceXpanderController

// -----------------------------------------------------------------------------
/// @brief Initializes an AceXpanderController object.
///
/// @note This is the designated initializer of AceXpanderController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // This must be the very first action, so that other classes may
  // report any errors to this central error handling class
  [self registerForNotifications];

  // Next create the applications user defaults/preferences object.
  // It will provide sensible defaults in the NSRegistration domain.
  m_thePreferences = [[AceXpanderPreferences alloc] init];
  // Store instance in a member variable because it is frequently used
  m_userDefaults = [[NSUserDefaults standardUserDefaults] retain];

  // Register for services in the Services system menu
  // We are not interested in receiving data of any type
  NSArray* returnTypes = nil;
  // We can send data of the types
  // - String (for Finder-ShowInfo, Finder-Reveal),
  // - Filename
  // - URL
  NSMutableArray* sendTypes = [NSMutableArray array];
  [sendTypes addObject:NSStringPboardType];
  [sendTypes addObject:NSFilenamesPboardType];
  [sendTypes addObject:NSURLPboardType];
  // Do the registering
  [[NSApplication sharedApplication] registerServicesMenuSendTypes:sendTypes returnTypes:returnTypes];

  // Perform other initialization
  m_passwordDialogCancelClicked = YES;
  m_myDefaultsHaveChanged = NO;

  // Return 
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this AceXpanderController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (m_thePreferences)
    [m_thePreferences autorelease];
  if (m_theModel)
    [m_theModel autorelease];
  if (m_theTable)
    [m_theTable autorelease];
  if (m_userDefaults)
    [m_userDefaults autorelease];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Is called after an AceXpanderController object has been allocated and
/// initialized from the .nib
///
/// @note This is an NSNibAwaking protocol method.
// -----------------------------------------------------------------------------
- (void) awakeFromNib
{
  // When the .nib is edited with InterfaceBuilder, the progress
  // indicator should be visible, otherwise it might be overlooked
  // by the person who is editing the .nib
  // -> we set this property here instead of in InterfaceBuilder
  if (m_progressIndicator)
    [m_progressIndicator setDisplayedWhenStopped:NO];

  // Tell these windows to automatically restore their frame from the user
  // defaults, and save it to the user defaults if any changes occur
  if (m_mainWindow)
    [m_mainWindow setFrameAutosaveName:mainWindowFrameNameKey];
  if (m_resultWindow)
    [m_resultWindow setFrameAutosaveName:resultWindowFrameNameKey];

  // Show the result window if the user defaults say so
  if (m_userDefaults && [m_userDefaults boolForKey:showResultWindowKey])
  {
    if (m_resultWindow)
      [m_resultWindow makeKeyAndOrderFront:self];
    if (m_mainWindow)
      [m_mainWindow makeKeyAndOrderFront:self];
  }
}

// -----------------------------------------------------------------------------
/// @brief Adds an item for file @a fileName to the application model, then
/// returns true. See AceXpanderModel::addItemForFile:() for details.
///
/// If this message is received during application launch, it is received
/// before applicationDidFinishLaunching:(), but after
/// applicationWillFinishLaunching:(). If multiple files should be opened,
/// the message is sent once for every file.
///
/// @note This is an NSApplication delegate method.
// -----------------------------------------------------------------------------
- (BOOL) application:(NSApplication*)theApplication openFile:(NSString*)fileName
{
  if (m_theModel)
    [m_theModel addItemForFile:fileName];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Starts expanding items that were previously added to the application
/// model by application:openFile:().
///
/// This can be prevented by a user preference. The application in this case
/// moves into interactive mode. The application also moves into interactive
/// mode if the application model does not contain any items.
///
/// @a aNotification is ignored.
///
/// @note This is an NSApplication delegate method.
// -----------------------------------------------------------------------------
- (void) applicationDidFinishLaunching:(NSNotification*)aNotification
{
  // Set initial state of some GUI elements (e.g. "expand" button is disabled
  // if no items have been added by application:openFile:()
  [self updateGUI];

  // We need the model for all further tasks
  if (! m_theModel)
    return;

  // If the user defaults say so, don't start automatically expanding
  // items on application launch
  if (m_userDefaults && ! [m_userDefaults boolForKey:startExpandingAfterLaunchKey])
  {
    [m_theModel setInteractive:true];
    return;
  }

  // If there are no items in the table the user must have launched the
  // application without double-clicking an archive (or a similar
  // action). In this case we switch to interactive mode (but do
  // nothing else)
  if (0 == [m_theModel numberOfRowsInTableView:nil])
  {
    [m_theModel setInteractive:true];
    return;
  }

  [m_theModel selectItemsWithState:QueuedState];
  [self expandItems:self];
}

// -----------------------------------------------------------------------------
/// @brief Stops any running command (as if the user had clicked the "cancel"
/// button, then sends an autorelease message to this AceXpanderController.
///
/// Autoreleasing and therefore deallocating this controller triggers
/// deallocation of all the application's objects (e.g. application model).
///
/// @a aNotification is ignored.
///
/// @note This is an NSApplication delegate method.
// -----------------------------------------------------------------------------
- (void)applicationWillTerminate:(NSNotification*)aNotification
{
  [self cancelCommand:nil];
  [self autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to windows being closed.
///
/// If the application's main window is closed, and the user preferences do not
/// prevent it, the application is terminated.
///
/// If the result window is closed, this fact is remembered, so that the next
/// time the application is started the result window is not displayed.
///
/// @note This is an NSWindow delegate method.
// -----------------------------------------------------------------------------
- (void) windowWillClose:(NSNotification*)aNotification
{
  if (! m_userDefaults)
    return;

  id window = [aNotification object];
  if (window == m_mainWindow)
  {
    // Depending on the user default, terminate the application when the
    // main window is closed
    if ([m_userDefaults boolForKey:quitAppWhenMainWindowIsClosedKey])
      [[NSApplication sharedApplication] terminate:self];
  }
  else if (window == m_resultWindow)
    [m_userDefaults setBool:false forKey:showResultWindowKey];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to windows becoming the main window
///
/// If the result window is becoming the main window, this fact is remembered,
/// so that the next time the application is started the result window is also
/// displayed.
///
/// @note This is an NSWindow delegate method.
// -----------------------------------------------------------------------------
- (void) windowDidBecomeMain:(NSNotification*)aNotification
{
  if (! m_userDefaults)
    return;

  id window = [aNotification object];
  if (window == m_resultWindow)
    [m_userDefaults setBool:true forKey:showResultWindowKey];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a menuItem should be enabled, false if it should be
/// disabled.
///
/// In general, all menu items are disabled while an unace command is being
/// executed. In other cases, menu items are disabled if the action that they
/// trigger currently does not make sense (e.g. the "Expand" menu item is
/// disabled if the table view does not contain any items to expand).
///
/// @note This is an NSMenuValidation protocol method.
// -----------------------------------------------------------------------------
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
  // Disable menus while expansion is in progress
  if (! m_theModel || [m_theModel isCommandRunning])
    return false;

  // Bug in unace: "assume yes" must always be turned on when
  // overwrite is turned on
  if (menuItem == m_assumeYesMenuItem)
  {
    if (! m_theModel || [m_theModel overwriteFiles])
      return false;
    else
      return true;
  }
  // Disable "main window" menu item if main window is already shown
  else if (menuItem == m_showMainWindowMenuItem)
  {
    if (! m_mainWindow || [m_mainWindow isVisible])
      return false;
    else
      return true;
  }
  // Disable "main window" menu item if main window is already shown
  else if (menuItem == m_showResultWindowMenuItem)
  {
    if (! m_resultWindow || [m_resultWindow isVisible])
      return false;
    else
      return true;
  }
  /// @todo Enable these items if application is able to call
  /// the corresponding services in the Services system menu.
  /// -> probably possible only with ObjC function NSPerformService()
  else if (menuItem == m_showInfoInFinderMenuItem ||
           menuItem == m_revealInFinderMenuItem)
  {
    return false;
  }
  else if (menuItem == m_rememberMyDefaultsMenuItem)
  {
    return m_myDefaultsHaveChanged;
  }
  else if (menuItem == m_forgetMyDefaultsMenuItem)
  {
    if (m_userDefaults && [m_userDefaults boolForKey:optionDefaultsRememberedKey])
      return true;
    else
      return false;
  }
  else if (menuItem == m_requeueMenuItem || menuItem == m_unqueueMenuItem ||
           menuItem == m_removeMenuItem || menuItem == m_expandMenuItem ||
           menuItem == m_listContentMenuItem || menuItem == m_testIntegrityMenuItem)
  {
    if (m_theTable && 1 <= [m_theTable numberOfSelectedRows])
      return true;
    else
      return false;
  }

  // Enable items in all other circumstances
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the selection in the table view being changed.
///
/// Updates the result window and the content list drawer.
///
/// @note This is an NSTableView delegate method.
// -----------------------------------------------------------------------------
- (void) tableViewSelectionDidChange:(NSNotification*)aNotification
{
  [self updateResultWindow];
  [self updateContentListDrawer];
  [self updateGUI];
}

// -----------------------------------------------------------------------------
/// @brief Sets all items to #QueuedState, regardless of whether or not they
/// are selected.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) queueAllItems:(id)sender
{
  if (m_theModel)
    [m_theModel setAllItemsToState:QueuedState fromState:-1];
}

// -----------------------------------------------------------------------------
/// @brief Sets all selected items to #QueuedState.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) queueItems:(id)sender
{
  if (m_theModel)
    [m_theModel setSelectedItemsToState:QueuedState fromState:-1];
}

// -----------------------------------------------------------------------------
/// @brief Sets all items with #QueuedState to #SkipState, regardless of
/// whether or not they are selected.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) unqueueAllItems:(id)sender
{
  if (m_theModel)
    [m_theModel setAllItemsToState:SkipState fromState:QueuedState];
}

// -----------------------------------------------------------------------------
/// @brief Sets all selected items from #QueuedState to #SkipState.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) unqueueItems:(id)sender
{
  if (m_theModel)
    [m_theModel setSelectedItemsToState:SkipState fromState:QueuedState];
}

// -----------------------------------------------------------------------------
/// @brief Removes all items from the model and table view, regardless of
/// whether or not they are selected.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) removeAllItems:(id)sender
{
  if (m_theModel)
    [m_theModel removeAllItems];
}

// -----------------------------------------------------------------------------
/// @brief Removes all selected items from the model and table view.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) removeItems:(id)sender
{
  if (m_theModel)
    [m_theModel removeSelectedItems];
}

// -----------------------------------------------------------------------------
/// @brief Starts the "expand" command for all selected items.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) expandItems:(id)sender
{
  if (! m_theModel)
    return;
  [m_theModel startExpandItems];
  [self updateGUI];
}

// -----------------------------------------------------------------------------
/// @brief Starts the "list" command for all selected items.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) listItems:(id)sender
{
  if (! m_theModel)
    return;
  [m_theModel startListItems];
  [self updateGUI];
  if (m_theContentListDrawer)
  {
    // If the list content drawer is not visible -> show it
    switch ([m_theContentListDrawer state])
    {
      case NSDrawerClosedState:
      case NSDrawerClosingState:
        [m_theContentListDrawer open];
        break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Starts the "test" command for all selected items.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) testItems:(id)sender
{
  if (! m_theModel)
    return;
  [m_theModel startTestItems];
  [self updateGUI];
}

// -----------------------------------------------------------------------------
/// @brief Displays the user preferences dialog.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showPreferencesDialog:(id)sender
{
  if (m_thePreferences)
    [m_thePreferences showPreferencesDialog];
}

// -----------------------------------------------------------------------------
/// @brief Displays an alert panel with the version of the unace binary that
/// the application is currently using.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showUnaceVersion:(id)sender
{
  // We don't actually launch a thread here - we simply use AceXpanderThread's
  // wrapper facilities for a one-shot execution of unace to get at the version
  // that we are currently using
  NSString* version = nil;
  if (m_theModel)
    version = [m_theModel unaceVersion];
  if (version)
  {
    NSAlert* alert = [NSAlert alertWithMessageText:@"Version information"
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:version];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert runModal];
  }
  else
  {
    NSAlert* alert = [NSAlert alertWithMessageText:@"Could not determine version information"
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];
  }
}

// -----------------------------------------------------------------------------
/// @brief Displays the open dialog.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showOpenDialog:(id)sender
{
  if (! m_theModel)
    return;

  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  if (! openPanel)
    return;
  [openPanel setAllowsMultipleSelection:YES];
  [openPanel setCanChooseDirectories:YES];
  NSString* directory = nil;
  NSString* selectedFile = nil;
  NSArray* fileTypes = nil;
  int iResult = [openPanel runModalForDirectory:directory file:selectedFile types:fileTypes];
  if (NSOKButton == iResult)
  {
    NSArray* fileNames = [openPanel filenames];
    NSEnumerator* enumerator = [fileNames objectEnumerator];
    NSString* fileName;
    while (fileName = (NSString*)[enumerator nextObject])
      [m_theModel addItemForFile:fileName];
  }
}

// -----------------------------------------------------------------------------
/// @brief Displays an information window as if the user selected the
/// corresponding action in the Finder.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showFinderInfo:(id)sender
{
  /// @todo Implement this
  NSAlert* alert = [NSAlert alertWithMessageText:@"Sorry"
                                   defaultButton:nil
                                 alternateButton:nil
                                     otherButton:nil
                       informativeTextWithFormat:@"Not yet implemented"];
  [alert setAlertStyle:NSInformationalAlertStyle];
  [alert runModal];
}

// -----------------------------------------------------------------------------
/// @brief Reveals the selected archive file in the Finder.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) revealInFinder:(id)sender
{
  /// @todo Implement this
  NSAlert* alert = [NSAlert alertWithMessageText:@"Sorry"
                                   defaultButton:nil
                                 alternateButton:nil
                                     otherButton:nil
                       informativeTextWithFormat:@"Not yet implemented"];
  [alert setAlertStyle:NSInformationalAlertStyle];
  [alert runModal];
}

// -----------------------------------------------------------------------------
/// @brief Displays a window that contains the GPL license information (i.e.
/// the COPYING file).
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showGPL:(id)sender
{
  [self showTextFileInWindow:gnuGPLFileName];
}

// -----------------------------------------------------------------------------
/// @brief Displays a window that contains the MANUAL file.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showManual:(id)sender
{
  [self showTextFileInWindow:manualFileName];
}

// -----------------------------------------------------------------------------
/// @brief Displays a window that contains the README file.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showReadme:(id)sender
{
  [self showTextFileInWindow:readMeFileName];
}

// -----------------------------------------------------------------------------
/// @brief Displays a window that contains the ChangeLog file.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showChangeLog:(id)sender
{
  [self showTextFileInWindow:changeLogFileName];
}

// -----------------------------------------------------------------------------
/// @brief Displays a window that contains the ReleasePlan file.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showReleasePlan:(id)sender
{
  [self showTextFileInWindow:releasePlanFileName];
}

// -----------------------------------------------------------------------------
/// @brief Displays a window that contains the TODO file.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showToDo:(id)sender
{
  [self showTextFileInWindow:toDoFileName];
}

// -----------------------------------------------------------------------------
/// @brief Displays a window that contains the ChangeLog file.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) gotoHomepage:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:homePageURL]];
}

// -----------------------------------------------------------------------------
/// @brief Displays the application's main window in front of all other windows.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showMainWindow:(id)sender
{
  if (m_mainWindow)
    [m_mainWindow makeKeyAndOrderFront:self];
  // No need to call makeMainWindow()
}

// -----------------------------------------------------------------------------
/// @brief Displays the result window in front of all other windows.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) showResultWindow:(id)sender
{
  if (m_resultWindow)
    [m_resultWindow makeKeyAndOrderFront:self];
  // No need to call makeMainWindow()
}

// -----------------------------------------------------------------------------
/// @brief Toggles the "assume yes" option.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) toggleAssumeYes:(id)sender
{
  if (! m_theModel)
    return;
  BOOL newState = ! [m_theModel assumeYes];
  [m_theModel setAssumeYes:newState];
  [self setMenuItem:(NSMenuItem*)sender state:newState];
  m_myDefaultsHaveChanged = true;
}

// -----------------------------------------------------------------------------
/// @brief Toggles the "extract full path" option.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) toggleExtractFullPath:(id)sender
{
  if (! m_theModel)
    return;
  BOOL newState = ! [m_theModel extractFullPath];
  [m_theModel setExtractFullPath:newState];
  [self setMenuItem:(NSMenuItem*)sender state:newState];
  m_myDefaultsHaveChanged = true;
}

// -----------------------------------------------------------------------------
/// @brief Toggles the "list verbosely" option.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) toggleListVerbosely:(id)sender
{
  if (! m_theModel)
    return;
  BOOL newState = ! [m_theModel listVerbosely];
  [m_theModel setListVerbosely:newState];
  [self setMenuItem:(NSMenuItem*)sender state:newState];
  m_myDefaultsHaveChanged = true;
}

// -----------------------------------------------------------------------------
/// @brief Toggles the "show comments" option.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) toggleShowComments:(id)sender
{
  if (! m_theModel)
    return;
  BOOL newState = ! [m_theModel showComments];
  [m_theModel setShowComments:newState];
  [self setMenuItem:(NSMenuItem*)sender state:newState];
  m_myDefaultsHaveChanged = true;
}

// -----------------------------------------------------------------------------
/// @brief Toggles the "overwrite files" option.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) toggleOverwriteFiles:(id)sender
{
  if (! m_theModel)
    return;
  BOOL newState = ! [m_theModel overwriteFiles];
  [m_theModel setOverwriteFiles:newState];
  [self setMenuItem:(NSMenuItem*)sender state:newState];
  m_myDefaultsHaveChanged = true;

  // Bug in unace: "assume yes" must always be turned on when
  // overwrite is turned on
  if (newState)
  {
    [m_theModel setAssumeYes:true];
    [self setMenuItem:(NSMenuItem*)m_assumeYesMenuItem state:true];
  }
}

// -----------------------------------------------------------------------------
/// @brief Makes the current option settings into default settings that will
/// be reloaded the next time the application is started.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) rememberMyDefaults:(id)sender
{
  if (! m_userDefaults || ! m_theModel)
    return;

  [m_userDefaults setBool:[m_theModel overwriteFiles] forKey:overwriteFilesOptionKey];
  [m_userDefaults setBool:[m_theModel extractFullPath] forKey:extractWithFullPathOptionKey];
  [m_userDefaults setBool:[m_theModel assumeYes] forKey:assumeYesOptionKey];
  [m_userDefaults setBool:[m_theModel showComments] forKey:showCommentsOptionKey];
  [m_userDefaults setBool:[m_theModel listVerbosely] forKey:listVerboselyOptionKey];

  [m_userDefaults setBool:true forKey:optionDefaultsRememberedKey];

  m_myDefaultsHaveChanged = false;
}

// -----------------------------------------------------------------------------
/// @brief Resets all options (e.g. "overwrite files") to their factory
/// settings.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) forgetMyDefaults:(id)sender
{
  if (! m_userDefaults || ! m_theModel)
    return;

  [m_userDefaults removeObjectForKey:overwriteFilesOptionKey];
  [m_userDefaults removeObjectForKey:extractWithFullPathOptionKey];
  [m_userDefaults removeObjectForKey:assumeYesOptionKey];
  [m_userDefaults removeObjectForKey:showCommentsOptionKey];
  [m_userDefaults removeObjectForKey:listVerboselyOptionKey];

  [m_userDefaults removeObjectForKey:optionDefaultsRememberedKey];

  [m_theModel updateMyDefaultsFromUserDefaults];
  [self setMenuItem:m_overwriteFilesMenuItem state:[m_theModel overwriteFiles]];
  [self setMenuItem:m_extractFullPathMenuItem state:[m_theModel extractFullPath]];
  [self setMenuItem:m_assumeYesMenuItem state:[m_theModel assumeYes]];
  [self setMenuItem:m_showCommentsMenuItem state:[m_theModel showComments]];
  [self setMenuItem:m_listVerboselyMenuItem state:[m_theModel listVerbosely]];

  m_myDefaultsHaveChanged = false;
}

// -----------------------------------------------------------------------------
/// @brief If password is toggled on, this method shows an application-modal
/// dialog that queries the user for the password
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) toggleUsePassword:(id)sender
{
  if (! m_theModel)
    return;

  NSString* password = nil;
  BOOL usePassword = ! [m_theModel usePassword];

  // Only display the dialog if the option is toggled on
  if (usePassword)
  {
    // Load the .nib if not yet done. m_passwordDialog is an outlet
    // and is set when the .nib is loaded. This works because
    // - we tell loadNibNamed that this object (self) is the owner of the .nib
    // - and in the .nib the "file's owner" is set to be an AceXpanderController
    //   object
    if (nil == m_passwordDialog)
    {
      [NSBundle loadNibNamed:passwordDialogNibName owner:self];
      if (! m_passwordDialog)
      {
        // Notify the error handler that an error has occurred
        NSString* errorDescription = @"m_passwordDialog is still unset after loading the password dialog .nib";
        [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification
                                                            object:errorDescription];
        return;
      }
    }
    
    // Prepare and run the dialog. The sheet is attached to m_mainWindow
    NSApplication* theApp = [NSApplication sharedApplication];
    if (! theApp)
      return;
    [theApp beginSheet:m_passwordDialog modalForWindow:m_mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
    [theApp runModalForWindow:m_passwordDialog];
    
    // -------------------------------------------------
    // --- At this point the modal dialog is running ---
    // -------------------------------------------------

    // Clean up and close the dialog
    [theApp endSheet:m_passwordDialog];
    // Remove dialog from screen
    [m_passwordDialog orderOut:self];

    // If the user clicked cancel, the usePassword option remains
    // toggled off
    if (m_passwordDialogCancelClicked)
      usePassword = false;
    // Otherwise we fetch the entered password
    else
      password = [m_passwordTextField stringValue];
  }

  // Finally update the model
  [m_theModel setUsePassword:usePassword withPassword:password];
  [self setMenuItem:(NSMenuItem*)sender state:usePassword];
}

// -----------------------------------------------------------------------------
/// @brief Closes the password query dialog and remembers that OK was clicked.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) passwordDialogOKClicked:(id)sender
{
  m_passwordDialogCancelClicked = false;
  [[NSApplication sharedApplication] stopModal];
}

// -----------------------------------------------------------------------------
/// @brief Closes the password query dialog and remembers that Cancel was
/// clicked.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) passwordDialogCancelClicked:(id)sender
{
  m_passwordDialogCancelClicked = true;
  [[NSApplication sharedApplication] stopModal];
}

// -----------------------------------------------------------------------------
/// @brief Cancels the command that is currently running.
///
/// @note This is an action method.
// -----------------------------------------------------------------------------
- (void) cancelCommand:(id)sender
{
  if (m_theModel)
    [m_theModel stopCommand];
}

// -----------------------------------------------------------------------------
/// @brief Updates the GUI after an unace command has started processing.
// -----------------------------------------------------------------------------
- (void) commandThreadHasStarted
{
  [self updateGUI];
}

// -----------------------------------------------------------------------------
/// @brief Updates the GUI after an unace command has finished processing its
/// items.
///
/// If the application is in non-interactive mode (i.e. the command that has
/// just finished was the command that was started immediately after application
/// launch), the application is terminated, unless the user preferences prevent
/// termination.
// -----------------------------------------------------------------------------
- (void) commandThreadHasStopped
{
  [self updateGUI];

  // Terminate application if all items expanded successfully and
  // the application mode is non-interactive. If this method is called
  // after the initial launch sequence's expand thread has finished,
  // the application mode should still be non-interactive.
  if (m_theModel && ! [m_theModel interactive])
  {
    // If the user defaults say so, don't terminate the application
    // after expanding items on application launch
    if (m_userDefaults && ! [m_userDefaults boolForKey:quitAfterExpandKey])
      [m_theModel setInteractive:true];
    // If the user defaults say so, terminate the application even if
    // an error occurred
    else if (m_userDefaults && [m_userDefaults boolForKey:alwaysQuitAfterExpandKey])
      [[NSApplication sharedApplication] terminate:self];
    // No special user defaults: check if all items expanded
    // successfully. If not, continue to run in interactive mode
    else if (! [m_theModel haveAllItemsState:SuccessState])
      [m_theModel setInteractive:true];
    // All items expanded successfully, therefore terminate the
    // application
    else
      [[NSApplication sharedApplication] terminate:self];
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs application-wide error handling.
///
/// This method is called by the NSNotificationCenter when a severe error
/// condition is detected. Trivial errors should be handled by the code that
/// detects the error.
///
/// If a method detects a severe error condition it should take the
/// appropriate steps for a first-level reaction to the error (usually it
/// just terminates/aborts the operation it was supposed to perform in a
/// clean way). Then it it should compose a text (ideally one or more
/// whole sentences) describing the error condition and post it together
/// with an NSNotification to the NSNotificationCenter.
///
/// This method then reacts to the notification by displaying an alert dialog
/// to the user, informing her about the problem and including the error
/// description. The dialog offers the user to terminate the application
/// (the default button), or to ignore the error.
// -----------------------------------------------------------------------------
- (void) errorConditionOccurred:(NSNotification*)aNotification
{
  NSAlert* alert = [NSAlert alertWithMessageText:@"AceXpander encountered a critical error!"
                                   defaultButton:@"Terminate application"
                                 alternateButton:@"Ignore error & continue"
                                     otherButton:nil
                       informativeTextWithFormat:(NSString*)[aNotification object]];
  [alert setAlertStyle:NSCriticalAlertStyle];
  int buttonClicked = [alert runModal];
  // Terminate the application if default button was clicked
  // Note: the documentation for the "runModal" method says that the method's
  // return values are the "new" (=more modern) values NSAlertFirstButtonReturn,
  // NSAlertSecondButtonReturn, etc. This does ***NOT*** apply to our case
  // because we have created the alert using "alertWithMessageText...", and this
  // method's documentation clearly states that the "old" return values
  // NSAlertDefaultReturn, NSAlertAlternateReturn, etc. are used.
  if (NSAlertDefaultReturn == buttonClicked)
    [[NSApplication sharedApplication] terminate:self];
}

// -----------------------------------------------------------------------------
/// @brief Updates the result window with information about the item that is
/// currently selected in the main table view.
///
/// If more than one item (or no item) is selected, the result window is
/// cleared.
///
/// This method is called by the default notification centre when an
/// AceXpanderItem sends a corresponding notification to indicate that its
/// stdout and stderr messages have changed. This method is also called when
/// the main table view's selection changes
// -----------------------------------------------------------------------------
- (void) updateResultWindow
{
  if (! m_theTable || ! m_theModel)
    return;

  if (1 != [m_theTable numberOfSelectedRows])
  {
    [m_stdoutTextView setString:@""];
    [m_stderrTextView setString:@""];
  }
  else
  {
    AceXpanderItem* item = [m_theModel itemForIndex:[m_theTable selectedRow]];
    NSString* messageStdout = [item messageStdout];
    if (messageStdout)
      [m_stdoutTextView setString:messageStdout];
    else
      [m_stdoutTextView setString:@""];
    NSString* messageStderr = [item messageStderr];
    if (messageStderr)
      [m_stderrTextView setString:messageStderr];
    else
      [m_stderrTextView setString:@""];
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the archive content drawer to display the content of the
/// item that is currently selected in the main table view.
///
/// If more than one item (or no item) is selected, the content drawer is
/// cleared.
///
/// This method is called by the default notification centre when an
/// AceXpanderItem sends a corresponding notification to indicate that its
/// content list has changed. This method is also called when the main table
/// view's selection changes
// -----------------------------------------------------------------------------
- (void) updateContentListDrawer
{
  if (! m_theTable || ! m_theModel || ! m_theContentListTable)
    return;
  
  if (1 != [m_theTable numberOfSelectedRows])
    [m_theContentListTable setDataSource:nil];
  else
  {
    AceXpanderItem* item = [m_theModel itemForIndex:[m_theTable selectedRow]];
    [m_theContentListTable setDataSource:item];
  }

  [m_theContentListTable reloadData];
}

// -----------------------------------------------------------------------------
/// @brief This method performs initializiation operations that need a delay
/// until after the application model has completely executed its
/// awakeFromNib:() method.
///
/// This method is called by the notification center after the model announces
/// that it has finished processing its awakeFromNib:() method.
// -----------------------------------------------------------------------------
- (void) awakeFromNibAfterModel
{
  // Initialize menu items that can be checked/unchecked with the
  // default state of the corresponding model data
  [self setMenuItem:m_overwriteFilesMenuItem state:[m_theModel overwriteFiles]];
  [self setMenuItem:m_extractFullPathMenuItem state:[m_theModel extractFullPath]];
  [self setMenuItem:m_assumeYesMenuItem state:[m_theModel assumeYes]];
  [self setMenuItem:m_showCommentsMenuItem state:[m_theModel showComments]];
  [self setMenuItem:m_listVerboselyMenuItem state:[m_theModel listVerbosely]];
  [self setMenuItem:m_usePasswordMenuItem state:[m_theModel usePassword]];
}

// -----------------------------------------------------------------------------
/// @brief Disables/enables buttons and other GUI elements depending on whether
/// an unace command is currently running, and whether any items are selected
/// in the GUI main table.
///
/// @note This is an internal helper method.
// -----------------------------------------------------------------------------
- (void) updateGUI
{
  bool isCommandRunning = false;
  if (m_theModel)
    isCommandRunning = [m_theModel isCommandRunning];
  int numberOfSelectedRows = 0;
  if (m_theTable)
    numberOfSelectedRows = [m_theTable numberOfSelectedRows];

  if (m_expandButton)
    [m_expandButton setEnabled:(! isCommandRunning && numberOfSelectedRows > 0)];
  if (m_cancelButton)
    [m_cancelButton setEnabled:isCommandRunning];

  if (isCommandRunning)
    [m_progressIndicator startAnimation:self];
  else
    [m_progressIndicator stopAnimation:self];
}

// -----------------------------------------------------------------------------
/// @brief Sets the state of @a item to the new state @a newState.
///
/// @note This is an internal helper method.
// -----------------------------------------------------------------------------
- (void) setMenuItem:(NSMenuItem*)item state:(BOOL)newState
{
  if (newState)
    [item setState:NSOnState];
  else
    [item setState:NSOffState];
}

// -----------------------------------------------------------------------------
/// @brief Shows the content of file @a fileName in a separate window.
///
/// @note This is an internal helper method.
// -----------------------------------------------------------------------------
- (void) showTextFileInWindow:(NSString*)fileName
{
  // Try to get the file's content
  NSString* textFileContent = nil;
  NSBundle* mainBundle = [NSBundle mainBundle];
  if (mainBundle)
  {
    NSString* textFilePath = [mainBundle pathForResource:fileName ofType:nil];
    if (textFilePath)
    {
      textFileContent = [NSString stringWithContentsOfFile:textFilePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    }
  }

  if (textFileContent)
  {
    [m_textView setString:textFileContent];
    [m_textViewWindow setTitle:fileName];
    [m_textViewWindow makeKeyAndOrderFront:self];
    // No need to call makeMainWindow()
  }
  else
  {
    NSAlert* alert = [NSAlert alertWithMessageText:@"Could not open file"
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:fileName];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert runModal];
  }
}

// -----------------------------------------------------------------------------
/// @brief Registers with the default notification center for getting various
/// notifications
// -----------------------------------------------------------------------------
- (void) registerForNotifications
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  if (! center)
    return;

  // Register for notification posted by the command thread when it
  // is launched
  [center addObserver:self
             selector:@selector(commandThreadHasStarted)
                 name:commandThreadHasStartedNotification
               object:nil];
  // Register for notification posted by the command thread after it
  // has finished processing its items
  [center addObserver:self
             selector:@selector(commandThreadHasStopped)
                name:commandThreadHasStoppedNotification
              object:nil];
  // Register for notification posted by anybody when an error condition
  // occurs
  [center addObserver:self
             selector:@selector(errorConditionOccurred:)
                 name:errorConditionOccurredNotification
               object:nil];
  // Register for notification posted by AceXpanderItem instances
  // when their stdout and stderr messages have changed
  [center addObserver:self
             selector:@selector(updateResultWindow)
                 name:updateResultWindowNotification
               object:nil];
  // Register for notification posted by AceXpanderItem instances
  // when their content list has changed
  [center addObserver:self
             selector:@selector(updateContentListDrawer)
                 name:updateContentListDrawerNotification
               object:nil];
  // Register for notification posted by AceXpanderModel when it
  // has finished processing its awakeFromNib() method
  [center addObserver:self
             selector:@selector(awakeFromNibAfterModel)
                 name:modelHasFinishedAwakeFromNibNotification
               object:nil];
}

@end
