## Summary

AceXpander is a Mac OS X graphical user interface to the `unace` command line utility. With AceXpander installed, you can simply double-click on any ACE archive in the Finder and the contents of the archive will be extracted to a sub-folder of the same folder where the original archive is located. To configure AceXpander, or to use additional program features, you have to directly launch the application (e.g. by double-clicking on the application icon in the Finder or the Dock).

**Note:** AceXpander is no longer maintained. It stopped working long ago when Mac OS X switched to the Intel platform, because the `unace` utility that ships with AceXpander is a PowerPC binary. An updated version of the utility is not available because the WinAce project appears to be defunct.

## Background information

ACE archives can only be created with the Windows application WinAce (see [the WinAce homepage](http://www.winace.com/)). The compression algorithms used by this program are not free, which is the reason why it was not possible for some time to decompress ACE archives on other platforms than Windows. The release of the command line utility `unace` has finally remedied the situation, at first for the Linux community only, but since autumn 2003 (when it was ported to Mac OS X) also for us Mac people. AceXpander closes the gap between the unbeloved (and actually often not-so-practical) Unix command line, and the graphical user interface of Mac OS X.

## Other unace front-ends

AceXpander is not the only application of its kind. The following list contains links to other Mac OS X graphical front-ends to `unace`:

- The [unaceX](http://unacex.sourceforge.net/) project over at SourceForge.
- [MacAce](http://www.gritsch-soft.com/) by Gabriel Gritsch
- iUnacer no longer seems to be available for download, although you can still find references to it on the Net (e.g. VersionTracker)

If there are other programs that can handle ACE archives, I am not aware of them. If you let me know about them I will add them to this list.

## License

AceXpander is released under the [GNU General Public License](http://www.gnu.org/copyleft/gpl.html) (GPLv2).

The source code of `unace` is not available to the public, however the program in its binary form may be freely used by everyone.

## Platforms

AceXpander runs on whatever version of Mac OS X I have currently installed when I make a release, although it will often run on older versions as well. See the README file in each release for details.

Starting with release 1.0.2, AceXpander is available as a universal binary. Although the same is not true for the `unace` utility bundled with AceXpander (it's still a PowerPC binary), you should nevertheless be able to run `unace` on MacIntel machines thanks to Apple's Rosetta technology.

## Installation instructions

The files from past releases are available for download under ["Releases" on the project page](https://github.com/herzbube/acexpander/releases).

Installation instructions:

1. Download the installation disk image (.dmg file) of the version of AceXpander you wish to install.
1. Double-clicking the .dmg file in the Finder should open the disk image. If this does not work you have to manually open the .dmg file with Apple&#39;s "Disk Copy" or "Installer" program.
1. In the Finder, drag the application icon from inside the open disk image to any location on one of your volumes.
1. The application is now being copied. Voilà, installation finished.

If you want to remove AceXpander from your system, simply delete the application and the associated user defaults file `~/Library/Preferences/ch.herzbube.acexpander.plist`. 

## Bugs and source code

If you want to report a bug, please use the project's [issue tracker on GitHub](https://github.com/herzbube/acexpander/issues).

The source code for the script is maintained in [this Git repository](https://github.com/herzbube/acexpander), also on GitHub.
