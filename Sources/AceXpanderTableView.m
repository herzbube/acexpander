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
#import "AceXpanderTableView.h"
#import "AceXpanderModel.h"

/// @brief This category declares private methods for the AceXpanderTableView
/// class. 
@interface AceXpanderTableView(Private)
/// @name Deallocation
//@{
- (void) dealloc;
//@}
/// @name NSNibAwaking protocol
//@{
- (void) awakeFromNib;
//@}

/// @name NSDraggingDestination protocol
//@{
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender;
- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>)sender;
- (void) draggingExited:(id <NSDraggingInfo>)sender;
- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender;
- (void) concludeDragOperation:(id <NSDraggingInfo>)sender;
//@}

/// @name Managing the Services application menu
//@{
- (id) validRequestorForSendType:(NSString*)sendType returnType:(NSString*)returnType;
- (BOOL) writeSelectionToPasteboard:(NSPasteboard*)pboard types:(NSArray*)types;
//@}

/// @name Other methods
//@{
- (BOOL) validateDragOperation:(id <NSDraggingInfo>)sender;
- (void) drawRect:(NSRect)rect;
//@}
@end

@implementation AceXpanderTableView

// -----------------------------------------------------------------------------
/// @brief Initializes an AceXpanderTableView object.
///
/// @note This is the designated initializer of AceXpanderTableView.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super initWithCoder:decoder];
  if (! self)
    return nil;

  m_highlight = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this AceXpanderTableView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Is called after an AceXpanderTableView object has been allocated and
/// initialized from the .nib
///
/// @note This is an NSNibAwaking protocol method.
// -----------------------------------------------------------------------------
- (void) awakeFromNib
{
  NSMutableArray* dragTypesArray = [NSMutableArray arrayWithCapacity:0];
  [dragTypesArray addObject:NSFilenamesPboardType];
  [self registerForDraggedTypes:dragTypesArray];
}

// -----------------------------------------------------------------------------
/// @brief Returns NSDragOperationNone, or NSDragOperationCopy, if the data
/// carried by @a sender is unsuitable, or suitable, for this table view.
///
/// This method is called when the mouse cursor enters the table's boundaries
/// during a drag operation.
///
/// @note This is an NSDraggingDestination protocol method.
// -----------------------------------------------------------------------------
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
  // Check if drag operation originates from suitable source and carries
  // suitable data
  if (! [self validateDragOperation:sender])
    return NSDragOperationNone;
  else
  {
    // Yes, drag operation is suitable
    // -> table should be displayed highlighted
    // -> drag is accepted (we will copy the data that is dragged)
    m_highlight = true;
    [self setNeedsDisplay:true];
    return NSDragOperationCopy;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns NSDragOperationNone, or NSDragOperationCopy, if the data
/// carried by @a sender is unsuitable, or suitable, for this table view.
///
/// This method is called when the mouse cursor moves within the table's
/// boundaries during a drag operation.
///
/// @note This method must be implemented, even though the article
/// "Receiving Drag Operations" in the "Drag and Drop" topic of ADC
/// claims otherwise!
///
/// @note This is an NSDraggingDestination protocol method.
// -----------------------------------------------------------------------------
- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>)sender
{
  if (! [self validateDragOperation:sender])
    return NSDragOperationNone;
  else
    return NSDragOperationCopy;
}

// -----------------------------------------------------------------------------
/// @brief Removes the table's highlighting.
///
/// This method is called when the mouse cursor leaves the table's boundaries
/// during a drag operation.
///
/// @note This is an NSDraggingDestination protocol method.
// -----------------------------------------------------------------------------
- (void) draggingExited:(id <NSDraggingInfo>)sender
{
  m_highlight = false;
  [self setNeedsDisplay:true];
}

