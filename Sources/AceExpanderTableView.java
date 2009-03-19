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
      if (! validateDrag(sender))
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
   // Note: this method must be implemented, even though the article
   // "Receiving Drag Operations" in the "Drag and Drop" topic of ADC
   // claims otherwise!
   public int draggingUpdated(NSDraggingInfo sender)
   {
      if (! validateDrag(sender))
         return NSDraggingInfo.DragOperationNone;
      else
         return NSDraggingInfo.DragOperationCopy;
   }
   
   // Is called when the drag leaves the table's boundaries
   public void draggingExited(NSDraggingInfo sender)
   {
      // Table should be displayed normal again
      m_bHighlight = false;
      setNeedsDisplay(true);
   }

/*
 * We don't need this - just for demonstration
 *
   // Is called when the drop is made and the most recent call to
   // draggingEntered() or draggingUpdated() accepted the drag
   public boolean prepareForDragOperation(NSDraggingInfo sender)
   {
      return validateDrag(sender);
   }
 */

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
      // Should never happen
      else
      {
         NSAlertPanel alert = new NSAlertPanel();
         alert.runAlert("Incorrect Type", "The table has not registered for this drag type", null, null, null);

         return false;
      }
   }

   // ======================================================================
   // Methods managing the Services application menu
   // ======================================================================

   // This method is called because this object is in the responder chain.
   // The method must check if the object is able to provide data for a
   // Service, or if it can accept data from a Service.
   public Object validRequestorForTypes(String sendType, String returnType)
   {
      // We don't want to receive data -> returnType must be null
      // We only send data of types Filename, URL, String
      // We can only provide data if something is selected
      if (null == returnType
          && (sendType.equals(NSPasteboard.FilenamesPboardType) ||
              sendType.equals(NSPasteboard.URLPboardType) ||
              sendType.equals(NSPasteboard.StringPboardType))
          && numberOfSelectedRows() > 0)
      {
         // Confirm that this object can provide data
         return this;
      }

      // Let the next responder handle the request
      return super.validRequestorForTypes(sendType, returnType);
   }

   // This method is called when we have to provide data for a Service
   boolean writeSelectionToPasteboardOfTypes(NSPasteboard pboard, NSArray types)
   {
      // Can we handle the requested types?
      if (! types.containsObject(NSPasteboard.StringPboardType) &&
          ! types.containsObject(NSPasteboard.FilenamesPboardType) &&
          ! types.containsObject(NSPasteboard.URLPboardType))
         return false;

      // Do we have any data to provide?
      if (numberOfSelectedRows() == 0)
      {
         return false;
      }
      
      // Get the filenames of the selected table rows
      NSMutableArray fileNames = new NSMutableArray();
      NSEnumerator tableEnumerator = selectedRowEnumerator();
      while (tableEnumerator.hasMoreElements())
      {
         Integer iSelectedRow = (Integer)tableEnumerator.nextElement();
         fileNames.addObject(m_theModel.getItem(iSelectedRow.intValue()).getFileName());
      }

      // For every type that we can handle, write the data to the pasteboard
      // in the appropriate form
      NSArray typesDeclared;
      if (types.containsObject(NSPasteboard.StringPboardType))
      {
         typesDeclared = new NSArray(NSPasteboard.StringPboardType);
         pboard.declareTypes(typesDeclared, null);
         // Only paste the first filename
         return pboard.setStringForType((String)fileNames.objectAtIndex(0), NSPasteboard.StringPboardType);
      }
      
      if (types.containsObject(NSPasteboard.FilenamesPboardType))
      {
         typesDeclared = new NSArray(NSPasteboard.FilenamesPboardType);
         pboard.declareTypes(typesDeclared, null);
         // Not sure if this is the right way to do it: the "Data Types"
         // article in the "Copying and Pasting" topic on ADC says:
         // "NSFilenamesPboardTypeÕs form is an array of NSStrings"
         // -> it could be the right way, because performDragOperation()
         //    demonstrates how it works backwards
         return pboard.setPropertyListForType(fileNames, NSPasteboard.StringPboardType);
      }

      if (types.containsObject(NSPasteboard.URLPboardType))
      {
         typesDeclared = new NSArray(NSPasteboard.URLPboardType);
         pboard.declareTypes(typesDeclared, null);
         // TODO: change this to something sensible! The "Data Types"
         // article in the "Copying and Pasting" topic on ADC says
         // to use NSURL::writeToPasteboard(), but we don't have NSURL
         // in Java :-(
         return false;
      }

      return false;
   }

   // ======================================================================
   // Methods
   // ======================================================================

   // Test whether we can handle the dragged object. If no, return
   // false, otherwise return true
   public boolean validateDrag(NSDraggingInfo sender)
   {
      // Reject the object if it originates from the window that contains
      // this table
      if (sender.draggingSource() == window())
      {
         return false;
      }
      
       // Get the pasteboard and check whether it contains dragged data
       // of the type FilenamesPboardType
       NSPasteboard pboard = sender.draggingPasteboard();
       String type = pboard.availableTypeFromArray(new NSArray(NSPasteboard.FilenamesPboardType));
       if (null == type)
       {
          return false;
       }
       
       // Check what type of drag the source allows. We accept any type.
       if (sender.draggingSourceOperationMask() == NSDraggingInfo.DragOperationNone)
       {
          return false;
       }

       // Finally accept the drag
       return true;
   }

   // Add highlighting to drawing of box
   // TODO: make this work!
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
