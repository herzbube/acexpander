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
#import "AceXpanderThread.h"
#import "AceXpanderItem.h"
#import "AceXpanderTask.h"
#import "AceXpanderGlobals.h"


/// @brief Conditions used to control the main method of the command thread.
enum AceXpanderThreadCondition
{
  ProcessingCondition,
  NoProcessingCondition
};


/// @brief This category declares private methods for the AceXpanderThread
/// class. 
@interface AceXpanderThread(Private)
- (void) dealloc;
- (void) main:(id)anObject;
+ (NSString*) determineUnaceExecutablePath;
- (NSString*) determineDestinationFolder:(NSString*)archiveFileName;
@end


@implementation AceXpanderThread
// -----------------------------------------------------------------------------
/// @brief Initializes an AceXpanderThread object. A new command thread is
/// detached before this method returns.
///
/// @note This is the designated initializer of AceXpanderThread.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // Initialize members
  m_itemList = [[NSMutableArray array] retain];
  m_unaceSwitchList = [[NSMutableArray array] retain];
  m_mainLock = [[NSConditionLock alloc] initWithCondition:NoProcessingCondition];
  m_stopProcessingLock = [[NSLock alloc] init];
  m_taskLock = [[NSLock alloc] init];
  m_stopProcessing = false;
  m_terminate = false;

  // Detach new thread
  [NSThread detachNewThreadSelector:@selector(main:) toTarget:self withObject:nil];

  // Return
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this AceXpanderThread object.
///
/// The command thread is stopped by this method.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // Make sure that all processing stops
  [self stopProcessing];
  // Acquire the main lock - this should be no problem after stopProcessing
  // has returned
  [m_mainLock lockWhenCondition:NoProcessingCondition];
  // Tell the thread to terminate itself. We can do this safely while we have
  // the main lock.
  m_terminate = true;
  // Unlock and wake up the thread so that it can terminate itself
  [m_mainLock unlockWithCondition:ProcessingCondition];

  // The following members are always filled with constants -> we don't have to
  // release these members
  // - m_unaceCommand

  if (m_mainLock)
    [m_mainLock autorelease];
  if (m_stopProcessingLock)
    [m_stopProcessingLock autorelease];
  if (m_taskLock)
    [m_taskLock autorelease];
  if (m_itemList)
    [m_itemList autorelease];
  if (m_unaceSwitchList)
    [m_unaceSwitchList autorelease];
  if (m_task)
    [m_task autorelease];
  if (m_destinationFolderAskWhenExpanding)
    [m_destinationFolderAskWhenExpanding autorelease];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Launches unace in a separate process to get information about the
