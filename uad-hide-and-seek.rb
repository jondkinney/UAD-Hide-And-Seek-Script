#!/usr/bin/env ruby
#rubocop:disable all
require 'fileutils'
require 'etc'
require 'json'
require 'find'
require 'pathname'

class String
  # remove non-whitespace chars and multi-spaces
  def squish
    tr("\r\n\t", ' ').gsub(/ {2,}/, ' ')
  end

  # pad string on the right before referencing directories for a cleaner look
  def fix(size, padstr = ' ')
    self[0...size].ljust(size, padstr) # or rjust
  end

  # allow for creating an array out of a multi-line string
  def to_multi_list
    strip.split(/\n+/).map { |a| a.strip }
  end
end

class Array
  def get_plugin_name
    # get the plugin name without the colon by splitting the string at the colon and taking the first half of the string
    map do |a|
      a.split(':').first
    end
  end
end

puts 'Which plugins do you want to alter? Type the number and press enter.'
puts '1. UAD Console'
puts '2. Pro Tools AAX'
puts '3. VST Plugins'
puts '4. VST Plugins (mono)'
puts '5. VST3 Plugins'
puts '6. Audio Units Plugins'
# puts '5. All'

ALTER_ALL = false

case gets # prompt user to act on folder structure for UAD Console or the DAW plugins
when /1/ # UAD Console
  PARENT_PATH = '/Library/Application Support/Universal Audio'
  PLUGIN_DIR = 'UAD-2 Powered Plug-Ins'
  PLUGIN_EXT = 'vst'
  PLUGIN_APPEND = ''
  UNUSED_PLUGIN_DIR = "#{PLUGIN_DIR} Unused"
  SKIP_PLUGINS = []
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
  PLUGIN_EXT = 'aaxplugin'
  PLUGIN_APPEND = ''
  UNUSED_PLUGIN_DIR = 'Unused'
  SKIP_PLUGINS = []
  REMAINING_FILE_LIST = %(
    Console Recall.aaxplugin
    UAD CS-1.aaxplugin
  ).to_multi_list
when /3/ # VST Plugins
  PARENT_PATH = '/Library/Audio'
  PLUGIN_DIR = 'Plug-Ins/VST/Universal Audio'
  PLUGIN_EXT = 'vst'
  PLUGIN_APPEND = ''
  UNUSED_PLUGIN_DIR = 'Plugins Unused/VST/Universal Audio'
  SKIP_PLUGINS = []
  REMAINING_FILE_LIST = %(
    UAD Console Recall.vst
    UAD CS-1.vst
  ).to_multi_list
when /4/ # VST Plugins (mono)
  PARENT_PATH = '/Library/Audio'
  PLUGIN_DIR = 'Plug-Ins/VST/Universal Audio/UAD Mono'
  PLUGIN_EXT = 'vst'
  PLUGIN_APPEND = '(m)'
  UNUSED_PLUGIN_DIR = 'Plugins Unused/VST/Universal Audio/UAD Mono'
  SKIP_PLUGINS = %(
    UAD Auto-Tune Realtime X(m).vst
    UAD bx_masterdesk Classic(m).vst
    UAD bx_masterdesk(m).vst
    UAD Putnam Mic Collection(m).vst
    UAD Putnam Mic Collection 180(m).vst
    UAD Ocean Way Mic Collection(m).vst
    UAD Ocean Way Mic Collection 180(m).vst
    UAD Sphere Mic Collection(m).vst
    UAD Sphere Mic Collection 180(m).vst
    UAD bx_digital V3(m).vst
    UAD Dangerous BAX EQ Master(m).vst
    UAD bx_digital V2(m).vst
  ).to_multi_list
  REMAINING_FILE_LIST = %(
    UAD CS-1(m).vst
  ).to_multi_list
