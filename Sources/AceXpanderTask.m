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
#import "AceXpanderTask.h"
#import "AceXpanderItem.h"
#import "AceXpanderGlobals.h"


/// @brief This category declares private methods for the AceXpanderTask class.
@interface AceXpanderTask(Private)
- (void) dealloc;
- (BOOL) terminated;
+ (BOOL) createDirectoriesAtPath:(NSString*)path attributes:(NSDictionary*)attributes;
@end

@implementation AceXpanderTask
// -----------------------------------------------------------------------------
/// @brief Initializes an AceXpanderTask object.
///
/// @note This is the designated initializer of AceXpanderTask.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // Initialize members
  m_terminated = false;
  m_terminatedLock = [[NSLock alloc] init];
  m_taskLock = [[NSLock alloc] init];

  // Return
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this AceXpanderTask object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (m_terminatedLock)
    [m_terminatedLock autorelease];
  if (m_taskLock)
    [m_taskLock lock];
  if (m_task)
  {
    [m_task autorelease];
    m_task = nil;
  }
  if (m_taskLock)
  {
    [m_taskLock unlock];
    [m_taskLock autorelease];
  }
  if (m_unaceExecutablePath)
    [m_unaceExecutablePath autorelease];
  if (m_destinationFolder)
    [m_destinationFolder autorelease];
  if (m_unaceCommand)
    [m_unaceCommand autorelease];
  if (m_unaceSwitchList)
    [m_unaceSwitchList autorelease];
  if (m_item)
    [m_item autorelease];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with the full path to the unace
