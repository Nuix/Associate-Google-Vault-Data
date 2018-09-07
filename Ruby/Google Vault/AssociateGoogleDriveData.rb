# Menu Title: Associate Google Drive Data
# Needs Case: true
# Needs Selected Items: false

# Define the date time format used to convert "Tag" nodes with a "TagDataType" of "DateTime"
# to an actual Joda DateTime object before storing as custom metadata
# http://joda-time.sourceforge.net/apidocs/org/joda/time/format/DateTimeFormat.html
date_time_format_pattern = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

script_directory = File.dirname(__FILE__)

# Load JAR with dialogs classes
require File.join(script_directory,"Nx.jar")
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

# Load class for parsing XML
load File.join(script_directory,"GoogleXmlObjects.rb_")
load File.join(script_directory,"Logger.rb_")

# We will need this to parse the DateTime values from the XML
java_import "org.joda.time.format.DateTimeFormat"

# Build settings dialog
dialog = TabbedCustomDialog.new("Associate Google Drive Data")
main_tab = dialog.addTab("main_tab","Main")
main_tab.appendCheckBox("apply_label_tags","Apply Tags for GDrive Labels",true)
main_tab.appendTextField("tag_prefix","Google Drive Label Tag Prefix","GDriveLabels")
main_tab.enabledOnlyWhenChecked("tag_prefix","apply_label_tags")
main_tab.appendHeader("XML Files")
main_tab.appendPathList("xml_file_paths")
main_tab.getControl("xml_file_paths").setDirectoriesButtonVisible(false)

# Define some settings validations
dialog.validateBeforeClosing do |values|
	# Validate provided paths
	if values["xml_file_paths"].size < 1
		CommonDialogs.showWarning("Please select at least one XML file.")
		next false
	else
		values["xml_file_paths"].each do |xml_file_path|
			invalid_paths = []
			if !java.io.File.new(xml_file_path).exists
				invalid_paths << xml_file_path
			end
			if invalid_paths.size > 0
				CommonDialogs.showWarning("#{invalid_paths.size} XML file paths are invalid:\n#{invalid_paths.take(10).join("\n")}\n#{invalid_paths.size > 10 ? "..." : ""}")
				next false
			end
		end
	end

	# Get user confirmation about closing all workbench tabs
	if CommonDialogs.getConfirmation("The script needs to close all workbench tabs, proceed?") == false
		next false
	end
	next true
end

# Display settings dialog
dialog.display

# User hit okay, validations passed, lets do this!
if dialog.getDialogResult == true
	# Applying custom metadata via script in GUI can cause errors so we close
	# all workbench tabs to prevent them
	$window.closeAllTabs

	# Build pattern for parsing DateTime values in "Tag" nodes
	date_time_format = DateTimeFormat.forPattern(date_time_format_pattern)

	# Load dialog settings
	values = dialog.toMap
	tag_prefix = values["tag_prefix"]
	xml_file_paths = values["xml_file_paths"]
	apply_label_tags = values["apply_label_tags"]

	# Track errors, warnings, successes and start time
	error_count = 0
	warning_count = 0
	match_count = 0
	start_time = Time.now

	# Show progress dialog while we do some work
	ProgressDialog.forBlock do |pd|
		pd.setTitle("Associate Google Drive Data")
		pd.setSubStatus("Errors: #{error_count}, Warnings: #{warning_count}, Matches: #{match_count}")

		# Parse 'Document' nodes from XML files user specified
		pd.setMainStatusAndLogIt("Parsing XML files...")
		data = GoogleXmlData.new
		xml_file_paths.each do |xml_file_path|
			pd.logMessage("Parsing: #{xml_file_path}")
			begin
				data.parse_xml_file(xml_file_path)
			rescue Exception => exc
				pd.logMessage("!!! Error while parsing XML file '#{xml_file_path}':")
				pd.logMessage(exc.message)
				error_count += 1
				pd.setSubStatus("Errors: #{error_count}, Warnings: #{warning_count}, Matches: #{match_count}")
			end
		end

		pd.logMessage("Total Document Nodes Parsed: #{data.total_documents}")
		pd.logMessage("Distinct 'TagName' Values:")
		data.distinct_tag_names.each do |name|
			pd.logMessage("\t#{name}")
		end

		# We are going to group matches items by the labels associated to those
		# items in the XML file.  We group them up so we can tag in batches
		grouped_by_label = Hash.new{|h,k|h[k]=[]}

		data.each_document do |document|
			external_file_name = document.external_file_name
			items = $current_case.searchUnsorted("name:\"#{external_file_name}\"")
			if items.size < 1
				pd.logMessage("Unable to locate item with name: #{external_file_name}")
				warning_count += 1
				pd.setSubStatus("Errors: #{error_count}, Warnings: #{warning_count}, Matches: #{match_count}")
			else
				document.annotate_items(items,date_time_format)
				match_count += 1
				pd.setSubStatus("Errors: #{error_count}, Warnings: #{warning_count}, Matches: #{match_count}")
				# Group item by labels associated in XML data
				labels = document.labels
				items.each do |item|
					labels.each do |label|
						grouped_by_label[label] << item
					end
				end
			end
		end
		
		# Apply labels as tags using groups so we perform fewer tagging operations
		if apply_label_tags
			pd.setMainStatusAndLogIt("Applying Labels as Tags...")
			annotater = $utilities.getBulkAnnotater
			grouped_by_label.each do |label,items|
				tag = "#{tag_prefix}|#{label}"
				pd.logMessage("\tApplying label '#{label}' as tag '#{tag}' to #{items.size} items...")
				annotater.addTag(tag,items)
			end
		end

		# We are done!
		pd.setMainStatusAndLogIt("Completed #{Time.at(Time.now - start_time).gmtime.strftime("%H:%M:%S")}")
		pd.setMainProgress(1,1)
		pd.setSubStatusAndLogIt("Errors: #{error_count}, Warnings: #{warning_count}, Matches: #{match_count}")

		$window.openTab("workbench",{:search=>""})
	end
end