#!/usr/bin/env ruby
require 'fileutils'
require 'etc'

class String
  # remove non-whitespace chars and multi-spaces
  def squish
    self.tr("\r\n\t", ' ').gsub(/ {2,}/, ' ')
  end

  # pad string on the right before referencing directories for a cleaner look
  def fix(size, padstr=' ')
    self[0...size].ljust(size, padstr) #or rjust
  end

  # allow for creating an array out of a multi-line string
  def to_multi_list
    self.strip.split(/\n+/).map{ |a| a.strip }
  end
end

puts "Which plugins do you want to alter? Type the number and press enter."
puts "1. UAD Console"
puts "2. Pro Tools AAX"
puts "3. VST Plugins"
puts "4. VST Plugins (Mono)"
puts "5. Audio Units Plugins"
puts "6. All"

case gets # prompt user to act on folder structure for UAD Console or the DAW plugins
when /1/ # UAD Console
  PARENT_PATH = '/Library/Application Support/Universal Audio'
  PLUGIN_DIR = 'UAD-2 Powered Plug-Ins'
  PLUGIN_APPEND = ''
  PLUGIN_EXT = 'vst'
  UNUSED_PLUGIN_DIR = "#{PLUGIN_DIR} Unused"
  REMAINING_FILE_LIST = %(
    UAD CS-1.vst
    UAD Input Strip Header.vst
    UAD Internal.vst
    UAD Mic Input Strip Header.vst
    UAD Talkback Input Strip Header.vst
  ).to_multi_list
when /2/ # Pro tools AAX
  PARENT_PATH = '/Library/Application Support/Avid/Audio'
  PLUGIN_DIR = 'Plug-Ins/Universal Audio'
  PLUGIN_APPEND = ''
  PLUGIN_EXT = 'aaxplugin'
  UNUSED_PLUGIN_DIR = "Unused"
  REMAINING_FILE_LIST = %(
    Console Recall.aaxplugin
    UAD CS-1.aaxplugin
  ).to_multi_list
when /3/ # VST Plugins
  PARENT_PATH = '/Library/Audio/Plug-Ins'
  PLUGIN_DIR = 'VST/Powered Plug-Ins'
  PLUGIN_APPEND = ''
  PLUGIN_EXT = 'vst'
  UNUSED_PLUGIN_DIR = "Unused/VST"
  REMAINING_FILE_LIST = %(
    Mono (this is a folder)
    UAD Console Recall.vst
    UAD CS-1.vst
  ).to_multi_list
when /4/ # VST Plugins (Mono)
  PARENT_PATH = '/Library/Audio/Plug-Ins'
  PLUGIN_DIR = 'VST/Powered Plug-Ins/Mono'
  PLUGIN_APPEND = '(m)'
  PLUGIN_EXT = 'vst'
  UNUSED_PLUGIN_DIR = "Unused/VST/Mono"
  REMAINING_FILE_LIST = %(
    UAD CS-1(m).vst
  ).to_multi_list
when /5/ # Audio Units
  PARENT_PATH = '/Library/Audio/Plug-Ins'
  PLUGIN_DIR = 'Components'
  PLUGIN_APPEND = ''
  PLUGIN_EXT = 'component'
  UNUSED_PLUGIN_DIR = "Unused/Components"
  REMAINING_FILE_LIST = %(
    Console Recall.component
    UAD CS-1.component
  ).to_multi_list
when /6/
  puts "Not yet implemented. Please run the script for each folder set you want to alter."
  exit
end


PLUGIN_PATH = "#{PARENT_PATH}/#{PLUGIN_DIR}"
UNUSED_PLUGIN_PATH = "#{PARENT_PATH}/#{UNUSED_PLUGIN_DIR}"
FILES_NOT_FOUND = []


puts ''
puts "If you just re-installed the UAD software, please delete existing 'Unused' folders. Delete existing 'Unused' folder? (Y/n)"
delete_unused = gets

if ['','y'].include?(delete_unused.chomp.downcase) # hitting enter accepts default of 'Y'
  # Remove up old 'Unused' plugin dirs
  FileUtils.rm_rf(UNUSED_PLUGIN_PATH, verbose: true)
