#!/bin/bash

#
# Created by Pico Mitchell (of Random Applications) on 1/5/23
#
# https://gist.github.com/PicoMitchell/877b645b113c9a5db95248ed1d496243#file-get_compatible_macos_versions-asls-sh
#
# MIT License
#
# Copyright (c) 2023 Pico Mitchell (Random Applications)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

readonly SCRIPT_VERSION='2023.4.16-1'

PATH='/usr/bin:/bin:/usr/sbin:/sbin'

current_macos_version="$(sw_vers -productVersion)"

echo "Running \"$(basename "${BASH_SOURCE[0]}")\" version ${SCRIPT_VERSION} on macOS ${current_macos_version} $(sw_vers -buildVersion)..."

mac_board_id=''
mac_device_id=''

mac_is_apple_silicon="$([[ "$(sysctl -in hw.optional.arm64)" == '1' ]] && echo 'true' || echo 'false')"

if [[ " $(sysctl -in machdep.cpu.features) " == *' VMM '* || "$(sysctl -in kern.hv_vmm_present)" == '1' ]]; then
	# "machdep.cpu.features" is always EMPTY on Apple Silicon (whether or not it's a VM) so it cannot be used to check for the "VMM" feature flag when the system is a VM,
	# but I examined the full "sysctl -a" output when running a VM on Apple Silicon and found that "kern.hv_vmm_present" is set to "1" when running a VM and "0" when not.
	# Through testing, I found the "kern.hv_vmm_present" key is also the present on Intel Macs starting with macOS 11 Big Sur and gets properly set to "1"
	# on Intel VMs, but still check for either since "kern.hv_vmm_present" is not available on every version of macOS that this script may be run on.

	mac_device_id="$($mac_is_apple_silicon && echo 'VMA2MACOSAP' || echo 'VMM-x86_64')" # These are the Device IDs listed in the "Apple Software Lookup Service" JSON for Apple Silicon and Intel VMs.
else
	if ! $mac_is_apple_silicon; then # Only Intel Macs have a Board ID. T2 Macs (which are Intel) will have both a Board ID and Device ID while Apple Silicon Macs only have a Device ID.
		mac_board_id="$(/usr/libexec/PlistBuddy -c 'Print 0:board-id' /dev/stdin <<< "$(ioreg -arc IOPlatformExpertDevice -k board-id -d 1)" 2> /dev/null | tr -d '[:cntrl:]')" # Remove control characters because this decoded value could end with a NUL char.

		if [[ "${mac_board_id}" != 'Mac-'* ]]; then
			>&2 echo 'ERROR: Failed to retrieve Board ID for Intel Mac.'
			exit 2
		fi
	fi

	if [[ -n "$(ioreg -rc AppleSEPManager)" ]]; then # The Device ID only exists for T2 and Apple Silicon Macs, both of which have a Secure Enclave (SEP).
		if $mac_is_apple_silicon; then # For Apple Silicon Macs, the Device ID is the first element of the "compatible" array in "ioreg -rc IOPlatformExpertDevice -d 1"
			# Annoyingly, the "compatible" array is easier to get elements out of from the plain text output rather than the plist output since the value is not actually a proper plist array.
			# NOTE: This "compatible" array will also exist on Intel Macs, but it will only contain the Model ID which was already retrieved above.
			mac_device_id="$(ioreg -rc IOPlatformExpertDevice -k compatible -d 1 | awk -F '"' '($2 == "compatible") { print $4; exit }')"
		else
			mac_device_id="$(/usr/libexec/remotectl get-property localbridge HWModel 2> /dev/null)" # For T2 Macs, this is the T2 chip Device ID.
		fi

		if [[ "${mac_device_id}" != *'AP' ]]; then
			>&2 echo 'ERROR: Failed to retrieve Device ID for T2 or Apple Silicon Mac.'
			exit 3
		fi
	fi
fi

asls_url='https://gdmf.apple.com/v2/pmv'
# About "Apple Software Lookup Service" (from https://support.apple.com/guide/deployment/use-mdm-to-deploy-software-updates-depafd2fad80/1/web/1.0#dep0b094c8d3 & https://developer.apple.com/business/documentation/MDM-Protocol-Reference.pdf):
# Use the service at https://gdmf.apple.com/v2/pmv to obtain a list of available updates.
# The JSON response contains two lists of available software releases. The "AssetSets" list contains all the releases available for MDMs to push to their supervised devices.
# The other list, "PublicAssetSets" contains the latest releases available to the general public (non-supervised devices) if they try to upgrade. The "PublicAssetSets" is a subset of the "AssetSets" list.
# Each element in the list contains the product version number of the OS, the posting date, the expiration date, and a list of supported devices for that release.

if ! asls_json="$(curl -m 5 -sfL "${asls_url}")" || [[ "${asls_json}" != *'"PublicAssetSets"'* ]]; then
	>&2 echo 'ERROR: Failed to download Apple Software Lookup Service JSON.'
	exit 4
fi

compatible_supported_macos_versions="$(osascript -l JavaScript -e '
"use strict"
function run(argv) {
	const macBoardID = argv[0], macDeviceID = argv[1], supportedVersion = []
	JSON.parse(argv[2]).PublicAssetSets.macOS.forEach(thisVersionDict => {
		const thisVersionSupportedDevices = thisVersionDict.SupportedDevices
		if ((macBoardID && thisVersionSupportedDevices.includes(macBoardID)) || (macDeviceID && thisVersionSupportedDevices.includes(macDeviceID)))
			supportedVersion.push(thisVersionDict.ProductVersion)
	})
	return supportedVersion.sort((thisVersion, thatVersion) => ObjC.wrap(thatVersion).compareOptions(thisVersion, $.NSNumericSearch)).join("\n")
}
' -- "${mac_board_id}" "${mac_device_id}" "${asls_json}" 2> /dev/null)"

echo -e "\nLatest Compatible macOS Version: $(echo "${compatible_supported_macos_versions}" | head -1)"

current_macos_major_version="${current_macos_version%%.*}"
echo -e "\nLatest Version of macOS ${current_macos_major_version} (Running Version): $(echo "${compatible_supported_macos_versions}" | grep -m 1 "^${current_macos_major_version}")"

echo -e "\nAll Compatible Supported macOS Versions:\n${compatible_supported_macos_versions}"
