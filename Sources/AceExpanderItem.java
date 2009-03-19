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
// AceExpanderItem.java
//
// This class represents an ACE archive in the file system and, at the same
// time, a row in the table of archives in the application's GUI. It
// is responsible for notifying others if its state changes (exceptions
// are construction/destruction):
// - whenever anything changes that is displayed in the main window table,
//   call the model's itemHasChanged() method
// - whenever anything changes that is displayed in the result window,
//   post a UpdateResultWindowNotification notification
// - whenever anything changes that is displayed in the content list drawer,
//   post a UpdateContentListDrawerNotification notification
//
// An item always has one of the following states:
//  - QUEUED: This is the initial state when the item is created. An item
//    may also re-enter this state if it was previously in state SKIP,
//    ABORTED, SUCCESS or FAILURE. When the item list is processed, every
//    item in the list that has this state is processed.
//  - SKIP: When the item list is processed, items with this state are
//    ignored
//  - PROCESSING: When the application starts processing an item, the
//    item is moved from being QUEUED to this state.
//  - ABORTED: When an item is in the state PROCESSING and the processing
//    is stopped forcefully, the item moves to this state
//  - SUCCESS: When the application finishes processing an item and it
//    was expanded successfully, the item moves to this state.
//  - FAILURE: as with SUCCESS, but an error occurred during processing
//

