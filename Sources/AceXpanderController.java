//
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
//
// --------------------------------------------------------------------------------
//
// AceXpanderController.java
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
// - central handling for severe application errors; this class registers
//   with the default notification center for the notification
//   ErrorConditionOccurred. Classes may post such a notification if they
//   detect an error they cannot handle
// - instantiates AceXpanderPreferences in the constructor, in order for
//   AceXpanderPreferences to correctly set up the user defaults database
//   NOTE: make sure that this class does not query the user defaults
//   database until after AceXpanderPreferences is instantiated (e.g. do
//   not initialize member variables with values from the user defaults
//   database).
//

package ch.herzbube.acexpander;

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class AceXpanderController
{
   // ======================================================================
   // Member variables
   // ======================================================================

   // Constants
   private final static String PasswordDialogNibName = "PasswordDialog";
   private final static String GnuGPLFileName = "COPYING";
   private final static String ManualFileName = "MANUAL";
   private final static String ReadMeFileName = "README";
   private final static String ChangeLogFileName = "ChangeLog";
   private final static String ReleasePlanFileName = "ReleasePlan";
   private final static String ToDoFileName = "TODO";
   private final static String HomePageURL = "http://www.herzbube.ch/drupal/?q=acexpander";
   // Notifications
   public static final String ExpandThreadHasFinishedNotification = "ExpandThreadHasFinished";
   public static final String ErrorConditionOccurredNotification = "ErrorConditionOccurred";
   public static final String UpdateResultWindowNotification = "UpdateResultWindow";
   public static final String UpdateContentListDrawerNotification = "UpdateContentListDrawer";
   public static final String ModelHasFinishedAwakeFromNibNotification = "ModelHasFinishedAwakeFromNib";

   // These variables are outlets and therefore initialized in the .nib
   // --- from MainMenu.nib
   private AceXpanderModel m_theModel;
   private NSWindow m_mainWindow;
   private NSTableView m_theTable;
   private NSTableView m_theContentListTable;
   private NSDrawer m_theContentListDrawer;
   private NSButton m_cancelButton;
   private NSButton m_expandButton;
   private NSProgressIndicator m_progressIndicator;
   private NSWindow m_resultWindow;
   private NSTextView m_stdoutTextView;
   private NSTextView m_stderrTextView;
   private NSWindow m_textViewWindow;
   private NSTextView m_textView;
   private NSMenuItem m_requeueMenuItem;
   private NSMenuItem m_unqueueMenuItem;
   private NSMenuItem m_removeMenuItem;
   private NSMenuItem m_expandMenuItem;
   private NSMenuItem m_listContentMenuItem;
   private NSMenuItem m_testIntegrityMenuItem;
   private NSMenuItem m_overwriteFilesMenuItem;
   private NSMenuItem m_extractFullPathMenuItem;
   private NSMenuItem m_assumeYesMenuItem;
   private NSMenuItem m_showCommentsMenuItem;
   private NSMenuItem m_listVerboselyMenuItem;
   private NSMenuItem m_usePasswordMenuItem;
   private NSMenuItem m_debugModeMenuItem;
   private NSMenuItem m_showMainWindowMenuItem;
   private NSMenuItem m_showResultWindowMenuItem;
   private NSMenuItem m_homepageMenuItem;
   private NSMenuItem m_showInfoInFinderMenuItem;
   private NSMenuItem m_revealInFinderMenuItem;
   private NSMenuItem m_rememberMyDefaultsMenuItem;
   private NSMenuItem m_forgetMyDefaultsMenuItem;
   // --- from PasswordDialog.nib
   private NSPanel m_passwordDialog;
   private NSSecureTextField m_passwordTextField;

   // Other variables
   private AceXpanderPreferences m_thePreferences = null;
   private NSUserDefaults m_userDefaults = null;
   private boolean m_bPasswordDialogCancelClicked = true;
   private boolean m_bMyDefaultsHaveChanged = false;

   // ======================================================================
   // Constructors
   // ======================================================================

   public AceXpanderController()
   {
      // This must be the very first action, so that other classes may
      // report any errors to this central error handling class
      registerForNotifications();

      // Next create the applications user defaults/preferences object.
      // It will provide sensible defaults in the NSRegistration domain.
      m_thePreferences = new AceXpanderPreferences();
      // Store instance in a member variable because it is frequently used
      m_userDefaults = NSUserDefaults.standardUserDefaults();

      // Register for services in the Services system menu
      // We are not interested in receiving data of any type
      NSArray returnTypes = null;
      // We can send data of the types
      // - String (for Finder-ShowInfo, Finder-Reveal),
      // - Filename
      // - URL
      NSMutableArray sendTypes = new NSMutableArray();
      sendTypes.addObject(NSPasteboard.StringPboardType);
      sendTypes.addObject(NSPasteboard.FilenamesPboardType);
      sendTypes.addObject(NSPasteboard.URLPboardType);
      // Do the registering
      NSApplication.sharedApplication().registerServicesMenuTypes(sendTypes, returnTypes);
   }

   // ======================================================================
   // NSNibAwaking protocol methods
   // ======================================================================

   // Is called after the class has been instantiated and initialized from
   // the .nib
   public void awakeFromNib()
   {
      // When the .nib is edited with InterfaceBuilder, the progress
      // indicator should be visible, otherwise it might be overlooked
      // by the person who is editing the .nib
      // -> we set this property here instead of in InterfaceBuilder
      m_progressIndicator.setDisplayedWhenStopped(false);

      // These windows automatically restore their frame from the user
      // defaults, and save it to the user defaults if any changes occur
      m_mainWindow.setFrameAutosaveName(AceXpanderPreferences.MainWindowFrameName);
      m_resultWindow.setFrameAutosaveName(AceXpanderPreferences.ResultWindowFrameName);

      // Show the result window if the user defaults say so
      if (m_userDefaults.booleanForKey(AceXpanderPreferences.ShowResultWindow))
      {
         m_resultWindow.makeKeyAndOrderFront(this);
         m_mainWindow.makeKeyAndOrderFront(this);
      }
   }

   // Is called by the notification center after the model announces that
   // it has finished processing its awakeFromNib() method.
   // Do stuff in this method that depends on the model having completely
   // executed its awakeFromNib() method.
   public void awakeFromNibAfterModel()
   {
      // Initialize menu items that can be checked/unchecked with the
      // default state of the corresponding model data
      setMenuItemState(m_overwriteFilesMenuItem, m_theModel.getOverwriteFiles());
      setMenuItemState(m_extractFullPathMenuItem, m_theModel.getExtractFullPath());
      setMenuItemState(m_assumeYesMenuItem, m_theModel.getAssumeYes());
      setMenuItemState(m_showCommentsMenuItem, m_theModel.getShowComments());
      setMenuItemState(m_listVerboselyMenuItem, m_theModel.getListVerbosely());
      setMenuItemState(m_usePasswordMenuItem, m_theModel.getUsePassword());
      setMenuItemState(m_debugModeMenuItem, m_theModel.getDebugMode());
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

   public void applicationDidFinishLaunching(NSNotification aNotification)
   {
      // If the user defaults say so, don't start automatically expanding
      // items on application launch
      if (! m_userDefaults.booleanForKey(AceXpanderPreferences.StartExpandingAfterLaunch))
      {
         m_theModel.setInteractive(true);
         return;
      }

      // If there are no items in the table the user must have launched the
      // application without double-clicking an archive (or a similar
      // action). In this case we switch to interactive mode (but do
      // nothing else)
      if (0 == m_theModel.numberOfRowsInTableView(null))
      {
         m_theModel.setInteractive(true);
         return;
      }

      m_theModel.selectItemsWithState(AceXpanderItem.QUEUED);
      expandItems(this);
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
         if (m_userDefaults.booleanForKey(AceXpanderPreferences.QuitAppWhenMainWindowIsClosed))
         {
            NSApplication.sharedApplication().terminate(this);
         }
      }
      else if (window == m_resultWindow)
      {
         m_userDefaults.setBooleanForKey(false, AceXpanderPreferences.ShowResultWindow);
      }
   }

   public void windowDidBecomeMain(NSNotification notification)
   {
      Object window = notification.object();
      if (window == m_resultWindow)
      {
         m_userDefaults.setBooleanForKey(true, AceXpanderPreferences.ShowResultWindow);
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
         // TODO: Enable these items if application is able to call
         // the corresponding services in the Services system menu.
         // -> probably possible only with ObjC function NSPerformService()
         else if (menuItem == m_showInfoInFinderMenuItem ||
                  menuItem == m_revealInFinderMenuItem)
         {
            return false;
         }
         else if (menuItem == m_rememberMyDefaultsMenuItem)
         {
            return m_bMyDefaultsHaveChanged;
         }
         else if (menuItem == m_forgetMyDefaultsMenuItem)
         {
            if (m_userDefaults.booleanForKey(AceXpanderPreferences.OptionDefaultsRemembered))
               return true;
            else
               return false;
         }
         else if (menuItem == m_requeueMenuItem || menuItem == m_unqueueMenuItem ||
                  menuItem == m_removeMenuItem || menuItem == m_expandMenuItem ||
                  menuItem == m_listContentMenuItem || menuItem == m_testIntegrityMenuItem)
         {
            if (1 <= m_theTable.numberOfSelectedRows())
               return true;
            else
               return false;
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
      updateResultWindow();
      updateContentListDrawer();
   }

   // ======================================================================
   // Methods that are actions and therefore connected in the .nib.
   // These methods are manipulating items and their state.
   // ======================================================================

   public void queueAllItems(Object sender)
   {
      m_theModel.setAllItemsToState(AceXpanderItem.QUEUED);
   }

   public void queueItems(Object sender)
   {
      m_theModel.setItemsToState(AceXpanderItem.QUEUED);
   }

   public void unqueueAllItems(Object sender)
   {
      m_theModel.setAllItemsToStateFromState(AceXpanderItem.SKIP, AceXpanderItem.QUEUED);
   }

   public void unqueueItems(Object sender)
   {
      m_theModel.setItemsToStateFromState(AceXpanderItem.SKIP, AceXpanderItem.QUEUED);
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
      else
      {
         // If the list thread was started successfully, and the list
         // content drawer is not visible -> show it
         switch(m_theContentListDrawer.state())
         {
            case NSDrawer.ClosedState:
            case NSDrawer.ClosingState:
               m_theContentListDrawer.open();
               break;
         }
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
      String version = new AceXpanderThread().getVersion();
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
      openPanel.setCanChooseDirectories(true);
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
      NSAlertPanel.runInformationalAlert("Sorry", "Not yet implemented", "OK", null, null);
   }

   public void revealInFinder(Object sender)
   {
      NSAlertPanel.runInformationalAlert("Sorry", "Not yet implemented", "OK", null, null);
   }

   // ======================================================================
   // Methods that are actions, items in "Help" menu
   // ======================================================================

   public void showGPL(Object sender)
   {
      showTextFileInWindow(GnuGPLFileName);
   }

   public void showManual(Object sender)
   {
      showTextFileInWindow(ManualFileName);
   }

   public void showReadme(Object sender)
   {
      showTextFileInWindow(ReadMeFileName);
   }

   public void showChangeLog(Object sender)
   {
      showTextFileInWindow(ChangeLogFileName);
   }

   public void showReleasePlan(Object sender)
   {
      showTextFileInWindow(ReleasePlanFileName);
   }

   public void showToDo(Object sender)
   {
      showTextFileInWindow(ToDoFileName);
   }

   public void gotoHomepage(Object sender)
   {
      try
      {
         NSWorkspace.sharedWorkspace().openURL(new java.net.URL(HomePageURL));
      }
      catch(java.net.MalformedURLException e)
      {
         // do nothing - we know :-) that our URL is correct
      }
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
      m_bMyDefaultsHaveChanged = true;
   }

   public void toggleExtractFullPath(Object sender)
   {
      boolean bNewState = ! m_theModel.getExtractFullPath();
      m_theModel.setExtractFullPath(bNewState);;
      setMenuItemState((NSMenuItem)sender, bNewState);
      m_bMyDefaultsHaveChanged = true;
   }

   public void toggleListVerbosely(Object sender)
   {
      boolean bNewState = ! m_theModel.getListVerbosely();
      m_theModel.setListVerbosely(bNewState);;
      setMenuItemState((NSMenuItem)sender, bNewState);
      m_bMyDefaultsHaveChanged = true;
   }

   public void toggleShowComments(Object sender)
   {
      boolean bNewState = ! m_theModel.getShowComments();
      m_theModel.setShowComments(bNewState);;
      setMenuItemState((NSMenuItem)sender, bNewState);
      m_bMyDefaultsHaveChanged = true;
   }

   public void toggleOverwriteFiles(Object sender)
   {
      boolean bNewState = ! m_theModel.getOverwriteFiles();
      m_theModel.setOverwriteFiles(bNewState);;
      setMenuItemState((NSMenuItem)sender, bNewState);
      m_bMyDefaultsHaveChanged = true;

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
   // Methods that are actions, saving/removing options in user defaults
   // ======================================================================

   public void rememberMyDefaults(Object sender)
   {
      m_userDefaults.setBooleanForKey(m_theModel.getOverwriteFiles(), AceXpanderPreferences.OverwriteFilesOption);
      m_userDefaults.setBooleanForKey(m_theModel.getExtractFullPath(), AceXpanderPreferences.ExtractWithFullPathOption);
      m_userDefaults.setBooleanForKey(m_theModel.getAssumeYes(), AceXpanderPreferences.AssumeYesOption);
      m_userDefaults.setBooleanForKey(m_theModel.getShowComments(), AceXpanderPreferences.ShowCommentsOption);
      m_userDefaults.setBooleanForKey(m_theModel.getListVerbosely(), AceXpanderPreferences.ListVerboselyOption);

      m_userDefaults.setBooleanForKey(true, AceXpanderPreferences.OptionDefaultsRemembered);

      m_bMyDefaultsHaveChanged = false;
   }

   public void forgetMyDefaults(Object sender)
   {
      m_userDefaults.removeObjectForKey(AceXpanderPreferences.OverwriteFilesOption);
      m_userDefaults.removeObjectForKey(AceXpanderPreferences.ExtractWithFullPathOption);
      m_userDefaults.removeObjectForKey(AceXpanderPreferences.AssumeYesOption);
      m_userDefaults.removeObjectForKey(AceXpanderPreferences.ShowCommentsOption);
      m_userDefaults.removeObjectForKey(AceXpanderPreferences.ListVerboselyOption);

      m_userDefaults.removeObjectForKey(AceXpanderPreferences.OptionDefaultsRemembered);

      m_theModel.updateMyDefaultsFromUserDefaults();
      setMenuItemState(m_overwriteFilesMenuItem, m_theModel.getOverwriteFiles());
      setMenuItemState(m_extractFullPathMenuItem, m_theModel.getExtractFullPath());
      setMenuItemState(m_assumeYesMenuItem, m_theModel.getAssumeYes());
      setMenuItemState(m_showCommentsMenuItem, m_theModel.getShowComments());
      setMenuItemState(m_listVerboselyMenuItem, m_theModel.getListVerbosely());

      m_bMyDefaultsHaveChanged = false;
   }

   // ======================================================================
   // Methods handling NSNotifications
   // ======================================================================

   // Is called by the NSNotificationCenter when the expansion thread
   // has finished. The thread posts the notification.
   // This method updates various GUI elements.
   // In addition, if it is called after the initial launch sequence's
   // expand thread has finished, this method will determine whether
   // the application should be terminated, or continue to run in
   // interactive mode.
   public void expandThreadHasFinished()
   {
      updateGUI(false);

      // Terminate application if all items expanded successfully and
      // the application mode is non-interactive. If this method is called
      // after the initial launch sequence's expand thread has finished,
      // the application mode should still be non-interactive.
      if (! m_theModel.getInteractive())
      {
         // If the user defaults say so, don't terminate the application
         // after expanding items on application launch
         if (! m_userDefaults.booleanForKey(AceXpanderPreferences.QuitAfterExpand))
            m_theModel.setInteractive(true);
         // If the user defaults say so, terminate the application even if
         // an error occurred
         else if (m_userDefaults.booleanForKey(AceXpanderPreferences.AlwaysQuitAfterExpand))
            NSApplication.sharedApplication().terminate(this);
         // No special user defaults: check if all items expanded
         // successfully. If not, continue to run in interactive mode
         else if (! m_theModel.haveAllItemsState(AceXpanderItem.SUCCESS))
            m_theModel.setInteractive(true);
         // All items expanded successfully, therefore terminate the
         // application
         else
            NSApplication.sharedApplication().terminate(this);
      }
   }

   // This method is called by the NSNotificationCenter when a severe error
   // condition is detected. Trivial errors should be handled by the
   // code that detects the error.
   // If a method detects a severe error condition it should take the
   // appropriate steps for a first-level reaction to the error (usually it
   // just terminates/aborts the operation it was supposed to perform in a
   // clean way). Then it it should compose a text (ideally one or more
   // whole sentences) describing the error condition and post it together
   // with an NSNotification to the NSNotificationCenter.
   // This method reacts to the notification by displaying a dialog to the
   // user, informing her about the problem and including the error
   // description. The dialog offers the user to terminate the application
   // (the default button), or to ignore the error.
   public void errorConditionOccurred(NSNotification notification)
   {
      String errorDescription = (String)notification.object();
      String errorMessage = "AceXpander encountered a critical error!";
      int iButtonClicked = NSAlertPanel.runCriticalAlert(errorMessage, errorDescription, "Terminate application", "Ignore error & continue", null);
      // Only do nothing if the "Ignore" button was clicked
      if (NSAlertPanel.AlternateReturn == iButtonClicked)
      {
         return;
      }
      // Otherwise terminate the application
      else
      {
         NSApplication.sharedApplication().terminate(this);
      }
   }

   // Updates the result window, depending on what is selected in the
   // main table. Is called by the default notification centre when an
   // AceXpanderItem sends a corresponding notification to indicate that
   // its stdout and stderr messages have changed. Is also called when the
   // main table's selection changes
   public void updateResultWindow()
   {
      if (1 != m_theTable.numberOfSelectedRows())
      {
         m_stdoutTextView.setString("");
         m_stderrTextView.setString("");
      }
      else
      {
         AceXpanderItem item = m_theModel.getItem(m_theTable.selectedRow());
         m_stdoutTextView.setString(item.getMessageStdout());
         m_stderrTextView.setString(item.getMessageStderr());
      }
   }

   // Updates the archive content drawer, depending on what is selected
   // in the main table. Is called by the default notification centre when
   // an AceXpanderItem sends a corresponding notification to indicate that
   // its content list has changed. Is also called when the main table's
   // selection changes
   public void updateContentListDrawer()
   {
      if (1 != m_theTable.numberOfSelectedRows())
      {
         m_theContentListTable.setDataSource(null);
      }
      else
      {
         AceXpanderItem item = m_theModel.getItem(m_theTable.selectedRow());
         m_theContentListTable.setDataSource(item);
      }

      m_theContentListTable.reloadData();
   }

   // ======================================================================
   // Other methods
   // ======================================================================

   // Internal helper method.
   // Disable/enable buttons and other GUI elements depending on whether
   // an expand process is currently running
   private void updateGUI(boolean bExpandIsRunning)
   {
      m_expandButton.setEnabled(! bExpandIsRunning);
      m_cancelButton.setEnabled(bExpandIsRunning);
      if (bExpandIsRunning)
      {
         m_progressIndicator.startAnimation(this);
      }
      else
      {
         m_progressIndicator.stopAnimation(this);
      }
   }

   // Internal helper method.
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

   // Internal helper method.
   // Shows the content of the given file in a separate window
   private void showTextFileInWindow(String textFileName)
   {
      NSBundle mainBundle = NSBundle.mainBundle();
      String textFilePath = mainBundle.pathForResource(textFileName, null);
      java.net.URL textFileURL = NSPathUtilities.URLWithPath(textFilePath);
      NSStringReference textFileContent = new NSStringReference(textFileURL, NSStringReference.UTF8StringEncoding);

      m_textView.setString(textFileContent.string());
      m_textViewWindow.setTitle(textFileName);
      m_textViewWindow.makeKeyAndOrderFront(this);
      // No need to call makeMainWindow()
   }

   // Register with the default notification center for getting various
   // notifications
   private void registerForNotifications()
   {
      // Register for notification posted by the expand thread after it
      // has finished
      NSNotificationCenter center = NSNotificationCenter.defaultCenter();
      center.addObserver(this,
                         new NSSelector("expandThreadHasFinished", new Class[] {}),
                         ExpandThreadHasFinishedNotification,
                         null);
      // Register for notification posted by anybody when an error condition
      // occurs
      center.addObserver(this,
                         new NSSelector("errorConditionOccurred", new Class[] {NSNotification.class}),
                         ErrorConditionOccurredNotification,
                         null);
      // Register for notification posted by AceXpanderItem instances
      // when their stdout and stderr messages have changed
      center.addObserver(this,
                         new NSSelector("updateResultWindow", new Class[] {}),
                         UpdateResultWindowNotification,
                         null);
      // Register for notification posted by AceXpanderItem instances
      // when their content list has changed
      center.addObserver(this,
                         new NSSelector("updateContentListDrawer", new Class[] {}),
                         UpdateContentListDrawerNotification,
                         null);
      // Register for notification posted by AceXpanderModel when it
      // has finished awakeFromNib()
      center.addObserver(this,
                         new NSSelector("awakeFromNibAfterModel", new Class[] {}),
                         ModelHasFinishedAwakeFromNibNotification,
                         null);
   }
}