when /5/ # VST3 Plugins
  PARENT_PATH = '/Library/Audio'
  PLUGIN_DIR = 'Plug-Ins/VST3/Universal Audio'
  PLUGIN_EXT = 'vst3'
  UNUSED_PLUGIN_DIR = 'Plugins Unused/VST3/Universal Audio'
  SKIP_PLUGINS = %(
    UAD Antares Auto-Tune Realtime.vst3
  ).to_multi_list
  REMAINING_FILE_LIST = %(
    UAD Console Recall.vst
    UAD CS-1.vst
  ).to_multi_list
when /6/ # Audio Units
  PARENT_PATH = '/Library/Audio'
  PLUGIN_DIR = 'Plug-Ins/Components'
  PLUGIN_EXT = 'component'
  UNUSED_PLUGIN_DIR = 'Plugins Unused/Components'
  SKIP_PLUGINS = []
  REMAINING_FILE_LIST = %(
    Console Recall.component
    UAD CS-1.component
  ).to_multi_list
when /7/
  ALTER_ALL = true #placeholder for future functionality
  puts 'Not yet implemented. Please run the script for each folder set you want to alter.'
  exit
end

PLUGIN_PATH = "#{PARENT_PATH}/#{PLUGIN_DIR}"
UNUSED_PLUGIN_PATH = "#{PARENT_PATH}/#{UNUSED_PLUGIN_DIR}"
FILES_NOT_FOUND = []

puts ''
puts "If you just re-installed the UAD software, please delete existing 'Unused' folders. Delete existing 'Unused' folder? (N/y)"
delete_unused = gets

puts '' unless delete_unused.chomp == '' # add linebreak if typing 'n'

if ['y'].include?(delete_unused.chomp.downcase) # hitting enter accepts default of 'N'
  puts ''
  # Remove up old 'Unused' plugin dirs
  FileUtils.rm_rf(UNUSED_PLUGIN_PATH, verbose: true)
  removed_existing_unused_folder = true
else
  removed_existing_unused_folder = false
end

# Create the path for unused plugins if it doesn't already exist
begin
  FileUtils.mkdir_p(UNUSED_PLUGIN_PATH, verbose: removed_existing_unused_folder)
  puts '' if removed_existing_unused_folder
rescue Errno::EACCES
  puts ''
  puts "Error creating 'Unused' directory: Access to the file system denied. Please run this script with 'sudo'"
  exit
end

user_dir = Etc.getlogin
uad_system_profile_file = "/Users/#{user_dir}/Desktop/UADSystemProfile.txt"

puts "!!!!! Reading UAD System Profile file from: #{uad_system_profile_file}..."

unless File.file?(uad_system_profile_file)
  puts ">>>>> 'UADSystemProfile.txt' file not found on desktop."

  msg = %(>>>>> Please click 'Save Detailed System Profile' from the UAD
  Control Panel app 'System Info' tab and save the file to your desktop, then
  re-run this script.).squish
  puts msg

  exit
end

puts ''
msg = %(If this is your first time using this script OR you upgraded to a new
version of the UAD Software and it contains new plugins, it's recommended to
re-export your UADSystemProfile.txt file, and run the 'Move All' test.).squish
puts msg
puts ''

