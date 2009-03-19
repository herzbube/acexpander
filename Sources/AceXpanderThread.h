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

// -----------------------------------------------------------------------------
// The following line is required so that doxygen documents the global items
// below.
/// @file
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
/// @brief States that an AceXpanderItem can have. See class documentation
/// for more information.
// -----------------------------------------------------------------------------
enum AceXpanderCommand
{
   ExpandCommand   = 0,
   ListCommand     = 1,
   TestCommand     = 2
};


// -----------------------------------------------------------------------------
/// @brief The AceXpanderThread class encapsulates access to the unace binary,
/// either the one that is included with the application as a resource, or the
/// one that the user specifies in the user preferences dialog.
///
/// The main function of AceXpanderThread is to execute all the possible unace
/// commands, using the unace binary that it encapsulates. It does so by
/// spawning a new thread and executing the command in that thread's context.
/// The GUI thereby remains responsive to any user requests, especially to
/// stop the currently running command.
///
/// Before any command can be executed, at least one archive item must have
/// been added to this thread with addItem:(). In addition, the setCommand:()
/// message must have been sent at least once so that a correct command line can
/// be built using the supplied arguments.
///
/// When all pre-conditions have been met, command execution can be started by
/// sending the run:() message. This will launch the new thread, which will then
/// iterate all archive items previously added and try to process those that
/// have their state set to #QueuedState. For each item, a new system process is
/// launched that executes the unace binary with the command (i.e. expand, list,
/// test) specified through setArguments:(). The process is run synchronously,
/// i.e. the thread waits for it to complete before it processes the next item.
///
/// After all items were processed, the notification
/// #commandThreadHasFinishedNotification is posted to the application's default
/// notification centre and the thread exits. To interrupt the thread while it
/// is still processing items, a client may send the message stopRunning:().
/// The thread then tries to stop its operation as soon as possible.
///
/// Items are updated with results as soon as their system process exits. Items
/// are responsible for making these results visible to the user.
// -----------------------------------------------------------------------------
@interface AceXpanderThread : NSObject
{
@private
  /// @brief List with items to expand
  NSMutableArray* m_itemList;

  /// @brief The command line arguments
  //@{
  NSString* m_unaceFrontendDebugParameter;
  NSString* m_unaceCommand;
  NSMutableArray* m_unaceSwitchList;
  //@}

  // The process
  NSTask* m_unaceTask;

  /// @brief Flag that indicates whether or not the thread is running
  BOOL m_isRunning;

  // This flag indicates whether or not the thread should stop running
  BOOL m_stopRunning;

  /// @brief Stores the destination folder for which the user has been queried
  /// when the first item was expanded.
  NSString* m_destinationFolderAskWhenExpanding;

  /// @brief The command currently running, or last run, in its numerical form
  int m_command;
}

/// @name Initializers
//@{
- (id) init;
//@}

/// @name Start/stop thread
//@{
- (void) run;
- (void) stopRunning;
- (BOOL) isRunning;
//@}

/// @name Adding/removing items
//@{
- (void) addItem:(AceXpanderItem*)item;
- (void) removeItem:(AceXpanderItem*)item;
//@}

/// @name Other methods
//@{
- (void) setCommand:(int)command
     overwriteFiles:(BOOL)overwriteFiles
    extractFullPath:(BOOL)extractFullPath
          assumeYes:(bool)assumeYes
       showComments:(BOOL)showComments
      listVerbosely:(BOOL)listVerbosely
        usePasswort:(BOOL)usePassword
           password:(NSString*)password
          debugMode:(BOOL)debugMode;
- (NSString*) unaceVersion;
//@}

@end
