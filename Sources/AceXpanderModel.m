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
#import "AceXpanderModel.h"
#import "AceXpanderController.h"
#import "AceXpanderPreferences.h"
#import "AceXpanderItem.h"
#import "AceXpanderThread.h"

#include <stdio.h>

// Constants
static NSString* columnIdentifierIcon = @"icon";
static NSString* columnIdentifierFileName = @"fileName";
static NSString* columnIdentifierState = @"state";


/// @brief This category declares private methods for the AceXpanderModel
/// class. 
@interface AceXpanderModel(Private)
- (void) dealloc;
- (void) awakeFromNib;
- (bool) startThreadWithCommand:(int)command;
- (int) numberOfRowsInTableView:(NSTableView*)aTableView;
- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex;
@end


@implementation AceXpanderModel

// -----------------------------------------------------------------------------
/// @brief Initializes an AceXpanderModel object.
///
/// @note This is the designated initializer of AceXpanderModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // Initialize members
  m_itemList = [[NSMutableArray array] retain];
  m_overwriteFiles = false;
  m_extractFullPath = false;
  m_assumeYes = false;
  m_showComments = false;
  m_listVerbosely = false;
  m_usePassword = false;
  m_debugMode = false;
  m_interactive = false;
  m_theDocumentController = [[NSDocumentController sharedDocumentController] retain];

  // Return 
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this AceXpanderModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // Deallocate thread first, before any AceXpanderItem that it still
  // references is deallocated
  if (m_commandThread)
    [m_commandThread autorelease];
  // When the array is deallocated, it releases all items for us
  if (m_itemList)
    [m_itemList autorelease];
  if (m_theDocumentController)
    [m_theDocumentController autorelease];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Is called after an AceXpanderModel object has been allocated and
