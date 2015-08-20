Each batch is just the Documents folder from an app dump, renamed to a unique name.

// xcode 7
to take a dump:
  window -> devices -> choose device on left -> select the install app -> gear menu -> download -> save it to ~/tmp or whatever

to replace a dump:
  same, except upload the image instead

if you want to copy a level batch to a device, make sure to first download the image, then replace level files, then replace image.

make sure app isn't running on device (even in background)
make sure device is passcode unlocked just in case

documents folder is here:
com.goodguyapps.JumpProto <date>.xcappdata/AppData/Documents
