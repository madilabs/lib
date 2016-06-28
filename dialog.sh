#!/bin/bash
#
# Copyright (c) 2015 Vincent LAMAR, openlabs@lamar.fr
#
# This file is licensed under the terms of the GNU General Public
# License version 3. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

configure_tty_screen ()
{
	TTY_X=$(($(stty size | awk '{print $2}')-6)) # determine terminal width
	TTY_Y=$(($(stty size | awk '{print $1}')-6)) # determine terminal height
}

choose_release ()
{
	options=()
	options+=("wheezy" "Debian 7 Wheezy (oldstable)")
	options+=("jessie" "Debian 8 Jessie (stable)")
	options+=("trusty" "Ubuntu Trusty 14.04.x LTS")
	options+=("xenial" "Ubuntu Xenial 16.04.x LTS")
	RELEASE=$(dialog --stdout --title "Choose a release" --backtitle "$backtitle" --menu "Select one of supported releases" $TTY_Y $TTY_X $(($TTY_Y - 8)) "${options[@]}")
	unset options
	[[ -z $RELEASE ]] && exit_with_error "No release selected"
}

choose_board ()
{
	options=()
	for board in $SRC/lib/config/boards/*.conf; do
		options+=("$(basename $board | cut -d'.' -f1)" "$(head -1 $board | cut -d'#' -f2)")
	done
	BOARD=$(dialog --stdout --title "Choose a board" --backtitle "$backtitle" --scrollbar --menu "Select one of supported boards" $TTY_Y $TTY_X $(($TTY_Y - 8)) "${options[@]}")
	unset options
	[[ -z $BOARD ]] && exit_with_error "No board selected"
}

choose_branch ()
{
	options=()
	[[ $KERNEL_TARGET == *default* ]] && options+=("default" "3.4.x - 3.14.x legacy")
	[[ $KERNEL_TARGET == *next* ]] && options+=("next" "Latest stable @kernel.org")
	[[ $KERNEL_TARGET == *dev* ]] && options+=("dev" "Latest dev @kernel.org")
	# do not display selection dialog if only one kernel branch is available
	if [[ "${#options[@]}" == 2 ]]; then
		BRANCH="${options[0]}"
	else
		BRANCH=$(dialog --stdout --title "Choose a kernel" --backtitle "$backtitle" --menu "Select one of supported kernels" $TTY_Y $TTY_X $(($TTY_Y - 8)) "${options[@]}")
	fi
	unset options
	[[ -z $BRANCH ]] && exit_with_error "No kernel branch selected"
}

choose_desktop ()
{
	options=()
	options+=("no" "Image with console interface")
	options+=("yes" "Image with desktop environment")
	BUILD_DESKTOP=$(dialog --stdout --title "Choose image type" --backtitle "$backtitle" --no-tags --menu "Select image type" $TTY_Y $TTY_X $(($TTY_Y - 8)) "${options[@]}")
	unset options
	[[ -z $BUILD_DESKTOP ]] && exit_with_error "No option selected"
}

chosse_only_kernel ()
{
	options+=("yes" "Kernel, u-boot and other packages")
	options+=("no" "Full OS image for writing to SD card")
	KERNEL_ONLY=$(dialog --stdout --title "Choose an option" --backtitle "$backtitle" --no-tags --menu "Select what to build" $TTY_Y $TTY_X $(($TTY_Y - 8)) "${options[@]}")
	unset options
	[[ -z $KERNEL_ONLY ]] && exit_with_error "No option selected"
}