// -----------------------------------------------------------------------------
/// @brief Prepares the table for performing the drag operation and returns
/// true if preparations were successful and drag operation can be accepted,
/// false if not.
///
/// This method is called when the drop is made at the end of a drag operation
/// and the most recent call to draggingEntered:() or draggingUpdated:()
/// accepted the drag operation.
///
/// @note This implementation exists for demonstration purposes only. It is a
/// dummy implementation that always returns true.
///
/// @note This is an NSDraggingDestination protocol method.
// -----------------------------------------------------------------------------
- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Performs the actual drag operation, i.e. adds one item to the
/// application model for each file that was dragged.
///
/// This method is called when prepareForDragOperation:() accepted the drag
/// operation.
///
/// @note This is an NSDraggingDestination protocol method.
// -----------------------------------------------------------------------------
- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
  if (! sender)
    return false;
  NSPasteboard* pboard = [sender draggingPasteboard];
  if (! pboard)
    return false;

  // Create new array and add the type of data that we want
  NSMutableArray* listOfTypesWeWant = [NSMutableArray array];
  [listOfTypesWeWant addObject:NSFilenamesPboardType];
  // Let the pasteboard check if it contains any of the wanted types.
  // If so it will return the first of the wanted types that it
  // contains
  NSString* type = [pboard availableTypeFromArray:listOfTypesWeWant];
  if (nil != type)
  {
    // Table should be displayed normal again
    m_highlight = false;
    [self setNeedsDisplay: true];

    // Get the list of all files/folders dropped...
    NSArray* fileNames = (NSArray*) [pboard propertyListForType:NSFilenamesPboardType];
    // ... and add the filenames/foldernames to the table
    NSEnumerator* enumerator = [fileNames objectEnumerator];
    NSString* iterFilename;
    while (iterFilename = (NSString*)[enumerator nextObject])
      [m_theModel addItemForFile:iterFilename];

    return true;
  }
  // Should never happen
  else
  {
    NSAlert* alert = [NSAlert alertWithMessageText:@"Incorrect Type"
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"The table has not registered for this drag type"];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];
    return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Cleans up after the drag operation has been performed (this may
/// include updating the visual representation).
///
/// This method is called when performDragOperation:() returned true.
///
/// @note This implementation exists for demonstration purposes only. It is a
/// dummy implementation that does nothing.
///
/// @note This is an NSDraggingDestination protocol method.
// -----------------------------------------------------------------------------
- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
  // do nothing, method implemented for demonstration purposes only
}

// -----------------------------------------------------------------------------
/// @brief Checks if this table view object is able to provide data for a
/// Service, or if it can accept data from a Service.
///
/// This method is called because this table view object is in the responder
/// chain.
///
/// @note This method is used for managing the Services application menu.
///
/// @retval this table view object (= self) if we are capable of providing one
///   of the requested send types
/// @retval otherwise we invoke the superclass' method implementation
// -----------------------------------------------------------------------------
- (id) validRequestorForSendType:(NSString*)sendType returnType:(NSString*)returnType
{
  // We don't want to receive data -> returnType must be null
  // We only send data of types Filename, URL, String
  // We can only provide data if something is selected
  if (nil == returnType
      && ([sendType isEqualToString:NSFilenamesPboardType] ||
          [sendType isEqualToString:NSURLPboardType] ||
          [sendType isEqualToString:NSStringPboardType])
      && [self numberOfSelectedRows] > 0)
  {
    // Confirm that this object can provide data
    return self;
  }

  // Let the next responder handle the request
  return [super validRequestorForSendType:sendType returnType: returnType];
}