end

# Create the path for unused plugins if it doesn't already exist
begin
  FileUtils.mkdir_p(UNUSED_PLUGIN_PATH, verbose: true)
rescue Errno::EACCES
  puts ''
  puts "Error creating 'Unused' directory: Access to the file system denied. Please run this script with 'sudo'"
  exit
end
puts ''

user_dir = Etc.getlogin
uad_system_profile_file = "/Users/#{user_dir}/Desktop/UADSystemProfile.txt"

puts "!!!!! Reading UAD System Profile file from: #{uad_system_profile_file}..."
puts ''

unless File.file?(uad_system_profile_file)
  puts ">>>>> 'UADSystemProfile.txt' file not found on desktop."

  msg = %(>>>>> Please click 'Save Detailed System Profile' from the UAD
  Control Panel app's "System Info" tab and save the file to your desktop,
  then re-run this script.).squish
  puts msg

  exit
end


# Open UADSystemProfile.txt file, read it into memory, and close the file
file_handle = open uad_system_profile_file
content = file_handle.read
file_handle.close


msg = %(If this is your first time using this script OR you upgraded to a new
version of the UAD Software and it contains new plugins, it's recommended to
re-export your UADSystemProfile.txt file, and run the 'Move All' test.).squish
puts msg
puts ''