package ch.herzbube.aceexpander;

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class AceExpanderItem
{
   // ======================================================================
   // Member variables
   // ======================================================================

   // Constants
   public final static int QUEUED = 0;
   public final static int SKIP = 1;
   public final static int PROCESSING = 2;
   public final static int ABORTED = 3;
   public final static int SUCCESS = 4;
   public final static int FAILURE = 5;
   public final static String ColumnIdentifierDate = "date";
   public final static String ColumnIdentifierTime = "time";
   public final static String ColumnIdentifierPacked = "packed";
   public final static String ColumnIdentifierSize = "size";
   public final static String ColumnIdentifierRatio = "ratio";
   public final static String ColumnIdentifierFileName = "fileName";
   
   // Attributes to the file item
   private String m_fileName;
   private NSImage m_icon;

   // Attributes to the unace execution state
   private int m_iState;
   private String m_messageStdout;
   private String m_messageStderr;

   // Content list of this item
   private NSMutableArray m_contentItemList = new NSMutableArray();

   // Other members
   private AceExpanderModel m_theModel;

   // ======================================================================
   // Constructors
   // ======================================================================

   public AceExpanderItem(String fileName, AceExpanderModel theModel)
   {
      m_theModel = theModel;
      if (null == m_theModel)
      {
         String errorDescription = "The AceExpanderModel instance given in the AceExpanderItem constructor is null.";
         NSNotificationCenter.defaultCenter().postNotification(AceExpanderController.ErrorConditionOccurredNotification, errorDescription);
      }

      // Do not call setFileName; we don't want that notifications are
      // posted during construction
      clearAttributes();
      m_fileName = fileName;
      updateIcon();
   }

   // ======================================================================
   // Accessor methods
   // ======================================================================

   public String getFileName()
   {
      return m_fileName;
   }

   public void setFileName(String fileName)
   {
      clearAttributes();
      m_fileName = fileName;
      updateIcon();

      // Notify others that state has changed
      m_theModel.itemHasChanged(this);
      NSNotificationCenter.defaultCenter().postNotification(AceExpanderController.UpdateResultWindowNotification, null);
      NSNotificationCenter.defaultCenter().postNotification(AceExpanderController.UpdateContentListDrawerNotification, null);
   }

   public NSImage getIcon()
   {
      return m_icon;
   }

   public int getState()
   {
      return m_iState;
   }

   public String getStateAsString()
   {
      switch (m_iState)
      {
         case QUEUED:
            return "Queued";
         case SKIP:
            return "Skip";
         case PROCESSING:
            return "Processing";
         case ABORTED:
            return "Aborted";
         case SUCCESS:
            return "Success";
         case FAILURE:
            return "Failure";
         default:
            return "Undefined";
      }
   }

   public void setState(int iState)
   {
      if (QUEUED != iState && SKIP != iState && PROCESSING != iState
          && ABORTED != iState && SUCCESS != iState && FAILURE != iState)
      {
         String errorDescription = "Unexpected state " + iState + " in AceExpanderItem.setState().";
         NSNotificationCenter.defaultCenter().postNotification(AceExpanderController.ErrorConditionOccurredNotification, errorDescription);
         return;
      }
      m_iState = iState;

      m_theModel.itemHasChanged(this);
   }

   public String getMessageStdout()
   {
      return m_messageStdout;
   }

   public void setMessageStdout(String messageStdout, int iCommand)
   {
      m_messageStdout = messageStdout;
      if (AceExpanderThread.LIST == iCommand)
      {
         parseMessageStdout();
      }
      NSNotificationCenter.defaultCenter().postNotification(AceExpanderController.UpdateResultWindowNotification, null);
   }

   public String getMessageStderr()
   {
      return m_messageStderr;
   }

   public void setMessageStderr(String messageStderr)
   {
      m_messageStderr = messageStderr;
      NSNotificationCenter.defaultCenter().postNotification(AceExpanderController.UpdateResultWindowNotification, null);
   }

   // Is implemented as a convenience method, and so that only one
   // notification is posted instead of two, if the messages were set
   // independently
   public void setMessages(String messageStdout, String messageStderr, int iCommand)
   {
      m_messageStdout = messageStdout;
      if (AceExpanderThread.LIST == iCommand)
      {
         parseMessageStdout();
      }
      m_messageStderr = messageStderr;
      NSNotificationCenter.defaultCenter().postNotification(AceExpanderController.UpdateResultWindowNotification, null);
   }

   // ======================================================================
   // Methods for managing the archive content list
   // ======================================================================

   // Internal helper method
   // Parses the currently set stdout message string and tries to determine
   // if it contains a listing of the archive contents. If a listing appears
   // to be there, the listing is parsed and each line of content is
   // appended to an array of line strings. This array is then passed
   // to another method for updating the content item list.
   private void parseMessageStdout()
   {
      boolean bMessageContainsListing = false;
      int bLeadInLines = 3;
      
      NSMutableArray contentLinesArray = new NSMutableArray();
      java.util.StringTokenizer tokenizer = new java.util.StringTokenizer(m_messageStdout, "\n");
      while (tokenizer.hasMoreElements())
      {
         String messageLine = (String)tokenizer.nextElement();
         // As long as we don't know whether or not the message contains
         // a listing of the archive contents, we go on looking for
         // a trigger line
         if (! bMessageContainsListing)
         {
            if (messageLine.startsWith("Contents of archive"))
            {
               bMessageContainsListing = true;
            }
         }
         // OK, now we know that the message contains a listing, but we
         // still have to skip a number of lead-in lines
         else if (bLeadInLines > 0)
         {
            bLeadInLines--;
         }
         // OK, everything from now on is a content line
         else
         {
            // A line starting like this marks the end of the listing
            if (messageLine.startsWith("listed:"))
            {
               break;
            }
            
            String trimmedMessageLine = messageLine.trim();
            // Ignore empty lines 
            if (0 == trimmedMessageLine.length())
            {
               continue;
            }
            
            contentLinesArray.addObject(trimmedMessageLine);
         }
      }

      updateContentItemList(contentLinesArray);
      NSNotificationCenter.defaultCenter().postNotification(AceExpanderController.UpdateContentListDrawerNotification, null);
   }
   
   // The given array should contain String objects, each of which
   // represents one content line from the unace list command.
   // For each line, create a new AceExpanderContentItem object and
   // let it parse the content line. Store the object in an internal list
   // (the list is cleared at the beginning)
   private void updateContentItemList(NSArray contentLines)
   {
      m_contentItemList.removeAllObjects();

      java.util.Enumeration enumerator = contentLines.objectEnumerator();
      while (enumerator.hasMoreElements())
      {
         String contentLine = (String)enumerator.nextElement();

         AceExpanderContentItem contentItem = new AceExpanderContentItem(contentLine);
         m_contentItemList.addObject(contentItem);
      }
   }

      // ======================================================================
   // NSTableView.DataSource interface methods
   // ======================================================================

   public int numberOfRowsInTableView(NSTableView theTableView)
   {
      return m_contentItemList.count();
   }

   public Object tableViewObjectValueForLocation(NSTableView theTableView, NSTableColumn aTableColumn, int rowIndex)
   {
      AceExpanderContentItem contentItem = (AceExpanderContentItem)m_contentItemList.objectAtIndex(rowIndex);
      Object id = aTableColumn.identifier();
      if (id.equals(ColumnIdentifierDate))
      {
         return contentItem.getDate();
      }
      else if (id.equals(ColumnIdentifierTime))
      {
         return contentItem.getTime();
      }
      else if (id.equals(ColumnIdentifierPacked))
      {
         return contentItem.getPacked();
      }
      else if (id.equals(ColumnIdentifierSize))
      {
         return contentItem.getSize();
      }
      else if (id.equals(ColumnIdentifierRatio))
      {
         return contentItem.getRatio();
      }
      else if (id.equals(ColumnIdentifierFileName))
      {
         return contentItem.getFileName();
      }
      else
      {
         return null;
      }
   }

   // ======================================================================
   // Methods
   // ======================================================================

   // Fetch the icon for the currently set file name
   private void updateIcon()
   {
      if (null == m_fileName)
      {
         return;
      }
      // false = the wrapper is not for a symlink
      m_icon = new NSFileWrapper(m_fileName, false).icon();
   }

   // Clear attributes / set them to their default values.
   private void clearAttributes()
   {
      m_fileName = "";
      m_icon = null;
      m_iState = QUEUED;
      m_messageStdout = "";
      m_messageStderr = "";
      m_contentItemList.removeAllObjects();
   }
}