/// executable.
///
/// This parameter is mandatory.
// -----------------------------------------------------------------------------
- (void) setUnaceExecutablePath:(NSString*)unaceExecutablePath
{
  if (m_unaceExecutablePath == unaceExecutablePath)
    return;
  if (m_unaceExecutablePath)
    [m_unaceExecutablePath autorelease];
  if (unaceExecutablePath)
    m_unaceExecutablePath = [unaceExecutablePath retain];
  else
    m_unaceExecutablePath = nil;
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with the full path to the destination
/// folder into which the archive should be expanded.
///
/// This parameter is required only if the unace command is #ExpandCommand.
// -----------------------------------------------------------------------------
- (void) setDestinationFolder:(NSString*)destinationFolder
{
  if (m_destinationFolder == destinationFolder)
    return;
  if (m_destinationFolder)
    [m_destinationFolder autorelease];
  if (destinationFolder)
    m_destinationFolder = [destinationFolder retain];
  else
    m_destinationFolder = nil;
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with the command to execute, both in
/// its numerical and in its string form (i.e. a switch for the unace binary).
///
/// This parameter is mandatory.
// -----------------------------------------------------------------------------
- (void) setUnaceCommand:(int)command commandSwitch:(NSString*)unaceCommand
{
  if (m_unaceCommand == unaceCommand)
    return;
  if (m_unaceCommand)
    [m_unaceCommand autorelease];
  if (unaceCommand)
    m_unaceCommand = [unaceCommand retain];
  else
    m_unaceCommand = nil;

  m_command = command;
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with a number of switches for the
/// unace binary.
///
/// This parameter is mandatory.
// -----------------------------------------------------------------------------
- (void) setUnaceSwitchList:(NSArray*)unaceSwitchList
{
  if (m_unaceSwitchList == unaceSwitchList)
    return;
  if (m_unaceSwitchList)
    [m_unaceSwitchList autorelease];
  if (unaceSwitchList)
    m_unaceSwitchList = [unaceSwitchList retain];
  else
    m_unaceSwitchList = nil;
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with the AceXpanderItem object that
/// represents the archive file to be processed.
///
/// This parameter is mandatory.
// -----------------------------------------------------------------------------
- (void) setItem:(AceXpanderItem*)item
{
  if (m_item == item)
    return;
  if (m_item)
    [m_item autorelease];
  if (item)
    m_item = [item retain];
  else
    m_item = nil;
}

// -----------------------------------------------------------------------------
/// @brief Launches the system process (= task) that executes the unace binary
/// previously configured.
///
/// The AceXpanderItem object passed earlier with setItem:() is updated with
/// the results of the command.
// -----------------------------------------------------------------------------
- (void) launch
{
  if (! m_item)
    return;

  // Start processing
  [m_item setState:ProcessingState];

  // Get the item's filename
  NSString* fileName = [m_item fileName];

  // Check for important arguments
  BOOL failed = false;
  if (! fileName || ! m_unaceExecutablePath || ! m_unaceCommand || ! m_unaceSwitchList)
    failed = true;
  // m_destinationFolder is only required for ExpandCommand
  else if (ExpandCommand == m_command && ! m_destinationFolder)
    failed = true;
  if (failed)
  {
    [m_item setState:FailureState];
    [m_item setMessageStdout:nil messageStderr:nil containsListing:NO];
    return;
  }

  // Create destination folder if it does not exist yet
  if (ExpandCommand == m_command && m_destinationFolder)
  {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (fileManager)
    {
      BOOL isDirectory;
      if (! [fileManager fileExistsAtPath:m_destinationFolder isDirectory:&isDirectory])
      {
        BOOL success = [AceXpanderTask createDirectoriesAtPath:m_destinationFolder attributes:nil];
        if (! success)
        {
          [m_item setState:FailureState];
          [m_item setMessageStdout:nil
                     messageStderr:@"Unable to create destination folder"
                   containsListing:NO];
          return;
        }
      }
      else
      {
        if (! isDirectory)
        {
          [m_item setState:FailureState];
          [m_item setMessageStdout:nil
                     messageStderr:@"Unable to create destination folder, file exists with the same name"
                   containsListing:NO];
          return;
        }
      }
    }
  }

  // Build command line
  // Note: it is important that the command line is built in a way that retains
  // spaces in path names! Also, special care must be taken that no empty
  // strings are passed as arguments to unace because it is confused by this
  // and will try to expand an archive named ".ace" (empty string followed by
  // extension ".ace")
  NSMutableArray* arguments = [NSMutableArray array];
  [arguments addObject:m_unaceCommand];
  [arguments addObjectsFromArray:m_unaceSwitchList];
  [arguments addObject:fileName];

  // Create pipes
  // Note: we must set both stdin and stdout, otherwise unace will hang when the
  // AceXpander application is launched from the Finder. It never hangs, though,
  // when AceXpander is launched from within Xcode, or from a terminal shell
  // like this: ./AceXpander.app/Contents/MacOS/AceXpander.
  NSPipe* stdinPipe = [NSPipe pipe];
  NSPipe* stdoutPipe = [NSPipe pipe];
  NSPipe* stderrPipe = [NSPipe pipe];
  // Create and configure task
  if (m_taskLock)
    [m_taskLock lock];
  m_task = [[NSTask alloc] init];
  [m_task setStandardInput:stdinPipe];
  [m_task setStandardOutput:stdoutPipe];
  [m_task setStandardError:stderrPipe];
  [m_task setLaunchPath:m_unaceExecutablePath];
  [m_task setArguments:arguments];
  if (m_destinationFolder)
    [m_task setCurrentDirectoryPath:m_destinationFolder];

  // Execute task and wait for its termination
  @try
  {
    [m_task launch];
    // Note: while we wait for the task's termination, we release the lock
    // that allows for task termination by terminate:()
    if (m_taskLock)
      [m_taskLock unlock];
    // There is a small loop hole here - if dealloc() acquires m_taskLock right
    // now and destroys m_task, we are in trouble. Practically this should not
    // happen, as AceXpanderThread will not release this AceXpanderTask object
    // until this method returns.
    [m_task waitUntilExit];
    // Lock again so that we can release the task
    if (m_taskLock)
      [m_taskLock lock];
  }
  @catch(NSException* exception)
  {
    // Notify the error handler that an error has occurred
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification
                                                        object:[exception reason]];
  }

  // Check if the task was aborted
  if ([self terminated])
    [m_item setState:AbortedState];
  else
  {
    // Evaluate task result
    int exitValue = [m_task terminationStatus];
    if (0 != exitValue)
      [m_item setState:FailureState];
    else
      [m_item setState:SuccessState];
  }

  // Get standard output and error messages
  NSFileHandle* stdoutReadHandle = [stdoutPipe fileHandleForReading];
  NSData* stdoutData = [stdoutReadHandle readDataToEndOfFile];
  NSString* messageStdout = [[NSString alloc] initWithData:stdoutData encoding:NSASCIIStringEncoding];
  NSFileHandle* stdErrReadHandle = [stderrPipe fileHandleForReading];
  NSData* stderrData = [stdErrReadHandle readDataToEndOfFile];
  NSString* messageStderr = [[NSString alloc] initWithData:stderrData encoding:NSASCIIStringEncoding];
  [m_item setMessageStdout:messageStdout
           messageStderr:messageStderr
         containsListing:(m_command == ListCommand)];
  if (messageStdout)
    [messageStdout autorelease];
  if (messageStderr)
    [messageStderr autorelease];

  // Cleanup
  [m_task release];
  m_task = nil;
  if (m_taskLock)
    [m_taskLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Terminates the command process that is currently running.
///
/// This method does nothing if no command process is currently running.
///
/// @note This method is called in the GUI thread context.
// -----------------------------------------------------------------------------
- (void) terminate
{
  if (m_terminatedLock)
    [m_terminatedLock lock];
  m_terminated = true;
  if (m_terminatedLock)
    [m_terminatedLock unlock];

  if (m_taskLock)
    [m_taskLock lock];
  if (m_task && [m_task isRunning])
    [m_task terminate];
  if (m_taskLock)
    [m_taskLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Returns whether the command process was forcefully terminated by
/// terminate:().
///
/// @note This method is called in the AceXpanderThread context.
// -----------------------------------------------------------------------------
- (BOOL) terminated
{
  if (m_terminatedLock)
    [m_terminatedLock lock];
  // Make a copy while we have the lock
  BOOL terminated = m_terminated;
  if (m_terminatedLock)
    [m_terminatedLock unlock];
  // Return the copied value after we have released the lock
  return terminated;
}

// -----------------------------------------------------------------------------
/// @brief Returns whether or not the command process is currently running.
///
/// @note This method is called in the GUI thread context.
// -----------------------------------------------------------------------------
- (BOOL) isRunning
{
  if (m_taskLock)
    [m_taskLock lock];
  // Get the state while we have the lock
  BOOL isRunning = false;
  if (m_task)
    isRunning = [m_task isRunning];
  if (m_taskLock)
    [m_taskLock unlock];
  // Return the state after we have released the lock
  return isRunning;
}

// -----------------------------------------------------------------------------
/// @brief Launches unace in a separate process to get information about the
/// executable's version.
///
/// @a unaceExecutablePath is the path to the unace binary that should be
/// queried for the version information.
///
/// @return a version string, or nil if something goes wrong
///
/// @note This is a class method.
// -----------------------------------------------------------------------------
+ (NSString*) unaceVersion:(NSString*)unaceExecutablePath
{
  if (! unaceExecutablePath)
    return nil;

  // Build command line
  // Note: it is important that the command line is built in a way that retains
  // spaces in path names! Also, special care must be taken that no empty
  // strings are passed as arguments to unace because it is confused by this
  // and will try to expand an archive named ".ace" (empty string followed by
  // extension ".ace")
  NSMutableArray* arguments = [NSMutableArray array];
  [arguments addObject:unaceSwitchVersion];

  // Create pipes
  // Note: we must set both stdin and stdout, otherwise unace will hang when the
  // AceXpander application is launched from the Finder. It never hangs, though,
  // when AceXpander is launched from within Xcode, or from a terminal shell
  // like this: ./AceXpander.app/Contents/MacOS/AceXpander.
  NSPipe* stdinPipe = [NSPipe pipe];
  NSPipe* stdoutPipe = [NSPipe pipe];
  NSPipe* stderrPipe = [NSPipe pipe];
  // Create and configure task
  NSTask* task = [[NSTask alloc] init];
  [task setStandardInput:stdinPipe];
  [task setStandardOutput:stdoutPipe];
  [task setStandardError:stderrPipe];
  [task setLaunchPath:unaceExecutablePath];
  [task setArguments:arguments];

  // Execute task and wait for its termination
  @try
  {
    [task launch];
    [task waitUntilExit];
  }
  @catch(NSException* exception)
  {
    // Notify the error handler that an error has occurred
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification
                                                        object:[exception reason]];
  }

  // The result we want to return
  NSString* messageStdout = nil;

  // Evaluate task result
  // -> we are not interested in the [task terminationStatus] because unace
  //    always returns a non-zero status when we pass "--version" to it
  NSFileHandle* stdoutReadHandle = [stdoutPipe fileHandleForReading];
  NSData* stdoutData = [stdoutReadHandle readDataToEndOfFile];
  messageStdout = [[NSString alloc] initWithData:stdoutData encoding:NSASCIIStringEncoding];
  if (messageStdout)
  {
    [messageStdout autorelease];
    // Parse message in the following way:
    // - filter out all empty lines (regexp ^$)
    // - discard all but the first two lines
    // This should result in a string that is sufficiently readable if
    // displayed in an alert panel.
    NSEnumerator* enumerator = [[messageStdout componentsSeparatedByString:@"\n"] objectEnumerator];
    messageStdout = nil;
    id anObject;
    while (anObject = [enumerator nextObject])
    {
      NSString* messageLine = (NSString*)anObject;
      // Discard empty lines
      if ([messageLine length] == 0)
        continue;
      // The first line
      if (! messageStdout)
        messageStdout = messageLine;
      else
      {
        // The second line
        messageStdout = [[messageStdout stringByAppendingString:@"\n"] stringByAppendingString:messageLine];
        // Discard remaining lines
        break;
      }
    }
  }

  // Cleanup
  [task release];

  // Return result
  return messageStdout;
}

// -----------------------------------------------------------------------------
/// @brief Similar to -[NSFileManager createDirectoryAtPath:attributes:] but
/// parent directory doesn't have to exist; this does it for you. You must pass
/// in a standardized path; e.g. no ~ is allowed.
///
/// Implementation of this method by Dan Wood, found at
/// http://lists.apple.com/archives/cocoa-dev/2003/Feb/msg00200.html
/// Thanks for the lifesaver at 3am, Dan!
// -----------------------------------------------------------------------------
+ (BOOL) createDirectoriesAtPath:(NSString*)path attributes:(NSDictionary *)attributes
{
  NSArray* components = [path pathComponents];
  BOOL result = YES;
  int i;
  int iCount = [components count];
  for (i = 1 ; i <= iCount; i++)
  {
    NSArray* subComponents = [components subarrayWithRange:NSMakeRange(0, i)];
    NSString* subPath = [NSString pathWithComponents:subComponents];
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:subPath isDirectory:&isDir];
    if (! exists)
    {
      result = [[NSFileManager defaultManager] createDirectoryAtPath:subPath attributes:attributes];
      if (! result)
        return result;
    }
  }
  return result;
}

@end

