# Menu Title: Associate Google Drive Data
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
load File.join(script_directory,"AssociateGoogleDriveDataController.rb_")

# Build settings dialog
dialog = TabbedCustomDialog.new("Associate Google Drive Data")
main_tab = dialog.addTab("main_tab","Main")
main_tab.appendCheckBox("apply_label_tags","Apply Tags for GDrive Labels",true)
main_tab.appendTextField("tag_prefix","Google Drive Label Tag Prefix","GDriveLabels")
main_tab.enabledOnlyWhenChecked("tag_prefix","apply_label_tags")
main_tab.appendCheckBox("tags_to_descendants","Copy applied tags to descendants",false)
main_tab.appendCheckBox("cm_to_descendants","Copy applied custom metadata value to descendants",false)
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

	# Load dialog settings
	values = dialog.toMap

	# Show progress dialog while we do some work
	ProgressDialog.forBlock do |pd|
		
		controller = AssociateGoogleDriveDataController.new
		controller.handleData(pd, values)
		$window.openTab("workbench",{:search=>""})
	end
end