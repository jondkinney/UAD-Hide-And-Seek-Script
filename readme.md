# UAD Hide and Seek Script

### Before running this script, save a detailed system profile to your Desktop

![image](https://user-images.githubusercontent.com/4521/69005051-c391d680-08e1-11ea-8cf7-d85fa5af8fac.png)

### Usage notes:

  * The plugins that this script alters are located in `/Library` so to move them around we need admin permissions.
  * That's why we have to use `sudo` and type your password.
  * This script only operates on plugins, and doesn't delete any files, it only created the necessary "unused" directories, and moves plugins into them.
  * The UADSystemProfile.txt file is required to be exported from


### Running the script

Note: the `$` below is only meant to indicate that the command is run on the command line. Don't type the `$` as part of the command.

Open `Terminal.app` and navigate to wherever you downloaded the script with the following command:
```
$ cd ~/Downloads/UAD-Hide-And-Seek-Script-master
```

Then run the script in `Terminal.app` by typing:
```
$ ruby uad-hide-and-seek.rb
```

This will prompt for which folder you want to operate on:

```
Which plugins do you want to alter? Type the number and press enter.
1. UAD Console
2. Pro Tools AAX
3. VST Plugins
4. VST Plugins (Mono)
5. Audio Units Plugins
```

Choose either 1 or 2 or 3 or 4 or 5 by typing that number at the command line and pressing enter.

#### Reading your authorizations from the UADSystemProfile.txt file
The script will try to read the UADSystemProfile.txt file from your desktop. If it is unable to do so, it'll prompt you to create that file.

#### The 'Move All' test
If the UADSystemProfile.txt file can be read successfully, then the script asks if you want to try to test moving all of your plugins to the 'Unused' folder. I highly recommend opening up the directories in finder, and then trying this test. The script will attempt to go through the entire UADSystemProfile.txt file parsing the name out of each plugin and moving ALL of them to the 'Unused' folder. If this succeeds, the script will output which 1-5 UAD plugins should remain in the main plugin folder. If you have extra plugins not in the list, then this script may need to be updated to account for newly released plugins.

#### Doing the actual move
Once the test is successful, you should manually move all the plugins back from the 'Unused' folder to the main folder via drag and drop, delete any of the 'Unused' folders that were created (they'll be recreated) and re-run the script. This time just hit enter or type 'n' when it prompts to run the test, and the script will only move the unauthorized plugins to the proper 'Unused' folder.

Re-run the script for each folder you want to alter.
