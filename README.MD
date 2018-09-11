
Associate Google Vault Data
===========================

![Last tested in Nuix 7.6](https://img.shields.io/badge/Nuix-7.4-green.svg)

View the GitHub project [here](https://github.com/Nuix/Associate-Google-Vault-Data) or download the latest release [here](https://github.com/Nuix/Associate-Google-Vault-Data/releases).

# Overview

**Written By:** Jason Wells

This project contains 2 scripts which can be used to associate additional metadata present in an XML file exported from [Google Vault](https://support.google.com/vault/answer/6099459?hl=en) to emails ingested into Nuix from MBOX files ingested and Google drive data ingested into Nuix.

# Getting Started

## Setup

Begin by downloading the latest release of this code.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

# Associate Google Email Data
## Workflow

1. User provides path to one or more XML files
1. User provides settings for tagging etc
1. Each XML file is parsed into a series of objects
1. For each MBOX item in case found using `mime-type:"application/mbox"`
	1. Binary for item is loaded through API.  **Note**: Nuix must be able to reach the binary, either as stored binary or from the source data.  The script must be able to parse the binary directly to build the cross reference.
	1. MBOX is split on `From_` lines (each email)
	1. Each split section is parsed for XML ID in `From_` line and `Message-ID` header.  This provides a cross reference between the Nuix metadata field `Message-ID` and the XML `ExternalFile` node's `FileName` attribute.
1. All emails in current case are located using `kind:email`
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