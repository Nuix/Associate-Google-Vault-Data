

Associate Google Vault Data
===========================

![This script was last tested in Nuix 7.6](https://img.shields.io/badge/Script%20Tested%20in%20Nuix-7.6-green.svg)

View the GitHub project [here](https://github.com/Nuix/Associate-Google-Vault-Data) or download the latest release [here](https://github.com/Nuix/Associate-Google-Vault-Data/releases).

# Overview

**Written By:** Jason Wells

This project contains 2 scripts which can be used to associate additional metadata present in an XML file exported from [Google Vault](https://support.google.com/vault/answer/6099459?hl=en) to emails ingested into Nuix from MBOX files ingested and Google drive data ingested into Nuix.

# Getting Started

## Setup

Begin by downloading the latest release of this code.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

## Cloning this Repository

These scripts rely on code from [Nx](https://github.com/Nuix/Nx) to present a settings dialog and progress dialog.  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of Nx.jar by either:
1. Building it from [the source](https://github.com/Nuix/Nx)
1. Downloading an already built JAR file from the [Nx releases](https://github.com/Nuix/Nx/releases)

Once you have a copy of Nx.jar, make sure to include it in the same directory as the scripts.

# Associate Google Email Data
## Workflow

There are several different workflows that may be executed depending on:
- Whether MBOX items were selected before running the script
- Whether you are running Nuix 7.4.0 or higher

If MBOX items are selected before running the script, only data related to the selected MBOX files will be processed.  If you are running the script in a version of Nuix before 7.4 this means only the selected MBOX files will be parsed for XREF and only the emails from those MBOX will be processed.  If you are running the script in Nuix 7.4 or later, MBOX parsing will be skipped regardless (see below), but only emails from the selected MBOX will be processed.

### Nuix 7.4.0 or Higher

In Nuix 7.4 Nuix captures the "From" line as a property of each email item extracted from the MBOX.  This means that for an MBOX which was processed by Nuix 7.4.0 or higher, the script no longer needs to parse the MBOX file, the XREF identifier needed is right on the item.  If the script detects it is being ran in Nuix 7.4.0 or higher, it will skip parsing the MBOX files altogether and instead get the needed XREF identifier right from the "MBOX From Line" property of the emails being processed.

**IMPORTANT:** While the script uses the current version of Nuix to determine whether to parse the MBOX files, the appropriate identifier *will only be present if the data was processed in Nuix 7.4.0 or later*.  For example, if you process MBOX files in Nuix 7.2, then migrate the case to 7.4 and run this script in Nuix 7.4 you will get no results because the script will use the new logic while the required identifiers will not be present because the data was processed in Nuix 7.2.

1. User provides path to one or more XML files
1. User provides settings for tagging etc
1. Each XML file is parsed into a series of objects
1. All emails in the current case are located using `kind:email`, if MBOX items were selected, only emails belonging to those MBOX are searched for using `path-guid(A OR B or etc) AND kind:email`
1. For each email item
	1. Cross reference data is used to associate a given email item to XML `Document` record.  Nuix property `MBOX From Line` is used to associate item to XML record.
	1. If no match can be found, record is skipped and this is recorded to output
	1. If a match is found
		1. Each `Tag` node in the associated `Document` node is applied as custom metadata.
		1. the XML `ExternalFile` node's `FileName` attribute used to associate this item is recorded as the custom metadata field `XmlExternalFileName`.
		1. Item is classified by associated `Tag` node with name `Labels` label values for tagging later if user specified to apply tags.
1. For each record which was a match, tags are applied based on associated XML `Labels` data, if user specified to apply tags.

### Versions Before Nuix 7.4.0

1. User provides path to one or more XML files
1. User provides settings for tagging etc
1. Each XML file is parsed into a series of objects
1. For each MBOX item in case found using `mime-type:"application/mbox"`, if MBOX items were selected when running the script only those MBOX files are used 
	1. Binary for item is loaded through API.  **Note**: Nuix must be able to reach the binary, either as stored binary or from the source data.  The script must be able to parse the binary directly to build the cross reference.
	1. MBOX is split on `From_` lines (each email)
	1. Each split section is parsed for XML ID in `From_` line and `Message-ID` header.  This provides a cross reference between the Nuix metadata field `Message-ID` and the XML `ExternalFile` node's `FileName` attribute.
1. All emails in current case are located using `kind:email`, if MBOX items were selected, only emails belonging to those MBOX are searched for using `path-guid(A OR B or etc) AND kind:email`
1. For each email item
	1. Cross reference data is used to associate a given email item to XML `Document` record.
	1. If no match can be found, record is skipped and this is recorded to output
	1. If a match is found
		1. Each `Tag` node in the associated `Document` node is applied as custom metadata.
		1. the XML `ExternalFile` node's `FileName` attribute used to associate this item is recorded as the custom metadata field `XmlExternalFileName`.
		1. Item is classified by associated `Tag` node with name `Labels` label values for tagging later if user specified to apply tags.
1. For each record which was a match, tags are applied based on associated XML `Labels` data, if user specified to apply tags.

## Settings Dialog

- **Apply Tags for GMail Labels**: When checked, tags will be applied to matching items based on Gmail label data located in associate XML record.
- **Gmail Label Tag Prefix**: Prefix to use for GMail label tag names.
- **XML Files**: Used to provide one or more XML file paths to load Gmail metadata from.
- **Log Directory**: Specify a directory where the script may create several time stamped files containing logging/reference data while processing.

# Associate Google Drive Data

## Workflow

1. User provides path to one or more XML files
1. User provides settings for tagging, etc.
1. Each XML file is parsed into a series of objects
1. For each `Document` node in the XML the associated `ExternalFile` node's `FileName` attribute is searched for against the `name` field.
	1. For each hit item found
		1. Each `Tag` node in the associated `Document` node is applied as custom metadata.
		1. Item is classified by associated `Tag` node with name `Labels` label values for tagging later if user specified to apply tags.
1. For each record which was a match, tags are applied based on associated XML `Labels` data, if user specified to apply tags.

## Settings Dialog

- **Apply Tags for GDrive Labels**: When checked, tags will be applied to matching items based on Google drive label data located in associate XML record.
- **Google Drive Label Tag Prefix**: Prefix to use for GDrive label tag names.
- **XML Files**: Used to provide one or more XML file paths to load Gmail metadata from.


## Headless Operation

The project contains 4 scripts that can be used to associate the metadata present in the XML files exported from Google Vault to emails and documents without requiring user interaction.

The scripts `AssociateGoogleDriveDataHeadless.rb_` and `AssociateGoogleEmailDataHeadless.rb_` search for the Google Vault XML files inside the Nuix case
and export them to `C:\Temp\Google_DATE`. Then the scripts run the association logic with the exported files.

The scripts `AssociateGoogleDriveDataRampiva.rb_` and `AssociateGoogleEmailDataRampiva.rb_` search for the Google Vault XML files inside the Nuix case
within the last batch of data loaded and export them to `C:\Temp\Google_DATE`. For the scripts to work, the variable `last_batch_load_guid` must be set with the GUID of the last batch. 
Then the scripts also run the association logic with the exported files, restricting the search of emails to the last batch of data loaded.


# License

```
Copyright 2018 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```