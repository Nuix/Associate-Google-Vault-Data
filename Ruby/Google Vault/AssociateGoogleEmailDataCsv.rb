# Menu Title: Associate Google Email Data (CSV)
# Needs Case: true
# Needs Selected Items: false

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

load File.join(script_directory,"GmailCsvParser.rb_")

# Build settings dialog
dialog = TabbedCustomDialog.new("Associate Google Email Data (CSV)")
main_tab = dialog.addTab("main_tab","Main")
main_tab.appendCheckBox("apply_label_tags","Apply Tags for GMail Labels",true)
main_tab.appendTextField("tag_prefix","Gmail Label Tag Prefix","GMailLabels")
main_tab.enabledOnlyWhenChecked("tag_prefix","apply_label_tags")
main_tab.appendHeader("CSV Files")
main_tab.appendPathList("csv_file_paths")
main_tab.getControl("csv_file_paths").setDirectoriesButtonVisible(false)

# Define some settings validations
dialog.validateBeforeClosing do |values|
	# Validate provided paths
	if values["csv_file_paths"].size < 1
		CommonDialogs.showWarning("Please select at least one CSV file.")
		next false
	else
		values["csv_file_paths"].each do |csv_file_path|
			invalid_paths = []
			if !java.io.File.new(csv_file_path).exists
				invalid_paths << csv_file_path
			end
			if invalid_paths.size > 0
				CommonDialogs.showWarning("#{invalid_paths.size} CSV file paths are invalid:\n#{invalid_paths.take(10).join("\n")}\n#{invalid_paths.size > 10 ? "..." : ""}")
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

	# Load dialog settings
	values = dialog.toMap

	# Show progress dialog while we do some work
	ProgressDialog.forBlock do |pd|
		all_guids = {}

		values["csv_file_paths"].each do |csv_file|
			parser = GmailCsvParser.new(csv_file)

			parser.label_tags = values["apply_label_tags"]
			parser.label_tag_prefix = values["tag_prefix"]

			parser.on_message_logged do |message|
				pd.logMessage(message)
			end

			csv_guids = parser.process_and_annotate($current_case)
			csv_guids.each{|guid|all_guids[guid]=true}
		end

		query = "guid:(#{all_guids.keys.join(" OR ")})"
		$window.openTab("workbench",{:search=>query})

		pd.setCompleted
	end
end