msg = %(This test will ensure your regular plugin folder doesn't contain extra
plugins that this script doesn't know about.).squish
puts msg
puts ''

puts "More output will guide you once the test is finished. Run test now? (N/y)"

user_input = gets # prompt user for 'Move All' test.

if ['','n'].include?(user_input.chomp.downcase) # hitting enter accepts default of 'N'
  TESTING = false
else
  TESTING = true
end

puts '' unless user_input.chomp == '' # avoid unsightly extra line break if accepting the default by hitting enter without typing 'n'

if TESTING
  puts ">>>>> 'Move All' test initiated."
else
  puts ">>>>> Skipping 'Move All' test."
end

puts "!!!!! Beginning to move #{TESTING == true ? 'ALL KNOWN' : 'unauthorized'} plugins to '#{UNUSED_PLUGIN_PATH}'"
puts ''

unauthorized_plugs =
  content
    .split("UAD-2 Plug-in Authorizations").last.strip # Get the content of the UAD System Profile text dump AFTER the "UAD-2 Plug-in Authorizations" heading (this is the list of plugins) and strip the whitespace characters from the front and back of the multi-line string
    .split("\r\n") # split the string into an array on each newline
    .select{|a| a.match(/.*#{TESTING == true ? '' : 'Demo'}.*/)} # only select the plugins that are NOT authorized, which is indicated by having "Demo" after a colon, like so - "UAD Putnam Microphone Collection: Demo not started"
    .map{|a| a.split(":").first} # get the plugin name without the colon by splitting the string at the colon and taking the first half of the string
    .map{|a| "#{a}.#{PLUGIN_EXT}"} # add the .vst extension to the plugin name which is recgonized as a folder on macOS
    .sort # order the list alphabetically (helped with testing)


def move_file(plugs:, retry_move: false)
  plugs.each do |plug|
    # for the plugins that didn't need to have their name overridden, we
    # don't have a mechanism to tap into their name to add the (m) for mono.
    # So retry assuming they aren't in the list and inject the (m)
    plug = plug.gsub(/\./,'(m).') if retry_move

    # Check if the plugin was already moved. Some collections include plugs
    # that can also be purchased one-off, so we need to account for that
    if File.exist?("#{UNUSED_PLUGIN_PATH}/#{plug}")
      puts "#{plug}".fix(55,'.') + " exists in '#{UNUSED_PLUGIN_DIR}' folder. Skipping..."
      next # display the warning, but don't attempt to move it again.
    end

    begin
      # Do the move (which is really a rename of the file in unix)
      FileUtils.mv("#{PLUGIN_PATH}/#{plug}", "#{UNUSED_PLUGIN_PATH}")
      puts "#{plug}".fix(55,'.') + " #{TESTING == true ? 'moved' : 'is unauthorized. Moved'} to '#{UNUSED_PLUGIN_DIR}' folder."

      FILES_NOT_FOUND.delete(plug) if retry_move # if the retry worked, remove the plugin from the not found list
    rescue Errno::ENOENT
      if PLUGIN_APPEND == '(m)'
        move_file(plugs: [plug], retry_move: true) and return unless retry_move
      end

      # Add the not found file to our FILES_NOT_FOUND array to report on later
      FILES_NOT_FOUND << "#{PLUGIN_PATH}/#{plug}"
      puts "#{plug}".fix(55,'.') + " File not found: #{PLUGIN_PATH}/#{plug}"
    end
  end
end

unauthorized_plugs.each do |plug|
  plugs = []

  # Fix naming inconsistencies (I didn't think this list was going to be this big!)
  case plug
  when /UAD AKG BX 20 Spring Reverb.#{PLUGIN_EXT}/
    plugs << "UAD AKG BX 20#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD AMS RMX16 Digital Reverb.#{PLUGIN_EXT}/
    plugs << "UAD AMS RMX16#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD AMS RMX16 Expanded Digital Reverb.#{PLUGIN_EXT}/
    plugs << "UAD AMS RMX16 Expanded#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD API 2500 Bus Compressor.#{PLUGIN_EXT}/
    plugs << "UAD API 2500#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD API 500 EQ Collection.#{PLUGIN_EXT}/
    plugs << "UAD API 550A#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD API 560#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Ampeg B15N Bass Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Ampeg B15N#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Ampeg SVT-3 Pro Bass Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Ampeg SVT3Pro#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Ampeg SVT-VR Bass Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Ampeg SVTVR#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Bermuda Triangle Distortion.#{PLUGIN_EXT}/
    plugs << "UAD Bermuda Triangle#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Cambridge EQ.#{PLUGIN_EXT}/
    plugs << "UAD Cambridge#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Chandler GAV19T Guitar Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Chandler GAV19T#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Chandler Limited Curve Bender EQ.#{PLUGIN_EXT}/
    plugs << "UAD Chandler Limited Curve Bender#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Dangerous BAX EQ Collection.#{PLUGIN_EXT}/
    plugs << "UAD Dangerous BAX EQ Master#{PLUGIN_APPEND}.#{PLUGIN_EXT}" unless PLUGIN_APPEND == '(m)'
    plugs << "UAD Dangerous BAX EQ Mix#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Diezel Herbert Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Diezel Herbert#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD DreamVerb Room Modeler.#{PLUGIN_EXT}/
    plugs << "UAD DreamVerb#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD ENGL 646 VS Guitar Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD ENGL E646 VS#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD ENGL 765 RT Guitar Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD ENGL E765 RT#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD ENGL Savage 120 Guitar Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD ENGL Savage 120#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Eden WT800 Bass Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Eden WT800#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Empirical Labs EL8 Distressor Compressor.#{PLUGIN_EXT}/
    plugs << "UAD Empirical Labs Distressor#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Fender 55 Tweed Deluxe Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Fender 55 Tweed Deluxe#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Friedman Amplifiers Collection.#{PLUGIN_EXT}/
    plugs << "UAD Friedman BE100#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Friedman DS40#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Friedman Buxom Betty Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Friedman Buxom Betty#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Fuchs Overdrive Supreme 50 Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Fuchs Overdrive Supreme 50#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Fuchs Train II Guitar Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Fuchs Train II#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Gallien-Krueger 800RB Bass Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Gallien Krueger 800RB#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Harrison 32C EQ.#{PLUGIN_EXT}/
    plugs << "UAD Harrison 32C#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Harrison 32C SE#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Helios Type 69 Legacy EQ.#{PLUGIN_EXT}/
    plugs << "UAD Helios Type 69 Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Helios Type 69 Preamp and EQ Collection.#{PLUGIN_EXT}/
    plugs << "UAD Helios Type 69#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Ibanez Tube Screamer TS808 Overdrive.#{PLUGIN_EXT}/
    plugs << "UAD Ibanez Tube Screamer TS808#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Korg SDD-3000 Digital Delay.#{PLUGIN_EXT}/
    plugs << "UAD Korg SDD-3000#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Lexicon 480L Digital Reverb and Effects.#{PLUGIN_EXT}/
    plugs << "UAD Lexicon 480L#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Little Labs IBP Phase Alignment.#{PLUGIN_EXT}/
    plugs << "UAD Little Labs IBP#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Maag EQ4 EQ.#{PLUGIN_EXT}/
    plugs << "UAD Maag EQ4#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Manley VOXBOX Channel Strip.#{PLUGIN_EXT}/
    plugs << "UAD Manley VOXBOX#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Manley Variable Mu Limiter.#{PLUGIN_EXT}/
    plugs << "UAD Manley Variable Mu#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Marshall Bluesbreaker 1962 Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Marshall Bluesbreaker 1962#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Marshall JMP 2203 Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Marshall JMP 2203#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Marshall Plexi Super Lead 1959 Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Marshall Plexi Super Lead 1959#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Marshall Silver Jubilee 2555 Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Marshall Silver Jubilee 2555#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Massenburg DesignWorks MDWEQ5 EQ.#{PLUGIN_EXT}/
    plugs << "UAD MDWEQ5-3B#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD MDWEQ5-5B#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Millennia NSEQ-2 EQ.#{PLUGIN_EXT}/
    plugs << "UAD Millennia NSEQ-2#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Moog Multimode Filter Collection.#{PLUGIN_EXT}/
    plugs << "UAD Moog Multimode Filter SE#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Moog Multimode Filter XL#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Moog Multimode Filter#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Moog Multimode Legacy Filter.#{PLUGIN_EXT}/
    plugs << "UAD Moog Multimode Filter#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Neve 1073 Legacy EQ.#{PLUGIN_EXT}/
    plugs << "UAD Neve 1073 Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Neve 1073 Preamp and EQ Collection.#{PLUGIN_EXT}/
    plugs << "UAD Neve 1073#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Neve 1073SE Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Neve 1081 EQ.#{PLUGIN_EXT}/
    plugs << "UAD Neve 1081#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Neve 1081SE#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Neve 31102 EQ.#{PLUGIN_EXT}/
    plugs << "UAD Neve 31102#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Neve 31102SE#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Neve 88RS Channel Strip Collection.#{PLUGIN_EXT}/
    plugs << "UAD Neve 88RS#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Neve 88RS Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD OTO Biscuit 8-bit Filter Effects.#{PLUGIN_EXT}/
    plugs << "UAD OTO Biscuit 8-bit Effects#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Ocean Way Microphone Collection.#{PLUGIN_EXT}/
    plugs << "UAD Ocean Way Mic Collection#{PLUGIN_APPEND}.#{PLUGIN_EXT}" unless PLUGIN_APPEND == '(m)'
    plugs << "UAD Ocean Way Mic Collection 180#{PLUGIN_APPEND}.#{PLUGIN_EXT}" unless PLUGIN_APPEND == '(m)'
  when /UAD Oxford Envolution Envelope Shaper.#{PLUGIN_EXT}/
    plugs << "UAD Oxford Envolution#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Oxford Limiter V2.#{PLUGIN_EXT}/
    plugs << "UAD Oxford Limiter#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Oxide Tape Recorder.#{PLUGIN_EXT}/
    plugs << "UAD Oxide Tape#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Pure Plate Reverb.#{PLUGIN_EXT}/
    plugs << "UAD Pure Plate#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Putnam Microphone Collection.#{PLUGIN_EXT}/
    plugs << "UAD Putnam Mic Collection#{PLUGIN_APPEND}.#{PLUGIN_EXT}" unless PLUGIN_APPEND == '(m)'
    plugs << "UAD Putnam Mic Collection 180#{PLUGIN_APPEND}.#{PLUGIN_EXT}" unless PLUGIN_APPEND == '(m)'
  when /UAD SPL TwinTube Saturation.#{PLUGIN_EXT}/
    plugs << "UAD SPL TwinTube#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD SSL 4000 E Channel Strip Collection.#{PLUGIN_EXT}/
    plugs << "UAD SSL E Channel Strip#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD SSL 4000 E Legacy Channel Strip.#{PLUGIN_EXT}/
    plugs << "UAD SSL E Channel Strip Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD SSL 4000 G Bus Compressor Collection.#{PLUGIN_EXT}/
    plugs << "UAD SSL G Bus Compressor#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD SSL 4000 G Legacy Bus Compressor.#{PLUGIN_EXT}/
    plugs << "UAD SSL G Bus Compressor Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Suhr PT100 Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Suhr PT100#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Suhr SE100 Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Suhr SE100#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Summit Audio TLA-100A Compressor.#{PLUGIN_EXT}/
    plugs << "UAD Summit Audio TLA-100A#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Thermionic Culture Vulture Distortion.#{PLUGIN_EXT}/
    plugs << "UAD Thermionic Culture Vulture#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Tonelux Tilt EQ.#{PLUGIN_EXT}/
    plugs << "UAD Tonelux Tilt#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Tonelux Tilt Live#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Townsend Labs Sphere Mic Modeler.#{PLUGIN_EXT}/
    plugs << "UAD Townsend Labs Sphere#{PLUGIN_APPEND}.#{PLUGIN_EXT}" unless PLUGIN_APPEND == '(m)'
    plugs << "UAD Townsend Labs Sphere 180#{PLUGIN_APPEND}.#{PLUGIN_EXT}" unless PLUGIN_APPEND == '(m)'
  when /UAD Trident A-Range EQ.#{PLUGIN_EXT}/
    plugs << "UAD Trident A-Range#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Tube-Tech CL 1B Compressor.#{PLUGIN_EXT}/
    plugs << "UAD Tube-Tech CL 1B#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Tube-Tech EQ Collection.#{PLUGIN_EXT}/
    plugs << "UAD Tube-Tech ME 1B#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Tube-Tech PE 1C#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD UA 175B and 176 Tube Compressor Collection.#{PLUGIN_EXT}/
    plugs << "UAD UA 175-B#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD UA 176#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD UA 610-A Tube Preamp and EQ.#{PLUGIN_EXT}/
    plugs << "UAD UA 610-A#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Valley People Dyna-mite Dynamics.#{PLUGIN_EXT}/
    plugs << "UAD Valley People Dyna-mite#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Vertigo VSC-2 Compressor.#{PLUGIN_EXT}/
    plugs << "UAD Vertigo VSC-2#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Vertigo VSM-3 Saturator.#{PLUGIN_EXT}/
    plugs << "UAD Vertigo VSM-3#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD bx_digital V2 EQ.#{PLUGIN_EXT}/
    plugs << "UAD bx_digital V2#{PLUGIN_APPEND}.#{PLUGIN_EXT}" unless PLUGIN_APPEND == '(m)'
    plugs << "UAD bx_digital V2 Mono#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD bx_digital V3 EQ Collection.#{PLUGIN_EXT}/
    plugs << "UAD bx_digital V3#{PLUGIN_APPEND}.#{PLUGIN_EXT}" unless PLUGIN_APPEND == '(m)'
    plugs << "UAD bx_digital V3 mix#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD bx_subsynth Subharmonic Synth.#{PLUGIN_EXT}/
    plugs << "UAD bx_subsynth#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD elysia alpha compressor.#{PLUGIN_EXT}/
    plugs << "UAD elysia alpha master#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD elysia alpha mix#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Ampeg SVT-VR Classic Bass Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Ampeg SVTVR Classic#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Ampex ATR-102 Tape Recorder.#{PLUGIN_EXT}/
    plugs << "UAD Ampex ATR-102#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Cooper Time Cube Delay.#{PLUGIN_EXT}/
    plugs << "UAD Cooper Time Cube#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD EMT 140 Plate Reverb.#{PLUGIN_EXT}/
    plugs << "UAD EMT 140#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD EMT 250 Digital Reverb.#{PLUGIN_EXT}/
    plugs << "UAD EMT 250#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Empirical Labs EL7 FATSO Compressor.#{PLUGIN_EXT}/
    plugs << "UAD Empirical Labs FATSO Jr#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Empirical Labs FATSO Sr#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Fairchild 670 Legacy Limiter.#{PLUGIN_EXT}/
    plugs << "UAD Fairchild 670 Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Fairchild Tube Limiter Collection.#{PLUGIN_EXT}/
    plugs << "UAD Fairchild 660#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Fairchild 670#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Lexicon 224 Digital Reverb.#{PLUGIN_EXT}/
    plugs << "UAD Lexicon 224#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Little Labs VOG Bass Enhancer.#{PLUGIN_EXT}/
    plugs << "UAD Little Labs VOG#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Manley Massive Passive EQ Collection.#{PLUGIN_EXT}/
    plugs << "UAD Manley Massive Passive#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Manley Massive Passive MST#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Marshall Plexi Classic Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Marshall Plexi Classic#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Neve 33609 Compressor.#{PLUGIN_EXT}/
    plugs << "UAD Neve 33609#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Neve 33609SE#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Neve 88RS Legacy Channel Strip.#{PLUGIN_EXT}/
    plugs << "UAD Neve 88RS Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Ocean Way Studios Room Modeler.#{PLUGIN_EXT}/
    plugs << "UAD Ocean Way Studios#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Precision K-Stereo Ambience Recovery.#{PLUGIN_EXT}/
    plugs << "UAD Precision K-Stereo#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Precision Mix Rack Collection.#{PLUGIN_EXT}/
    plugs << "UAD Precision Channel Strip#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Precision Reflection Engine#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Precision Delay Mod#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Precision Delay Mod L#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Precision Multiband Compressor.#{PLUGIN_EXT}/
    plugs << "UAD Precision Multiband#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Pultec EQP-1A Legacy EQ.#{PLUGIN_EXT}/
    plugs << "UAD Pultec EQP-1A Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Pultec Passive EQ Collection.#{PLUGIN_EXT}/
    plugs << "UAD Pultec EQP-1A#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Pultec HLF-3C#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Pultec MEQ-5#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Pultec-Pro Legacy EQ.#{PLUGIN_EXT}/
    plugs << "UAD Pultec-Pro Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Raw Distortion.#{PLUGIN_EXT}/
    plugs << "UAD Raw#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD RealVerb-Pro Room Modeler.#{PLUGIN_EXT}/
    plugs << "UAD RealVerb-Pro#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Roland CE-1 Chorus.#{PLUGIN_EXT}/
    plugs << "UAD Roland CE-1#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Roland Dimension D Chorus.#{PLUGIN_EXT}/
    plugs << "UAD Roland Dimension D#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Roland RE-201 Tape Delay.#{PLUGIN_EXT}/
    plugs << "UAD Roland RE-201#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Studer A800 Tape Recorder.#{PLUGIN_EXT}/
    plugs << "UAD Studer A800#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Teletronix LA-2A Legacy Leveler.#{PLUGIN_EXT}/
    plugs << "UAD Teletronix LA-2A Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Teletronix LA-2A Leveler Collection.#{PLUGIN_EXT}/
    plugs << "UAD Teletronix LA-2#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Teletronix LA-2A Gray#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD Teletronix LA-2A Silver#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Teletronix LA-3A Leveler.#{PLUGIN_EXT}/
    plugs << "UAD LA3A#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD UA 1176 Limiter Collection.#{PLUGIN_EXT}/
    plugs << "UAD UA 1176 Rev A#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD UA 1176LN Rev E#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    plugs << "UAD UA 1176AE#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD UA 1176LN Legacy Limiter.#{PLUGIN_EXT}/
    plugs << "UAD UA 1176LN Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD UA 1176SE Legacy Limiter.#{PLUGIN_EXT}/
    plugs << "UAD UA 1176SE Legacy#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD UA 610-B Tube Preamp and EQ.#{PLUGIN_EXT}/
    plugs << "UAD UA 610-B#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD dbx 160 Compressor.#{PLUGIN_EXT}/
    plugs << "UAD dbx 160#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD UAD Avalon VT-737sp Channel Strip.#{PLUGIN_EXT}/
    plugs << "UAD Avalon VT-737sp#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD Diezel VH4 Amplifier.#{PLUGIN_EXT}/
    plugs << "UAD Diezel VH4#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  when /UAD bx_masterdesk Classic.#{PLUGIN_EXT}/
    plugs << "UAD bx_masterdesk Classic#{PLUGIN_APPEND}.#{PLUGIN_EXT}/" unless PLUGIN_APPEND == '(m)'
  when /UAD bx_masterdesk.#{PLUGIN_EXT}/
    plugs << "UAD bx_masterdesk#{PLUGIN_APPEND}.#{PLUGIN_EXT}/" unless PLUGIN_APPEND == '(m)'
  # New Plugs
  # ---------
  # when /UAD Plugin Name From UADSystemProfile.txt file.#{PLUGIN_EXT}/
  #   plugs << "UAD Name Here As It Appears In The Plugin Folder#{PLUGIN_APPEND}.#{PLUGIN_EXT}"

    # Add more when statements above ☝️  as new plugins are released.
  else
    # Keep the name the same, they didn't change it between the name in the
    # UADSystemProfile.txt file and the plugin in the plugins folder.
    plugs << plug
  end

  # do the actual work to move the file(s)
  move_file(plugs: plugs)
end

if TESTING == true
  puts ''
  puts "Finished moving ALL KNOWN plugins to '#{UNUSED_PLUGIN_PATH}'"

  puts ''
  puts "Your '#{PLUGIN_PATH}' folder should only contain the following required stock UAD plugins:"
  puts ''

  puts REMAINING_FILE_LIST

  puts ''
  msg = %(If it contains additional plugins, please update this script to be
  aware of the newly released plugins and then re-run it until the list
  matches.).squish
  puts msg
  puts ''

  msg = %(Once the 'Move All' test is successful in moving all non-stock
  plugins without any "File not found" errors, manually open the 'Unused'
  plugins folder, drag all plugins back to the regular plugin folder, and
  re-run this script to move only your unauthorized plugins to the 'Unused'
  folder by choosing 'N' when prompted to run the 'Move All' test.).squish
  puts msg
  puts ''

  msg = %(Alternatively, if you aren't able to update the script, you can still
  run it and then manually manage the remaining newly released plugins by
  moving the plugin files between the regular and 'Unused' plugin folders
  referenced in this script.).squish
  puts msg
end

if FILES_NOT_FOUND.length > 0
  puts ''
  puts "The following files were not found:"
  puts "-----------------------------------"
  puts FILES_NOT_FOUND.join("\n")
  puts ''
  msg = %(First check that the files listed here actually exist in the main
  plugin folder they're trying to be moved out of. If they don't exist,
  re-install the UAD software to restore them, then re-run this script to move
  them to the 'Unused' folder. If they do, but have slightly differnet names,
  see the next line about fixing a naming conflict.).squish
  puts msg
  puts ''

  msg = %(To fix "File not found" errors when the issue is a naming conflict,
  add an additional 'when' entry to the case statement. This translates the
  plugin name from your UADSystemProfile.txt file to what exists in your
  '#{PLUGIN_PATH}' folder.  These changes are usually as simple as removing
  words like 'EQ' or 'Channel Strip' or 'Amplifier' or 'Compressor' from the
  end of the name.).squish
  puts msg
  puts ''

  msg = %(This is quite easy and there are many examples in the script. When
  the Avalon VT-737sp was released, I had to add translations for it to the end of
  the case statement after the UAD dbx 160 lines that looked like this:).squish
  puts msg
  puts ''

  puts %(when /UAD dbx 160 Compressor.\#{PLUGIN_EXT}/
  plugs << "UAD dbx 160\#{PLUGIN_APPEND}.\#{PLUGIN_EXT}")
  puts ''

  puts 'I added these Avalon lines below the dbx lines shown above.'
  puts ''

  msg = %(when /UAD UAD Avalon VT-737sp Channel Strip.\#{PLUGIN_EXT}/
  plugs << "UAD Avalon VT-737sp\#{PLUGIN_APPEND}.\#{PLUGIN_EXT}")
  puts msg
end