// -----------------------------------------------------------------------------
/// @brief Writes the current selection to pasteboard @a pboard under each
/// type given in @a types.
///
/// This method is called when this table view has to provide data for a
/// Service.
///
/// @note This method is used for managing the Services application menu.
///
/// @retval true if the data for any single type was successfully written,
/// false if not.
// -----------------------------------------------------------------------------
- (BOOL) writeSelectionToPasteboard:(NSPasteboard*)pboard types:(NSArray*)types
{
  // Can we handle the requested types?
  if (! [types containsObject:NSStringPboardType] &&
      ! [types containsObject:NSFilenamesPboardType] &&
      ! [types containsObject:NSURLPboardType])
    return false;

  // Do we have any data to provide?
  if ([self numberOfSelectedRows] == 0)
    return false;

  // Get the filenames of the selected table rows
  NSMutableArray* fileNames = [NSMutableArray array];
  NSIndexSet* selectedRowIndexes = [self selectedRowIndexes];
  if (! selectedRowIndexes)
    return false;
  unsigned int selectedRowIndex;
  for (selectedRowIndex = [selectedRowIndexes firstIndex]; selectedRowIndex != NSNotFound; selectedRowIndex = [selectedRowIndexes indexGreaterThanIndex:selectedRowIndex])
  {
    id item = [m_theModel itemForIndex:selectedRowIndex];
    if (! item)
      continue;
    [fileNames addObject:[item fileName]];
  }

  // For every type that we can handle, write the data to the pasteboard
  // in the appropriate form
  NSArray* typesDeclared;
  if ([types containsObject:NSStringPboardType])
  {
    typesDeclared = [NSArray arrayWithObject:NSStringPboardType];
    [pboard declareTypes:typesDeclared owner:nil];
    // We are lazy and paste only the first file name - although, if we were
    // strict, we should paste a string that is a concatenation of all strings
    // in the "fileNames" array
    return [pboard setString:(NSString*)[fileNames objectAtIndex:0] forType:NSStringPboardType];
  }

  if ([types containsObject:NSFilenamesPboardType])
  {
    typesDeclared = [NSArray arrayWithObject:NSFilenamesPboardType];
    [pboard declareTypes:typesDeclared owner:nil];
    // Not sure if this is the right way to do it: the "Data Types"
    // article in the "Copying and Pasting" topic on ADC says:
    // "NSFilenamesPboardType’s form is an array of NSStrings"
    // -> it could be the right way, because performDragOperation()
    //    demonstrates how it works backwards
    return [pboard setPropertyList:fileNames forType:NSStringPboardType];
  }

  if ([types containsObject:NSURLPboardType])
  {
    typesDeclared = [NSArray arrayWithObject:NSURLPboardType];
    [pboard declareTypes:typesDeclared owner:nil];
    /// @todo Change this to something sensible! The "Data Types"
    /// article in the "Copying and Pasting" topic on ADC says
    /// to use NSURL::writeToPasteboard(), but we don't have NSURL
    /// in Java :-(
    /// -> now we are in Obj-C and we ***do*** have NSUrl !
    return false;
  }

  return false;
}

// -----------------------------------------------------------------------------
/// @brief Tests whether this table view can handle the drag operation attempted
/// by @a sender.
///
/// @return true if drag operation can be handled, false if not.
// -----------------------------------------------------------------------------
- (BOOL) validateDragOperation:(id <NSDraggingInfo>)sender
{
  // Reject the operation if it originates from the window that contains
  // this table
  if ([sender draggingSource] == [self window])
    return false;

  // Get the pasteboard and check whether it contains dragged data
  // of the type FilenamesPboardType
  NSPasteboard* pboard = [sender draggingPasteboard];
  NSString* type = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]];
  if (nil == type)
    return false;

  // Check what type of drag operation (e.g. copy, link, etc.) the source
  // allows. We accept any type.
  if ([sender draggingSourceOperationMask] == NSDragOperationNone)
    return false;

  // Finally accept the drag
  return true;
}

// -----------------------------------------------------------------------------
/// @brief If #m_highlight is true (usually because a drag operation hovers
/// over the table view), add highlighting to the drawing of this view's box.
///
/// @todo Make this work!
// -----------------------------------------------------------------------------
- (void) drawRect:(NSRect)rect
{
  if (m_highlight)
  {
    // Make sure that subsequent drawing uses a light gray color
    [[NSColor lightGrayColor] set];
    // Fill the rectangle with the color set above (light gray)
    [NSBezierPath fillRect:rect];
  }
  // Let the superclass draw the rest for us
  [super drawRect:rect];
}

@end