/// initialized from the .nib
///
/// @note This is an NSNibAwaking protocol method.
// -----------------------------------------------------------------------------
- (void) awakeFromNib
{
  if (m_theTable)
  {
    // Replace the icon column cell with a cell that can display
    // images. I didn't find any way to set this in InterfaceBuilder
    NSTableColumn* iconColumn = [m_theTable tableColumnWithIdentifier:columnIdentifierIcon];
    if (iconColumn)
    {
      NSCell* iconCell = [[NSCell alloc] initImageCell:nil];
      if (iconCell)
      {
        [iconColumn setDataCell:iconCell];
        // Release the cell - we created it using an init... method, therefore
        // we are its owner according to Cocoa object ownership policy
        [iconCell release];
      }
    }
  }

  [self updateMyDefaultsFromUserDefaults];

  // Notify observers that the model has finished processing the
  // awakeFromNib:() method
  [[NSNotificationCenter defaultCenter] postNotificationName:modelHasFinishedAwakeFromNibNotification object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Adds a new AceXpanderItem instance to this model that represents the
/// file named @a fileName.
///
/// The item is added to the end of the list. The GUI is automatically updated
/// to display the item.
///
/// If @a fileName refers to a folder, the folder and all its sub-folders are
/// recursively examined: one item is added for each file found. The user can
/// restrict this "look into folders" feature to files with extension .ace,
/// or she can completely disable the feature, in the preferences dialog.
// -----------------------------------------------------------------------------
- (void) addItemForFile:(NSString*)fileName
{
  if (! fileName)
    return;

  // Check if a file or directory exists
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (! fileManager)
    return;
  BOOL isDirectory;
  if (! [fileManager fileExistsAtPath:fileName isDirectory:&isDirectory])
    return;

  // If the user defaults say so, check whether the item is a folder
  // and if it is, recursively call this method for each item inside
  // the folder
  if (isDirectory)
  {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if (! userDefaults)
      return;
    if (! [userDefaults boolForKey:lookIntoFoldersKey])
      return;   // throw away a folder if we should not look into it

    // Check if we should add items for all regular files, or only for files
    // with extension ".ace"
    BOOL treatAllFilesAsArchives = [userDefaults boolForKey:treatAllFilesAsArchivesKey];

    // Iterate only children directly below the directory
    NSArray* directoryContents = [fileManager directoryContentsAtPath:fileName];
    NSEnumerator* enumerator = [directoryContents objectEnumerator];
    NSString* iterFilename;
    while (iterFilename = (NSString*)[enumerator nextObject])
    {
      NSString* iterPath = [fileName stringByAppendingPathComponent:iterFilename];
      if (! [fileManager fileExistsAtPath:iterPath isDirectory:&isDirectory])
        continue;
      // If it's not a directory, we need to look at the file's extension if
      // the user has turned on that restriction
      if (! isDirectory && ! treatAllFilesAsArchives)
      {
        if (! [[iterFilename pathExtension] isEqualToString: @"ace"])
          continue;
      }
      [self addItemForFile:iterPath];
    }
  }   // if (isDirectory)
  else
  {
    // Create the item
    AceXpanderItem* item = [[AceXpanderItem alloc] initWithFile:fileName model:self];
    // We want the array to retain and release the object for us -> decrease
    // the retain count by 1 (was set to 1 by alloc/init)
    [item autorelease];
    [m_itemList addObject:item];

    // Update the table
    if (m_theTable)
      [m_theTable reloadData];

    // Let the document controller update the File-OpenRecent menu
    if (m_theDocumentController)
    {
      id url = [NSURL fileURLWithPath:fileName]; 
      [m_theDocumentController noteNewRecentDocumentURL:url];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all items that are selected in the GUI.
///
/// The GUI is automatically updated.
// -----------------------------------------------------------------------------
- (void) removeSelectedItems
{
  if (! m_theTable || ! m_itemList)
    return;
  if (0 == [m_theTable numberOfSelectedRows])
    return;

  // First determine which items to delete and store them in a
  // temporary array.
  // Note: we cannot delete the objects directly via the indexes that the
  // table's selectedRowIndexes returns, because deleting an object
  // from an array also changes the index positions of the items located
  // behind the deleted object.
  NSMutableArray* tempItemList = [NSMutableArray array];
  NSIndexSet* selectedRowIndexes = [m_theTable selectedRowIndexes];
  if (! selectedRowIndexes)
    return;
  unsigned int selectedRowIndex;
  for (selectedRowIndex = [selectedRowIndexes firstIndex]; selectedRowIndex != NSNotFound; selectedRowIndex = [selectedRowIndexes indexGreaterThanIndex:selectedRowIndex])
  {
    id item = [m_itemList objectAtIndex:selectedRowIndex];
    [tempItemList addObject:item];
  }

  // Second, delete the items
  NSEnumerator* enumerator = [tempItemList objectEnumerator];
  id item;
  while (item = [enumerator nextObject])
  {
    // Note: The array releases the object for us
    [m_itemList removeObject:item];
  }

  // Update the table
  [m_theTable reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Removes all items.
///
/// The GUI is automatically updated.
// -----------------------------------------------------------------------------
- (void) removeAllItems
{
  // Note: The array releases the objects for us
  if (m_itemList)
    [m_itemList removeAllObjects];
  // Update the table
  if (m_theTable)
    [m_theTable reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Returns the AceXpanderItem* that matches @a fileName.
///
/// Returns @e nil if no matching object is found.
// -----------------------------------------------------------------------------
- (AceXpanderItem*) itemForFile:(NSString*)fileName
{
  if (! m_itemList)
    return nil;

  NSEnumerator* enumerator = [m_itemList objectEnumerator];
  id item;
  while (item = [enumerator nextObject])
  {
    if ([[item fileName] isEqualToString:fileName])
      return item;
  }

  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the AceXpanderItem* at index position @a index.
///
/// Returns @e nil if no object lives at position @a index.
// -----------------------------------------------------------------------------
- (AceXpanderItem*) itemForIndex:(unsigned int)index
{
  if (! m_itemList)
    return nil;
  else if (index >= [m_itemList count])
    return nil;
  else
    return [m_itemList objectAtIndex:index];
}

// -----------------------------------------------------------------------------
/// @brief Sets the state of all items that currently have state @a fromState
/// to the new state @a toState.
///
/// If @a fromState is -1, all items are updated regardless of their current
/// state.
// -----------------------------------------------------------------------------
- (void) setAllItemsToState:(int)toState fromState:(int)fromState
{
  if (! m_itemList)
    return;

  NSEnumerator* enumerator = [m_itemList objectEnumerator];
  id item;
  while (item = [enumerator nextObject])
  {
    if (-1 == fromState || [item state] == fromState)
      [item setState:toState];
  }

  // No need to tell the table to reload data -> the items that have
  // changed have already done this for us
}

// -----------------------------------------------------------------------------
/// @brief Sets the state of all items to the new state @a state.
///
/// Is equivalent to setAllItemsToState:fromState:() with @a state and @a -1
/// as parameters.
// -----------------------------------------------------------------------------
- (void) setAllItemsToState:(int)state
{
  [self setAllItemsToState:state fromState:-1];
}

// -----------------------------------------------------------------------------
/// @brief Sets the state of all @e selected items that currently have state
/// @a fromState to the new state @a toState.
///
/// If @a fromState is -1, all items are updated regardless of their current
/// state (they must still be selected).
// -----------------------------------------------------------------------------
- (void) setSelectedItemsToState:(int)toState fromState:(int)fromState
{
  if (! m_theTable || ! m_itemList)
    return;
  if (0 == [m_theTable numberOfSelectedRows])
    return;

  NSIndexSet* selectedRowIndexes = [m_theTable selectedRowIndexes];
  if (! selectedRowIndexes)
    return;
  unsigned int selectedRowIndex;
  for (selectedRowIndex = [selectedRowIndexes firstIndex]; selectedRowIndex != NSNotFound; selectedRowIndex = [selectedRowIndexes indexGreaterThanIndex:selectedRowIndex])
  {
    id item = [m_itemList objectAtIndex:selectedRowIndex];
    if (-1 == fromState || [item state] == fromState)
      [item setState:toState];
  }

  // No need to tell the table to reload data -> the items that have
  // changed have already done this for us
}

// -----------------------------------------------------------------------------
/// @brief Sets the state of all items to the new state @a state.
///
/// Is equivalent to setSelectedAllItemsToState:fromState:() with @a state
/// and @a -1 as parameters.
// -----------------------------------------------------------------------------
- (void) setSelectedItemsToState:(int)state
{
  [self setAllItemsToState:state fromState:-1];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if all items have state @a state. Returns false
/// if at least one item has a different state.
// -----------------------------------------------------------------------------
- (bool) haveAllItemsState:(int)state
{
  if (! m_itemList)
    return false;

  NSEnumerator* enumerator = [m_itemList objectEnumerator];
  id item;
  while (item = [enumerator nextObject])
  {
    // Abort as soon as one item has a different state
    if ([item state] != state)
      return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Select all items in the GUI that have state @a state
// -----------------------------------------------------------------------------
- (void) selectItemsWithState:(int)state
{
  if (! m_theTable || ! m_itemList)
    return;

  NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
  NSEnumerator* enumerator = [m_itemList objectEnumerator];
  id item;
  while (item = [enumerator nextObject])
  {
    if ([item state] == state)
      [indexSet addIndex:[m_itemList indexOfObject:item]];
  }
  [m_theTable selectRowIndexes:indexSet byExtendingSelection:false];
}

// -----------------------------------------------------------------------------
/// @brief Returns the value of the "overwrite" option.
// -----------------------------------------------------------------------------
- (bool) overwriteFiles
{
  return m_overwriteFiles;
}

// -----------------------------------------------------------------------------
/// @brief Sets the value of the "overwrite" option to @a overwriteFiles.
// -----------------------------------------------------------------------------
- (void) setOverwriteFiles:(bool)overwriteFiles
{
  m_overwriteFiles = overwriteFiles;
}

// -----------------------------------------------------------------------------
/// @brief Returns the value of the "extract full path" option.
// -----------------------------------------------------------------------------
- (bool) extractFullPath
{
  return m_extractFullPath;
}

// -----------------------------------------------------------------------------
/// @brief Sets the value of the "extract full path" option to
/// @a extractFullPath.
// -----------------------------------------------------------------------------
- (void) setExtractFullPath:(bool)extractFullPath
{
  m_extractFullPath = extractFullPath;
}

// -----------------------------------------------------------------------------
/// @brief Returns the value of the "assume yes" option.
// -----------------------------------------------------------------------------
- (bool) assumeYes
{
  return m_assumeYes;
}

// -----------------------------------------------------------------------------
/// @brief Sets the value of the "assume yes" option to @a assumeYes.
// -----------------------------------------------------------------------------
- (void) setAssumeYes:(bool)assumeYes
{
  m_assumeYes = assumeYes;
}

// -----------------------------------------------------------------------------
/// @brief Returns the value of the "show comments" option.
// -----------------------------------------------------------------------------
- (bool) showComments
{
  return m_showComments;
}

// -----------------------------------------------------------------------------
/// @brief Sets the value of the "show comments" option to @a showComments.
// -----------------------------------------------------------------------------
- (void) setShowComments:(bool)showComments
{
  m_showComments = showComments;
}

// -----------------------------------------------------------------------------
/// @brief Returns the value of the "list verbosely" option.
// -----------------------------------------------------------------------------
- (bool) listVerbosely
{
  return m_listVerbosely;
}

// -----------------------------------------------------------------------------
/// @brief Sets the value of the "list verbosely" option to @a listVerbosely.
// -----------------------------------------------------------------------------
- (void) setListVerbosely:(bool)listVerbosely
{
  m_listVerbosely = listVerbosely;
}

// -----------------------------------------------------------------------------
/// @brief Returns the value of the "use password" option.
// -----------------------------------------------------------------------------
- (bool) usePassword
{
  return m_usePassword;
}

// -----------------------------------------------------------------------------
/// @brief Returns the current password.
// -----------------------------------------------------------------------------
- (NSString*) password
{
  if (m_password)
    return [[m_password retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Sets the value of the "use password" option to @a usePassword
/// and the password to @a password.
// -----------------------------------------------------------------------------
- (void) setUsePassword:(bool)usePassword withPassword:(NSString*)password
{
  m_usePassword = usePassword;
  if (m_password)
    [m_password autorelease];
  m_password = password;
  if (m_password)
    [m_password retain];
}

// -----------------------------------------------------------------------------
/// @brief Returns the value of the "debug mode" option.
// -----------------------------------------------------------------------------
- (bool) debugMode
{
  return m_debugMode;
}

// -----------------------------------------------------------------------------
/// @brief Sets the value of the "debug mode" option to @a debugMode.
// -----------------------------------------------------------------------------
- (void) setDebugMode:(bool)debugMode
{
  m_debugMode = debugMode;
}

// -----------------------------------------------------------------------------
/// @brief Returns the value of the "interactive" option.
// -----------------------------------------------------------------------------
- (bool) interactive
{
  return m_interactive;
}

// -----------------------------------------------------------------------------
/// @brief Sets the value of the "interactive" option to @a interactive.
// -----------------------------------------------------------------------------
- (void) setInteractive:(bool)interactive
{
  m_interactive = interactive;
}

// -----------------------------------------------------------------------------
/// @brief Starts expanding all @e selected items.
///
/// This method returns immediately. The actual "expand" operation is performed
/// by a worker thread. See startThreadWithCommand:() for details.
///
/// @return true if thread was launched successfully, false if not.
// -----------------------------------------------------------------------------
- (bool) startExpandItems
{
  return [self startThreadWithCommand:ExpandCommand];
}

// -----------------------------------------------------------------------------
/// @brief Starts listing the content of all @e selected items.
///
/// This method returns immediately. The actual "list" operation is performed
/// by a worker thread. See startThreadWithCommand:() for details.
///
/// @return true if thread was launched successfully, false if not.
// -----------------------------------------------------------------------------
- (bool) startListItems
{
  return [self startThreadWithCommand:ListCommand];
}

// -----------------------------------------------------------------------------
/// @brief Starts testing the integrity of all @e selected items.
///
/// This method returns immediately. The actual "test" operation is performed
/// by a worker thread. See startThreadWithCommand:() for details.
///
/// @return true if thread was launched successfully, false if not.
// -----------------------------------------------------------------------------
- (bool) startTestItems
{
  return [self startThreadWithCommand:TestCommand];
}

// -----------------------------------------------------------------------------
/// @brief Stops the command (expand, list, test) that is currently running.
///
/// This method returns immediately. The worker thread that performs the actual
/// command operation stops its activities as soon as possible, i.e. it
/// finishes processing the current item.
///
/// This method does nothing if the worker thread is currently not running.
// -----------------------------------------------------------------------------
- (void) stopCommand
{
  if (m_commandThread && [m_commandThread isRunning])
    [m_commandThread stop];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if a command (expand, list, test) is currently running.
// -----------------------------------------------------------------------------
- (bool) isCommandRunning
{
  if (m_commandThread)
    return [m_commandThread isRunning];
  else
    return false;
}

// -----------------------------------------------------------------------------
/// @brief Spawns a thread that performs the operation @a command on all
/// @e selected items.
///
/// @todo The thread launches a separate process for unace to operate in. The
/// reason for this is historical: AceXpander originally was programmed in Java,
/// which did not provide the means to start an external command in a thread.
/// This should be fixed soon, since we are now coding in Objective-C.
///
/// @return true if thread was spawned successfully, false if not. Note that
/// this method returns true even if the number of selected items was 0.
// -----------------------------------------------------------------------------
- (bool) startThreadWithCommand:(int)command
{
  // Abort if no items are selected
  if (! m_theTable || ! m_itemList || 0 == [m_theTable numberOfSelectedRows])
    return true;

  // Create the thread if it does not exist
  if (! m_commandThread)
  {
    m_commandThread = [[AceXpanderThread alloc] init];
    if (! m_commandThread)
      return false;
  }

  // Collect the selected items and feed them into the thread
  NSIndexSet* selectedRowIndexes = [m_theTable selectedRowIndexes];
  if (! selectedRowIndexes)
    return false;
  unsigned int selectedRowIndex;
  for (selectedRowIndex = [selectedRowIndexes firstIndex]; selectedRowIndex != NSNotFound; selectedRowIndex = [selectedRowIndexes indexGreaterThanIndex:selectedRowIndex])
  {
    id item = [m_itemList objectAtIndex:selectedRowIndex];
    [m_commandThread addItem:(AceXpanderItem*)item];
  }

  // Set the options
  [m_commandThread setCommand:command
               overwriteFiles:m_overwriteFiles
              extractFullPath:m_extractFullPath
                    assumeYes:m_assumeYes
                 showComments:m_showComments
                listVerbosely:m_listVerbosely
                  usePasswort:m_usePassword
                     password:m_password
                    debugMode:m_debugMode];

  // Run the thread
  [m_commandThread run];

  // Return success
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of rows that @a aTableView should display.
///
/// @note This is an NSTableDataSource protocol method.
// -----------------------------------------------------------------------------
- (int) numberOfRowsInTableView:(NSTableView*)aTableView
{
  if (m_itemList)
    return [m_itemList count];
  else
    return 0;
}

// -----------------------------------------------------------------------------
/// @brief Returns an attribute value for the cell in @a aTableView that is
/// located at @a rowIndex and @a aTableColumn.
///
/// @note This is an NSTableDataSource protocol method.
// -----------------------------------------------------------------------------
- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex
{
  if (! m_itemList || ! aTableColumn)
    return nil;

  if (rowIndex >= [m_itemList count])
    return nil;
  id item = [m_itemList objectAtIndex:rowIndex];
  if (! item)
    return nil;

  id identifier = [aTableColumn identifier];
  if ([identifier isEqual:columnIdentifierIcon])
    return [item icon];
  else if ([identifier isEqual:columnIdentifierFileName])
    return [item fileName];
  else if ([identifier isEqual:columnIdentifierState])
    return [item stateAsString];

  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Performs a GUI update as a result of @a item having changed its
/// state.
// -----------------------------------------------------------------------------
- (void) itemHasChanged:(AceXpanderItem*)item
{
  if (m_theTable)
    [m_theTable reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model from the user's defaults
/// (i.e. [NSUserDefaults standardUserDefaults]).
// -----------------------------------------------------------------------------
- (void) updateMyDefaultsFromUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  if (! userDefaults)
    return;

  if ([userDefaults boolForKey:overwriteFilesOptionKey])
    m_overwriteFiles = true;
  else
    m_overwriteFiles = false;
  
  if ([userDefaults boolForKey:extractWithFullPathOptionKey])
    m_extractFullPath = true;
  else
    m_extractFullPath = false;
  
  if ([userDefaults boolForKey:assumeYesOptionKey])
    m_assumeYes = true;
  else
    m_assumeYes = false;
  
  if ([userDefaults boolForKey:showCommentsOptionKey])
    m_showComments = true;
  else
    m_showComments = false;
  
  if ([userDefaults boolForKey:listVerboselyOptionKey])
    m_listVerbosely = true;
  else
    m_listVerbosely = false;
}

@end
