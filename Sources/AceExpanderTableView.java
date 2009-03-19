//
// AceExpander - a Mac OS X graphical user interface to the unace command line utility
//
// Copyright (C) 2004 Patrick NŠf
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
// aceexpander@herzbube.ch
//
// --------------------------------------------------------------------------------
//
// AceExpanderTableView.java
//
// This class is instantiated when the application's .nib is loaded.
//
// This class is sub-classed from NSTableView only for the sake of
// implementing the NSDraggingDestination protocol, so that the user
// can drag&drop files into the area of the table.
//

package ch.herzbube.aceexpander;

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class AceExpanderTableView extends NSTableView
{
   // ======================================================================
   // Member variables
   // ======================================================================

   // These variables are outlets and therefore initialized in the .nib
   AceExpanderModel m_theModel;

   // Determines whether the table view should be displayed highlighted
   // when the table view is drawn next (in order to indicate that the
   // drag is accepted)
   boolean m_bHighlight;

   // ======================================================================
   // Constructors
   // ======================================================================

   // Because this class is a sub-class of an NSView sub-class, this
   // constructor is needed, otherwise the java bridge complains with an
   // obscure error and the application won't start.
   // Got the solution from http://developer.apple.com/documentation/DeveloperTools/Conceptual/IBTips/Articles/FreqAskedQuests.html
   protected AceExpanderTableView(NSCoder decoder, long token)
   {
      super(decoder, token);
      m_bHighlight = false;
   }

   // ======================================================================
   // NSNibAwaking protocol methods
   // ======================================================================

   public void awakeFromNib()
   {
      NSMutableArray dragTypesArray = new NSMutableArray();
      dragTypesArray.addObject(NSPasteboard.FilenamesPboardType);
      registerForDraggedTypes(dragTypesArray);
   }

   // ======================================================================
   // NSDraggingDestination protocol methods
   // ======================================================================

   // Is called when the drag enters the table's boundaries.
   public int draggingEntered(NSDraggingInfo sender)
   {
      // Check if drag is valid
      if (null == validateDrag(sender))
      {
         // No, drag is not valid -> drag cannot be accepted
         return NSDraggingInfo.DragOperationNone;
      }
      else
      {
         // Yes, drag is valid
         // -> table should be displayed highlighted
         // -> drag is accepted (we will copy the data that is dragged)
         m_bHighlight = true;
         setNeedsDisplay(true);
         return NSDraggingInfo.DragOperationCopy;
      }
   }

   // Is called while the drag remains within the table's boundaries
   public int draggingUpdated(NSDraggingInfo sender)
   {
      if (null == validateDrag(sender))
      {
         return NSDraggingInfo.DragOperationNone;
      }
      else
      {
         return NSDraggingInfo.DragOperationCopy;
      }
   }

   // Is called when the drag leaves the table's boundaries
   public void draggingExited(NSDraggingInfo sender)
   {
      // Table should be displayed normal again
      m_bHighlight = false;
      setNeedsDisplay(true);
   }

   // Is called when the drop is made and the most recent call to
   // draggingEntered() or draggingUpdated() accepted the drag
   public boolean prepareForDragOperation(NSDraggingInfo sender)
   {
      if (null == validateDrag(sender))
      {
         return false;
      }
      else
      {
         return true;   // OK, we're prepared
      }
   }

   // Is called when prepareForDragOperation() returned true
   public boolean performDragOperation(NSDraggingInfo sender)
   {
      NSPasteboard pboard = sender.draggingPasteboard();
      
      // Create new array and add the type of data that we want
      NSMutableArray listOfTypesWeWant = new NSMutableArray();
      listOfTypesWeWant.addObject(NSPasteboard.FilenamesPboardType);
      // Let the pasteboard check if it contains any of the wanted types.
      // If so it will return the first of the wanted types that it
      // contains
      String type = pboard.availableTypeFromArray(listOfTypesWeWant);
      if (null != type)
      {
         // Table should be displayed normal again
         m_bHighlight = false;
         setNeedsDisplay(true);

         // Get the list of all files/folders dropped...
         NSArray fileNames = (NSArray) pboard.propertyListForType(NSPasteboard.FilenamesPboardType);
         // ... and add the filenames/foldernames to the table
         java.util.Enumeration enumerator = fileNames.objectEnumerator();
         while (enumerator.hasMoreElements())
         {
            String fileName = (String)enumerator.nextElement();
            m_theModel.addItem(fileName);
         }

         return true;
      }
      // Should not happen
      else
      {
         NSAlertPanel alert = new NSAlertPanel();
         alert.runAlert("Incorrect Type", "The table has not registered for this drag type", null, null, null);

         return false;
      }
   }
   
   // ======================================================================
   // Methods
   // ======================================================================

   // Test whether we can handle the dragged object. If no, return
   // null. If yes return the type of the dragged object as string.
   public String validateDrag(NSDraggingInfo sender)
   {
      // Only accept the object if it does not originate from this window
      if (sender.draggingSource() != this)
      {
         // Get the pasteboard and check whether it contains dragged data
         // of the type FilenamesPboardType
         NSPasteboard pboard = sender.draggingPasteboard();
         String type = pboard.availableTypeFromArray(new NSArray(NSPasteboard.FilenamesPboardType));

         if (null != type)
         {
            return pboard.stringForType(type);
         }
      }
      return null;
   }

   // Add highlighting to drawing of box
   public void drawRect(NSRect rect)
   {
      if (m_bHighlight)
      {
         NSColor.lightGrayColor().set();
         NSBezierPath.fillRect(rect);
      }
      super.drawRect(rect);
   }
}
