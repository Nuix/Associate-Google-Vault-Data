# Menu Title: Associate Google Email Data (XML)
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

#Load Controller
load File.join(script_directory,"AssociateGoogleEmailDataController.rb_")

# If user has selected some MBOX files, lets update only the emails of those MBOX items.  We will only
# generate the XREF data for those select MBOX, and only then if we're in a version of Nuix pre 7.4
selected_mbox_items = []
if $current_selected_items.nil? == false && $current_selected_items.size > 0
	selected_mbox_items = $current_selected_items.select{|i| i.getType.getName == "application/mbox"}
end

# Build settings dialog
dialog = TabbedCustomDialog.new("Associate Google Email Data")
main_tab = dialog.addTab("main_tab","Main")
if selected_mbox_items.size > 0
	main_tab.appendHeader("Processing only emails of #{selected_mbox_items.size} selected MBOX items")
end
main_tab.appendCheckBox("apply_label_tags","Apply Tags for GMail Labels",true)
main_tab.appendTextField("tag_prefix","Gmail Label Tag Prefix","GMailLabels")
main_tab.enabledOnlyWhenChecked("tag_prefix","apply_label_tags")
default_log_dir = java.io.File.new($current_case.getLocation,"AssociateGoogleVaultData").getAbsolutePath
main_tab.appendDirectoryChooser("log_directory","Log Directory")
main_tab.setText("log_directory",default_log_dir)
main_tab.appendHeader("XML Files")
main_tab.appendPathList("xml_file_paths")
main_tab.getControl("xml_file_paths").setDirectoriesButtonVisible(false)
main_tab.appendCheckBox("data_is_pre_74","MBOX was processed pre Nuix 7.4",false)

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

	# Load dialog settings
	values = dialog.toMap

	# Nuix 7.4 captures "From" property, eliminating the need to parse the MBOX anymore, so
	# we check if this is Nuix 7.4 or above and skip all the MBOX xref stuff if we can
	nuix_7dot4_or_above = NuixConnection.getCurrentNuixVersion.isAtLeast("7.4")

	# Show progress dialog while we do some work
	ProgressDialog.forBlock do |pd|
		controller = AssociateGoogleEmailDataController.new
		controller.handleData(pd, values, selected_mbox_items, nil, nuix_7dot4_or_above)
		$window.openTab("workbench",{:search=>""})
	end
end