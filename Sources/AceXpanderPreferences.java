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
// AceXpanderPreferences.java
//
// This class is a mini-controller for the Preferences dialog. It is also
// responsible to set up defaults in the NSRegistration domain.
//

package ch.herzbube.acexpander;

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class AceXpanderPreferences
{
   // ======================================================================
   // Member variables
   // ======================================================================

   // Constants
   private final static String RegistrationDomainDefaultsFileName = "RegistrationDomainDefaults.plist";
   private final static String PreferencesDialogNibName = "PreferencesDialog";
   // Constant values for the defaults
   public final static String BundledExecutablePath = "<bundled>";
   public final static String DestinationFolderTypeSameAsArchive = "SameAsArchive";
   public final static String DestinationFolderTypeAskWhenExpanding = "AskWhenExpanding";
   public final static String DestinationFolderTypeFixedLocation = "FixedLocation";
   // Keys for the defaults
   public final static String MainWindowFrameName = "MainWindow";
   public final static String ResultWindowFrameName = "ResultWindow";
   public final static String QuitAppWhenMainWindowIsClosed = "QuitAppWhenMainWindowIsClosed";
   public final static String ShowResultWindow = "ShowResultWindow";
   public final static String ExecutablePath = "ExecutablePath";
   public final static String StartExpandingAfterLaunch = "StartExpandingAfterLaunch";
   public final static String QuitAfterExpand = "QuitAfterExpand";
   public final static String AlwaysQuitAfterExpand = "AlwaysQuitAfterExpand";
   public final static String DestinationFolderType = "DestinationFolderType";
   public final static String DestinationFolder = "DestinationFolder";
   public final static String CreateSurroundingFolder = "CreateSurroundingFolder";
   public final static String LookIntoFolders = "LookIntoFolders";
   public final static String TreatAllFilesAsArchives = "TreatAllFilesAsArchives";
   public final static String OptionDefaultsRemembered = "OptionDefaultsRemembered";
   public final static String OverwriteFilesOption = "OverwriteFilesOption";
   public final static String ExtractWithFullPathOption = "ExtractWithFullPathOption";
   public final static String AssumeYesOption = "AssumeYesOption";
   public final static String ShowCommentsOption = "ShowCommentsOption";
   public final static String ListVerboselyOption = "ListVerboselyOption";

   // The shared defaults object
   private NSUserDefaults m_userDefaults = null;

   // The preferences dialog
   private NSWindow m_preferencesDialog = null;

   // These variables are outlets and therefore initialized in the .nib
   private NSButton m_quitAppWhenMainWindowIsClosedButton;
   private NSPopUpButton m_setExecutablePathButton;
   private NSButton m_startExpandingAfterLaunchButton;
   private NSButton m_quitAfterExpandButton;
   private NSButton m_alwaysQuitAfterExpandButton;
   private NSPopUpButton m_destinationFolderButton;
   private NSButton m_createSurroundingFolderButton;
   private NSButton m_lookIntoFoldersButton;
   private NSButton m_treatAllFilesAsArchivesButton;

   // Other variables
   private boolean m_bPreferencesDialogCancelClicked = false;
   private String m_executablePath;   // Stores the entire path
   private String m_previousDestinationFolderType;
   private String m_destinationFolderType;
   private String m_destinationFolder;   // Stores the entire path

   // ======================================================================
   // Constructors
   // ======================================================================

   public AceXpanderPreferences()
   {
      // Store instance in a member variable because it is frequently used
      m_userDefaults = NSUserDefaults.standardUserDefaults();
      if (null == m_userDefaults)
      {
         String errorDescription = "Shared user defaults instance is null."; 
         NSNotificationCenter.defaultCenter().postNotification(AceXpanderController.ErrorConditionOccurredNotification, errorDescription);
      }
      loadDefaultsToRegistrationDomain();
   }

   // ======================================================================
   // Methods that manage opening/closing the preferences dialog
   // ======================================================================
   
   public void showPreferencesDialog()
   {
      NSApplication theApp = NSApplication.sharedApplication();
      // Load the .nib if not yet done. m_preferencesDialog is an outlet
      // and is set when the .nib is loaded.
      if (null == m_preferencesDialog)
      {
         theApp.loadNibNamed(PreferencesDialogNibName, this);
      }
      // Configure the GUI with values read from the defaults
      writeDefaultsToGUI();

      // Prepare and run the dialog. The sheet is attached to
      // m_mainWindow
      theApp.beginSheet(m_preferencesDialog, null, null, null, null);
      theApp.runModalForWindow(m_preferencesDialog);

      // -------------------------------------------------
      // --- At this point the modal dialog is running ---
      // -------------------------------------------------

      // Clean up and close the dialog
      theApp.endSheet(m_preferencesDialog);
      m_preferencesDialog.orderOut(this);   // remove dialog from screen
   }

   public void preferencesDialogOKClicked(Object sender)
   {
      readDefaultsFromGUI();
      m_bPreferencesDialogCancelClicked = false;
      NSApplication.sharedApplication().stopModal();
   }

   public void preferencesDialogCancelClicked(Object sender)
   {
      m_bPreferencesDialogCancelClicked = true;
      NSApplication.sharedApplication().stopModal();
   }

   // ======================================================================
   // Methods writing to/reading from the GUI
   // ======================================================================

   // Set up the various GUI elements to reflect the current defaults
   private void writeDefaultsToGUI()
   {
      // ------------------------------------------------------------
      // QuitAppWhenMainWindowIsClosed
      if (m_userDefaults.booleanForKey(QuitAppWhenMainWindowIsClosed))
         m_quitAppWhenMainWindowIsClosedButton.setState(NSCell.OnState);
      else
         m_quitAppWhenMainWindowIsClosedButton.setState(NSCell.OffState);

      // ------------------------------------------------------------
      // ExecutablePath
      m_executablePath = m_userDefaults.stringForKey(ExecutablePath);
      updateExecutablePathButton();

      // ------------------------------------------------------------
      // DestinationFolderType + DestinationFolder
      m_previousDestinationFolderType = DestinationFolderTypeSameAsArchive;
      m_destinationFolderType = m_userDefaults.stringForKey(DestinationFolderType);
      m_destinationFolder = m_userDefaults.stringForKey(DestinationFolder);
      updateDestinationFolderButton();

      // ------------------------------------------------------------
      // StartExpandingAfterLaunch + QuitAfterExpand + AlwaysQuitAfterExpand
      if (m_userDefaults.booleanForKey(StartExpandingAfterLaunch))
         m_startExpandingAfterLaunchButton.setState(NSCell.OnState);
      else
         m_startExpandingAfterLaunchButton.setState(NSCell.OffState);

      if (m_userDefaults.booleanForKey(QuitAfterExpand))
         m_quitAfterExpandButton.setState(NSCell.OnState);
      else
         m_quitAfterExpandButton.setState(NSCell.OffState);

      if (m_userDefaults.booleanForKey(AlwaysQuitAfterExpand))
         m_alwaysQuitAfterExpandButton.setState(NSCell.OnState);
      else
         m_alwaysQuitAfterExpandButton.setState(NSCell.OffState);

      NSButton[] buttons = {m_startExpandingAfterLaunchButton, m_quitAfterExpandButton, m_alwaysQuitAfterExpandButton};
      enableButtonHierarchy(buttons);
      
      // ------------------------------------------------------------
      // CreateSurroundingFolder
      if (m_userDefaults.booleanForKey(CreateSurroundingFolder))
         m_createSurroundingFolderButton.setState(NSCell.OnState);
      else
         m_createSurroundingFolderButton.setState(NSCell.OffState);
      
      // ------------------------------------------------------------
      // LookIntoFolders + TreatAllFilesAsArchives
      if (m_userDefaults.booleanForKey(LookIntoFolders))
         m_lookIntoFoldersButton.setState(NSCell.OnState);
      else
         m_lookIntoFoldersButton.setState(NSCell.OffState);

      if (m_userDefaults.booleanForKey(TreatAllFilesAsArchives))
         m_treatAllFilesAsArchivesButton.setState(NSCell.OnState);
      else
         m_treatAllFilesAsArchivesButton.setState(NSCell.OffState);

      buttons = new NSButton[] {m_lookIntoFoldersButton, m_treatAllFilesAsArchivesButton};
      enableButtonHierarchy(buttons);
   }

   // Analyzes the state of the various GUI elements and sets the
   // appropriate defaults in the application domain.
   // Note: Defaults are only set if their new value is different from the
   // value already stored in the user defaults. The effect of this is
   // that if the user never changes a default's value from the value stored
   // in the NSRegistration domain, the default is never written to the
   // application domain. As soon as the user changes the default's value
   // for the first time, it is written to the application domain. It
   // remains there, even if the user changes its value back to the value
   // stored in the NSRegistration domain.
   private void readDefaultsFromGUI()
   {
      // ------------------------------------------------------------
      // QuitAppWhenMainWindowIsClosed
      readDefaultsFromCheckbox(m_quitAppWhenMainWindowIsClosedButton, QuitAppWhenMainWindowIsClosed);

      // ------------------------------------------------------------
      // ExecutablePath
      // The full path is stored in m_executablePath, not the GUI)
      m_userDefaults.setObjectForKey(m_executablePath, ExecutablePath);

      // ------------------------------------------------------------
      // StartExpandingAfterLaunch
      readDefaultsFromCheckbox(m_startExpandingAfterLaunchButton, StartExpandingAfterLaunch);
         
      // ------------------------------------------------------------
      // DestinationFolderType + DestinationFolder
      // The full path is stored in m_destinationFolder, not the GUI)
      m_userDefaults.setObjectForKey(m_destinationFolderType, DestinationFolderType);
      m_userDefaults.setObjectForKey(m_destinationFolder, DestinationFolder);
      
      // ------------------------------------------------------------
      // QuitAfterExpand + AlwaysQuitAfterExpand
      readDefaultsFromCheckbox(m_quitAfterExpandButton, QuitAfterExpand);
      readDefaultsFromCheckbox(m_alwaysQuitAfterExpandButton, AlwaysQuitAfterExpand);

      // ------------------------------------------------------------
      // CreateSurroundingFolder
      readDefaultsFromCheckbox(m_createSurroundingFolderButton, CreateSurroundingFolder);
      
      // ------------------------------------------------------------
      // LookIntoFolders + TreatAllFilesAsArchives
      readDefaultsFromCheckbox(m_lookIntoFoldersButton, LookIntoFolders);
      readDefaultsFromCheckbox(m_treatAllFilesAsArchivesButton, TreatAllFilesAsArchives);
   }

   // Read the state of a single checkbox and write it back to the
   // user defaults if it differs from the current value in the
   // user defaults
   private void readDefaultsFromCheckbox(NSButton checkbox, String key)
   {
      boolean bChecked;
      int iState = checkbox.state();
      if (NSCell.OnState == iState)
         bChecked = true;
      else
         bChecked = false;
      
      if (bChecked != m_userDefaults.booleanForKey(key))
      {
         m_userDefaults.setBooleanForKey(bChecked, key);
      }
   }

   // ======================================================================
   // Methods that are actions, related to setting the executable
   // ======================================================================

   // Sets the executable path to a dummy default value which indicates
   // that the bundled version of unace will be used.
   public void setExecutableToBundled(Object sender)
   {
      m_executablePath = BundledExecutablePath;
      updateExecutablePathButton();
   }

   // Lets the user choose from an open panel which executable to use.
   public void setExecutableChooseLocation(Object sender)
   {
      NSOpenPanel openPanel = NSOpenPanel.openPanel();
      openPanel.setAllowsMultipleSelection(false);
      openPanel.setCanChooseDirectories(false);
      String directory = null;
      String selectedFile = null;
      NSArray fileTypes = null;
      int iResult = openPanel.runModalInDirectory(directory, selectedFile, fileTypes, m_preferencesDialog);
      if (NSPanel.OKButton == iResult)
      {
         // We trust the panel to return at least one item!
         m_executablePath = (String)openPanel.filenames().objectAtIndex(0);
      }

      // Update the button: the user's action selected a menu item -> this
      // must be undone even if the user clicked "cancel" on the open panel
      updateExecutablePathButton();
   }

   // No action, just a helper.
   // Updates the top-most menu item in the popup button, e.g. the menu
   // item that is visible when the button's popup menu is closed
   private void updateExecutablePathButton()
   {
      m_setExecutablePathButton.removeItemAtIndex(0);
      m_setExecutablePathButton.insertItemAtIndex(NSPathUtilities.lastPathComponent(m_executablePath), 0);
      m_setExecutablePathButton.selectItemAtIndex(0);
      // TODO: make it work! With this code, the image displayed when the
      // popup menu is closed is far too big!
      // NSMenuItem menuItem = m_setExecutablePathButton.itemAtIndex(0);
      // menuItem.setImage(new NSFileWrapper(m_executablePath, false).icon());
   }

   // ======================================================================
   // Methods that are actions, related to setting the destination folder
   // ======================================================================

   // Sets the destination folder to SameAsArchive
   public void setDestinationSameAsArchive(Object sender)
   {
      m_previousDestinationFolderType = m_destinationFolderType;
      m_destinationFolderType = DestinationFolderTypeSameAsArchive;
      m_destinationFolder = "";
      updateDestinationFolderButton();
   }

   // Sets the destination folder to AskWhenExpanding
   public void setDestinationAskWhenExpanding(Object sender)
   {
      m_previousDestinationFolderType = m_destinationFolderType;
      m_destinationFolderType = DestinationFolderTypeAskWhenExpanding;
      m_destinationFolder = "";
      updateDestinationFolderButton();
   }

   // Lets the user choose the destination folder from an open panel
   public void setDestinationChooseFolder(Object sender)
   {
      NSOpenPanel openPanel = NSOpenPanel.openPanel();
      openPanel.setAllowsMultipleSelection(false);
      openPanel.setCanChooseFiles(false);
      openPanel.setCanChooseDirectories(true);
      String directory = null;
      String selectedFile = null;
      NSArray fileTypes = null;
      int iResult = openPanel.runModalInDirectory(directory, selectedFile, fileTypes, m_preferencesDialog);
      if (NSPanel.OKButton == iResult)
      {
         m_previousDestinationFolderType = m_destinationFolderType;
         m_destinationFolderType = DestinationFolderTypeFixedLocation;
         m_destinationFolder = (String)openPanel.filenames().objectAtIndex(0);
      }

      // Update the button: the user's action selected a menu item -> this
      // must be undone even if the user clicked "cancel" on the open panel
      updateDestinationFolderButton();
   }

   // No action, just a helper.
   // Makes sure that the correct menu item is visible in the button's
   // popup menu. If necessary, additional items are created to display
   // the folder name & icon
   private void updateDestinationFolderButton()
   {
      // If the previous type was "fixed location" we need to remove
      // the two menu items that were created to display that location
      if (m_previousDestinationFolderType.equals(DestinationFolderTypeFixedLocation))
      {
         m_destinationFolderButton.removeItemAtIndex(0);
         m_destinationFolderButton.removeItemAtIndex(0);
      }
      
      if (m_destinationFolderType.equals(DestinationFolderTypeSameAsArchive))
      {
         m_destinationFolderButton.selectItemAtIndex(0);
      }
      else if (m_destinationFolderType.equals(DestinationFolderTypeAskWhenExpanding))
      {
         m_destinationFolderButton.selectItemAtIndex(1);
      }
      else if (m_destinationFolderType.equals(DestinationFolderTypeFixedLocation))
      {
         m_destinationFolderButton.insertItemAtIndex("", 0);
         m_destinationFolderButton.insertItemAtIndex(NSPathUtilities.lastPathComponent(m_destinationFolder), 0);
         m_destinationFolderButton.selectItemAtIndex(0);
         // TODO: make it work! With this code, the image displayed when the
         // popup menu is closed is far too big!
         // NSMenuItem menuItem = m_destinationFolderButton.itemAtIndex(0);
         // menuItem.setImage(new NSFileWrapper(m_destinationFolder, false).icon());
      }
   }

   // ======================================================================
   // Methods that are actions, related to QuitAfterExpand
   // ======================================================================

   // Enable/disable the m_quitAfterExpandButton and
   // m_alwaysQuitAfterExpandButton, depending on whether
   // the m_startExpandingAfterLaunchButton is checked or not.
   public void startExpandingAfterLaunchButtonClicked(Object sender)
   {
      NSButton[] buttons = {m_startExpandingAfterLaunchButton, m_quitAfterExpandButton, m_alwaysQuitAfterExpandButton};
      enableButtonHierarchy(buttons);
   }
   
   // Enable/disable the m_alwaysQuitAfterExpandButton, depending on whether
   // the m_quitAfterExpandButton is checked or not.
   public void quitAfterExpandButtonClicked(Object sender)
   {
      NSButton[] buttons = {m_startExpandingAfterLaunchButton, m_quitAfterExpandButton, m_alwaysQuitAfterExpandButton};
      enableButtonHierarchy(buttons);
   }

   // ======================================================================
   // Methods that are actions, related to LookIntoFolders
   // ======================================================================

   // Enable/disable the m_treatAllFilesAsArchivesButton,
   // depending on whether the m_lookIntoFoldersButton is checked or not.
   public void lookIntoFoldersButtonClicked(Object sender)
   {
      NSButton[] buttons = {m_lookIntoFoldersButton, m_treatAllFilesAsArchivesButton};
      enableButtonHierarchy(buttons);
   }

   // ======================================================================
   // Methods
   // ======================================================================

   // Read the defaults for the NSRegistration domain from a file
   // inside the application bundle
   private void loadDefaultsToRegistrationDomain()
   {
      try
      {
         NSBundle mainBundle = NSBundle.mainBundle();
         String defaultsPathName = mainBundle.pathForResource(RegistrationDomainDefaultsFileName, null);
         if (null == defaultsPathName)
         {
            throw new AceXpanderException("The defaults file " + RegistrationDomainDefaultsFileName + " could not be found in the resources of the application bundle.");
         }
         java.io.File defaultsFile = new java.io.File(defaultsPathName);
         if (! defaultsFile.exists())
         {
            throw new AceXpanderException("The defaults file " + defaultsPathName + " does not exist.");
         }
         else if (! defaultsFile.canRead())
         {
            throw new AceXpanderException("No read access to defaults file " + defaultsPathName + ".");
         }
         NSData defaultsXMLData = new NSData(defaultsFile);
         Object defaultsObject = NSPropertyListSerialization.
            propertyListFromData(defaultsXMLData,
                                 NSPropertyListSerialization.PropertyListImmutable,
                                 null, null);
         // Did we get a valid property list?
         if (null == defaultsObject)
         {
            throw new AceXpanderException("A property list could not be generated from defaults file " + defaultsPathName + ".");
         }

         // Make sure that we got an NSMutableDictionary. I have not found
         // this documented anywhere in Apple's topics/examples/documentation.
         // The example by Apple only shows the way until we get the Object
         // result from the call to propertyListFromData()
         String defaultsObjectType = defaultsObject.getClass().getName();
         if ("com.apple.cocoa.foundation.NSMutableDictionary" == defaultsObjectType)
         {
            m_userDefaults.registerDefaults((NSMutableDictionary)defaultsObject);
         }
         else
         {
            throw new AceXpanderException("The property list generated from defaults file " + defaultsPathName + " is of unexpected type " + defaultsObjectType + ".");
         }
      }
      catch(AceXpanderException exception)
      {
         // Notify the error handler that an error has occurred
         NSNotificationCenter.defaultCenter().postNotification(AceXpanderController.ErrorConditionOccurredNotification, exception.getMessage());
      }
   }

   // Internal helper method.
   // Enables the first button if the second button is checked.
   // Disables the first button if the second button is not checked.
   private void enableButtonDependingOnOtherButton(NSButton enableButton, NSButton dependButton)
   {
      boolean bChecked;
      int iState = dependButton.state();
      if (NSCell.OnState == iState)
         bChecked = true;
      else
         bChecked = false;

      enableButton.setEnabled(bChecked);
   }

   // Helper method
   // Beginning with the first button in the array, the "checked" state of
   // the buttons in the array is tested. If the state is "on", the next
   // button in the array is enabled and tested. If the state is "off", all
   // subsequent buttons in the array are disabled.
   // Note: the first button in the array is always enabled
   private void enableButtonHierarchy(NSButton[] buttons)
   {
      // The first button is always enabled
      boolean bEnable = true;

      int iNumElements = java.lang.reflect.Array.getLength(buttons);
      for (int iIndex = 0; iIndex < iNumElements; iIndex++)
      {
         NSButton button = (NSButton)java.lang.reflect.Array.get(buttons, iIndex);
         button.setEnabled(bEnable);
         // As soon as the first button is disabled, we don't check the
         // button state anymore
         if (! bEnable)
            continue;

         // The first unchecked button will disable all subsequent buttons
         int iState = button.state();
         if (NSCell.OffState == iState)
            bEnable = false;
      }
   }
}