msg = %(This test will ensure your regular plugin folder doesn't contain extra
plugins that this script doesn't know about.).squish
puts msg
puts ''

puts "More output will guide you once the test is finished. Run 'Move All' test now? (N/y/skip)"

user_input = gets # prompt user for 'Move All' test.

SKIP_MOVE = user_input.chomp.downcase == 'skip'

TESTING = if ['', 'n'].include?(user_input.chomp.downcase) # hitting enter accepts default of 'N'
            false
          else
            true
          end

puts '' unless user_input.chomp == '' # add linebreak if typing 'n'

if TESTING && !SKIP_MOVE
  puts ">>>>> 'Move All' test initiated."
else
  puts ">>>>> Skipping 'Move All' test."
end

# Open UADSystemProfile.txt file, read it into memory, and close the file
file_handle = open uad_system_profile_file
content = file_handle.read
file_handle.close

plugin_array_with_authorizations =
  content
  .split('UAD-2 Plug-in Authorizations').last.strip # Get the content of the UAD System Profile text dump AFTER the "UAD-2 Plug-in Authorizations" heading (this is the list of plugins) and strip the whitespace characters from the front and back of the multi-line string
  .split("\n") # split the string into an array on each newline

all_plugs =
  plugin_array_with_authorizations
  .get_plugin_name

authorized_plugs =
  plugin_array_with_authorizations
  .select { |a| a.match(/.*Authorized.*/) } # only select the plugins that are AUTHORIZED, which is indicated by having "Authorized" after a colon, like so - "UAD Teletronix LA-2A Legacy Leveler: Authorized for all devices"
  .get_plugin_name

# Helper function to find all files matching a given filename in a directory (including nested directories)
# Returns a list of file paths along with their relative paths from the root search directory
def find_files_and_relative_paths(directory, filename)
  matching_files = []
  Find.find(directory) do |path|
    if File.basename(path) == filename
      relative_path = Pathname.new(path).relative_path_from(Pathname.new(directory))
      matching_files << [path, relative_path.to_s]
    end
  end
  matching_files
end

def move_plugs(plugs:, move_to:)
  if move_to == 'unused'
    plugin_path_target = PLUGIN_PATH
    plugin_path_destination = UNUSED_PLUGIN_PATH
  else
    plugin_path_target = UNUSED_PLUGIN_PATH
    plugin_path_destination = PLUGIN_PATH
  end

  plugs.each do |plug|
    if SKIP_PLUGINS.include?(plug)
      puts "#{plug.fix(55, '.')} irrelevant plugin authorization for #{PLUGIN_EXT} #{PLUGIN_APPEND} file type#{"".fix(82,'.')}Skipping"
      next
    end

    # Use the helper function to find all instances of the plugin in the nested structure
    matching_files_and_paths_target = find_files_and_relative_paths(plugin_path_target, plug)
    matching_files_and_paths_destination = find_files_and_relative_paths(plugin_path_destination, plug)

    if matching_files_and_paths_target.empty?
      # Check if the plugin was already moved
      if matching_files_and_paths_destination.any?
        new_destination_path = File.dirname(matching_files_and_paths_destination.first.first)
        if move_to == 'unused' # Just formatting the output differently when moving to unused versus the default destination folders
          puts "#{plug.fix(55, '.')} exists in #{new_destination_path.fix(125,'.')}Skipping"
        else
          puts "#{plug.fix(55, '.')} Skipping exists in..... '#{new_destination_path}'"
        end
        next
      end
      # If no matching files found, report file not found
      FILES_NOT_FOUND << "#{plugin_path_target}/#{plug}"
      puts "#{plug.fix(55, '.')} File not found: #{plugin_path_target}/#{plug}"
      next
    end

    matching_files_and_paths_target.each do |file_path, relative_path|
      # Construct the new destination path, preserving the folder hierarchy
      new_destination_path = File.join(plugin_path_destination, File.dirname(relative_path))

      # Ensure the destination directory exists
      FileUtils.mkdir_p(new_destination_path) unless File.directory?(new_destination_path)

      destination_file_path = File.join(new_destination_path, File.basename(file_path))
      destination_file_path_display = destination_file_path.gsub(/\/\.\//,'/') # gsub removes the /./ part of "Plug-Ins/Universal Audio/./UAD Lexicon 224.aaxplugin" when a plugin is not inside of a nested folder

      begin
        # Do the move
        FileUtils.mv(file_path, destination_file_path)

        if TESTING || move_to == 'unused'
          puts "#{plug.fix(55, '.')} moved to '#{destination_file_path_display}'"
        else
          puts "#{plug.fix(55, '.')} is authorized. Moved to '#{destination_file_path_display}'" 
        end
      rescue Errno::EACCES
        puts "Error moving file #{plug}: Access to the file system denied. Please run this script with 'sudo'"
        exit
      rescue Errno::ENOENT
        # This block may not be necessary anymore due to earlier checks, but kept for safety
        FILES_NOT_FOUND << file_path
        puts "#{plug.fix(55, '.')} File not found: #{file_path}"
      end
    end
  end
end


def plug_case_statement(plug)
  # Load the plugin mappings
  file_content = File.read('plugin_mappings.json')
  plugin_mappings = JSON.parse(file_content)

  plugs = []

  if plugin_mappings.key?(plug)
    # Found a direct match in the JSON mappings
    name = plugin_mappings[plug]
    if name.is_a?(Array)
      # If the mapping is an array, iterate through each name
      name.each do |n|
        plugs << "#{n}#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
      end
    else
      # Single name string
      plugs << "#{name}#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
    end
  else
    # No direct match found, handle according to your logic
    plugs << "#{plug}#{PLUGIN_APPEND}.#{PLUGIN_EXT}"
  end

  plugs
end

puts "!!!!! Moving all KNOWN plugins to '#{UNUSED_PLUGIN_PATH}'"
puts ''

# Move all plugins to the 'Unused' folder
# unless already done!
unless SKIP_MOVE
  all_plugs.each do |plug|
    move_plugs(plugs: plug_case_statement(plug), move_to: 'unused')
  end
end

unless TESTING
  puts ''
  puts "!!!!! Moving AUTHORIZED plugins to '#{PLUGIN_PATH}'"
  puts ''
end

# Move explicitly authorized plugins back to the default plugin location. It's
# important to move all plugins out of the default folder, then move only the
# authorized plugins back in. This is because if you own a one-off plugin but
# not a separate bundle that the plugin is contained within, you would
# accidentally end up with plugins you actually own moving to the 'Unused'
# folder because they're contained within a bundle that you don't own.
authorized_plugs.each do |plug|
  move_plugs(plugs: plug_case_statement(plug), move_to: 'default') unless TESTING && !SKIP_MOVE
end

if !TESTING || SKIP_MOVE
  puts ''
  puts "#{authorized_plugs.count} plugins are authorized for use."
end

if TESTING && !SKIP_MOVE
  puts ''
  puts "Finished moving all KNOWN '#{PLUGIN_EXT.upcase} #{PLUGIN_APPEND}' plugins to '#{UNUSED_PLUGIN_PATH}'"

  puts ''
  puts "Your '#{PLUGIN_PATH}' folders should ONLY contain the following required UAD system plugins:"
  puts ''

  puts REMAINING_FILE_LIST

  puts ''
  msg = %(If it contains additional UAD plugins, please ensure you have the
  latest UADSystemProfile.txt exported to your desktop and re-run the 'Move
  All' test.).squish
  puts msg
  puts ''

  msg = %(If non-system plugins (newly released musical plugins, for example)
  still remain after exporting the latest UADSystemProfile.txt file, update
  this script's plugin_mappings.json file to be aware of the differences between 
  the plugin names listed in the UADSystemProfile.txt file and the the newly
  released plugins that exist in the default plugin folders. Then re-run this
  script's 'Move All' test until the list matches, leaving only required system
  plugins in the plugin folders.).squish
  puts msg
  puts ''

  msg = %(Once the 'Move All' test is successful in moving all non-system
  plugins without any "File not found" errors, re-run this script to move only
  your authorized plugins to the default folder. When prompted to run the 'Move
  All' test, type 'skip' without quotes and press enter to skip the 'Move All' 
  test.).squish
  puts msg
  puts ''

  msg = %(Alternatively, if you aren't able to update the json file, you can still
  run it and then manually manage the remaining newly released plugins by
  moving the plugin files between the regular and 'Unused' plugin folders
  referenced above.).squish
  puts msg
end

if FILES_NOT_FOUND.length > 0
  puts ''
  puts 'The following files were not found:'
  puts '-----------------------------------'
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
  add an additional entry to the plugin_mappings.json file. This translates the
  plugin name from your UADSystemProfile.txt file to what exists in your
  '#{PLUGIN_PATH}' folder.  These changes are usually as simple as removing
  words like 'EQ' or 'Channel Strip' or 'Amplifier' or 'Compressor' from the
  name. To account for a Collection like the UAD Moog Multimode Filter Collection, 
  add multiple values in an array following the existing entries as a guide.).squish
  puts ''
end
