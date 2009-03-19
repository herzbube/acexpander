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
// AceExpanderModel.java
//
// This class is instantiated when the application's .nib is loaded.
//
// This class takes the Model role of the design pattern commonly known
// as Model-View-Controller. It stores the application's working data
// (the ACE archive files that the user specifies) and knows how to operate
// on this data (expand the archive files).
//
// In addition, this class implements the following protocols and
// interfaces:
// - NSNibAwaking protocol: to do stuff after the class has been
//   loaded and instantiated from the .nib file
// - NSTableView.DataSource interface: to provide data for the table
//   in the GUI to display
//

package ch.herzbube.aceexpander;

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class AceExpanderModel
{
   // ======================================================================
   // Member variables
   // ======================================================================

   // These variables are outlets and therefore initialized in the .nib
   private NSTableView m_theTable;

   // Stores a list of items to expand
   private NSMutableArray m_itemList = new NSMutableArray();

   // The thread that manages the expansion
   private AceExpanderThread m_expandThread = null;

   // Options that need to be applied to the expansion process
   private boolean m_bOverwriteFiles = false;
   private boolean m_bExtractFullPath = false;
   private boolean m_bAssumeYes = false;
   private boolean m_bShowComments = true;
   private boolean m_bListVerbosely = true;
   private boolean m_bUsePassword = false;
   private String m_password;
   private boolean m_bDebugMode = false;
   
   // ======================================================================
   // Constructors
   // ======================================================================

   public AceExpanderModel()
   {
   }

   // ======================================================================
   // NSNibAwaking protocol methods
   // ======================================================================

   // Is called after the class has been instantiated and initialized from
   // the .nib
   public void awakeFromNib()
   {
      if (null != m_theTable)
      {
         // Replace the icon column cell with a cell that can display
         // images. I didn't find any way to set this in InterfaceBuilder
         NSTableColumn iconColumn = m_theTable.tableColumnWithIdentifier("icon");
         NSImageCell iconCell = new NSImageCell();
         iconColumn.setDataCell(iconCell);
      }
   }
   
   // ======================================================================
   // Accessor methods
   // ======================================================================

   public void addItem(String fileName)
   {
      AceExpanderItem item = new AceExpanderItem(fileName, this);
      m_itemList.addObject(item);

      // Update the table
      m_theTable.reloadData();
   }

   // Remove all items selected in the table
   public void removeItems()
   {
      if (0 == m_theTable.numberOfSelectedRows())
      {
         return;
      }

      NSEnumerator enumerator = m_theTable.selectedRowEnumerator();
      while (enumerator.hasMoreElements())
      {
         Integer iSelectedRow = (Integer)enumerator.nextElement();
         m_itemList.removeObjectAtIndex(iSelectedRow.intValue());
      }
      
      // Update the table
      m_theTable.reloadData();
   }

   // Remove all items
   public void removeAllItems()
   {
      m_itemList.removeAllObjects();
      // Update the table
      m_theTable.reloadData();
   }
   
   // Return the item that matches the given filename
   public AceExpanderItem getItem(String fileName)
   {
      java.util.Enumeration enumerator = m_itemList.objectEnumerator();
      while (enumerator.hasMoreElements())
      {
         AceExpanderItem item = (AceExpanderItem)enumerator.nextElement();
         if (item.getFileName() == fileName)
         {
            return item;
         }
      }
      return null;
   }

   public void setOverwriteFiles(boolean bOverwriteFiles)
   {
      m_bOverwriteFiles = bOverwriteFiles;
   }

   public boolean getOverwriteFiles()
   {
      return m_bOverwriteFiles;
   }

   public void setExtractFullPath(boolean bExtractFullPath)
   {
      m_bExtractFullPath = bExtractFullPath;
   }

   public boolean getExtractFullPath()
   {
      return m_bExtractFullPath;
   }

   public void setAssumeYes(boolean bAssumeYes)
   {
      m_bAssumeYes = bAssumeYes;
   }

   public boolean getAssumeYes()
   {
      return m_bAssumeYes;
   }

   public void setShowComments(boolean bShowComments)
   {
      m_bShowComments = bShowComments;
   }

   public boolean getShowComments()
   {
      return m_bShowComments;
   }

   public void setListVerbosely(boolean bListVerbosely)
   {
      m_bListVerbosely = bListVerbosely;
   }

   public boolean getListVerbosely()
   {
      return m_bListVerbosely;
   }

   public void setUsePassword(boolean bUsePassword, String password)
   {
      m_bUsePassword = bUsePassword;
      m_password = password;
   }

   public boolean getUsePassword()
   {
      return m_bUsePassword;
   }

   public String getPassword()
   {
      return m_password;
   }

   public void setDebugMode(boolean bDebugMode)
   {
      m_bDebugMode = bDebugMode;
   }

   public boolean getDebugMode()
   {
      return m_bDebugMode;
   }

   // ======================================================================
   // Methods for expanding items
   // ======================================================================

   public boolean startExpandItems()
   {
      return startThread(AceExpanderThread.EXPAND);
   }

   public boolean startListItems()
   {
      return startThread(AceExpanderThread.LIST);
   }

   public boolean startTestItems()
   {
      return startThread(AceExpanderThread.TEST);
   }

   // If a thread is running, tell it to stop as soon as possible
   public void stopCommand()
   {
      if (null != m_expandThread && m_expandThread.isAlive())
      {
         m_expandThread.stopRunning();
      }
   }

   // Is the thread that manages the expansion still running?
   public boolean isExpansionRunning()
   {
      if (null != m_expandThread && m_expandThread.isAlive())
      {
         return true;
      }
      else
      {
         return false;
      }
   }

   // Spawn a thread to perform the expansion (or whatever command is
   // given). The thread starts the actual expansion done by unace in
   // a separate process. Returns true if a thread was started,
   // otherwise returns false.
   public boolean startThread(int iCommand)
   {
      // We don't know what to operate on if no table item is selected
      // -> abort
      if (0 == m_theTable.numberOfSelectedRows())
      {
         return false;
      }

      // Create the thread
      m_expandThread = new AceExpanderThread(this);

      // Collect the selected items and feed them into the thread
      NSEnumerator enumerator = m_theTable.selectedRowEnumerator();
      while (enumerator.hasMoreElements())
      {
         Integer iSelectedRow = (Integer)enumerator.nextElement();
         AceExpanderItem item = (AceExpanderItem)m_itemList.objectAtIndex(iSelectedRow.intValue());
         m_expandThread.addItem(item);
      }

      // Set the options
      m_expandThread.setArguments(iCommand, m_bOverwriteFiles,
                                  m_bExtractFullPath, m_bAssumeYes,
                                  m_bShowComments, m_bListVerbosely,
                                  m_bUsePassword, m_password, m_bDebugMode);

      // Run the thread
      m_expandThread.start();

      return true;
   }
   
   // ======================================================================
   // NSTableView.DataSource interface methods
   // ======================================================================

   public int numberOfRowsInTableView(NSTableView theTableView)
   {
      return m_itemList.count();
   }

   public Object tableViewObjectValueForLocation(NSTableView theTableView, NSTableColumn aTableColumn, int rowIndex)
   {
      AceExpanderItem item = (AceExpanderItem)m_itemList.objectAtIndex(rowIndex);
      Object id = aTableColumn.identifier();
      String foo = id.toString();
      if (id.equals("icon"))
      {
         return item.getIcon();
      }
      else if (id.equals("fileName"))
      {
         return item.getFileName();
      }
      else if (id.equals("state"))
      {
         return item.getStateAsString();
      }
      else
      {
         return null;
      }
   }

   // ======================================================================
   // Methods
   // ======================================================================

   public void setAllItemsToState(int iState)
   {
      java.util.Enumeration enumerator = m_itemList.objectEnumerator();
      while (enumerator.hasMoreElements())
      {
         AceExpanderItem item = (AceExpanderItem)enumerator.nextElement();
         item.setState(iState);
      }

      // No need to tell the table to reload data -> the items that have
      // changed have already done this for us
   }

   // Set the state of only the selected items
   public void setItemsToState(int iState)
   {
      if (0 == m_theTable.numberOfSelectedRows())
      {
         return;
      }

      NSEnumerator enumerator = m_theTable.selectedRowEnumerator();
      while (enumerator.hasMoreElements())
      {
         Integer iSelectedRow = (Integer)enumerator.nextElement();
         AceExpanderItem item = (AceExpanderItem)m_itemList.objectAtIndex(iSelectedRow.intValue());
         item.setState(iState);
      }

      // No need to tell the table to reload data -> the items that have
      // changed have already done this for us
   }

   // An item calls this method if it is changed in any way
   public void itemHasChanged(AceExpanderItem item)
   {
      // Update the table
      m_theTable.reloadData();
   }
}