/// executable's version.
///
/// This method is synchronous, i.e. it does @not launch a thread to execute
/// the unace binary. This method is simply a convenient way to get at the
/// unace binary's version information.
///
/// @return a version string, or nil if something goes wrong
///
/// @note This is a class method.
// -----------------------------------------------------------------------------
+ (NSString*) unaceVersion
{
  NSString* unaceExecutablePath = [AceXpanderThread determineUnaceExecutablePath];
  if (unaceExecutablePath)
    return [AceXpanderTask unaceVersion:unaceExecutablePath];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief This is the main method of the command thread.
///
/// It starts processing items when they are submitted by processItems:().
/// It stops processing items when it either runs out of items, or when it is
/// told to stop processing items by stopProcessing:(). The latter occurs in
/// two cases:
/// - when the user clicks the "cancel" button in the GUI
/// - when the user terminates the application and the AceXpanderThread object
///   is deallocated
// -----------------------------------------------------------------------------
- (void) main:(id)anObject
{
  // ------------------------------------------------------------
  // The thread cannot run successfully if these members are not set
  if (! m_mainLock || ! m_taskLock || ! m_stopProcessingLock || ! m_itemList)
    return;

  // ------------------------------------------------------------
  // Loop until m_terminate is set to true by dealloc:()
  while (true)
  {
    // ------------------------------------------------------------
    // Acquire main lock
    [m_mainLock lockWhenCondition:ProcessingCondition];

    // ------------------------------------------------------------
    // Check if the thread should exit
    if (m_terminate)
    {
      // Release lock, just for completeness sake
      [m_mainLock unlockWithCondition:NoProcessingCondition];
      // Break the main loop
      break;
    }

    // ------------------------------------------------------------
    // Create an autorelease pool. This must be one of the very first things
    // that this thread is doing...
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if (! pool)
      return;

    // ------------------------------------------------------------
    // Notify observers that the command thread has started processing items
    [[NSNotificationCenter defaultCenter] postNotificationName:commandThreadHasStartedNotification object:nil];

    // ------------------------------------------------------------
    // Determine the path to the unace executable that we should use
    NSString* unaceExecutablePath = [AceXpanderThread determineUnaceExecutablePath];

    // ------------------------------------------------------------
    // Iterate & process items
    BOOL stopProcessing = false;
    while ([m_itemList count] > 0 && ! stopProcessing)
    {
      // Get item
      AceXpanderItem* iterItem = (AceXpanderItem*)[m_itemList objectAtIndex:0];
      [m_itemList removeObjectAtIndex:0];
      if (! iterItem)
        continue;

      // We need to check the state because it might be possible that the item
      // was added even though its state was not QueuedState
      if (QueuedState != [iterItem state])
        continue;

      // Destination folder is required only if we expand
      NSString* destinationFolder = nil;
      if (ExpandCommand == m_command)
        destinationFolder = [self determineDestinationFolder:[iterItem fileName]];

      // Create new task
      [m_taskLock lock];
      m_task = [[AceXpanderTask alloc] init];
      if (! m_task)
      {
        [m_taskLock unlock];
        continue;
      }
      // Configure task
      [m_task setUnaceExecutablePath:unaceExecutablePath];
      [m_task setDestinationFolder:destinationFolder];
      [m_task setUnaceCommand:m_command commandSwitch:m_unaceCommand];
      [m_task setUnaceSwitchList:m_unaceSwitchList];
      [m_task setItem:iterItem];
      // Execute task
      // Note: while we wait for the task's termination, we release the lock
      // that allows for task termination by stopProcessing:()
      [m_taskLock unlock];
      /// @todo There is a small loop hole here - if stopProcessing() calls
      /// [m_taskLock isRunning] right now, it will think that the task is
      /// not running, yet we are just about to start it...
      [m_task launch];
      // Lock again so that we can release the task
      [m_taskLock lock];
      [m_task release];
      m_task = nil;
      [m_taskLock unlock];

      // Check if we need to abort processing
      [m_stopProcessingLock lock];
      if (m_stopProcessing)
        stopProcessing = true;
      [m_stopProcessingLock unlock];
    }

    // ------------------------------------------------------------
    // Cleanup after processing has finished
    [m_itemList removeAllObjects];
    if (m_destinationFolderAskWhenExpanding)
    {
      [m_destinationFolderAskWhenExpanding autorelease];
      m_destinationFolderAskWhenExpanding = nil;
    }

    // ------------------------------------------------------------
    // Release main lock
    [m_mainLock unlockWithCondition:NoProcessingCondition];

    // ------------------------------------------------------------
    // Notify observers that the command thread has stopped processing items
    // Note: do this ***AFTER*** releasing m_mainLock to prevent a deadlock
    //  where
    // - the GUI thread is waiting on m_mainLock in stopProcessing:(), because
    //   the user clicked the "cancel" button
    // - posting the notification leads to a GUI update of the "expand" button,
    //   which will then wait on a lock inside Cocoa that was already acquired
    //   by the GUI thread when the user clicked the "cancel" button
    [[NSNotificationCenter defaultCenter] postNotificationName:commandThreadHasStoppedNotification object:nil];

    // ------------------------------------------------------------
    // Release the autorelease pool
    [pool release];
    pool = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Submits a list with AceXpanderItems for processing.
///
/// @note If the command thread is currently processing items, this method
/// blocks until the thread stops processing.
// -----------------------------------------------------------------------------
- (void) processItems:(NSArray*)itemList
{
  if (! itemList || [itemList count] == 0 || ! m_itemList)
    return;
  [m_mainLock lockWhenCondition:NoProcessingCondition];
  [m_itemList removeAllObjects];
  [m_itemList addObjectsFromArray:itemList];
  [m_mainLock unlockWithCondition:ProcessingCondition];
}

// -----------------------------------------------------------------------------
/// @brief Tells the command thread to stop processing items.
///
/// This method does not return until the command thread has stopped
/// processing.
// -----------------------------------------------------------------------------
- (void) stopProcessing
{
  // Set the flag that tells the main:() method to stop on its next
  // iteration
  if (m_stopProcessingLock)
    [m_stopProcessingLock lock];
  m_stopProcessing = true;
  if (m_stopProcessingLock)
    [m_stopProcessingLock unlock];

  // The thread waits for the process, so we need to kill the process in
  // order for the thread to be able to check on the m_stopProcessing flag
  if (m_taskLock)
    [m_taskLock lock];
  if (nil != m_task && [m_task isRunning])
    [m_task terminate];
  if (m_taskLock)
    [m_taskLock unlock];

  // Try to acquire the main lock - we will get it as soon as main() stops
  // processing
  [m_mainLock lockWhenCondition:NoProcessingCondition];
  // Reset the flag
  if (m_stopProcessingLock)
    [m_stopProcessingLock lock];
  m_stopProcessing = false;
  if (m_stopProcessingLock)
    [m_stopProcessingLock unlock];
  // Release the lock just before we return (without changing the condition)
  [m_mainLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Returns whether or not the command thread is currently processing
/// items.
// -----------------------------------------------------------------------------
- (BOOL) isProcessing
{
  if (m_mainLock)
    return ([m_mainLock condition] == ProcessingCondition);
  else
    return false;
}

// -----------------------------------------------------------------------------
/// @brief Tells the command thread that it should execute the command
/// @a command, using the other method parameters as command options, when it
/// processes the next batch of items.
///
/// @note If the command thread is currently processing items, this method
/// blocks until the thread stops processing.
// -----------------------------------------------------------------------------
- (void) setCommand:(int)command
     overwriteFiles:(BOOL)overwriteFiles
    extractFullPath:(BOOL)extractFullPath
          assumeYes:(bool)assumeYes
       showComments:(BOOL)showComments
      listVerbosely:(BOOL)listVerbosely
        usePasswort:(BOOL)usePassword
           password:(NSString*)password
{
  if (m_mainLock)
    [m_mainLock lockWhenCondition:NoProcessingCondition];

  m_unaceCommand = @"";
  [m_unaceSwitchList removeAllObjects];

  m_command = command;
  switch (command)
  {
    case ExpandCommand:
      if (extractFullPath)
        m_unaceCommand = unaceCmdExtractWithFullPath;
      else
        m_unaceCommand = unaceCmdExtract;
      break;
    case ListCommand:
      if (listVerbosely)
        m_unaceCommand = unaceCmdListVerbosely;
      else
        m_unaceCommand = unaceCmdList;
      break;
    case TestCommand:
      m_unaceCommand = unaceCmdTest;
      break;
    default:
    {
      NSString* errorDescription = [NSString stringWithFormat:@"Unexpected command code %d", command];
      [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification object:errorDescription];

      if (m_mainLock)
        [m_mainLock unlock];
      return;
    }
  }
  
  NSString* switchString;

  switchString = unaceSwitchOverwriteFiles;
  if (overwriteFiles) { switchString = [switchString stringByAppendingString:@"+"]; }
  else                { switchString = [switchString stringByAppendingString:@"-"]; }
  [m_unaceSwitchList addObject:switchString];

  switchString = unaceSwitchAssumeYes;
  if (assumeYes) { switchString = [switchString stringByAppendingString:@"+"]; }
  else           { switchString = [switchString stringByAppendingString:@"-"]; }
  [m_unaceSwitchList addObject:switchString];
  
  switchString = unaceSwitchShowComments;
  if (showComments) { switchString = [switchString stringByAppendingString:@"+"]; }
  else              { switchString = [switchString stringByAppendingString:@"-"]; }
  [m_unaceSwitchList addObject:switchString];

  if (usePassword)
  {
    switchString = [unaceSwitchUsePassword stringByAppendingString:password];
    [m_unaceSwitchList addObject:switchString];
  }

  if (m_mainLock)
    [m_mainLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Returns the path to the unace executable that should be used
/// according to the user defaults.
///
/// @note This is a class method.
// -----------------------------------------------------------------------------
+ (NSString*) determineUnaceExecutablePath
{
  NSString* unaceExecutablePath = [[NSUserDefaults standardUserDefaults] stringForKey:executablePathKey];
  if (! unaceExecutablePath || [unaceExecutablePath isEqualToString:bundledExecutablePath])
    return [[NSBundle mainBundle] pathForResource:unaceBundledResourceName ofType:nil];
  else
    return unaceExecutablePath;
}

// -----------------------------------------------------------------------------
/// @brief Tries to determine the destination folder where the archive contents
/// should be expanded from the various user default settings.
///
/// This method must be called once for each item processed by the thread. The
/// reason is because one or both of the following user preferences might be
/// set:
/// - "DestinationFolderType" is set to "SameAsArchive"
/// - "CreateSurroundingFolder" is set to true
///
/// If "DestinationFolderType" is "AskWhenExpanding", this method lets the user
/// choose a folder from an NSOpenPanel. It does so only for the first item of
/// the current thread run.
/// 
/// @note This method does not @e create the destination folder if it doesn't
/// exist yet - this is the responsibility of the unace front-end shell script.
///
/// @return the destination folder, or nil if the folder could not be
/// determined (e.g. because the user was queried for a folder, but she clicked
/// the "cancel" button in the NSOpenPanel).
// -----------------------------------------------------------------------------
- (NSString*) determineDestinationFolder:(NSString*)archiveFileName
{
  NSString* destinationFolder = nil;

  NSString* destinationFolderType = [[NSUserDefaults standardUserDefaults] stringForKey:destinationFolderTypeKey];
  if ([destinationFolderType isEqualToString:destinationFolderTypeSameAsArchive])
    destinationFolder = [archiveFileName stringByDeletingLastPathComponent];
  else if ([destinationFolderType isEqualToString:destinationFolderTypeFixedLocation])
    destinationFolder = [[NSUserDefaults standardUserDefaults] stringForKey:destinationFolderKey];
  else if ([destinationFolderType isEqualToString:destinationFolderTypeAskWhenExpanding])
  {
    // Only query the user if she hasn't chosen a folder yet.
    if (! m_destinationFolderAskWhenExpanding)
    {
      NSOpenPanel* openPanel = [NSOpenPanel openPanel];
      if (! openPanel)
        return nil;
      [openPanel setAllowsMultipleSelection:NO];
      [openPanel setCanChooseFiles:NO];
      [openPanel setCanChooseDirectories:YES];
      NSString* directory = nil;
      NSString* selectedFile = nil;
      NSArray* fileTypes = nil;
      int iResult = [openPanel runModalForDirectory:directory file:selectedFile types:fileTypes];
      // Remember the user's answer to prevent querying in subsequent calls to
      // this method
      if (NSOKButton == iResult)
      {
        // We trust the panel to return at least one item!
        m_destinationFolderAskWhenExpanding = (NSString*)[[openPanel filenames] objectAtIndex:0];
        if (m_destinationFolderAskWhenExpanding)
          [m_destinationFolderAskWhenExpanding retain];
      }
      // The user cancelled the query -> the process should be aborted
      else
        return nil;
    }

    // Use the folder that the user chose when she was queried during the first
    // item's processing
    destinationFolder = m_destinationFolderAskWhenExpanding;
  }

  // If user defaults say so, add an additional surrounding folder to the
  // destination folder.
  if ([[NSUserDefaults standardUserDefaults] boolForKey:createSurroundingFolderKey])
  {
    destinationFolder = [[[destinationFolder stringByAppendingString:@"/"]
                                            stringByAppendingString:[archiveFileName lastPathComponent]]
                                             stringByAppendingString:@" Folder"];
  }

  if (destinationFolder)
    return [[destinationFolder retain] autorelease];
  else
    return nil;
}

@end
