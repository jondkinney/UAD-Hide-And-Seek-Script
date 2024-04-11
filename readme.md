# UAD Hide and Seek Script

## Motivations

#### Apollo Central

I wrote this script initially to hide the UAD Console plugins from my file system so that when using the Softube Console 1 hardware and loading UAD plugins into the channel strips through [Apollo Central](https://www.softube.com/apollo#/) mode, I could select from just the list that I own. Even when you [hide unauthorized plugins](https://help.uaudio.com/hc/en-us/articles/210897963-Hiding-Plug-Ins-in-Console-2-0) in the UAD Console settings, the Softube Console 1 interface still shows them all since it seems to look at the plugin folder directly, not the hidden settings in the UAD Console.

![CleanShot 2024-04-11 at 01 08 23@2x](https://github.com/jondkinney/UAD-Hide-And-Seek-Script/assets/4521/eda1a105-f8f2-46ad-a5dc-6a590c1a8e86)
This screenshot is only showing my authorized plugins!

#### VST, AAX, AU

After creating that first version, I decided I'd extend it to allow for hiding the VST (stereo and mono), AAX, and AU plugins from Studio One and Pro Tools as well. The script probably works for other DAWs if they share the same VST or AU folder setup. But let me know if this isn't working for your DAW and I can try to help extend support.

Studio One has the ability to manage plugins and hide them similarly to the UAD setup, but this script can simplify things a bit (at least in my opinion) by hiding the plugins directly in the same way across all the platforms by manipulating the directories that the plugins exist within on the file system.

### Before running this script, save a detailed system profile to your desktop

- The `UADSystemProfile.txt` file is required to be exported to the desktop for this script to know for which plugins you have valid authorizations.

  ![image](https://user-images.githubusercontent.com/4521/69005051-c391d680-08e1-11ea-8cf7-d85fa5af8fac.png)

  **Note:** You should re-export this file each time you upgrade the UAD software as it'll have new plugins in the list that this script can operate on.

### Usage notes

- The UAD plugins that this script alters are located in `/Library` so to move them around we need admin permissions.
  - That's why we have to use `sudo` and type your password.
- This script only operates on UAD plugins and their folders. It creates the necessary 'Unused' folders, and moves plugins from their main folders into the newly created 'Unused' folders.
- The script will optionally delete any existing 'Unused' folders (that the script created) each time it runs.
  - This is to allow for the script to work well after a fresh install of the UAD software when all the plugins need to be moved to the 'Unused' folder again. Remember to re-export the `UADSystemProfile.txt` when you upgrade!
  - Without deleting the existing 'Unused' folders, the newly installed plugins from a UAD software upgrade will not move properly because the script checks to see if a plugin already exists in the destination 'Unused' folder before moving it there.

## Downloading the script

1. Download a zip of this repo to your Downloads folder. See below.
   ![image](https://user-images.githubusercontent.com/4521/69011535-06c76600-0931-11ea-8d8b-1df3e5faa342.png)

1. With the mouse, double click the "UAD-Hide-And-Seek-Script-master.zip" file in your Downloads folder to unzip it.

## Running the script

1. Open `Terminal.app` from the `/Applications/Utilities` folder.
1. At the terminal, change into the unzipped folder called `UAD-Hide-And-Seek-Script-master` by executing the following command:

       cd ~/Downloads/UAD-Hide-And-Seek-Script-master

1. Now type: `sudo ruby uad-hide` and press the `tab` key.
1. If the terminal fills in the rest of the file name so the screen is showing `sudo ruby uad-hide-and-seek.rb` at the command prompt, then you're golden.
1. Press the `enter` key and the script will run, prompting for which folder to operate on:

   Which plugins do you want to alter? Type the number and press enter.

   1. UAD Console
   2. Pro Tools AAX
   3. VST Plugins
   4. VST Plugins (Mono)
   5. VST3 Plugins
   6. Audio Units Plugins

   Choose either `1` or `2` or `3` or `4` or `5` or `6` by typing that number at the command line and pressing the `enter` key.

**Notes:**

- I'd recommend making the terminal window large so you can see the logging output and messages helping you along the way. Read all the output.
- Also, I highly recommend opening up [the folders that are being worked on](https://help.uaudio.com/hc/en-us/articles/210216306-Default-Install-Locations-for-UAD-Plug-Ins) in the finder so you can see the result of what the script did and verify that both folders exist and they have both the authorized and unauthorized plugins in them that you'd expect.
- Remember - nothing magic is going on here. We're just automating the movement of some plugins from their main folder to a folder where the DAW or UAD Console doesn't know how to load them.

### Reading your authorizations from the exported Detailed System Profile

The script will try to read the `UADSystemProfile.txt` file from your desktop. If it is unable to do so, it'll prompt you to create that file. See the first section of this Readme for tips on how to export that file to your desktop.

### The 'Move All' test

If the `UADSystemProfile.txt` file can be read successfully, then the script asks if you want to try to test moving all of your plugins to the relevant 'Unused' folders that the script creates. I highly recommend opening up the [plugin folders](https://help.uaudio.com/hc/en-us/articles/210216306-Default-Install-Locations-for-UAD-Plug-Ins) in finder, and then trying this test. The script will attempt to go through the entire `UADSystemProfile.txt` file parsing the name out of each plugin and moving ALL of them to the relevant 'Unused' folders.

If this succeeds, the script will show a list of between 1 to 5 UAD plugins that should still remain in the main plugin folders. Open up these folders and compare the list shown in the terminal with the plugins in the main folders to ensure all the non-system plugins were properly moved. Plugins like the `UAD Console Recall.vst` and `UAD CS-1.vst` aren't authorized or not (and aren't listed in the `UADSystemProfile.txt` file, so they aren't ever moved by this script), they are just part of the UAD system and are required to be in the main plugin folders for things to work properly.

**Note:** If you have extra non-system plugins in the main folder that look like actual musical UAD plugins (like the newly released "UAD Auto-Tune Realtime X", for example), then this script may need to be updated to account for newly released plugins. The prompts attempt to help you alter the script yourself to accomodate those new releases. Alternatively you can create an issue on this repo and I can take a look at updating the script.

### Doing the actual move

Once the 'Move All' test is successful and your main plugin directory is left with only UAD system plugins, re-run the script skipping the 'Move All' test (by typing 'skip' without quotes and pressing enter when prompted) to move your authorized plugins back to their main directories.

Re-run the script for each plugin type you want to alter!

Note: if you're confident that the script is going to work fully and move the plugins to the "Unused" folders, then back into their proper places (for example when repeating the script for more than one plugin extension type), you answer 'n' when prompted to run the 'Move All' test and the full process will complete for that plugin extension type without stopping in between moving the plugins to the "Unused" folder and back to their proper directories.

### Troubleshooting

If you think something got messed up, you can always re-install the UAD software entirely to restore the plugin folders then try to run this script again. If you're stuck, file an issue on this repo and I'll try to help.

### Plugin Collections

One thing that can be tricky to account for is when someone has a plugin authorization as a part of a plugin collection versus purchasing a plugin directly. I think I've accounted for all of the plugin collections, but if not, they're relatively easy to add in the new JSON plugin dictionary. Here's a small sampling of some of the [collections that UA offers](https://help.uaudio.com/hc/en-us/articles/206337276-Plug-In-Collection-Bundle-Pricing-Explained). If you see some plugins being skipped because they were already moved, it's likely becauase you purchased a plugin that is also in a bundle you purchased, or vice versa.
