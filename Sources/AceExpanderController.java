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
// AceExpanderController.java
//
// This class is instantiated when the application's main .nib is loaded.
//
// This class takes the Controller role of the design pattern commonly known
// as Model-View-Controller. It reacts to user input in the GUI and controls
// the program flow resulting from this user input.
//
// This class also takes the role of delegate of the NSApplication main
// object. In this role it manages the opening of files when the user
// drags them on a representation of the application in the Finder,
// such as on the application icon residing in the dock.
//
// In addition, this class has the following responsibilities:
// - implements NSNibAwaking protocol: to do stuff after the class has been
//   loaded and instantiated from the .nib file
// - implements MenuValidation interface: for all menu items that have this
//   class set as their target, the method validateMenuItem() is queried to
//   automatically enable or disable those menu items
// - is the delegate of the main table view
// 

package ch.herzbube.aceexpander;

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class AceExpanderController
{
   // ======================================================================
   // Member variables
   // ======================================================================

   // Constants
   private final static String PasswordDialogNibName = "PasswordDialog";
   
   // These variables are outlets and therefore initialized in the .nib
   // --- from MainMenu.nib
   private AceExpanderModel m_theModel;
   private NSWindow m_mainWindow;
   private NSTableView m_theTable;
   private NSButton m_cancelButton;
   private NSButton m_expandButton;
   private NSProgressIndicator m_progressIndicator;
   private NSWindow m_resultWindow;
   private NSTextView m_stdoutTextView;
   private NSTextView m_stderrTextView;
   private NSMenuItem m_overwriteFilesMenuItem;
   private NSMenuItem m_extractFullPathMenuItem;
   private NSMenuItem m_assumeYesMenuItem;
   private NSMenuItem m_showCommentsMenuItem;
   private NSMenuItem m_listVerboselyMenuItem;
   private NSMenuItem m_usePasswordMenuItem;
   private NSMenuItem m_debugModeMenuItem;
   private NSMenuItem m_showMainWindowMenuItem;
   private NSMenuItem m_showResultWindowMenuItem;

   // --- from PasswordDialog.nib
   private NSPanel m_passwordDialog;
   private NSSecureTextField m_passwordTextField;

   // Other variables
   private boolean m_bPasswordDialogCancelClicked = true;
   private AceExpanderPreferences m_thePreferences;

   // ======================================================================
   // Constructors
   // ======================================================================

   public AceExpanderController()
   {
      m_thePreferences = new AceExpanderPreferences();
   }

   // ======================================================================
   // NSNibAwaking protocol methods
   // ======================================================================

   // Is called after the class has been instantiated and initialized from
   // the .nib
   public void awakeFromNib()
   {
      // Register for notification posted by the expand thread after it
      // has finished
      Class[] parameterTypes = {};   // must not be null
      NSNotificationCenter.
      defaultCenter().
      addObserver(this,
                  new NSSelector("expandThreadHasFinished", parameterTypes),
                  AceExpanderThread.ExpandThreadHasFinishedNotification,
                  null);

      // When the .nib is edited with InterfaceBuilder, the progress
      // indicator should be visible, otherwise it might be overlooked
      // by the person who is editing the .nib
      // -> we set this property here instead of in InterfaceBuilder
      m_progressIndicator.setDisplayedWhenStopped(false);

      // Initialize menu items that can be checked/unchecked with the
      // default state of the corresponding model data
      setMenuItemState(m_overwriteFilesMenuItem, m_theModel.getOverwriteFiles());
      setMenuItemState(m_extractFullPathMenuItem, m_theModel.getExtractFullPath());
      setMenuItemState(m_assumeYesMenuItem, m_theModel.getAssumeYes());
      setMenuItemState(m_showCommentsMenuItem, m_theModel.getShowComments());
      setMenuItemState(m_listVerboselyMenuItem, m_theModel.getListVerbosely());
      setMenuItemState(m_usePasswordMenuItem, m_theModel.getUsePassword());
      setMenuItemState(m_debugModeMenuItem, m_theModel.getDebugMode());

      // These windows automatically restore their frame from the user
      // defaults, and save it to the user defaults if any changes occur
      m_mainWindow.setFrameAutosaveName(AceExpanderPreferences.MainWindowFrameName);
      m_resultWindow.setFrameAutosaveName(AceExpanderPreferences.ResultWindowFrameName);

      // Show the result window if the user defaults say so
      if (NSUserDefaults.standardUserDefaults().booleanForKey(AceExpanderPreferences.ShowResultWindow))
      {
         m_resultWindow.makeKeyAndOrderFront(this);
         m_mainWindow.makeKeyAndOrderFront(this);
      }
   }

   // ======================================================================
   // NSApplication delegate methods
   // ======================================================================
   
   // If this message is received during application launch, it is received
   // before applicationDidFinishLaunching(), but after
   // applicationWillFinishLaunching(). If multiple files should be opened,
   // the message is sent once for every file.
   public boolean applicationOpenFile(NSApplication theApplication, String fileName)
   {
      m_theModel.addItem(fileName);
      return true;
   }

   // ======================================================================
   // NSWindow delegate methods
   // ======================================================================

   public void windowWillClose(NSNotification notification)
   {
      Object window = notification.object();
      if (window == m_mainWindow)
      {
         // Depending on the user default, terminate the application when the
         // main window is closed
         if (NSUserDefaults.standardUserDefaults().booleanForKey(AceExpanderPreferences.QuitAppWhenMainWindowIsClosed))
         {
            NSApplication.sharedApplication().terminate(this);
         }
      }
      else if (window == m_resultWindow)
      {
         NSUserDefaults.standardUserDefaults().setBooleanForKey(false, AceExpanderPreferences.ShowResultWindow);
      }
   }

   public void windowDidBecomeMain(NSNotification notification)
   {
      Object window = notification.object();
      if (window == m_resultWindow)
      {
         NSUserDefaults.standardUserDefaults().setBooleanForKey(true, AceExpanderPreferences.ShowResultWindow);
      }
   }

   // ======================================================================
   // MenuValidation interface methods
   // ======================================================================

   // We use NSMenuItem for the parameter's type, because the AppKit
   // documentation says that the original type _NSObsoleteMenuItemProtocol
   // will be removed in the future
   public boolean validateMenuItem(NSMenuItem menuItem)
   {
      // Disable menus while expansion is in progress
      if (m_theModel.isExpansionRunning())
      {
         return false;
      }
      else
      {
         // Bug in unace: "assume yes" must always be turned on when
         // overwrite is turned on
         if (menuItem == m_assumeYesMenuItem)
         {
            if (m_theModel.getOverwriteFiles())
               return false;
            else
               return true;
         }
         // Disable "main window" menu item if main window is already shown
         else if (menuItem == m_showMainWindowMenuItem)
         {
            if (m_mainWindow.isVisible())
               return false;
            else
               return true;
         }
         // Disable "main window" menu item if main window is already shown
         else if (menuItem == m_showResultWindowMenuItem)
         {
            if (m_resultWindow.isVisible())
               return false;
            else
               return true;
         }
         // Enable items in all other circumstances
         else
         {
            return true;
         }
      }
   }

   // ======================================================================
   // NSTableView delegate methods
   // ======================================================================

   public void tableViewSelectionDidChange(NSNotification aNotification)
   {
      updateResultsWindow();
   }

   // ======================================================================
   // Methods that are actions and therefore connected in the .nib.
   // These methods are manipulating items and their state.
   // ======================================================================

   public void queueAllItems(Object sender)
   {
      m_theModel.setAllItemsToState(AceExpanderItem.QUEUED);
   }

   public void queueItems(Object sender)
   {
      m_theModel.setItemsToState(AceExpanderItem.QUEUED);
   }

   public void unqueueAllItems(Object sender)
   {
      m_theModel.setAllItemsToState(AceExpanderItem.SKIP);
   }

   public void unqueueItems(Object sender)
   {
      m_theModel.setItemsToState(AceExpanderItem.SKIP);
   }

   public void removeAllItems(Object sender)
   {
      m_theModel.removeAllItems();
   }

   public void removeItems(Object sender)
   {
      m_theModel.removeItems();
   }

   public void expandItems(Object sender)
   {
      updateGUI(true);
      boolean bThreadWasStarted = m_theModel.startExpandItems();
      if (! bThreadWasStarted)
      {
         updateGUI(false);
      }
   }

   public void cancelCommand(Object sender)
   {
      m_theModel.stopCommand();
   }

   public void listItems(Object sender)
   {
      updateGUI(true);
      boolean bThreadWasStarted = m_theModel.startListItems();
      if (! bThreadWasStarted)
      {
         updateGUI(false);
      }
   }

   public void testItems(Object sender)
   {
      updateGUI(true);
      boolean bThreadWasStarted = m_theModel.startTestItems();
      if (! bThreadWasStarted)
      {
         updateGUI(false);
      }
   }

   // ======================================================================
   // Methods that are actions, items in application menu
   // ======================================================================

   public void showPreferencesDialog(Object sender)
   {
      m_thePreferences.showPreferencesDialog();
   }

   public void showUnaceVersion(Object sender)
   {
      String version = new AceExpanderThread().getVersion();
      if (null == version)
      {
         NSAlertPanel.runCriticalAlert("Could not determine version information", "", null, null, null);
      }
      else
      {
         NSAlertPanel.runInformationalAlert("Version information", version, null, null, null);
      }
   }

   // ======================================================================
   // Methods that are actions, items in "File" menu
   // ======================================================================

   // Let the user select files via Cocoa's standard Open panel
   public void showOpenDialog(Object sender)
   {
      NSOpenPanel openPanel = NSOpenPanel.openPanel();
      openPanel.setAllowsMultipleSelection(true);
      openPanel.setCanChooseDirectories(false);
      String directory = null;
      String selectedFile = null;
      NSArray fileTypes = null;
      int iResult = openPanel.runModalInDirectory(directory, selectedFile, fileTypes, m_mainWindow);
      if (NSPanel.OKButton == iResult)
      {
         NSArray filesToOpen = openPanel.filenames();
         for (int i = 0; i < filesToOpen.count(); i++)
         {
            String fileToOpen = (String)filesToOpen.objectAtIndex(i);
            m_theModel.addItem(fileToOpen);
         }
      }
   }

   public void showFinderInfo(Object sender)
   {
      NSAlertPanel.runInformationalAlert("Sorry", "Not yet implemented", "OK", "OK", "OK");
   }

   public void revealInFinder(Object sender)
   {
      NSAlertPanel.runInformationalAlert("Sorry", "Not yet implemented", "OK", "OK", "OK");
   }

   // ======================================================================
   // Methods that are actions, items in "Help" menu
   // ======================================================================

   public void showGPL(Object sender)
   {
      NSAlertPanel.runInformationalAlert("Sorry", "Not yet implemented", "OK", "OK", "OK");
   }

   public void showReadme(Object sender)
   {
      NSAlertPanel.runInformationalAlert("Sorry", "Not yet implemented", "OK", "OK", "OK");
   }

   public void showChangeLog(Object sender)
   {
      NSAlertPanel.runInformationalAlert("Sorry", "Not yet implemented", "OK", "OK", "OK");
   }

   // ======================================================================
   // Methods that are actions, items in "Window" menu
   // ======================================================================

   public void showMainWindow(Object sender)
   {
      m_mainWindow.makeKeyAndOrderFront(this);
      // No need to call makeMainWindow()
   }

   public void showResultWindow(Object sender)
   {
      m_resultWindow.makeKeyAndOrderFront(this);
      // No need to call makeMainWindow()
   }

   // ======================================================================
   // Methods that are actions, toggling items in "Options" menu
   // ======================================================================

   public void toggleAssumeYes(Object sender)
   {
      boolean bNewState = ! m_theModel.getAssumeYes();
      m_theModel.setAssumeYes(bNewState);
      setMenuItemState((NSMenuItem)sender, bNewState);
   }

   public void toggleExtractFullPath(Object sender)
   {
      boolean bNewState = ! m_theModel.getExtractFullPath();
      m_theModel.setExtractFullPath(bNewState);;
      setMenuItemState((NSMenuItem)sender, bNewState);
   }

   public void toggleListVerbosely(Object sender)
   {
      boolean bNewState = ! m_theModel.getListVerbosely();
      m_theModel.setListVerbosely(bNewState);;
      setMenuItemState((NSMenuItem)sender, bNewState);
   }

   public void toggleShowComments(Object sender)
   {
      boolean bNewState = ! m_theModel.getShowComments();
      m_theModel.setShowComments(bNewState);;
      setMenuItemState((NSMenuItem)sender, bNewState);
   }

   public void toggleOverwriteFiles(Object sender)
   {
      boolean bNewState = ! m_theModel.getOverwriteFiles();
      m_theModel.setOverwriteFiles(bNewState);;
      setMenuItemState((NSMenuItem)sender, bNewState);

      // Bug in unace: "assume yes" must always be turned on when
      // overwrite is turned on
      if (bNewState)
      {
         m_theModel.setAssumeYes(true);;
         setMenuItemState(m_assumeYesMenuItem, true);
      }
   }

   public void toggleDebugMode(Object sender)
   {
      boolean bNewState = ! m_theModel.getDebugMode();
      m_theModel.setDebugMode(bNewState);;
      setMenuItemState((NSMenuItem)sender, bNewState);
   }

   // ======================================================================
   // Methods that are actions, related to managing the password dialog
   // ======================================================================

   // If password is toggled on, show an application-modal dialog that
   // queries the user for the password
   public void toggleUsePassword(Object sender)
   {
      String password = "";
      boolean bUsePassword = ! m_theModel.getUsePassword();

      // Only display the dialog if the option is toggled on
      if (bUsePassword)
      {
         NSApplication theApp = NSApplication.sharedApplication();
         // Load the .nib if not yet done. m_passwordDialog is an outlet
         // and is set when the .nib is loaded.
         if (null == m_passwordDialog)
         {
            theApp.loadNibNamed(PasswordDialogNibName, this);
         }
         // Prepare and run the dialog. The sheet is attached to
         // m_mainWindow
         theApp.beginSheet(m_passwordDialog, m_mainWindow, null, null, null);
         theApp.runModalForWindow(m_passwordDialog);

         // -------------------------------------------------
         // --- At this point the modal dialog is running ---
         // -------------------------------------------------
         
         // Clean up and close the dialog
         theApp.endSheet(m_passwordDialog);
         m_passwordDialog.orderOut(this);   // remove dialog from screen

         // If the user clicked cancel, the usePassword option remains
         // toggled off
         if (m_bPasswordDialogCancelClicked)
         {
            bUsePassword = false;
         }
         // Otherwise we fetch the entered password
         else
         {
            password = m_passwordTextField.stringValue();
         }
      }

      // Finally update the model
      m_theModel.setUsePassword(bUsePassword, password);
      setMenuItemState((NSMenuItem)sender, bUsePassword);
   }

   public void passwordDialogOKClicked(Object sender)
   {
      m_bPasswordDialogCancelClicked = false;
      NSApplication.sharedApplication().stopModal();
   }
   
   public void passwordDialogCancelClicked(Object sender)
   {
      m_bPasswordDialogCancelClicked = true;
      NSApplication.sharedApplication().stopModal();
   }

  
   // ======================================================================
   // Methods
   // ======================================================================

   // Disable/enable buttons when the expansion process starts/finishes 
   private void updateGUI(boolean bExpandIsRunning)
   {
      m_cancelButton.setEnabled(bExpandIsRunning);
      if (bExpandIsRunning)
      {
         m_progressIndicator.startAnimation(this);
      }
      else
      {
         m_progressIndicator.stopAnimation(this);
      }
      
      m_expandButton.setEnabled(! bExpandIsRunning);
   }

   // Is called by the NSNotificationCenter when the expansion thread
   // has finished. The thread posts the notification.
   public void expandThreadHasFinished()
   {
      updateGUI(false);
      updateResultsWindow();
   }

   // Sets the state of the given menu item to the new state
   private void setMenuItemState(NSMenuItem item, boolean bNewState)
   {
      if (bNewState)
      {
         item.setState(NSCell.OnState);
      }
      else
      {
         item.setState(NSCell.OffState);
      }
   }

   private void updateResultsWindow()
   {
      if (1 != m_theTable.numberOfSelectedRows())
      {
         m_stdoutTextView.setString("");
         m_stderrTextView.setString("");
      }
      else
      {
         AceExpanderItem item = m_theModel.getItem(m_theTable.selectedRow());
         m_stdoutTextView.setString(item.getMessageStdout());
         m_stderrTextView.setString(item.getMessageStderr());
      }
   }
}
