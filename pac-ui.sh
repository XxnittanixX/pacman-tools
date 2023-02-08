#!/usr/bin/bash
SHELL=/usr/bin/bash                                                                 # set the shell for pacui and its child processes (such as "fzf --preview "). needed for compatibility with e.g. fish shell.

# SC1117: Backslash is literal in "\e". Prefer explicit escaping: "\\e".
# SC1117: Backslash is literal in "\n". Prefer explicit escaping: "\\n".
# SC1117: Backslash is literal in "\t". Prefer explicit escaping: "\\t".
# SC2001: See if you can use ${variable//search/replace} instead.
# SC2016: Expressions don't expand in single quotes, use double quotes for that.
# SC2086: Double quote to prevent globing and word splitting.                       # ${variable}  does not work when double quoted. also, double quote breaks this script in many cases --> there are warning comments containing "ATTENTION" about this.
# SC2116: Useless echo?
# shellcheck disable=SC1117,SC2001,SC2016,SC2086,SC2116                             # exclude MANY false-positive shellcheck warnings (see above)

#  This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# =======================
#
#  Design based on IceFox script. Heavily modified by pekman, excalibur1234, Chrysostomus, papajoker, and thefallenrat.

# ANSI Escape sequences used in this script:                                        # ATTENTION: do NOT use \\e[  or  tput, because it does not always work!
#  \e[31m                                                                           # red text
#  \e[36m                                                                           # cyan text
#  \e[41m                                                                           # red background
#  \e[7m                                                                            # inverse/reverse text and background
#  \e[1m         \033[1m                                                            # bold text  ( \033[1m has to be used in "awk")
#  \e[0m         \033[0m                                                            # non-colored, non-bold text without background color  ( \033[0m has to be used in "awk")

# use unofficial strict mode in order to make bash behave like modern programming languages. this should only be used for debugging during development!
#set -e                                                                             # exit script immediately, if any command exits with non-zero error code. this is useful for parts of a script, which print an error message when exiting with non-zero value. ATTENTION: when fzf is quit using CTRL+C or ESC, it quits with an error. therefore, "set -e" should not be used around fzf!
#set -E                                                                             # let traps execute even when "set -e" is used. only use this in conjunction with "set -e" to avoid unexpected behavior
#set -u                                                                             # only allow previously defined variables. This prevents acces to environment variables!
#set -o pipefail                                                                    # if one command in a pipe fails, all fail (this is not default behavior!)
#set -x                                                                             # print every command (with expanded arguments) before execution. can be useful for debugging content of variables and to see in which line the script has failed. ATTENTION: this makes PacUI almost unusable.


# =======================


#set +u

# here, the preferred AUR helper can be set manually by the user. for example, AUR_Helper="trizen" uses Trizen despite any other installed AUR helpers.
AUR_Helper="$PACUI_AUR_HELPER"                                                      # global variable, which does not get unset (i.e. cleaned up), because it is needed both in GUI and non-GUI

#set -u


# if $PACUI_AUR_HELPER environment variable is not set, the installed AUR helpers are detected and one is chosen automatically:
if [[ -z "$AUR_Helper" ]]                                                           # check, if AUR_Helper variable is empty. more precise: check, if output of "$AUR_Helper" is zero
then

    if [[ -f /usr/bin/yay ]]                                                        # check, if /usr/bin/yay file exists (i.e. yay is installed)
    then
        AUR_Helper="yay"

    elif [[ -f /usr/bin/pikaur ]]
    then
        AUR_Helper="pikaur"

    elif [[ -f /usr/bin/aurman ]]
    then
        AUR_Helper="aurman"

    elif [[ -f /usr/bin/pakku ]]
    then
        AUR_Helper="pakku"

    elif [[ -f /usr/bin/trizen ]]
    then
        AUR_Helper="trizen"

    elif [[ -f /usr/bin/paru ]]
    then
	AUR_Helper="paru"

    elif [[ -f /usr/bin/pacaur ]]
    then
        AUR_Helper="pacaur"

    elif [[ -f /usr/bin/pamac ]]
    then
        AUR_Helper="pamac"

    fi
fi


# =======================

# all functions of pacui are defined here in the same order as they appear in pacui's UI (including some additional some helper functions):


# bug #3:
# "pacui --pacui_tty_clean" helper function. this function is only called from within pacui.
function pacui_tty_clean
{
        if ( tty | grep tty &>/dev/null )                                           # check, whether output of "tty" contains the string "tty". this is TRUE, if pacui is used within a tty.
        then
            # in tty, fzf does not clear the screen before and after it runs. this makes a bad visual style in tty. the other code (in the "else bracket") does not help to "clear" the screen before and after fzf runs, either. only the real "clear" command works.
            # unfortunately the "clear" command also destroys the terminal history. therefore, the "clear" command should only be used when absolutely necessary (such as in tty)!
            clear
        fi
}


# Update System
# this function provides core functionality of "Update System". the help page provides additional explanations.
function func_u
{
        # define local variable, which indicates whether the installation process was successful or not.
        local install_successful
        install_successful=false

        if [[ "$AUR_Helper" == "yay" ]]                                             # check, if $AUR_Helper variable is set to "yay". ATTENTION: sometimes, this requires   [[ "$AUR_Helper" == "yay" ]]   and sometimes   test '$AUR_Helper' = "yay"  . i do not know why this is the case.
        then

            # execute "yay -Syu" command:
            if ( yay $argument_flag-Syu )                                           # ATTENTION: (i do not know why but) using quotes (" symbols) around $argument_flag breaks yay command for arguments (e.g. "pacui -u --noconfirm")
            then
                # only set $install_successful=true, if the command "yay -Syu" was executed without errors
                install_successful=true
            else
                install_successful=false
            fi

        elif [[ "$AUR_Helper" == "pikaur" ]]
        then

            if ( pikaur "$argument_flag"-Syu )                                      # execute command "yay -Syu". if this command fails "false" is returned and the result is: "if ( false )"
            then
                install_successful=true
            else
                install_successful=false
            fi

        elif [[ "$AUR_Helper" == "aurman" ]]
        then

            if ( aurman "$argument_flag"-Syu )
            then
                install_successful=true
            else
                install_successful=false
            fi

        elif [[ "$AUR_Helper" == "pakku" ]]
        then

            if ( pakku "$argument_flag"-Syu )
            then
                install_successful=true
            else
                install_successful=false
            fi

        elif [[ "$AUR_Helper" == "trizen" ]]
        then

            if ( trizen "$argument_flag"-Syu )
            then
                install_successful=true
            else
                install_successful=false
            fi

        elif [[ "$AUR_Helper" == "paru" ]]
        then

            # execute "paru --sudoloop -Syu"
            if (paru "$argument_flag"--sudoloop -Syu --color always)
            then
                # only set $install_successful=true, if the command above was executed without errors
                install_successful=true
            else
                install_successful=false
            fi

        elif [[ "$AUR_Helper" == "pacaur" ]]
        then

            if ( pacaur "$argument_flag"-Syu --color always )
            then
                install_successful=true
            else
                install_successful=false
            fi

        elif [[ "$AUR_Helper" == "pamac" ]]
        then

            # execute "update -a" command:
            if ( pamac "$argument_flag"update -a )                                  # execute command "update -a". if this command fails "false" is returned and the result is: "if ( false )"
            then
                # only set $install_successful=true, if the command "update -a" was executed without errors
                install_successful=true
            else
                install_successful=false
            fi

        else

            if ( sudo pacman "$argument_flag"-Syu --color always )
            then
                install_successful=true
            else
                install_successful=false
            fi

        fi

        # if one of the above update commands has failed, the following if-statement is true:
        if [[ "$install_successful" == "false" ]]
        then

            local server
            # extract mirror/repository server url from /etc/pacman.d/mirrorlist file with command:
            server="$( grep "^Server =" -m 1 "/etc/pacman.d/mirrorlist" |awk -F '=' '{print $2}' | awk -F '$' '{print $1}' )"

            # if one of the above update commands has failed, there are multiple points of failure.
            # first, we can force the update, but only for packages from the system repositories and not packages from the AUR. this means, we make sure package updates from system repositories fail:
            if ! ( sudo pacman -Syu --color always )                                # the "sudo pacman -Syu --color always" command gets executed in any case in order to check its output.
            then

                # now, we are sure there is an active connection to the server/mirror/repository and package updates from there have failed. in this case, we can offer the user to forcefully install updates:
                local answer
                # ask, whether to force update the system and save answer in "answer" variable:
                echo -e " \e[1m Updates from system repositories have failed. \e[0m"
                echo -e " \e[41m Do you want to try updating forcefully? [y|N] \e[0m"
                read -r -n 1 -e answer                                              # this "read" command only accepts 1 letter as answer. this feels faster and is enough in this situation.

                case ${answer:-n} in                                                # if ENTER is pressed, the variable "answer" is empty. if "answer" is empty, its default value is "n".
                    y|Y|yes|Yes|YES )                                               # do this, if "answer" is y or Y or yes or Yes or YES
                        sudo pacman -Syu --color always --overwrite='*'
                        ;;
                    * )                                                             # do this in all other cases
                        echo -e " \e[1m Packages have not been updated.\e[0m"
                        ;;
                esac

            fi

        fi


        # do updates of installed snap packages
        if [[ -f /usr/bin/snap ]]
        then
            echo " updating snap packages ..."
            sudo snap refresh
            echo ""
        fi


        # do updates of installed flatpak packages
        if [[ -f /usr/bin/flatpak ]]
        then
            echo " updating flatpak packages ..."
            flatpak update -y
            echo ""
        fi
}


# "pacui --diff" helper function
# this function is not called by pacui or pacui's UI directly. instead, it gets called in func_m (using "pacui --diff") when no DIFFPROG environment variable is found. it provides simple file difference viewer functionality and is essentially a wrapper around the GNU program "diff". therefore, this function expects 2 arguments!
function func_diff
{
        # $(( ... )) does arithmetic evaluation. always use this when dealing with numbers, instead of strings - $[[ ... ]] does sting evaluation!
        local {temp,temp2,temp3}                                                    # define local variables - these variables will be automatically deleted after the function is finished/exited.
        temp2="$( echo "$argument_input" | awk '{print $1}' )"                      # write second argument of "pacui --diff temp2 temp3" to variable temp2.
        temp3="$( echo "$argument_input" | awk '{print $2}' )"                      # write third argument of "pacui --diff temp2 temp3"to variable temp3.
        temp="$((  ( $(tput cols) / 2 ) - ${#temp2} + ${#temp3}  ))"                # calculate half the width of the terminal window ( $(tput cols)=width of terminal window ; ${#temp2}=width of second argument )

        # insert extra line with file paths above the diff viewer output:
        echo -n -e "\e[31;1m$temp2"                                                 # print $temp2 (without \newline at the end) = file path of file1 . use ANSI escape sequence to print file names in this line bold and red.
        printf "%*s\n" "$temp" "$temp3"                                             # print (still in the same line) $temp3 ( = file path of file2) with $temp number of spaces in front and \newline at the end.
        tput sgr0                                                                   # printf does not support any ANSI escape sequences, so output (= red and bold text) has to be reset manually using "tput".

        # use "diff" as a file difference viewer with many options, which make it look good. "diff" takes 2 arguments (=the files, which are supposed to be compared)
        diff --side-by-side --suppress-common-lines --ignore-all-space --color=always --width="$(tput cols)" "$temp2" "$temp3"
}


# Maintain System
# this function provides core functionality of "Maintain System". it is separated into multiple parts. most parts begin (or contain) an "echo" command, which explains what is being done. the help page explains the core functionality of every part in detail, too.
function func_m
{
        # delete only pacui-related packages in /tmp directory. if other files are deleted, linux starts to act strange!
        if [[ -n "$( sudo find /tmp -name 'pacui*' 2>/dev/null )" ]]                # check if "pacui-*" file or directory is found in /tmp/ directory
        then
            echo " deleting PacUI cache ..."
            sudo rm --recursive --dir /tmp/pacui*                                   # here the "rm --recursive" command is needed, because both directories and files have to be removed. "unlink" and "rmdir" do not work here.
            echo ""
        fi


        # get cache directory from file /etc/pacman.conf (without any white spaces) and write results to variable $cache:
        cache="$( awk -F '=' '/^CacheDir/ {gsub(" ","",$2); print $2}' '/etc/pacman.conf' )"
        # set variable $cache to default directory, if  variable $cache is empty:
        if [[ -z "$cache" ]]                                                        # if "cache" variable is empty (exact: if output of $cache is zero)
        then
            cache="/var/cache/pacman/pkg/"
        fi
        # removing partially downloaded files from pacman cache. this can prevent pacman updates
        if [[ -n "$( sudo find "$cache" -iname "*.part" -type f )" ]]               # check, whether outupt of sudo find "$cache" -type f -iname "*.part" is non-zero (i.e. not empty). "sudo find "$cache" -type f -iname "*.part"" searches partially downloaded files (file name ends with ".part") in pacman cache.
        then
            echo " deleting partially downloaded packages from cache ..."
            sudo find "$cache" -iname "*.part" -delete
            echo ""
        fi


        # check for "pacman-mirrors" or "reflector" packages. one of those is needed!
        local connection_error
        connection_error=true
        if [[ -f /usr/bin/pacman-mirrors ]] || [[ -f /usr/bin/reflector ]]
        then

            echo " choosing fastest mirror (which can take a while) and updating system ..."
            if [[ -f /usr/bin/pacman-mirrors ]]                                     # checks, whether file "pacman-mirrors" exists
            then
                if ( sudo pacman-mirrors -f 0 )                                     # choose mirrors server (with up-to-date packages) with lowest ping from all available mirrors and sync database.
                then
                    sudo pacman -Syyuu
                    connection_error=false
                fi

            elif [[ -f /usr/bin/reflector ]]                                        # checks, whether file "reflector" exists
            then

                if ( sudo reflector --verbose --protocol https,ftps --age 5 --sort rate --save /etc/pacman.d/mirrorlist )            # If it does exists, then the mirror will sort by it
                then
                    sleep 10 && sudo pacman -Syyuu
                    connection_error=false
                fi
            fi
            echo ""
        fi


        if [[ "$connection_error" == "false" ]] && [[ -f /usr/bin/flatpak ]]
        then
            echo " cleaning up flatpak packages ..."
            flatpak uninstall --unused --delete-data -y
            echo ""
        fi


        echo " searching orphans ..."
        if [[ "$AUR_Helper" == "yay" ]]
        then
            yay -Yc                                                                 # do orphan cleaning with yay
        elif [[ "$AUR_Helper" == "pamac" ]]
        then
            pamac remove -o 							                            # do orphan cleaning with pamac
        elif [[ "$AUR_Helper" == "paru"  ]]
        then
            paru -c                                                                 # do orphan cleaning with paru
        else                                                                        # do this for all other AUR helpers:
            if [[ -n "$(pacman -Qdt)" ]]                                            # only run the following commands, if output of "pacman -Qdt" is not empty.
            then
                pacman -Qdt --color always                                          # display orphaned packages
                # ask, whether to remove the displayed orphaned packages:
                echo -e " \e[41m Do you want to remove these orphaned packages? [Y|n] \e[0m"
                read -r -n 1 -e answer                                              # save user input in "answer" variable (only accept 1 character as input)

                case ${answer:-y} in                                                # if ENTER is pressed, the variable "answer" is empty. if "answer" is empty, its default value is "y".
                    y|Y|yes|YES|Yes )                                               # do this, if "answer" is y or Y or yes or YES or Yes
                        sudo pacman -Rsn $(pacman -Qqdt) --color always --noconfirm                     # ATTENTION: (i do not know why but) using quotes (" symbols) around $(...) breaks pacman command for multiple packages
                        ;;
                    * )                                                             # do this in all other cases
                        echo -e " \e[1m Orphaned packages have not been removed.\e[0m"
                        ;;
                esac                                                                # end of "case" loop
            fi
        fi
        echo ""


        echo " sudo pacdiff ..."
        #set +u                                                                     # temporarily disable strict mode for environment variables
        if [[ -n "$DIFFPROG" ]]                                                     # this if-condition avoids error message when $DIFFPROG is not set/empty
        then
            sudo pacdiff
        else
            # use pacdiff to search for .pacnew and .pacsave files. display both the original and the used config file using "func_diff" function defined above.
            sudo DIFFPROG="pacui --diff" pacdiff
        fi
        #set -u
        echo ""


        echo " checking systemctl ..."
        # "LC_ALL=C" forces the output to use english language. this is important, if the output is queried.
        if [[ "$( LC_ALL=C systemctl is-system-running )" != "running" ]]
        then
            echo -e " \e[41m The following systemd service(s) have failed. Please fix them manually. \e[0m"
            echo -e " \e[1m Display detailed information about a systemd service with: systemctl status <SYSTEMD SERVICE NAME> \e[0m"
            echo
            systemctl list-units --state=failed
            echo
        fi
        echo ""


        echo " checking symlink(s) ..."
        if [[ -n "$(sudo find -xtype l)" ]]                                         # only run, if output of "sudo find -xtype l -print" is not empty
        then
            echo -e " \e[41m The following symbolic links are broken, please fix them manually: \e[0m"
            sudo find -xtype l
        fi
        echo ""


        echo " checking consistency of local repository ..."
        # check, whether "pacman -Dk" command finishes with errors, but do not output anything when this command runs with "&>/dev/null"
        if ! ( pacman -Dk &>/dev/null )
        then
            echo -e " \e[41m The following inconsistencies have been found in your local packages: \e[0m"
            echo -e "$( pacman -Dk )"                                               # encapsulate "pacman -Dk" in echo command. without this, the strict bash mode would quit pacui whenever "pacman -Dk" encounters an error!
        fi
        echo ""


        if [[ -n "$AUR_Helper" ]]                                                   # check, if output of "$AUR_Helper" is non-zero
        then
            echo " checking AUR package(s) (which can take a while) ..."
            # download AUR package list to /tmp/pacui-aur/packages.

            #wget -P "/tmp/pacui-aur/" "https://aur.archlinux.org/packages.gz" &>/dev/null
            #wget -P "/tmp/pacui-aur/" "https://aur.archlinux.org/packages.gz" &>/dev/null && gunzip -f "/tmp/pacui-aur/packages.gz"
            curl --url 'https://aur.archlinux.org/packages.gz' --create-dirs --output "/tmp/pacui-aur/packages.gz" &>/dev/null && gunzip -f "/tmp/pacui-aur/packages.gz"
            # now, file /tmp/pacui-aur/packages contains an unsorted list of all packages from the AUR with the download date on top (in a commented line).

            # check, if /tmp/pacui-aur/packages exists. /tmp/pacui-aur/packages does not exist, if there is no internet connection or something went wrong during the download of the list of AUR packages.
            #if [[ -f /tmp/pacui-aur/packages.gz ]]
            if [[ -f /tmp/pacui-aur/packages ]]
            then

                local pkg
                # the "comm" command compares 2 files and outputs the differences between them. both files have to be sorted!
                # "pacman -Qqm | sort" outputs a list of all installed packages from the AUR
                #pkg=$(  comm -23 <(pacman -Qqm | sort) <(sort -u /tmp/pacui-aur/packages.gz)  )
                pkg="$(  comm -23 <(pacman -Qqm | sort) <(sort -u /tmp/pacui-aur/packages)  )"

                # only run the command inside the if-statement, if $pkg variable is not empty
                if [[ -n "$pkg" ]]                                                  # checks, if length of string is non-zero ("-n" conditional bash expression is the opposite of "-z" (check, whether length of string is zero))
                then
                    echo -e " \e[1m The following packages are neither in your package repository nor the AUR. \e[0m"
                    echo -e " \e[1m They are orphaned and will never be updated. \e[0m"
                    echo -e " \e[41m It is recommended to remove these packages carefully: \e[0m"
                    echo "$pkg"
                    echo ""
                fi

            fi
        fi
        echo ""


        echo " checking for package(s) moved to the AUR ..."
        local pkg
        # "pacman -Qqm" lists all packages, which are not from the system repositories.  "pacman -Qqem" lists all files, which were explicitly installed, but are not present in the system repositories.
        # comm -23 only outputs unique packages from the 1. list (not present in the 2. list)
        pkg="$(  comm -23 <(pacman -Qqm | sort) <(pacman -Qqem | sort)  )"
        # only run the command inside the if-statement, if $pkg variable is not empty
        if [[ -n "$pkg" ]]                                                          # checks, if length of string is non-zero ("-n" conditional bash expression is the opposite of "-z" (check, whether length of string is zero))
        then
            echo -e " \e[1m The following packages were not explicitly installed and are not part of your system repository. \e[0m"
            echo -e " \e[41m If no important packages depend on them, it is recommended to remove these packages carefully: \e[0m"
            echo "$pkg"
            echo ""
        fi
        echo ""


        if [[ "$(cat /proc/1/comm)" == "systemd" ]]                                 # if init system is systemd
        then
            echo " cleaning systemd log file(s) ..."
            # limit logs in journalctl to an age of 30 days and a combined size of 50mb
            sudo journalctl --vacuum-size=100M --vacuum-time=30days
        fi
        echo ""


        echo " cleaning package cache ..."
        # remove all packages, which are not installed on this system, except the latest versions (this is a back up, in case somebody removes networkmanager)
        sudo paccache -rvu -k 1
        echo ""
        # remove all package versions, except the latest 3
        sudo paccache -rv -k 3
        echo ""
        # general comment: "pacaur" is currently the only aur helper, which creates its own download directory for aur packages. the content of this download folder can be cleaned with "pacaur -Sc". But "pacaur -Sc" removes too many files and is therefore not used here.


        local installed_kernels                                                     # declare local variable
        # filter installed kernels from boot sector and determine, which package owns that file. this yields the package name of all installed kernels (including kernels from the AUR):
        installed_kernels="$( pacman -Qq | grep -E '^linux$|^linux-lts$|^linux-zen$|^linux-hardened$|^linux[0-9]*$' | sort -u )"    # search for one of the following (hardcoded) package names of the linux kernel within arch linux (linux, linux-lts, linux-zen, or linux-hardened) or manjaro (linuxXY).
        # check, whether any installed kernels have been found  (in ARCH linux, no kernels are found, but this is ok, because kernels are not EOLd as in Manjaro)
        if [[ -n "$installed_kernels" ]]
        then
            echo " checking installed kernel(s) ..."

            local {available_kernels,eol_kernels}                                   # declare local variables
            # Check if installed kernels are available in repositories and forward it/them to available_kernels variable:
            available_kernels="$(
                for p in $( echo "$installed_kernels" )                             # ATTENTION: using quotes (" symbols) around $(...) breaks for-loop
                do
                    pacman -Ssq "^$p$"
                done | sort -u )"
            # filter kernels to $eol_kernels variable, which are installed but no longer available:
            eol_kernels="$( comm -13 <(echo "$available_kernels") <(echo "$installed_kernels") )"
            # print warning message, if end-of-life kernel(s) are found:
            if [[ -n "$eol_kernels" ]]
            then
                echo
                echo -e " \e[41m The following Linux kernel(s) are no longer available in your system repositories. \e[0m"
                echo -e " \e[1m Do not expect any security or stability fixes for the(se) kernel(s) anymore. \e[0m"
                echo -e " \e[1m Kernel modules are likely to break. It is recommended to remove the kernel(s).\e[0m"
                echo -e " \e[1m If the(se) kernel(s) are taken from the AUR, you may safely ignore this warning. \e[0m"
                echo "$eol_kernels"
            fi
            echo ""
        fi


        if [[ -f /usr/bin/fwupdmgr ]]
        then
            echo " checking for firmware update(s) ..."
            local update_available
            update_available=false

            fwupdmgr refresh --force                                                    # download the latest metadata from LVFS silently
            # "LC_ALL=C" forces the output to use english language. this is important, if the output is queried.
            if ( LC_ALL=C fwupdmgr get-updates | grep 'No updatable devices' ) &>/dev/null                              # fwupd has not found any supported devices
            then
                update_available=true
            elif ( LC_ALL=C fwupdmgr get-updates | grep 'No updates available' ) &>/dev/null                            # fwupd has no available firmware updates
            then
                update_available=true
            elif ( LC_ALL=C fwupdmgr get-updates | grep 'Devices that have been updated successfully' ) &>/dev/null     # fwupd has recently updated a device
            then
                update_available=true
            fi

            if [[ "$update_available" == "true" ]]
            then
                echo -e " \e[41m fwupd reports the following: \e[0m"
                fwupdmgr get-updates
                echo -e " \e[41m Do you want to execute 'fwupdmgr update'? [y|N] \e[0m"
                read -r -n 1 -e answer                                                  # save user input in "answer" variable (only accept 1 character as input)

                case ${answer:-n} in                                                    # if ENTER is pressed, the variable "answer" is empty. if "answer" is empty, its default value is "y".
                    y|Y|yes|YES|Yes )                                                   # do this, if "answer" is y or Y or yes or YES or Yes
                        fwupdmgr update
                        ;;
                    * )                                                                 # do this in all other cases
                        echo -e " \e[1m 'fwupdmgr update' not executed \e[0m"
                        ;;
                esac                                                                    # end of "case" loop
            fi
            echo ""
        fi
}


# Install Packages
# this function provides core functionality of "Install Packages". the help page provides additional explanations.
function func_i
{
        local {pacui_list_install,pkg}                                              # declare local variables

        # write package list of system repositories (package name and description) to $pacui_list_install. %-33n uses printf support in expac to format output nicely (reserve a 33 character wide field for package name %n).
        pacui_list_install="$(  expac -S "%-33n    %d" )"                           # here the parenthesis in "$(...)" are essential to write multiple lines to a variable! without parenthesis the variable will contain only a single line (space separated)!


        # for performance reasons, there are multiple files of package lists created in the following code. a comparison to local files is much faster than checking, whether a selected package is part of an online repository.
        # the use of variables instead of files can give more performance (and security) gains, but variables cannot be called from within fzf's preview, because it needs to be used with ' symbols (e.g. --preview '...')
        # these files do not need a trap (for security reasons), because they are only used for comparison. if tampered with, the comparison (which is done in "comm" without root privileges) simply fails and no package info is shown.
        expac -Q "%n" > /tmp/pacui-list-installed                                   # get locally installed packages (equivalent to "pacman -Qq", but faster).

        if [[ ! -f /tmp/pacui-list-install-repo ]]                                  # check, if file does not exist.
        then
            echo "$pacui_list_install" | cut -d " " -f 1 > /tmp/pacui-list-install-repo                     # get the content of $pacui_list_install variable and save (only a list of package names) to /tmp/pacui-list-install-repo file.
        fi

        # add a list of package groups in the system repositories to $pacui_list_install variable
        pacui_list_install+="\n"                                                    # by default, the "+=" operator adds all stuff directly to the end of a variable (but without a newline!). therefore, an additional "\n" (newline) is needed before adding stuff to a list.

        if [[ ! -f /tmp/pacui-list-install-groups ]]
        then
            # "pacman -Sgq" is equivalent to "expac -Sg %G | sort -u | sed 's/ /\n/g' | sort -u | awk 'NF != 0'", but much faster
            # split output of "pacman -Sgq" using "tee" to $pacui_list_install variable and /tmp/pacui-list-install-groups file. this saves a little time.
            pacui_list_install+="$( pacman -Sgq | tee /tmp/pacui-list-install-groups )"
        else
            pacui_list_install+="$( cat /tmp/pacui-list-install-groups )"           # if /tmp/pacui-list-install-groups file already exists, its content is added to $pacui_list_install variable. this is insecure, but because the same is done below (which i do not know how to do differently) with a list of AUR packages, i think it is an acceptable performance optimization.
            #pacui_list_install+="$( pacman -Sgq )"                                 # secure solution needs a bit of extra time.
        fi


        if [[ -n "$AUR_Helper" ]]                                                   # check, if output of "$AUR_Helper" is non-zero
        then

            # download AUR package list (only when not already downloaded) and add it to $pacui_list_install
            #if  [[ ! -f /tmp/pacui-aur/packages.gz ]]
            if  [[ ! -f /tmp/pacui-aur/packages ]]
            then
                echo " downloading list of AUR packages (which can take a while) ..."

                #wget -P "/tmp/pacui-aur/" "https://aur.archlinux.org/packages.gz" &>/dev/null
                #wget -P "/tmp/pacui-aur/" "https://aur.archlinux.org/packages.gz" &>/dev/null && gunzip -f "/tmp/pacui-aur/packages.gz"
                curl --url 'https://aur.archlinux.org/packages.gz' --create-dirs --output "/tmp/pacui-aur/packages.gz" &>/dev/null && gunzip -f "/tmp/pacui-aur/packages.gz"
            fi

            # check, if /tmp/pacui-aur/packages exists. /tmp/pacui-aur/packages does not exist, if there is no internet connection or something went wrong during the download of the list of AUR packages.
            #if [[ -f /tmp/pacui-aur/packages.gz ]]
            if [[ -f /tmp/pacui-aur/packages ]]
            then
                pacui_list_install+="\n"
                # remove line with download date from list of AUR packages with "grep" and add content of /tmp/pacui-aur/packages file to $pacui_list_install variable. this is insecure, but i do not know how to download the list of AUR packages directly into a variable. doing this with temporary files and traps would be a (quite slow!) secure solution, which i am not willing to implement yet.
                #pacui_list_install+="$( grep -v '#' '/tmp/pacui-aur/packages.gz' | tr -d ' ' )"            # delete all trailing spaces with "tr". command equivalent to "awk '{print $1}'"
                pacui_list_install+="$( grep -v '#' '/tmp/pacui-aur/packages' )"
            fi

        fi


        pacui_tty_clean                                                             # clear terminal
        #set +e                                                                     # prevent PacUI to quit, if fzf is quit using CTRL+C or ESC (which exits fzf with an error code)
        #set +E

        # fzf lets you search and select a given list. "man fzf" lists all its arguments beautifully. "fzf" commands in this script are typically in a convoluted form. here, a long "fzf" command is listed in maximum readable form.
        # the package list in $pacui_list_install gets sorted and displayed by fzf. then it is filtered by awk and saved in pkg variable.
        pkg="$(
                echo -e "$pacui_list_install" |                                     # load list of package names from $pacui_list_install_all variable. "-e" interprets the added newlines.
                sort -k1,1 -u |                                                     # sort list: only first column gets used for sorting
                # the "--multi" flag makes it possible to select multiple list items
                # $argument_input variable gets defined after function definitions --> search for "argument_input="
                # the "--preview" flag displays information about the currently selected line in fzf's preview window
                fzf -i \
                    --multi \
                    --exact \
                    --no-sort \
                    --select-1 \
                    --query="$argument_input" \
                    --cycle \
                    --layout=reverse \
                    --bind=pgdn:half-page-down,pgup:half-page-up \
                    --margin=1 \
                    --info=inline --no-separator \
                    --no-unicode \
                    --no-separator \
                    --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                    --header="TAB key to (un)select. ENTER to install. ESC to quit." \
                    --prompt="Enter string to filter list > " \
                    --preview '
                        if [[ $(comm -12 <(echo {1}) <(sort /tmp/pacui-list-installed)) ]]                      # check, if 1. field of selected line (in fzf) is a locally installed package.
                        then
                            echo -e "\e[1mInstalled package info: \e[0m"
                            pacman -Qi {1} --color always                           # display local package information in preview window of fzf
                            echo
                        fi

                        if [[ $(comm -12 <(echo {1}) <(sort /tmp/pacui-list-install-repo)) ]]                   # check, if 1. field of selected line (in fzf) is a package from system repositories
                        then
                            echo -e "\e[1mRepository package info: \e[0m"
                            pacman -Si {1} --color always                           # display repository package information in preview window of fzf
                            echo
                        fi

                        if [[ $(comm -12 <(echo {1}) <(sort /tmp/pacui-list-install-groups)) ]]                 # check, if 1. field of selected line (in fzf) is a package group
                        then
                            echo -e "\e[1m{1} group has the following members: \e[0m"
                            pacman -Sgq {1}                                         # display package name of group members in preview window of fzf

                        else

                            if [[ ! $(comm -12 <(echo {1}) <(sort /tmp/pacui-list-install-repo)) ]] && ( test -n '$AUR_Helper' )                   # preview window of fzf requires checking with "test": check whether internet connection is up.
                            then
                                echo -e "\e[1mAUR package info: \e[0m"

                                if test '$AUR_Helper' = "yay"
                                then
                                    yay -Si {1} | grep -v "::"                      # grep command removes all errors displayed by yay

                                elif test '$AUR_Helper' = "pikaur"
                                then
                                    pikaur -Si {1}

                                elif test '$AUR_Helper' = "aurman"                  # if {1} is neither locally installed nor a group, it is from the AUR. display info with AUR helper
                                then
                                    aurman -Si {1} | grep -v "::"                   # grep command removes all errors displayed by aurman

                                elif test '$AUR_Helper' = "pakku"
                                then
                                    pakku -Si {1}

                                elif test '$AUR_Helper' = "trizen"
                                then
                                    trizen -Si {1}

                                elif test '$AUR_Helper' = "paru"
                                then
                                    paru -Si {1} --color always | grep -v "\*\*.*\*\*"

                                elif test '$AUR_Helper' = "pacaur"
                                then
                                    pacaur -Si {1} --color always | grep -v "::"    # grep command removes all errors displayed by pacaur

                                elif test '$AUR_Helper' = "pamac"
                                then
                                    pamac info -a {1}

                                fi
                            fi

                        fi
                    ' |
                awk '{print $1}'                                                    # use "awk" to filter output of "fzf" and only get the first field (which contains the package name). "fzf" should output a separated (by newline characters) list of all chosen packages!
        )"

        #set -e
        #set -E
        pacui_tty_clean                                                             # clear terminal

        # $pkg contains package names below each other (=separated by \n), but we need a list in 1 line (which is space separated):
        pkg="$( echo "$pkg" | paste -sd " " )"


        # only run the command inside the if-statement, if variable $pkg is not empty (this happens when fzf is quit with ESC or CTRL+C)
        if [[ -n "$pkg" ]]
        then

            if [[ "$AUR_Helper" == "yay" ]]
            then
                yay $argument_flag-S $pkg                                           # ATTENTION: (i do not know why but) using quotes (" symbols) around $argument_flag breaks yay command for arguments (e.g. "pacui -u --noconfirm")          # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg variable breaks AUR helper and pacman

            elif [[ "$AUR_Helper" == "pikaur" ]]
            then
                pikaur "$argument_flag"-S $pkg                                      # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg variable breaks AUR helper and pacman

            elif [[ "$AUR_Helper" == "aurman" ]]
            then
                aurman "$argument_flag"-S $pkg                                      # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg variable breaks AUR helper and pacman

            elif [[ "$AUR_Helper" == "pakku" ]]
            then
                pakku "$argument_flag"-S $pkg                                       # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg variable breaks AUR helper and pacman

            elif [[ "$AUR_Helper" == "trizen" ]]
            then
                trizen "$argument_flag"-S $pkg                                      # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg variable breaks AUR helper and pacman

            elif [[ "$AUR_Helper" == "paru" ]]
            then
                paru "$argument_flag"--color always -S $pkg                         # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg variable breaks AUR helper and pacman

            elif [[ "$AUR_Helper" == "pacaur" ]]
            then
                pacaur "$argument_flag"--color always -S $pkg                       # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg variable breaks AUR helper and pacman

            elif [[ "$AUR_Helper" == "pamac" ]]
            then
                pamac "$argument_flag"install $pkg                                  # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg variable breaks AUR helper and pacman

            else
                sudo pacman "$argument_flag"--color always -Syu $pkg                # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg variable breaks AUR helper and pacman

            fi

        fi
}


# Remove Packages
# this function provides core functionality of "Remove Packages". the help page provides additional explanations.
function func_r
{
        # write package list of local repository to /tmp/pacui-packages-group.
        #pacman -Qq | tr -d " " > /tmp/pacui-packages-group
        expac -Q "%-33n    %d" > /tmp/pacui-packages-group
        # use expac command to print a list of installed package groups (of installed packages. then extract installed package groups from all of them) and add it to the bottom of /tmp/pacui-packages-group
        # awk 'NF != 0'  only displays lines where the number of fields is not zero (i.e. non-empty lines)
        expac -Qg %G | sort -u | sed 's/ /\n/g' | sort -u | awk 'NF != 0' >> /tmp/pacui-packages-group

        local {pkg,pkg_remove,pkg_remove_backup}                                    # declare local variables

        pacui_tty_clean                                                             # clear terminal
        #set +e
        #set +E

        # take a sorted package (and group) list from /tmp/pacui-packages-group, then make the resulting list available to fzf. see above for a "fzf" command with good readability and many comments
        pkg="$( sort -k1,1 -u /tmp/pacui-packages-group |
            fzf -i --multi --exact --no-sort --select-1 --query="$argument_input" --cycle --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                --header="TAB key to (un)select. ENTER to remove. ESC to quit." --prompt='Enter string to filter list > ' \
                --preview '
                    if ( pacman -Qq {1} &>/dev/null )                               # check, if selected line is a locally installed package
                    then
                        echo -e "\e[1mInstalled package info: \e[0m"
                        pacman -Qi {1} --color always

                    else
                        echo -e "\e[1m{1} group has the following installed packages: \e[0m"
                        pacman -Qgq {1}

                    fi
                ' |
            awk '{print $1}'
        )"

        #set -e
        #set -E
        pacui_tty_clean                                                             # clear terminal

        if [[ -n "$pkg" ]]                                                          # check, whether $pkg variable is not empty. this happens when fzf is quit with CTRL+C.
        then
            # $pkg contains package names below each other, but we need a list (in 1 line, space separated):
            pkg="$( echo "$pkg" | paste -sd " " )"
            pkg_remove="$( echo "$pkg" )"

            # wrap the "sudo pacman -Rns" command in an if-statement, which checks, whether the removal of packages works. the removal of packages does not work, if the user tries to remove a dependency.
            # the failure of "sudo pacman -Rns" is especially annoying, if many packages has been chose for removal and 1 package is a dependency. by default, the list of packages (which are supposed to be removed) is NOT saved!
            # "sudo pacman -Rsn $pkg_remove --color always" always gets executed!
            if ! ( sudo pacman "$argument_flag"-Rsn $pkg_remove --color always )    # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg_remove variable breaks AUR helper and pacman
            then

                # now, "sudo pacman -Rsn $pkg_remove --color always" has failed. this means that a dependency was selected. Print error message below the error output of pacman.
                echo
                echo -e " \e[1m Package removal has failed. \e[0m"
                echo -e " \e[1m Choose one of the following options: \e[0m"
                echo
                echo -e "\e[1m    1     Try again. \e[0m"
                echo -e "\e[1m          Read the error message(s) above carefully and try not to select dependencies next time. \e[0m"
                echo
                echo -e "\e[1;31m    2     Forcefully remove package(s) without checking their dependencies first. \e[0m"
                echo -e "\e[1;31m          Attention: This command can break dependencies. \e[0m"
                echo
                echo -e "\e[1;31m    3     Remove package(s) and all additional packages, which depend on them. \e[0m"
                echo -e "\e[1;31m          Attention: This is a recursive option and can remove many potentially needed packages. \e[0m"
                echo
                echo -e "\e[1m   ENTER  Exit without removing any packages. \e[0m"
                echo
                # save answer in "answer" variable:
                read -r -n 1 -e answer

                case ${answer:-n} in                                                # if ENTER is pressed, the variable "answer" is empty. if "answer" is empty, its default value is "n".

                    1 )                                                             # do this, if "answer" is 1
                        # continue here only if "sudo pacman -Rns" has failed:
                        # 1. save list of packages to variable
                        pkg_remove_backup="$( echo "$pkg_remove" | tr " " "\n" )"   # tr " " "\n" is needed to convert the list of package names (in 1 line) back to multiple lines. otherwise, fzf cannot work with it.

                        # 2. try again with a limited list of packages in fzf. this loop is dependent on the pkg_remove_backup variable!
                        while [[ -n "$pkg_remove_backup" ]]
                        do

                            local {pkg,pkg_remove}                                  # declare local variables

                            pacui_tty_clean                                         # clear terminal
                            #set +e
                            #set +E

                            # fzf lets you search and select the given list in a fast way. see above for a "fzf" command with good readability and many comments
                            pkg="$( echo "$pkg_remove_backup" |
                                fzf -i --multi --exact --no-sort --query="$argument_input" --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                                    --header="TAB key to (un)select. ENTER to remove. ESC to quit." --prompt='Enter string to filter list > ' \
                                    --preview '
                                        if ( pacman -Qq {1} &>/dev/null )           # check, if selected line is a locally installed package
                                        then
                                            echo -e "\e[1mInstalled package info: \e[0m"
                                            pacman -Qi {1} --color always

                                        else
                                            echo -e "\e[1m{1} group has the following installed packages: \e[0m"
                                            pacman -Qgq {1}

                                        fi
                                    ' |
                                awk '{print $1}'
                            )"

                            #set -e
                            #set -E
                            pacui_tty_clean                                         # clear terminal

                            if [[ -z "$pkg" ]]                                      # check, whether $pkg variable is empty. this happens when fzf is quit with CTRL+C.
                            then
                                break                                               # break while-loop, if fzf was quit using CTRL+C
                            fi

                            # $pkg contains package names below each other, but we need a list (in 1 line, space separated):
                            pkg_remove="$(echo "$pkg" | paste -sd " ")"

                            if ! ( sudo pacman -Rsn $pkg_remove --color always )    # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg_remove variable breaks AUR helper and pacman
                            then
                                # continue here only if "sudo pacman -Rns" has failed (again):
                                # a) save list of packages to backup variable
                                pkg_remove_backup="$( echo "$pkg_remove" | tr " " "\n" )"           # here, do NOT write selection to file. this enables the user to guess which packages are dependencies.

                                # b) Print error message. the user can read all error messages (of pacman) and decide what to do next.
                                echo
                                echo -e " \e[41m  Package removal has failed again. \e[0m"
                                echo -e " \e[1m Press ENTER to try again or CTRL+C to quit. \e[0m"
                                read -r
                                # now, start at the top of the while-loop again...
                            else
                                # removing the pkg_remove_backup variable quits the while-loop
                                unset pkg_remove_backup
                            fi

                        done
                        ;;


                    2 )                                                             # do this, if "answer" is 2
                        sudo pacman -Rdd $pkg_remove --color always                 # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg_remove variable breaks AUR helper and pacman
                        ;;


                    3 )                                                             # do this, if "answer" is 3
                        sudo pacman -Rsnc $pkg_remove --color always                # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg_remove variable breaks AUR helper and pacman
                        ;;


                    * )                                                             # do this in all other cases
                        echo -e " \e[1m Removal of packages has been cancelled. \e[0m"
                        ;;

                esac

            fi
        fi
}


# Dependency Tree
# this function provides core functionality of "Dependency Tree". the help page provides additional explanations.
function func_t
{
        # write list of all installed packages to file /tmp/pacui-packages-local . then add list of packages in system repositories to the bottom of /tmp/pacui-packages-local.
        #pacman -Qq | tr -d " " > /tmp/pacui-packages-local
        expac -Q "%-33n    %d" > /tmp/pacui-packages-local
        #pacman -Slq | tr -d " " >> /tmp/pacui-packages-local
        expac -S "%-33n    %d" >> /tmp/pacui-packages-local

        local pkg

        pacui_tty_clean                                                             # clear terminal
        #set +e
        #set +E

        pkg="$( sort -k1,1 -u /tmp/pacui-packages-local |
            fzf -i --exact --no-sort --select-1 --query="$argument_input" --cycle --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                --header="ENTER for dependency tree. ESC to quit." --prompt='Enter string to filter list > ' \
                --preview '
                    if ( pacman -Qq {1} &>/dev/null )                               # check, if 1. element of selected line is a locally installed package
                    then
                        echo -e "\e[1mInstalled package info: \e[0m"
                        pacman -Qi {1} --color always

                    else
                        echo -e "\e[1mRepository package info: \e[0m"
                        pacman -Si {1} --color always                               # do this, if package is not locally installed

                    fi
                ' |
            awk '{print $1}'
        )"

        pacui_tty_clean                                                             # clear terminal


        if [[ -n "$pkg" ]]
        then
            if ( pacman -Qq "$pkg" &>/dev/null )                                    # check, if (in fzf) selected package is locally installed
            then

                # explain the " echo {} | sed 's/^[|`- ]*//g' | cut -d ' ' -f 1 " command used below:
                # first echo selected line in fzf. then, remove all symbols from the beginning of the line, which does not belong to the package name. if there are multiple package names (e.g. with "provides") in 1 line all other (except for the first package name) are cut from the result.
                pactree --color --ascii "$pkg" |
                    fzf -i --multi --exact --no-sort --ansi --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                        --header="Local Dependency Tree of \"$pkg\". ESC to quit." --prompt='Enter string to filter list > ' \
                        --preview '
                            echo -e "\e[1mInstalled package info: \e[0m"
                            pacman -Qi "$( echo -e {} | sed "s/[\|\`\ -]*//" | cut -d " " -f 1 )" --color always
                        ' > /tmp/pacui-t

            else

                # if $pkg is not a locally installed package, "pactree --sync" shows reverse dependency tree of repository packages:
                pactree --color --ascii --sync "$pkg" |
                    fzf -i --multi --exact --no-sort --ansi --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                        --header="Repository Dependency Tree of \"$pkg\". ESC to quit." --prompt='Enter string to filter list > ' \
                        --preview '
                            if ( pacman -Qq "$( echo -e {} | sed "s/[\|\`\ -]*//" | cut -d " " -f 1 )" &>/dev/null )                                                 # check, if selected line contains a locally installed package.
                            then
                                echo -e "\e[1mInstalled package info: \e[0m"
                                pacman -Qi "$( echo -e {} | sed "s/[\|\`\ -]*//" | cut -d " " -f 1 )" --color always                                                 # display local package information in preview window of fzf

                            else
                                echo -e "\e[1mRepository package info: \e[0m"
                                pacman -Si "$( echo -e {} | sed "s/[\|\`\ -]*//" | cut -d " " -f 1 )" --color always                                                 # display package info from repository, if package is not locally installed

                            fi
                        ' > /tmp/pacui-t

            fi

            pacui_tty_clean                                                         # clear terminal

        fi

        #set -e
        #set -E
}


# Reverse Dependency Tree
# this function provides core functionality of "Reverse Dependency Tree". the help page provides additional explanations.
function func_rt
{
        # write list of all installed packages to file /tmp/pacui-packages-local . then add list of packages in system repositories to the bottom of /tmp/pacui-packages-local.
        #pacman -Qq | tr -d " " > /tmp/pacui-packages-local
        expac -Q "%-33n    %d" > /tmp/pacui-packages-local
        #pacman -Slq | tr -d " " >> /tmp/pacui-packages-local
        expac -S "%-33n    %d" >> /tmp/pacui-packages-local

        local pkg

        pacui_tty_clean                                                             # clear terminal
        #set +e
        #set +E

        pkg="$( sort -k1,1 -u /tmp/pacui-packages-local  |
            fzf -i --exact --no-sort --select-1 --query="$argument_input" --cycle --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                --header="ENTER for reverse dependency tree. ESC to quit." --prompt='Enter string to filter list > ' \
                --preview '
                    if ( pacman -Qq {1} &>/dev/null )                               # check, if 1. element of selected line is a locally installed package
                    then
                        echo -e "\e[1mInstalled package info: \e[0m"
                        pacman -Qi {1} --color always

                    else
                        echo -e "\e[1mRepository package info: \e[0m"
                        pacman -Si {1} --color always                               # do this, if package is not locally installed

                    fi
                ' |
            awk '{print $1}'
        )"

        pacui_tty_clean                                                             # clear terminal


        if [[ -n "$pkg" ]]
        then
            if ( pacman -Qq "$pkg" &>/dev/null )                                    # check, if (in fzf) selected package is locally installed
            then

                # explain the " echo {} | sed 's/^[|`- ]*//g' | cut -d ' ' -f 1 " command used below:
                # first echo selected line in fzf. then, remove all symbols from the beginning of the line, which does not belong to the package name. if there are multiple package names (e.g. with "provides") in 1 line all other (except for the first package name) are cut from the result.
                pactree --color --ascii --reverse "$pkg" |
                    fzf -i --multi --exact --no-sort --ansi --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                        --header="Local Reverse Dependency Tree of \"$pkg\". ESC to quit." --prompt='Enter string to filter list > ' \
                        --preview '
                            echo -e "\e[1mInstalled package info: \e[0m"
                            pacman -Qi "$( echo -e {} | sed "s/[\|\`\ -]*//" | cut -d " " -f 1 )" --color always
                        ' > /tmp/pacui-rt

            else

                # if $pkg is not a locally installed package, "pactree --sync" shows reverse dependency tree of repository packages:
                pactree --color --ascii --sync --reverse "$pkg" |
                    fzf -i --multi --exact --no-sort --ansi --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                        --header="Repository Reverse Dependency Tree of \"$pkg\". ESC to quit." --prompt='Enter string to filter list > ' \
                        --preview '
                            if ( pacman -Qq "$( echo -e {} | sed "s/[\|\`\ -]*//" | cut -d " " -f 1 )" &>/dev/null )                                                 # check, if selected line contains a locally installed package.
                            then
                                echo -e "\e[1mInstalled package info: \e[0m"
                                pacman -Qi "$( echo -e {} | sed "s/[\|\`\ -]*//" | cut -d " " -f 1 )" --color always                                                 # display local package information in preview window of fzf

                            else
                                echo -e "\e[1mRepository package info: \e[0m"
                                pacman -Si "$( echo -e {} | sed "s/[\|\`\ -]*//" | cut -d " " -f 1 )" --color always                                                 # display package info from repository, if package is not locally installed

                            fi
                        ' > /tmp/pacui-rt

            fi

            pacui_tty_clean                                                         # clear terminal

        fi

        #set -e
        #set -E
}


# List Package Files
# this function provides core functionality of "List Package Files". the help page provides additional explanations.
function func_l
{
        # write list of all installed packages to file /tmp/pacui-packages-local . then add list of packages in system repositories to the bottom of /tmp/pacui-packages-local.
        #pacman -Qq | tr -d " " > /tmp/pacui-packages-local
        expac -Q "%-33n    %d" > /tmp/pacui-packages-local
        #pacman -Slq | tr -d " " >> /tmp/pacui-packages-local
        expac -S "%-33n    %d" >> /tmp/pacui-packages-local

        local pkg

        pacui_tty_clean                                                             # clear terminal
        #set +e
        #set +E

        pkg="$( sort -k1,1 -u /tmp/pacui-packages-local |
            fzf -i --exact --no-sort --select-1 --query="$argument_input" --cycle --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                --header="ENTER to list files. ESC to quit." --prompt='Enter string to filter list > ' \
                --preview '
                    if ( pacman -Qq {1} &>/dev/null )                               # check, if selected line is a locally installed package
                    then
                        echo -e "\e[1mInstalled package info: \e[0m"
                        pacman -Qi {1} --color always                               # for local packages, local query is sufficient.

                    else
                        echo -e "\e[1mRepository package info: \e[0m"
                        pacman -Si {1} --color always                               # do this, if package is not locally installed

                    fi
                ' |
            awk '{print $1}'
        )"

        pacui_tty_clean                                                             # clear terminal

        if [[ -n "$pkg" ]]
        then
            # next, it is checked, whether "pkg" is part of a list of all installed packages (pacman -Qq): the if-statement checks the exit code of the command "pacman -Qq $pkg &>/dev/null".
            if ( pacman -Qq "$pkg" &>/dev/null )
            then

                # "pacman -Ql" shows sometimes more files than "pacman -Fl". therefore, both commands have to be used!
                # take the output of command "pacman -Qlq $pkg" and make it searchable with fzf. for all used fzf flags see "man fzf". store all marked lines in file /tmp/pacui-list.
                pacman -Ql "$pkg" --color always 2>/dev/null | grep -a -v "/$" | awk '{print $NF}' | fzf -i --multi --exact --no-sort --query="usr/bin/" --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --header="List of files of local package \"$pkg\". Press ESC to quit." --prompt='Manipulate string to filter list > ' > /tmp/pacui-l

            else

                # update local package database. this needs a long time when internet connection is slow.
                # in some cases, the local database has to be initialized with "sudo pacman -Fyy" before "sudo pacman -Fy" actually works
                sudo pacman -Fy

                pacui_tty_clean                                                     # clear terminal

                # search in system repositories with "pacman -Fl" --> machine readable version of output is easier to read for awk!
                # grep -a is used, because "pacman -Fl --machinereadable" returns a file starting with non-text data. the "-a" option ignores that.
                # the awk command is used to format output: "-F '\0'" set "\0" as separator. this makes it possible to easily use $1,$2,$3,$4 as syntax later.
                # "{print $1 "/" $2 "  " $4}" prints output nicely formatted.
                pacman -Fl --machinereadable "$pkg" | grep -a -v "/$" | awk -F '\0' '{print $4}' | fzf -i --multi --exact --no-sort --query="usr/bin/" --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --header="List of files of repository package \"$pkg\". Press ESC to quit." --prompt='Manipulate string to filter list > ' > /tmp/pacui-l

            fi

            pacui_tty_clean                                                         # clear terminal

        fi

        #set -e
        #set -E
}


# Search Package Files
# this function provides core functionality of "Search Package Files". the help page provides additional explanations.
function func_s
{
        # define local variables - all get deleted automatically when the function is exited
        local file

        if [[ -n "$argument_input" ]]
        then
            # do this if variable "input" is not empty:
            file="$argument_input"
        else
            # do this if pacui is used with UI or no argument is specified in "pacui s" command:
            echo -e " \e[41m Enter (parts of) the file name to be searched. Press ENTER to start search. \e[0m"
            echo -e " \e[1m Using regular expressions can narrow the search result dramatically: \e[0m"
            read -r file
            echo
        fi

        if [[ -n "$file" ]]
        then

            # use as many local variables as possible. unfortunately, it is still necessary to use a couple of temporary files (i have done a lot of tests and this current form of 'pacui s' seems to be the fastest):
            local {pacui_search_temp_local,pacui_search_temp_repo2,pacui_search_temp_only_in_repo2}


            echo -e "\n\e[1mLocal package files: \e[0m" > /tmp/pacui-search

            echo " searching local repositories ..."

            # list all files of all installed local packages using "pacman -Ql --color always"
            # awk -v VAR="$file" '$NF ~ VAR' searches for $file (using regex) in the last field/column only. write resulting list to /tmp/pacui-search
            pacman -Ql --color always | awk -v VAR="$file" -F '/' '$NF ~ VAR' >> /tmp/pacui-search
            # write a list of package names (which install files containing "$file" string) to variable $pacui_search_temp_local
            pacui_search_temp_local="$( pacman -Ql | awk -v VAR="$file" -F '/' '$NF ~ VAR' | awk -F '/' '{print $1}' | sort -u | tr -d ' ' )"

            # update local package database. this needs a long time when internet connection is slow.
            # in some cases, the local database has to be initialized with "sudo pacman -Fyy" before "sudo pacman -Fy" actually works
            sudo pacman -Fy

            echo -e "\n\e[1mPackage files in system repositories: \e[0m" >> /tmp/pacui-search
            # search in system repositories with "pacman -Fsx" --> machine readable version of output is easier to read for awk!
            # comment: possible improvement: use "pv -ptb" to show progress bar (useful for large searches)
            # the awk command is used to format output: "-F '\0'" set "\0" as separator. this makes it possible to easily use $1,$2,$3,$4 as syntax later.

            echo " searching online repositories (which can take a while) ..."

            # store raw output of "pacman -Fsx" in file /tmp/pacui-search-temp-repo, because this process is quite slow
            pacman -Fx --machinereadable "$file" > "/tmp/pacui-search-temp-repo"

            # create new variable $pacui_search_temp_repo2 ,which only contains package names
            pacui_search_temp_repo2="$( awk -F '\0' '{print $2}' "/tmp/pacui-search-temp-repo" | sort -u | tr -d ' ' )"

            # compare list of package names and only keep package names in system repository (in variable $pacui_search_temp_repo2):
            pacui_search_temp_only_in_repo2="$( comm -13 <(echo "$pacui_search_temp_local") <(echo "$pacui_search_temp_repo2") )"

            # grep all package names from variable $pacui_search_temp_only_in_repo2 and search for them in file /tmp/pacui-search-temp-repo (leave "cat" and "grep" in their current order for better code readability)
            # next, awk formats the list to the desired style
            grep -a -f <(echo "$pacui_search_temp_only_in_repo2") "/tmp/pacui-search-temp-repo" | awk -F '\0' '{print  $1 "/" "\033[1m" $2 "\033[0m  " $4}' >> /tmp/pacui-search

            ### the last command (above) is REALLY fast, but the result is much less exact than desired!!! if an exact result is needed, the following command at the end of this comment block can provide it.
            # "system( "grep -q " $2 " /tmp/pacui-search-temp-local" ) == 1" check exit status of "grep -q <package name> /tmp/pacui-search-temp-local"(checks, if <package name> is part of list /tmp/pacui-search-temp-local). if error occurs (==1), the package is printed to /tmp/pacui-search-temp
            # "{print $1 "/" $2, $4}" prints output nicely formatted to /tmp/pacui-search.
            # instead of regular ANSI escape sequences, i need to use \033[1m instead of \e[1m inside the awk command.
            #pacman -Fsx --machinereadable "$file" | awk -F '\0' 'system("grep -q " $2 " /tmp/pacui-search-temp-local") == 1 {print  $1 "/" "\033[1m" $2 "\033[0m " $4}' >> /tmp/pacui-search


            pacui_tty_clean                                                         # clear terminal
            #set +e
            #set +E

            # display results from file /tmp/pacui-search in fzf.
            cat /tmp/pacui-search | fzf -i --multi --exact --no-sort --ansi --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --header="Package file names (bold) and paths containing \"$file\". Press ESC to quit." --prompt='Enter string to filter list > ' > /tmp/pacui-s

            #set -e
            #set -E
            pacui_tty_clean                                                         # clear terminal

        fi
}


# =======================


# Roll Back System
# this function provides core functionality of "Roll Back System". the help page provides additional explanations.
function func_b
{
        # declare local variables
        local {cache,logpath,cachePACAUR,pkgR,pkgI,pkgD,pkgU,line,temp1,temp2,temp3,pacui_cache_packages,pacui_cache_install,pacui_aur_install,pacui_cache_downgrade,pacui_cache_downgrade_counted,pacui_tmp_downgrade,pacui_aur_install,pacui_install,pacui_downgrade,pacui_cache_upgrade,pacui_cache_upgrade_counted,pacui_tmp_upgrade,pacui_upgrade}
        pacui_aur_install=""                                                        # needed to avoid "unbound variable error"

        # get cache directory from file /etc/pacman.conf (without any white spaces) and write results to variable $cache:
        cache="$( awk -F '=' '/^CacheDir/ {gsub(" ","",$2); print $2}' '/etc/pacman.conf' )"
        # set variable $cache to default directory, if  variable $cache is empty:
        if [[ -z "$cache" ]]                                                        # if "cache" variable is empty (exact: if output of $cache is zero)
        then
            cache="/var/cache/pacman/pkg/"
        fi

        # get log file path from file /etc/pacman.conf (without any white spaces) and write results to variable $logpath:
        logpath="$( awk -F '=' '/^LogFile/ {gsub(" ","",$2); print $2}' '/etc/pacman.conf' )"
        # set variable $logpath to default directory, if  variable $logpath is empty:
        if [[ -z "$logpath" ]]                                                      # if "logpath" variable is empty (exact: if output of $logpath is zero)
        then
            logpath="/var/log/pacman.log"
        fi

        if [[ "$AUR_Helper" == "pacaur" ]]                                          # checks, whether file "pacaur" exists, i.e. pacaur is installed
        then
            #set +u                                                                 # temporarily disable strict mode for environment variables

            # the cache location of pacaur is important for downgrading packages installed from the AUR or reinstalling removed packages from the AUR:
            if [[ -z $AURDEST ]]                                                    # $AURDEST is environment variable for changing pacaur's default cache directory. check, if "AURDEST" variable is empty
            then
                cachePACAUR="$HOME/.cache/pacaur/"
            else
                cachePACAUR="$AURDEST"
            fi

            #set -u
        fi


        pacui_tty_clean                                                             # clear terminal
        #set +e
        #set +E

        # 1. get list of last installs/upgrades/removals/downgrades from pacman log and display result in fzf.
        # when fzf quits, only selected package names (including the words " installed/upgraded/removed/downgraded") are saved to variable $pacui_cache_packages
        #  the space in front of "installed" prevents reinstallations being displayed (otherwise, they would be removed)! the ] in "] installed" prevents config file changes being displayed, e.g. "warning: /etc/sddm.conf installed as /etc/sddm.conf.pacnew"
        # awk -F '[\\[\\]]' '{ print $2 " " $5 }': this uses 2 field separators [ and ]. using these field separators, the second and fifth field are printed.
        # awk '{ $1=$1 ":"  ; $2="  " $2 ; $3="\t\033[1m" $3 " \033[0m" ; print }': this uses the output of the above awk command. the first field gets a colon added, the second field gets a coupld of spaces in front, the third field gets printed in bold case.
        pacui_cache_packages="$( tail -8000 "$logpath" | grep "] installed\|removed\|upgraded\|downgraded" | awk -F '[\\[\\]]' '{ print $2 " " $5 }' | awk '{ $1=$1 ":"  ; $2="  " $2 ; $3="\t\033[1m" $3 " \033[0m" ; print }' | fzf -i --multi --exact --no-sort --select-1 --ansi --query="$argument_input" --cycle --tac --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --header="Press TAB key to (un)select. ENTER to roll back. ESC to quit." --prompt='Enter string to filter displayed list of recent Pacman changes > ' | sed 's/ ([^)]*)//g' | awk '{ print $(NF-1) " " $NF }' )"

        #set -e
        #set -E
        pacui_tty_clean                                                             # clear terminal

        # only run the command inside the if-statement, if variable $pacui_cache_packages is not empty and exists - this happens when fzf is quit with ESC or CTRL+C
        if [[ -n "$pacui_cache_packages" ]]
        then


            # 2. in case of conflicting packages, packages have to be first removed (with the force option, because other packages might still depend on them).
            # filter variable $pacui_cache_packages for the word "installed" and write package names to variable $pkgR
            pkgR="$( echo "${pacui_cache_packages}" | awk '/installed/ {print $2}' | sort -u | paste -sd " " )"

            if [[ -n "$pkgR" ]]                                                     # this if-condition avoids error message when no package gets removed (and $pkgR is empty)
            then
                # remove packages with pacman command. use parameter substitution with ${...} (without quotes!!!) for it, because otherwise the pacman command fails!
                sudo pacman "$argument_flag"-R ${pkgR} --color always               # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkgR variable breaks AUR helper and pacman
            fi


            # 3. in case an "upgraded" package needs a package as dependency, the "removed" packages have to be installed.
            # filter variable $pacui_cache_packages for the word "removed" and write package names to variable $pacui_cache_install
            pacui_cache_install="$( echo "${pacui_cache_packages}" | awk '/removed/ {print $2}' )"

            if [[ -n "$pacui_cache_install" ]]                                      # this if-condition avoids error messages when no package gets installed (and variable $pacui_cache_install is empty)
            then

                if [[ "$AUR_Helper" == "pacaur" ]]                                  # checks, whether file "pacaur" exists, i.e. pacaur is installed
                then
                    # the while-loop here is needed to read the content of every line of $pacui_cache_install variable and save that line to variable $line.
                    pacui_aur_install="$(
                        while IFS='' read -r line || [[ -n "$line" ]]
                        do
                            ## the problem here is that AUR packages are not named/numbered in a constant and easy sortable way. therefore, we search for all files and output their modification date in an easy searchable format (and then, the file name).
                            ## then, "grep" is used to get only package files. then, the list is sorted (by the modification date).
                            ## awk gets rid of the modification date. grep filters for the file name $line. sed only chooses the first/top line.
                            find "$cachePACAUR" -maxdepth 2 -mindepth 2 -type f -printf "%T+\t%p\n" | grep ".pkg.tar.[gx]z$" | sort -rn | awk '{print $2}' | grep "$line""-" | sed -n '1p'
                        done < <(echo "${pacui_cache_install}")
                    )"
                fi

                # read line by line from variable $pacui_cache_install in while loop and save that line to variable $line
                pacui_install="$(
                    while IFS='' read -r line || [[ -n "$line" ]]
                    do
                        # write name of latest version in cache into variable $pacui_install ("sort" puts latest version on top, which is then selected):
                        find "$cache" -name "${line}-[0-9a-z.-_]*.pkg.tar.[gx]z" | sort -r | sed -n '1p'
                    done < <(echo "${pacui_cache_install}")
                )"

                # sort output to suit pacman's syntax. pacman needs a list of package names separated by single spaces.
                if [[ -n "$pacui_aur_install" ]]
                then
                    # if AUR packages should be installed, the lists of package names are first combined before they get sorted and rearranged to space separated lists.
                    # use parameter substitution to combine 2 lists of packages.
                    pkgI="$( printf "${pacui_install}\n${pacui_aur_install}" | sort -u | paste -sd " " )"
                else
                    pkgI="$( echo "${pacui_install}" | sort -u | paste -sd " " )"
                fi

                # finally, all packages get installed manually using "pacman -U":
                if [[ -n "$pkgI" ]]
                then
                    # install cannot be done as dependency, because sometimes packages are simply replaced by other packages. in this case, installing as dependency would be bad!
                    sudo pacman "$argument_flag"-U ${pkgI} --color always           # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkgI variable breaks AUR helper and pacman
                fi

            fi


            # 4. filter variable $pacui_cache_packages file for the word "upgraded" and write package names to variable $pacui_cache_downgrade
            # variable $pacui_cache_packages contains list of package names to be downgraded!
            pacui_cache_downgrade="$( echo "${pacui_cache_packages}" | awk '/upgraded/ {print $2}' )"

            if [[ -n "$pacui_cache_downgrade" ]]                                    # this if-condition avoids error messages when no package gets downgraded (and variables $pacui_cache_downgrade is empty)
            then

                # here, it is impossible to use variables instead of temporary files. therefore, the temporary files should be as tamper-proof as possible.
                # Create temp file with mktemp command (Important for security). the XXXXXXXX indicates numbers assigned by "mktemp" command.
                # the XXXXXXXXX numbers make it necessary to call the temporary file in the code below with ${pacui_tmp_downgrade} !
                pacui_tmp_downgrade="$( mktemp /tmp/pacui-tmp-downgrade.XXXXXXXX )"

                # add trap command to immediately remove upon ctrl+c (or any other case this function quits in the middle) for security purposes
                # this is the normal syntax for "trap" command.
                trap 'unlink ${pacui_tmp_downgrade}' EXIT

                # first, count the number of times the package name appears in file ${pacui_cache_downgrade}:
                pacui_cache_downgrade_counted="$( echo "${pacui_cache_downgrade}" | sort | uniq -c )"
                # "uniq" command: first argument in variable $pacui_cache_downgrade_counted is the number of times the package name appears and the second is the package name.

                # read line by line from variable $pacui_cache_downgrade_counted in while loop and save that line to variable $line
                pacui_downgrade="$(
                while read -r line && [[ -n "$line" ]]
                do

                    # attention, the following variables can be empty:
                    temp1="$( echo "$line" | awk '{print $1}' )"                    # this variable is the no. of times a package has to be downgraded
                    temp2="$( echo "$line" | awk '{print $2}' )"                    # this variable is the package name to be downgraded

                    if [[ -n "$temp2" ]]                                            # checks, if length of string is non-zero ("-n" conditional bash expression is the opposite of "-z" (check, whether length of string is zero))
                    then
                        # write list with all versions of package in cache into file ${pacui_tmp_downgrade} (sorted - newest package version is on top)
                        find "$cache" -name "${temp2}-[0-9a-z.-_]*.pkg.tar.[gx]z" | sort -r > ${pacui_tmp_downgrade}

                        if [[ "$AUR_Helper" == "pacaur" ]]                          # checks, whether file "pacaur" exists, i.e. pacaur is installed
                        then
                            # do the same as below for files from pacaur's cache directory.
                            # the problem here is that AUR packages are not named/numbered in a constant and easy sortable way. therefore, we search for all files and output their modification date in an easy searchable format (and then, the file name).
                            # then, "grep" is used to get only package files. then, the list is sorted (by the modification date).
                            # awk gets rid of the modification date. grep filters for the file name $temp2.
                            find "$cachePACAUR" -maxdepth 2 -mindepth 2 -type f -printf "%T+\t%p\n" | grep ".pkg.tar.[gx]z$" | sort -rn | awk '{print $2}' | grep "$temp2""-" >> ${pacui_tmp_downgrade}
                        fi

                        # temp3 is supposed to be "2p" when temp1=1 and "3p" when temp1=2 ...  --> needed for "sed" command below
                        temp3="$(( temp1 + 1 ))p"

                        # the next line moves the $((temp3-1))-th version below the currently installed package version to file ${pacui_downgrade}. if no such old version is available, nothing happens.
                        # this command determines the currently installed verions of package $temp2:  pacman -Q "$temp2" | awk '{print $2}'
                        grep "$( pacman -Q "$temp2" | awk '{print $2}' )" -A 100 "$pacui_tmp_downgrade" | sed -n "$temp3"
                    fi

                done < <(echo "${pacui_cache_downgrade_counted}") )"

                # remove temporary file. it is no longer needed and should not be left on the system.
                unlink ${pacui_tmp_downgrade}

                # sort output to suit pacman's syntax. pacman needs a list of package names separated by single spaces.
                pkgD="$( echo "${pacui_downgrade}" | sort -u | paste -sd " ")"

                # the following if-statement prevents the following error, in case there is no older package version available: "error: no targets specified (use -h for help)"
                if [[ -n "$pkgD" ]]                                                 # checks, if variable is not empty
                then
                    # downgrade packages by manually installing them: (sudo pacman -U --noconfirm --color always )
                    sudo pacman "$argument_flag"-U ${pkgD} --color always           # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkgD variable breaks AUR helper and pacman
                fi

            fi


            # 5. filter variable $pacui_cache_packages file for the word "downgraded" and write package names to variable $pacui_cache_upgrade
            # variable $pacui_cache_packages contains list of package names to be downgraded!
            pacui_cache_upgrade="$( echo "${pacui_cache_packages}" | awk '/downgraded/ {print $2}' )"

            if [[ -n "$pacui_cache_upgrade" ]]                                      # this if-condition avoids error messages when no package gets upgraded (and variables $pacui_cache_upgrade is empty)
            then

                # here, it is impossible to use variables instead of temporary files. therefore, the temporary files should be as tamper-proof as possible.
                # Create temp file with mktemp command (Important for security). the XXXXXXXX indicates numbers assigned by "mktemp" command.
                # the XXXXXXXXX numbers make it necessary to call the temporary file in the code below with "${pacui_tmp_upgrade}" (without ")!
                pacui_tmp_upgrade="$( mktemp /tmp/pacui-tmp-upgrade.XXXXXXXX )"

                # add trap command to immediately remove upon ctrl+c (or any other case this function quits in the middle) for security purposes
                # this is the normal syntax for "trap" command.
                trap 'unlink ${pacui_tmp_upgrade}' EXIT

                # first, count the number of times the package name appears in file ${pacui_cache_upgrade}:
                pacui_cache_upgrade_counted="$( echo "${pacui_cache_upgrade}" | sort | uniq -c )"
                # "uniq" command: first argument in variable $pacui_cache_upgrade_counted is the number of times the package name appears and the second is the package name.

                # read line by line from variable $pacui_cache_upgrade_counted in while loop and save that line to variable $line
                pacui_upgrade="$(
                while read -r line && [[ -n "$line" ]]
                do

                    # attention, the following variables can be empty:
                    temp1="$( echo "$line" | awk '{print $1}' )"                    # this variable is the no. of times a package has to be upgraded
                    temp2="$( echo "$line" | awk '{print $2}' )"                    # this variable is the package name to be upgraded

                    if [[ -n "$temp2" ]]   # checks, if length of string is non-zero: "-n" conditional bash expression is the opposite of "-z", which checks whether length of string is zero
                    then
                        # write list with all versions of package in cache into file ${pacui_tmp_upgrade} - sorted by newest package version
                        find "$cache" -name "${temp2}-[0-9a-z.-_]*.pkg.tar.[gx]z" | sort -r > ${pacui_tmp_upgrade}

                        if [[ "$AUR_Helper" == "pacaur" ]]                          # checks, whether file "pacaur" exists, i.e. pacaur is installed
                        then
                            # do the same as below for files from pacaur's cache directory.
                            # the problem here is that AUR packages are not named/numbered in a constant and easy sortable way. therefore, we search for all files and output their modification date in an easy searchable format (and then, the file name).
                            # then, "grep" is used to get only package files. then, the list is sorted (by the modification date).
                            # awk gets rid of the modification date. grep filters for the file name $temp2.
                            find "$cachePACAUR" -maxdepth 2 -mindepth 2 -type f -printf "%T+\t%p\n" | grep ".pkg.tar.[gx]z$" | sort -rn | awk '{print $2}' | grep "$temp2""-" >> ${pacui_tmp_upgrade}
                        fi

                        # temp3 is supposed to be "2p" when temp1=1 and "3p" when temp1=2 ...  --> needed for "sed" command below
                        temp3="$(( temp1 + 1 ))p"

                        # the next line moves the $((temp3-1))-th version below the currently installed package version to file $pacui_upgrade. if no such old version is available, nothing happens.
                        # this command determines the currently installed versions of package $temp2:  pacman -Q "$temp2" | awk '{print $2}'
                        grep "$( pacman -Q "$temp2" | awk '{print $2}' )" -B 100 "$pacui_tmp_upgrade" | tac | sed -n "$temp3"
                    fi

                done < <(echo "${pacui_cache_upgrade_counted}") )"

                # remove temporary file. it is no longer needed an should not be left on the system.
                unlink ${pacui_tmp_upgrade}

                # sort output to suit pacman's syntax. pacman needs a list of package names separated by single spaces.
                pkgU="$( echo "${pacui_upgrade}" | sort -u | paste -sd " " )"

                # the following if-statement prevents the following error, in case there is no older package version available: "error: no targets specified (use -h for help)"
                if [[ -n "$pkgU" ]]                                                 # checks, if variable is not empty
                then
                    # upgrade packages by manually installing them: (sudo pacman -U --noconfirm --color always )
                    sudo pacman "$argument_flag"-U ${pkgU} --color always           # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkgU variable breaks AUR helper and pacman
                fi

            fi


        fi
}


# Fix Pacman Errors
# this function provides core functionality of "Fix Pacman Errors". it is separated into multiple parts. most parts begin (or contain) an introducing "echo" command or comment, which explains what is being done. the help page explains the core functionality of every part in detail, too.
function func_f
{
        # delete only pacui-related packages in /tmp directory. if other files are deleted, linux starts to act strange!
        if ( sudo find /tmp/ -iname 'pacui*' -print -quit | grep pacui -q )         # check if "pacui*" file or directory is found in /tmp/ directory and print its first path. use a quiet "grep" to have a success condition.
        then
            echo " deleting PacUI cache ..."
            sudo rm -r /tmp/pacui*                                                  # here the "rm -r" command is needed, because both directories and files have to be removed. "unlink" and "rmdir" do not work here.
            echo ""
        fi


        # remove pacman database lock file
        local dbpath
        dbpath="$( awk -F '=' '/^DBPath/ {gsub(" ","",$2); print $2}' '/etc/pacman.conf' )"               # extract path of database file from pacman.conf
        if [[ -z "$dbpath" ]]                                                       # if "dbpath" variable is empty (exact: if output of $dbpath is zero)
        then
            dbpath="/var/lib/pacman/"                                               # default database path
        fi

        if [[ -f "$dbpath"db.lck ]]                                                 # check, if pacman database lock file "db.lck" exists
        then
            echo " removing pacman database lock ..."
            sudo unlink "$dbpath"db.lck                                             # remove file
            echo ""
        fi
        unset dbpath


        # check for "pacman-mirrors" or "reflector" packages. one of those is needed!
        if [[ -f /usr/bin/pacman-mirrors ]] || [[ -f /usr/bin/reflector ]]
        then
            echo " fixing mirrors (which can take a while) ..."
            # do this, if system uses pacman-mirrors (default in Manjaro)
            if [[ -f /usr/bin/pacman-mirrors ]]
            then
                sudo pacman-mirrors -f 0 && sudo pacman -Syy                        # choose mirrors server (with up-to-date packages) with lowest ping from all available mirrors and sync database.
                # here, "pacman -Syy" is used to sync to the (potentially new) repository server. this is important!
                # but "pacman -Syy" (when pacman -S is executed later on) can result in a partially updated system. this cannot be prevented here, because it is possible the user's keys are corrupted and he is no longer able to install/update any packages.
            fi
            # do this, if system uses reflector (default on Arch Linux or distributions using Arch Linux mirrors/repo servers)
            if [[ -f /usr/bin/reflector ]]
            then
                sudo reflector --verbose --protocol https,ftps --age 5 --sort rate --save /etc/pacman.d/mirrorlist && sleep 10 && sudo pacman -Syy
            fi
            echo ""
        fi


        local server
        # extract mirror/repository server url from /etc/pacman.d/mirrorlist file with command:
        server="$( grep "^Server =" -m 1 "/etc/pacman.d/mirrorlist" | awk -F '=' '{print $2}' | awk -F '$' '{print $1}' )"

        # check, whether there is a connection to the mirror/repository server. this is needed for package download/update!
        if ! ( curl --silent --fail $(echo "$server") &>/dev/null )                 # ATTENTION: the curl command needs   $(echo "$server")   without quotes!        # the "curl --silent --fail" command gets executed in any case in order to check its output.
        then

            # print error message, if there is no connection to a mirror/repository server and quit
            echo
            echo -e " \e[41m Either there is something wrong with your internet connection or with your mirror/repository server: $server \e[0m"        # writing the $server variables in quotes (" or ') does not work! using ' for echo command does not work either!
            echo -e " \e[1;41m Please make sure both are ok and rerun this part of PacUI. \e[0m"
            echo

        else

            # the following command sometimes prevents an error connecting to the key server
            echo
            echo " sudo dirmngr </dev/null ..."
            # suppress error output with "2>/dev/null"
            if ! ( sudo dirmngr </dev/null 2>/dev/null )                            # check, if any critical errors occurred in command in parenthesis
            then
                echo
                echo -e " \e[41m The following dirmngr errors have occured: \e[0m"
                sudo dirmngr </dev/null
            fi
            echo


            echo " cleaning pacman cache ..."
            # if keyring was broken, all non-installed (and potentially newer) packages cannot be manually installed anymore, because of key mismatch. solution: delete all non-installed packages from cache here:
            sudo pacman -Sc --noconfirm
            echo ""


            #set +u
            if [[ -f $HOME/.gnupg/gpg.conf ]]                                       # check, whether file $HOME/.gnupg/gpg.conf exists
            then
                if ! ( grep "/etc/pacman.d/gnupg/pubring.gpg" "$HOME/.gnupg/gpg.conf" &>/dev/null )             # check, whether string "/etc/pacman.d/gnupg/pubring.gpg" is already present in file "$HOME/.gnupg/gpg.conf".
                then

                    echo " trusting keys from system developers ..."

                    # sometimes, people get a "missing key" error about keys they have already installed. this can be confusing
                    # automatically trust all keys from arch linux trusted users (and manjaro developers) - both for packages from the repositories and packages from the AUR.
                    # there are 2 different places on system for keys to be stored. include pacman's keys in your private collection of keys, which is used when installing (i.e. veritying) packages from the AUR.
                    {
                    echo "# ";
                    echo "# Automatically trust all keys in Pacman's keyring: ";
                    echo "keyring /etc/pacman.d/gnupg/pubring.gpg";
                    echo ""
                    } >> "$HOME/.gnupg/gpg.conf"

                fi
            fi
            #set -u


            echo " trying to update system conventionally ..."
            if ! ( sudo pacman -Syuu --noconfirm)
            then

                echo
                echo -e " \e[41m Conventional update(s) failed. Please read the error message(s) above. \e[0m"
                echo -e " \e[1;41m Did the update fail because of key or keyring errors? [y|N] \e[0m"
                read -r -n 1 -e answer                                              # save user input in "answer" variable (only accept 1 character as input)

                case ${answer:-n} in                                                # if ENTER is pressed, the variable "answer" is empty. if "answer" is empty, its default value is "n".

                    y|Y|yes|YES|Yes )                                               # do this, if "answer" is y or Y or yes or YES or Yes

                        echo
                        echo -e " Lowering pacman securities (in case keyring is broken) ..."
                        # first, make a backup of /etc/pacman.conf, which preserves all file permissions and other attributes. "cp -f" overwrites the target file, if it already exists.
                        # the second command replaces all "SigLevel = ....." strings with "SigLevel = Never" in the /etc/pacman.conf file. This change deactivates all key signature checks in pacman.
                        # general comment about "sed" usage in scripts: in order to avoid breakage, it is recommended to escape all the following characters /\.*[]^$ with a \ character!
                        sudo cp --preserve=all -f /etc/pacman.conf /etc/pacman.conf.backup && sudo sed -i 's/SigLevel[ ]*=[A-Za-z ]*/SigLevel = Never/' '/etc/pacman.conf'
                        # if something goes wrong in the following code, the SigLevel is never raised back and we would mess on a user's system. THIS HAS TO BE PREVENTED! solution: use trap, which reverses our changes in /etc/pacman.conf file whenever pacui quits unexpectedly:
                        trap "sudo cp --preserve=all -f /etc/pacman.conf.backup /etc/pacman.conf && sudo rm /etc/pacman.conf.backup" EXIT
                        echo ""


                        echo " trying to update system manually without checking keys ..."
                        # if keyring is broken, updates (without checking keys) can be manually installed now.
                        if ! ( sudo pacman -Syu )                                   # this last update attempt does not use "--noconfirm" and allows user intervention
                        then

                            echo
                            echo -e " \e[41m Update still not successful. PacUI is unable to fix the system automatically. \e[0m"
                            echo -e " \e[41m Read all error messages carefully and try to fix them yourself. \e[0m"
                            echo

                            echo " raising pacman securities back ..."
                            # This command will revert the change from above: overwrite (modified) /etc/pacman.conf file with its (unmodified) backup. then, the backup file is deleted.
                            sudo cp --preserve=all -f /etc/pacman.conf.backup /etc/pacman.conf && sudo rm /etc/pacman.conf.backup
                            # now, the trap is longer needed. reset trap:
                            trap − EXIT
                            echo ""

                        else

                            echo
                            echo -e " \e[41m It seems the update succeded because of the temporary lack of key checks. \e[0m"
                            echo -e " \e[1;41m Should PacUI prevent all future key / keyring errors? [y|N] \e[0m"
                            read -r -n 1 -e answer2                                 # save user input in "answer2" variable (only accept 1 character as input)

                            case ${answer2:-n} in                                   # if ENTER is pressed, the variable "answer2" is empty. if "answer2" is empty, its default value is "n".

                                y|Y|yes|YES|Yes )                                   # do this, if "answer2" is y or Y or yes or YES or Yes

                                    # remove gnupg including all keys
                                    if [[ -f /etc/pacman.d/gnupg ]]
                                    then
                                        echo
                                        echo " sudo rm -r /etc/pacman.d/gnupg ..."
                                        sudo rm -r /etc/pacman.d/gnupg &>/dev/null
                                    fi

                                    echo
                                    echo " reinstalling gnupg ..."
                                    sudo pacman -Syu gnupg --noconfirm
                                    echo ""


                                    echo " installing all necessary keyrings ..."
                                    # This command will install all keyrings from avialable current repository
                                    sudo pacman -Syu $( pacman -Qsq '(-keyring)' | grep -v -i -E '(gnome|python|debian)' | paste -sd " " ) --noconfirm                    # ATTENTION: (i do not know why but) using quotes (" symbols) around $(...) does not work!
                                    echo ""


                                    echo " raising pacman securities back ..."
                                    # This command will revert the change from above: overwrite (modified) /etc/pacman.conf file with its (unmodified) backup. then, the backup file is deleted.
                                    sudo cp --preserve=all -f /etc/pacman.conf.backup /etc/pacman.conf && sudo rm /etc/pacman.conf.backup
                                    # now, the trap is longer needed. reset trap:
                                    trap − EXIT
                                    echo ""


                                    echo " initializing and populating keyring ..."
                                    sudo pacman-key --init && echo "" && sudo pacman-key --populate $( pacman -Qsq '(-keyring)' | grep -v -i -E '(gnome|python|debian)' | sed 's/-keyring//' | paste -sd ' ' )          # ATTENTION: (i do not know why but) using quotes (" symbols) around $(...) does not work!
                                    echo ""


                                    echo " updating file database ..."
                                    sudo pacman -Fyy
                                    echo ""
                                ;;


                                n|N|no|NO|No )                                      # do this, if "answer2" is n or N or no or NO or No

                                    echo
                                    echo " do not fix keyring(s) ..."
                                    echo


                                    echo " raising pacman securities back ..."
                                    # This command will revert the change from above: overwrite (modified) /etc/pacman.conf file with its (unmodified) backup. then, the backup file is deleted.
                                    sudo cp --preserve=all -f /etc/pacman.conf.backup /etc/pacman.conf && sudo rm /etc/pacman.conf.backup
                                    # now, the trap is longer needed. reset trap:
                                    trap − EXIT
                                    echo ""


                                    echo " updating file database ..."
                                    sudo pacman -Fyy
                                    echo ""
                                ;;


                                * )                                                 # do this, if "answer2" is neither "no" nor "yes".
                                    echo
                                    echo -e " \e[41m Answer not recognized. Please try again with a valid answer. \e[0m"
                                    echo -e " \e[41m All attempts to fix your system were stopped. \e[0m"
                                    echo


                                    echo " raising pacman securities back ..."
                                    # This command will revert the change from above: overwrite (modified) /etc/pacman.conf file with its (unmodified) backup. then, the backup file is deleted.
                                    sudo cp --preserve=all -f /etc/pacman.conf.backup /etc/pacman.conf && sudo rm /etc/pacman.conf.backup
                                    # now, the trap is longer needed. reset trap:
                                    trap − EXIT
                                    echo ""
                                ;;
                            esac
                        fi
                    ;;


                    n|N|no|NO|No )                                                  # do this, if "answer" is n or N or no or NO or No

                        if [[ "$(cat /proc/1/comm)" == "systemd" ]]                 # if init system is systemd
                        then

                            # set almost correct time (while ignoring time zone and daylight saving time):
                            # 1. stop running NTPD service (and ignore output in case NTPD is not installed):
                            echo
                            echo " sudo systemctl stop ntpd.service ..."
                            sudo systemctl stop ntpd.service &>/dev/null
                            echo ""


                            # 2. download and install ntp:
                            echo " installing ntp ..."
                            sudo pacman -S ntp --noconfirm
                            # if "sudo pacman -Syu --noconfirm" (above) was not completed successfully, a partial update is done here in order to try to fix the update machanism.
                            # if "sudo pacman -Syu --noconfirm" (without checking keys) (below) is successful, the system will not be left in a partially updated state!
                            echo ""


                            # 3. start NTP daemon and set system clock
                            # 4. wait for 10 seconds (maximum time needed for system clock to set to new time)
                            # 5. write time from system clock to hardware clock
                            echo " setting clock (which can take a while) ..."
                            sudo ntpd -qg && sleep 10 && sudo hwclock -w
                            echo ""

                        fi


                        echo " trying to update system manually again ..."
                        if ! ( sudo pacman -Syuu )                                   # this last update attempt does not use "--noconfirm" and allows user intervention
                        then
                            echo
                            echo -e " \e[41m Update still not successful. PacUI is unable to fix the system automatically. \e[0m"
                            echo -e " \e[41m Read all error messages carefully and try to fix them yourself. \e[0m"
                            echo

                        else
                            echo
                            echo " updating file database ..."
                            sudo pacman -Fyy
                            echo ""

                        fi
                    ;;


                    * )                                                             # do this, if "answer" is neither "no" nor "yes".
                        echo
                        echo -e " \e[41m Answer not recognized. Please try again with a valid answer. \e[0m"
                        echo -e " \e[41m All attempts to fix your system were stopped. \e[0m"
                    ;;
                esac                                                                # end of "case" loop

            else

                # do this, if conventional system update was successful
                echo
                echo " updating file database ..."
                sudo pacman -Fyy
                echo ""

            fi

        fi
}


# Edit Config Files
# this function provides core functionality of "Edit Config Files". the help page provides additional explanations.
function func_c
{
        # here, it is impossible to use variables instead of temporary files. therefore, the temporary files should be as tamper-proof as possible.
        # Create temp file with mktemp command (Important for security). the XXXXXXXX indicates numbers assigned by "mktemp" command.
        # the XXXXXXXXX numbers make it necessary to call the temporary file in the code below with ${pacui_config} !
        pacui_config="$( mktemp /tmp/pacui-config.XXXXXXXX )"

        # add trap command to immediately remove upon ctrl+c (or any other case this function quits in the middle) for security purposes
        # this is the normal syntax for "trap" command:
        trap 'unlink ${pacui_config}' EXIT

        #set +u

        # if file /etc/tlp exists, push string "/etc/tlp              Configure power management." into ${pacui_config} file. there are enough spaces added to avoid users seeing file/folder description:
        [[ -f /etc/tlp ]]                               && echo -e "/etc/tlp                                                                                                                                                                                                                                                         Configure power management in file:" >> ${pacui_config}
        [[ -f /etc/default/cpupower ]]                  && echo -e "/etc/default/cpupower                                                                                                                                                                                                                                            Configure CPU power management in file:" >> ${pacui_config}
        [[ -f /etc/profile.d/freetype2.sh ]]            && echo -e "/etc/profile.d/freetype2.sh                                                                                                                                                                                                                                      Configure TrueType interpreter (including Infinality mode) in file:" >> ${pacui_config}
        [[ -f /etc/pulse/daemon.conf ]]                 && echo -e "/etc/pulse/daemon.conf                                                                                                                                                                                                                                           Configure global PulseAudio daemon in file:" >> ${pacui_config}
        [[ -f /etc/pulse/default.pa ]]                  && echo -e "/etc/pulse/default.pa                                                                                                                                                                                                                                            Configure PulseAudio modules in file:" >> ${pacui_config}
        [[ -f /etc/asound.conf ]]                       && echo -e "/etc/asound.conf                                                                                                                                                                                                                                                 Configure ALSA in file:" >> ${pacui_config}
        [[ -f $HOME/.gnupg/gpg.conf ]]                  && echo -e "\e[31m$HOME/.gnupg/gpg.conf                                                                                                                                                                                                                                      Configure GnuPG user settings in file:\e[0m" >> ${pacui_config}
        [[ -f /etc/pacman.conf ]]                       && echo -e "\e[31m/etc/pacman.conf                                                                                                                                                                                                                                           Configure Pacman in file:\e[0m" >> ${pacui_config}
        [[ -f /etc/pacman-mirrors.conf ]]               && echo -e "/etc/pacman-mirrors.conf                                                                                                                                                                                                                                         Configure Manjaro's pacman-mirrors in file:" >> ${pacui_config}
        [[ -f /etc/xdg/reflector/reflector.conf ]]      && echo -e "/etc/xdg/reflector/reflector.conf                                                                                                                                                                                                                                Configure Arch Linux's reflector in file:" >> ${pacui_config}
        [[ -f /etc/pacman.d/mirrorlist ]]               && echo -e "/etc/pacman.d/mirrorlist                                                                                                                                                                                                                                         Configure mirror list manually in file:" >> ${pacui_config}
        [[ -f $HOME/.config/trizen/trizen.conf ]]       && echo -e "$HOME/.config/trizen/trizen.conf                                                                                                                                                                                                                                 Configure Trizen in file:" >> ${pacui_config}
        [[ -f $HOME/.config/yay/config.json ]]          && echo -e "$HOME/.config/yay/config.json                                                                                                                                                                                                                                    Configure Yay in file:" >> ${pacui_config}
        [[ -f $XDG_CONFIG_DIRS/pacaur/config ]]         && echo -e "$XDG_CONFIG_DIRS/pacaur/config                                                                                                                                                                                                                                   Configure Pacaur in file:" >> ${pacui_config}
        [[ -f $HOME/.config/pikaur.conf ]]              && echo -e "$HOME/.config/pikaur.conf                                                                                                                                                                                                                                        Configure Pikaur in file:" >> ${pacui_config}
        [[ -f /etc/pakku.conf ]]                        && echo -e "/etc/pakku.conf                                                                                                                                                                                                                                                  Configure Pakku in file:" >> ${pacui_config}
        [[ -f $XDG_CONFIG_HOME/aurman/aurman_config ]]  && echo -e "$XDG_CONFIG_HOME/aurman/aurman_config                                                                                                                                                                                                                            Configure Aurman in file:" >> ${pacui_config}
        [[ -f $HOME/.config/aurman/aurman_config ]]     && echo -e "$HOME/.config/aurman/aurman_config                                                                                                                                                                                                                               Configure Aurman in fallback file:" >> ${pacui_config}
        [[ -f $XDG_CONFIG_HOME/paru/paru.conf ]]        && echo -e "$XDG_CONFIG_HOME/paru/paru.conf                                                                                                                                                                                                                                  Configure Paru in file:" >> ${pacui_config}
        [[ -f $HOME/.config/paru/paru.conf ]]           && echo -e "$HOME/.config/paru/paru.conf                                                                                                                                                                                                                                     Configure Paru in file:" >> ${pacui_config}
        [[ -f /etc/pamac.conf ]]                        && echo -e "/etc/pamac.conf                                                                                                                                                                                                                                                  Configure Pamac in file:" >> ${pacui_config}
        [[ -f /etc/makepkg.conf ]]                      && echo -e "/etc/makepkg.conf                                                                                                                                                                                                                                                Configure package compilation in file:" >> ${pacui_config}
        [[ -d /usr/lib/NetworkManager/conf.d ]]         && echo -e "/usr/lib/NetworkManager/conf.d/                                                                                                                                                                                                                                  Configure NetworkManager in files:" >> ${pacui_config}
        [[ -f /etc/resolv.conf ]]                       && echo -e "/etc/resolv.conf                                                                                                                                                                                                                                                 Configure DNS servers in file:" >> ${pacui_config}
        [[ -f /etc/hostname ]]                          && echo -e "/etc/hostname                                                                                                                                                                                                                                                    Configure your network hostname in file:" >> ${pacui_config}
        [[ -f /etc/hosts ]]                             && echo -e "/etc/hosts                                                                                                                                                                                                                                                       Configure local DNS in file:" >> ${pacui_config}
        [[ -f /etc/environment ]]                       && echo -e "/etc/environment                                                                                                                                                                                                                                                 Configure system-wide environment variables in file:" >> ${pacui_config}
        [[ -f /etc/locale.conf ]]                       && echo -e "/etc/locale.conf                                                                                                                                                                                                                                                 Configure regional standards in file:" >> ${pacui_config}
        [[ -f /etc/vconsole.conf ]]                     && echo -e "/etc/vconsole.conf                                                                                                                                                                                                                                               Configure virtual console in file:" >> ${pacui_config}
        [[ -f /etc/slim.conf ]]                         && echo -e "/etc/slim.conf                                                                                                                                                                                                                                                   Configure slim display manager in file:" >> ${pacui_config}
        [[ -f /etc/lightdm.conf ]]                      && echo -e "/etc/lightdm.conf                                                                                                                                                                                                                                                Configure lightdm display manager in file:" >> ${pacui_config}
        [[ -f /etc/sddm.conf ]]                         && echo -e "/etc/sddm.conf                                                                                                                                                                                                                                                   Configure sddm display manager in file:" >> ${pacui_config}
        [[ -f /etc/mdm/mdm.conf ]]                      && echo -e "/etc/mdm/mdm.conf                                                                                                                                                                                                                                                Configure mdm display manager in file:" >> ${pacui_config}
        [[ -f /etc/lxdm/lxdm.conf ]]                    && echo -e "/etc/lxdm/lxdm.conf                                                                                                                                                                                                                                              Configure lxdm display manager in file:" >> ${pacui_config}
        [[ -f /etc/gdm/custom.conf ]]                   && echo -e "/etc/gdm/custom.conf                                                                                                                                                                                                                                             Configure gdm display manager in file:" >> ${pacui_config}
        [[ -f /etc/entrance/entrance.conf ]]            && echo -e "/etc/entrance/entrance.conf                                                                                                                                                                                                                                      Configure entrance display manager in file:" >> ${pacui_config}
        [[ -f /etc/conf.d/xdm ]]                        && echo -e "/etc/conf.d/xdm                                                                                                                                                                                                                                                  Configure xdm display manager in file:" >> ${pacui_config}
        [[ -f /etc/updatedb.conf ]]                     && echo -e "/etc/updatedb.conf                                                                                                                                                                                                                                               Configure database of locate in file:" >> ${pacui_config}
        [[ -f $HOME/.bashrc ]]                          && echo -e "$HOME/.bashrc                                                                                                                                                                                                                                                    Configure bash shell in file:" >> ${pacui_config}
        [[ -f $HOME/.zshrc ]]                           && echo -e "$HOME/.zshrc                                                                                                                                                                                                                                                     Configure zsh shell in file:" >> ${pacui_config}
        [[ -f $HOME/.config/fish ]]                     && echo -e "$HOME/.config/fish/                                                                                                                                                                                                                                              Configure fish shell in file:" >> ${pacui_config}
        [[ -f $HOME/.xinitrc ]]                         && echo -e "\e[31m$HOME/.xinitrc                                                                                                                                                                                                                                             Configure X server startup in file:\e[0m" >> ${pacui_config}
        [[ -f $HOME/.Xresources ]]                      && echo -e "\e[31m$HOME/.Xresources                                                                                                                                                                                                                                          Configure X client applications in file:\e[0m" >> ${pacui_config}
        [[ -f /etc/fstab ]]                             && echo -e "\e[31m/etc/fstab                                                                                                                                                                                                                                                 Configure file system mount table in file:\e[0m" >> ${pacui_config}
        [[ -f /etc/crypttab ]]                          && echo -e "\e[31m/etc/crypttab                                                                                                                                                                                                                                              Configure encrypted file system mount table in file:\e[0m" >> ${pacui_config}
        [[ -f /etc/sudoers ]]                           && echo -e "\e[31m/etc/sudoers                                                                                                                                                                                                                                               Configure sudo in file:\e[0m" >> ${pacui_config}
        [[ -d /etc/udev/rules.d/ ]]                     && echo -e "/etc/udev/rules.d/                                                                                                                                                                                                                                               Configure device manager for Linux kernel in these files:" >> ${pacui_config}
        [[ -f /etc/systemd/swap.conf ]]                 && echo -e "/etc/systemd/swap.conf                                                                                                                                                                                                                                           Configure systemd swap in file:" >> ${pacui_config}
        [[ -f /etc/systemd/logind.conf ]]               && echo -e "/etc/systemd/logind.conf                                                                                                                                                                                                                                         Configure systemd user logins in file:" >> ${pacui_config}
        [[ -f /etc/systemd/journald.conf ]]             && echo -e "/etc/systemd/journald.conf                                                                                                                                                                                                                                       Configure systemd logging in file:" >> ${pacui_config}
        [[ -f /etc/systemd/coredump.conf ]]             && echo -e "/etc/systemd/coredump.conf                                                                                                                                                                                                                                       Configure systemd coredumps in file:" >> ${pacui_config}
        [[ -f /etc/systemd/system.conf ]]               && echo -e "/etc/systemd/system.conf                                                                                                                                                                                                                                         Configure systemd system in file:" >> ${pacui_config}
        [[ -f /etc/systemd/timesyncd.conf ]]            && echo -e "/etc/systemd/timesyncd.conf                                                                                                                                                                                                                                      Configure systemd-timesyncd in file:" >> ${pacui_config}
        [[ -f /etc/systemd/user.conf ]]                 && echo -e "/etc/systemd/user.conf                                                                                                                                                                                                                                           Configure systemd user units in file:" >> ${pacui_config}
        [[ -d /usr/lib/systemd/system  ]]               && echo -e "/usr/lib/systemd/system/                                                                                                                                                                                                                                         Configure systemd in these files:" >> ${pacui_config}
        [[ -d /usr/lib/systemd/network  ]]              && echo -e "/usr/lib/systemd/network/                                                                                                                                                                                                                                        Configure systemd-networkd in these files:" >> ${pacui_config}
        [[ -d /etc/X11/xorg.conf.d ]]                   && echo -e "\e[31m/etc/X11/xorg.conf.d/                                                                                                                                                                                                                                      Configure Xorg display server in these files:\e[0m" >> ${pacui_config}
        [[ -f $HOME/.config/weston.ini ]]               && echo -e "$HOME/.config/weston.ini                                                                                                                                                                                                                                         Configure Weston compositor in file:" >> ${pacui_config}
        [[ -d /usr/lib/sysctl.d ]]                      && echo -e "/usr/lib/sysctl.d/                                                                                                                                                                                                                                               Configure kernel parameter files at runtime:" >> ${pacui_config}
        [[ -d /etc/modules-load.d ]]                    && echo -e "\e[31m/etc/modules-load.d/                                                                                                                                                                                                                                       Configure Kernel module loading during boot in files:\e[0m" >> ${pacui_config}
        [[ -f /etc/mkinitcpio.conf ]]                   && echo -e "\e[31m/etc/mkinitcpio.conf                                                                                                                                                                                                                                       Configure initial ramdisk environment in file:\e[0m" >> ${pacui_config}
        [[ -f /etc/default/grub ]]                      && echo -e "\e[31m/etc/default/grub                                                                                                                                                                                                                                          Configure GRUB boot loader in file:\e[0m" >> ${pacui_config}
        [[ -f /boot/grub/custom.cfg ]]                  && echo -e "/boot/grub/custom.cfg                                                                                                                                                                                                                                            Configure custom GRUB entries in file:" >> ${pacui_config}
        [[ -f /boot/loader/loader.conf ]]               && echo -e "\e[31m/boot/loader/loader.conf                                                                                                                                                                                                                                   Configure systemd-boot boot loader in file:\e[0m" >> ${pacui_config}
        [[ -f /etc/sdboot-manage.conf ]]                && echo -e "\e[31m/etc/sdboot-manage.conf                                                                                                                                                                                                                                    Configure systemd-boot-manager in file:\e[0m" >> ${pacui_config}
        [[ -d /boot/loader/entries ]]                   && echo -e "\e[31m/boot/loader/entries/                                                                                                                                                                                                                                      Configure systemd-boot boot loader entries:\e[0m" >> ${pacui_config}
        [[ -f /boot/refind_linux.conf ]]                && echo -e "\e[31m/boot/refind_linux.conf                                                                                                                                                                                                                                    Configure rEFInd boot loader in file:\e[0m" >> ${pacui_config}
        [[ -f /boot/EFI/refind/refind.conf ]]           && echo -e "\e[31m/boot/EFI/refind/refind.conf                                                                                                                                                                                                                               Configure rEFInd boot loader in file:\e[0m" >> ${pacui_config}
        [[ -f /boot/EFI/CLOVER/config.plist ]]          && echo -e "\e[31m/boot/EFI/CLOVER/config.plist                                                                                                                                                                                                                              Configure Clover boot loader in file:\e[0m" >> ${pacui_config}
        [[ -f /boot/syslinux/syslinux.cfg ]]            && echo -e "\e[31m/boot/syslinux/syslinux.cfg                                                                                                                                                                                                                                Configure syslinux boot loaders in file:\e[0m" >> ${pacui_config}

        #set -u

        # create local variables
        local {file,check}

        pacui_tty_clean                                                             # clear terminal
        #set +e
        #set +E

        # echo -e "$( cat ${pacui_config} )"  -- this command interprets the ANSI escape sequences contained in ${pacui_config}.
        file="$( echo -e "$( cat ${pacui_config} )" |
            fzf -i --exact --no-sort --select-1 --ansi --cycle --query="$argument_input" --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,60%,wrap,<68(bottom,60%,wrap)' \
                --header="ENTER to edit file in text editor or select directory. ESC to quit." --prompt='Enter string to filter list > ' \
                --preview '
                    echo -e "\e[1m$(echo {2..}) $(echo {1})\e[0m"                   # display file/folder description ( {2..} = second to last field in selected line)
                    echo
                    if ( echo {1} | grep "/$" &>/dev/null )                         # check, if 1. field ends with a "/"" (= is a directory)
                    then
                        ls {1}                                                      # if directory is selected in fzf, display list of files in that directory

                    elif ( cat {1} &>/dev/null )
                    then
                        cat {1}                                                     # display file content, if no directory is selected. an error is displayed, when root privilges are required (because "sudo cat {1}" breaks fzf when password entry is required !!!)

                    else
                        echo "{1}: Read permission denied"

                    fi
                ' |
            awk '{print $1}'
        )"
        # the output of fzf is saved in the $file variable. $file can contain a filename (with its full path) or a directory (with its full path).

        pacui_tty_clean                                                             # clear terminal

        # we need a method to check, whether fzf is quit with ESC. if this happens, we should NOT open a text editor!
        check=1                                                                     # set initial value

        # only run the command inside the if-statement, if $file variable is not empty <-- this happens when fzf is quit with ESC or CTRL+C
        if [[ -n "$file" ]]                                                         # checks, if length of string is non-zero ("-n" conditional bash expression is the opposite of "-z" (check, whether length of string is zero))
        then
            # if $file contains a directory, another instance of fzf is opened to let the user choose the file (within the directory) he wants to edit:
            if ( echo "$file" | grep "/$" &>/dev/null )
            then

                # set $check to 0. 0 means a text editor will NOT open.
                check=0

                # attention: currently $file contains directory path and NOT the file name!
                # find $file -maxdepth 1 -xtype f  --  this command displays a list of files (including their full path) and symlinks to files (including their full path) in a directory given by $file.
                file="$( find "$file" -maxdepth 1 -xtype f | sort -u |
                    fzf -i --exact --no-sort --select-1 --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,60%,wrap,<68(bottom,60%,wrap)' \
                        --header="ENTER to edit file in text editor. ESC to quit." --prompt='Enter string to filter list > ' \
                        --preview '
                            echo -e "\e[1mFile preview: \e[0m"
                            cat {1}                                                 # {1} is the first field of the marked line in fzf. the file given by {1} is shown in the preview window.
                        '
                )"

                pacui_tty_clean                                                     # clear terminal

                if [[ -n "$file" ]]                                                 # $file is empty when fzf is quit with ESC.
                then
                    check=1                                                         # only set $check variable back to 1, if fzf is not quit with ESC.
                fi

            fi
        fi

        #set -e
        #set -E

        # because not all files should be opened the same way, multiple if-statements are needed to specify special conditions for opening files in a text editor:
        # only run the command inside the if-statement, if $file variable is not empty <-- this happens when fzf is quit with ESC or CTRL+C
        if [[ -n "$file" ]] && (( check == 1 ))                                     # here $check variable needs to be 1 in order to continue normally and display files in a text editor.
        then

            #set +u                                                                 # temporarily disable strict mode for environment variables. "$EDITOR" and "$SUDO_EDITOR" variable gets used extensibly in the following code!

            if [[ "$( echo "$file" | cut -c -6 )" == "/home/" ]]                    # check, if "file"'s first characters is "/home/"
            then
                # if $file starts with "/home/", open it in "EDITOR" (without root privileges).
                # "${EDITOR:-/usr/bin/nano}" outputs the content of the $EDITOR environment variable. if it is not set, '/usr/bin/nano' gets used.
                "${EDITOR:-/usr/bin/nano}" "$file"

            elif [[ "$file" == "/etc/sudoers" ]]
            then
                # the sudoers file should never be edited directly! if something goes wrong, sudo stops working. instead, visudo should be used. this is much safer.
                # if $SUDO_EDITOR variable does not exist, use 'nano'. visudo uses $SUDO_EDITOR variable by default!
                sudo SUDO_EDITOR="${SUDO_EDITOR:-/usr/bin/nano}" visudo

            elif [[ "$file" == "/etc/pacman.d/mirrorlist" ]] || [[ "$file" == "/etc/pacman.conf" ]]
            then
                sudo "${EDITOR:-/usr/bin/nano}" "$file"
                sudo pacman "$argument_flag"-Syyu                                   # apply changes

            elif [[ "$file" == "/etc/pacman-mirrors.conf" ]]
            then
                sudo "${EDITOR:-/usr/bin/nano}" "$file"
                sudo pacman-mirrors -f 0 && sudo pacman "$argument_flag"-Syyu

            elif [[ "$file" == "/etc/pamac.conf" ]]
            then
                sudo "${EDITOR:-/usr/bin/nano}" "$file"
                pamac "$argument_flag"update --force-refresh

            elif [[ "$file" == "/etc/fstab" ]] || [[ "$file" == "/etc/crypttab" ]]
            then
                sudo "${EDITOR:-/usr/bin/nano}" "$file"
                sudo mount -a                                                       # mount all drives/partitions in /etc/fstab file. this shows immediately mistakes in your /etc/fstab file and prevents non-working systems.

            elif [[ "$file" == "/etc/mkinitcpio.conf" ]]
            then
                sudo "${EDITOR:-/usr/bin/nano}" "$file"

                echo -e " \e[1;41m Do you want to regenerate the initramfs and update /boot/grub/grub.cfg? [y|N] \e[0m"
                read -r -n 1 -e answer                                              # save user input in "answer" variable (only accept 1 character as input)

                case ${answer:-n} in                                                # if ENTER is pressed, the variable "answer" is empty. if "answer" is empty, its default value is "n".
                    y|Y|yes|YES|Yes )
                        sudo mkinitcpio -P && sudo grub-mkconfig -o /boot/grub/grub.cfg               # apply changes   # "grub-mkconfig -o /boot/grub/grub.cfg" == "udpate-grub" (in manjaro)
                    ;;

                    * )
                        echo -e " \e[1m Changes in /etc/mkinitcpio.conf will only be applied after initramfs and boot loader configuration have been regenerated! \e[0m"
                    ;;
                esac

            elif [[ "$file" == "/etc/default/grub" ]] || [[ "$file" == "/boot/grub/custom.cfg" ]]
            then
                sudo "${EDITOR:-/usr/bin/nano}" "$file"
                sudo grub-mkconfig -o /boot/grub/grub.cfg                           # apply changes   # "grub-mkconfig -o /boot/grub/grub.cfg" == "udpate-grub" (in manjaro)

            else
                # start "sudo nano $file" for all other files (not mentioned separately in elif-statements above)
                sudo "${EDITOR:-/usr/bin/nano}" "$file"
            fi

            #set -u

        fi

        # cleanup
        unlink ${pacui_config}                                                      # remove temporary file ${pacui_config}
        trap - EXIT                                                                 # disable trap, which was set above
}


# List Packages by Size
# this function provides core functionality of "List Packages by Size". the help page provides additional explanations.
function func_ls
{
        pacui_tty_clean                                                             # clear terminal
        #set +e
        #set +E

        # list all packages on local system sorted by their installed size using "expac" and "sort".
        # expac -H M -Q "%12m - \e[1m%n\e[0m"  displays size and name
        # "sort -n -r"  sorts list by number (with which every element begins).
        expac -H M -Q '%12m - \e[1m%n\e[0m' | sort -n -r |
            fzf -i --multi --exact --no-sort --ansi --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,60%,wrap,<72(bottom,60%,wrap)' \
                --header="Navigate with PageUp / PageDown. ESC to quit." --prompt='Enter string to filter list > ' \
                --preview '
                    echo -e "\e[1mInstalled package info: \e[0m"
                    pacman -Qi {4} --color always
                ' > /tmp/pacui-ls

        #set -e
        #set -E
        pacui_tty_clean                                                             # clear terminal
}


# =======================


# Force Update AUR
# this function provides core functionality of "Force Update AUR". the help page provides additional explanations.
function func_ua
{
        if [[ "$AUR_Helper" == "yay" ]]
        then
            yay $argument_flag-Syu --devel --needed                                 # ATTENTION: (i do not know why but) using quotes (" symbols) around $argument_flag breaks yay command for arguments (e.g. "pacui -u --noconfirm")

        elif [[ "$AUR_Helper" == "pikaur" ]]
        then
            pikaur "$argument_flag"-Syu --devel --needed

        elif [[ "$AUR_Helper" == "aurman" ]]
        then
            aurman "$argument_flag"-Syu --devel --needed

        elif [[ "$AUR_Helper" == "pakku" ]]
        then
            pakku "$argument_flag"-Syu --needed                                     # does not support "--devel" flag

        elif [[ "$AUR_Helper" == "trizen" ]]
        then
            trizen "$argument_flag"-Syu --devel --needed

        elif [[ "$AUR_Helper" == "paru" ]]
        then
            paru "$argument_flag"-Syu --devel --needed --color always

        elif [[ "$AUR_Helper" == "pacaur" ]]
        then
            pacaur "$argument_flag"-Syua --devel --needed --color always

        elif [[ "$AUR_Helper" == "pamac" ]]
        then
            pamac "$argument_flag"update -a --devel

        else
            echo -e " \e[41m No AUR helper has been found. Please install at least one supported AUR helper manually: \e[0m"
            echo -e " \e[1m  yay \e[0m"
            echo -e " \e[1m  pikaur \e[0m"
            echo -e " \e[1m  aurman \e[0m"
            echo -e " \e[1m  pakku \e[0m"
            echo -e " \e[1m  trizen \e[0m"
            echo -e " \e[1m  paru \e[0m"
            echo -e " \e[1m  pacaur \e[0m"
            echo -e " \e[1m  pamac \e[0m"

        fi
}


# List Installed from AUR
# this function provides core functionality of "List Installed from AUR". the help page provides additional explanations.
function func_la
{
        pacui_tty_clean                                                             # clear terminal
        #set +e
        #set +E

        # check, whether there is a connection to AUR server. this is needed for AUR package information. If there is no connection to AUR server, no AUR package info get displayed.
        if ( curl --silent --fail "https://aur.archlinux.org" &>/dev/null )         # the "curl --silent --fail" command gets executed in any case in order to check its output.
        then
            AurSserverIsUp="true"
        else
            AurSserverIsUp="false"
        fi

        # this command shows all packages from external, i.e. not in system repositories, sources:
        # packages from the AUR and manually installed packages
        # "pacman -Qm --color always"
        pacman -Qqm |
            fzf -i --multi --exact --no-sort --layout=reverse --bind=pgdn:half-page-down,pgup:half-page-up --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,60%,wrap,<68(bottom,60%,wrap)' \
                --header="List of manually installed packages. ESC to quit." --prompt='Enter string to filter list > ' \
                --preview '
                    echo -e "\e[1mInstalled package info: \e[0m"
                    pacman -Qi {} --color always
                    echo

                    if ( $(test '$AurSserverIsUp' = true) ) && ( $(test -n '$AUR_Helper') )             # preview window of fzf requires checking with "test": first, check whether internet connection is up. second, check if any AUR helper is installed.
                    then
                        echo -e "\e[1mAUR package info: \e[0m"

                        if test '$AUR_Helper' = "yay"
                        then
                            yay -Si {1} | grep -v "::"                              # grep command removes all errors displayed by yay

                        elif test '$AUR_Helper' = "pikaur"
                        then
                            pikaur -Si {1}

                        elif test '$AUR_Helper' = "aurman"                          # if {1} is neither locally installed nor a group, it is from the AUR. display info with AUR helper
                        then
                            aurman -Si {1} | grep -v "::"                           # grep command removes all errors displayed by aurman

                        elif test '$AUR_Helper' = "pakku"
                        then
                            pakku -Si {1}

                        elif test '$AUR_Helper' = "trizen"
                        then
                            trizen -Si {1}

                        elif test '$AUR_Helper' = "paru"
                        then
                            paru -Si {1} --color always | grep -v "\*\*.*\*\*"

                        elif test '$AUR_Helper' = "pacaur"
                        then
                            pacaur -Si {1} --color always | grep -v "::"            # grep command removes all errors displayed by pacaur

                        elif test '$AUR_Helper' = "pamac"
                        then
                            pamac info -a {1}

                        fi
                    fi
                ' > /tmp/pacui-la

        #set -e
        #set -E
        pacui_tty_clean                                                             # clear terminal
}


# =======================
# the following functions are hidden from the UI.


# Downgrade Packages
# this function provides core functionality of "Downgrade Packages". the help page provides additional explanations.
function func_d
{
        # check for "downgrade" package
        if [[ ! -f /usr/bin/downgrade ]]
        then

            echo -e " \e[41m No 'downgrade' package has been found. Please install it. Alternatively, use PacUI's 'Roll Back System' option. \e[0m"

        else

            # write list of all installed packages to file /tmp/pacui-packages-local . then add list of packages in system repositories to the bottom of /tmp/pacui-packages-local.
            expac -Q "%-33n    %d" > /tmp/pacui-packages-local
            expac -S "%-33n    %d" >> /tmp/pacui-packages-local

            local {pkg,pkg_downgrade}

            pacui_tty_clean                                                         # clear terminal
            #set +e
            #set +E

            pkg="$( sort -k1,1 -u /tmp/pacui-packages-local |
                fzf -i --multi --exact --no-sort --select-1 --bind=pgdn:half-page-down,pgup:half-page-up --query="$argument_input" --cycle --layout=reverse --margin=1 --info=inline --no-separator --no-unicode --preview-window='right,55%,wrap,<68(bottom,60%,wrap)' \
                    --header="TAB to (un)select. ENTER to downgrade. ESC to quit." --prompt='Enter string to filter list > ' \
                    --preview '
                        if ( pacman -Qq {1} &>/dev/null )                           # check, if selected line is a locally installed package
                        then
                            echo -e "\e[1mInstalled package info: \e[0m"
                            pacman -Qi {1} --color always                           # for local packages, local query is sufficient.

                        else
                            echo -e "\e[1mRepository package info: \e[0m"
                            pacman -Si {1} --color always                           # do this, if package is not locally installed

                        fi
                    ' |
                awk '{print $1}'
            )"

            #set -e
            #set -E
            pacui_tty_clean                                                         # clear terminal

            # $pkg contains package names below each other, but we need a list (in 1 line, space separated):
            pkg_downgrade="$(echo "$pkg" | paste -sd " ")"

            if [[ -n "$pkg" ]]
            then
                sudo downgrade "$argument_flag"$pkg_downgrade                       # ATTENTION: (i do not know why but) using quotes (" symbols) around $pkg_downgrade variable breaks AUR helper and pacman
            fi

        fi
}


# Search + Install from AUR
# this function provides core functionality of "Search + Install from AUR". the help page provides additional explanations.
function func_a
{
         local pkg

        if [[ -n "$argument_input" ]]                                               # checks, if length of string is non-zero ("-n" conditional bash expression is the opposite of "-z" (check, whether length of string is zero))
        then
            # do this if variable "$argument_input" is not empty:

            if [[ "$AUR_Helper" == "yay" ]]
            then
                yay "$argument_input"

            elif [[ "$AUR_Helper" == "pikaur" ]]
            then
                pikaur "$argument_input"

            elif [[ "$AUR_Helper" == "aurman" ]]
            then
                aurman "$argument_input"

            elif [[ "$AUR_Helper" == "pakku" ]]
            then
                pakku -Ss "$argument_input"

            elif [[ "$AUR_Helper" == "trizen" ]]
            then
                trizen "$argument_input"

            elif [[ "$AUR_Helper" == "paru" ]]
            then
                paru "$argument_input" --color always

            elif [[ "$AUR_Helper" == "pacaur" ]]
            then
                pacaur -Ss "$argument_input" --color always | grep -v "::"          # grep command removes errors being displayed in pacaur

            elif [[ "$AUR_Helper" == "pamac" ]]
            then
                pamac search -a "$argument_input"

            else
                echo -e " \e[41m No AUR helper has been found. Please install at least one supported AUR helper manually: \e[0m"
                echo -e " \e[1m  yay \e[0m"
                echo -e " \e[1m  pikaur \e[0m"
                echo -e " \e[1m  aurman \e[0m"
                echo -e " \e[1m  pakku \e[0m"
                echo -e " \e[1m  trizen \e[0m"
                echo -e " \e[1m  paru \e[0m"
                echo -e " \e[1m  pacaur \e[0m"
                echo -e " \e[1m  pamac \e[0m"

            fi

        else

            # do this if pacui is used with UI or no argument is specified in "pacui a" command:
            echo -e " \e[41m Enter (parts of) name and/or description of package to be searched. Then press ENTER. \e[0m"
            read -r pkg

            if [[ "$AUR_Helper" == "yay" ]]
            then
                yay "$pkg"

            elif [[ "$AUR_Helper" == "pikaur" ]]
            then
                pikaur "$pkg"

            elif [[ "$AUR_Helper" == "aurman" ]]
            then
                aurman "$pkg"

            elif [[ "$AUR_Helper" == "pakku" ]]
            then
                pakku -Ss "$pkg"

            elif [[ "$AUR_Helper" == "trizen" ]]
            then
                trizen "$pkg"

            elif [[ "$AUR_Helper" == "paru" ]]
            then
                paru "$pkg" --color always

            elif [[ "$AUR_Helper" == "pacaur" ]]
            then
                pacaur -Ss "$pkg" --color always | grep -v "::"                     # grep command removes errors being displayed in pacaur

            elif [[ "$AUR_Helper" == "pamac" ]]
            then
                pamac search -a "$pkg"

            else
                echo -e " \e[41m No AUR helper has been found. Please install at least one supported AUR helper manually: \e[0m"
                echo -e " \e[1m  yay \e[0m"
                echo -e " \e[1m  pikaur \e[0m"
                echo -e " \e[1m  aurman \e[0m"
                echo -e " \e[1m  pakku \e[0m"
                echo -e " \e[1m  trizen \e[0m"
                echo -e " \e[1m  paru \e[0m"
                echo -e " \e[1m  pacaur \e[0m"
                echo -e " \e[1m  pamac \e[0m"

            fi

        fi
}


# =======================
# 2 different help functions


# Help
# this function provides core functionality of "Help" page: Helpful text (including ANSI escapes) is written to /tmp/pacui-help file and read with "less".
function func_help
{
        # this "heredoc" command pushes all the following lines into "cat" (and "cat pushes it to file /tmp/pacui-help) until a line containing the "EOF" keyword is encountered
        cat > /tmp/pacui-help <<- "EOF"

\e[1mWelcome to PacUIs Help Page

PacUI is an interactive package manager for your command line terminal. It provides an easy user interface and uses Pacman and Yay/Pikaur/Aurman/Pakku/Trizen/Paru/Pacaur/Pamac-cli as back ends.

Navigate this help page with your Arrow Keys, PageUp/PageDown Keys, SpaceBar, or your Mouse Wheel. To search this Help Page, enter /<SEARCH TERM> and press ENTER. For example, enter the following (without quotes " ") in order to search for the word "update": "/update". Press N key to continue searching for other occurrences of "update". Search is not case sensitive. To exit this Help Page, press your Q key.
PacUI uses Fuzzy Finder (fzf) to display selectable lists, which can be easily searched by starting to type. Advanced users can even utilize regular expressions for it. Navigate fzf's list the same way you navigate this help page.


\e[1mHOME SCREEN
PacUI's home screen is split into three parts:
The first part focuses on updates, maintenance, installations, and removals of packages from system repositories and the Arch User Repository (AUR). It includes useful tools for these actions, too.
The second part includes options for fixing and configuring your system. Options, which can break your system, are marked in red.
The last part offers options exclusive to Arch User Repository (AUR) management.


\e[1m99 - HELP
Display this help page. A very shot summary of this help page can be displayed in your terminal with "pacui -h" or "pacui h".
Quit this help page by pressing the Q key.


\e[1m0 - QUIT
\e[36m"clear && exit"
This will quit PacUI and clear your terminal. Scroll up to see all terminal output of your last PacUI session.


\e[1m1 - UPDATE SYSTEM
\e[36m"yay -Syua"
\e[36m"sudo snap refresh" \e[0m(only if snapd is installed)
\e[36m"flatpak update -y" \e[0m(only if flatpak is installed)
The first command compares a list of all installed packages with package database on your system repository mirror/server. If an updated package is available from your system repositories, it will get downloaded and installed on your system.
Afterwards, all packages from the Arch User Repository (AUR), which have an updated PKGBUILD file, are downloaded, compiled, and installed.
If updates from system repositories fail, the user is offered the choice to update packages using \e[36m"sudo pacman -Syu --overwrite='*'"\e[0m.
\e[1mAttention\e[0m: When a new version of an AUR package is available, sometimes the PKGBUILD file is not updated. If you want to install the latest version of a single AUR package, (re-)install it with INSTALL PACKAGES. If you want to install the latest versions of ALL AUR packages use FORCE UPDATE AUR.


\e[1m2 - MAINTAIN SYSTEM
\e[36m"sudo rm -r /tmp/pacui*"
This command deletes all PacUI files in /tmp directory. PacUI uses this temporary directory to cache package lists and fzf selections. By deleting the /tmp directory, PacUI behaves exactly as after a reboot: Its first usage probably feels slower but any strange bugs and incompatibilities, e.g. originating from PacUI updates, should be gone.

\e[36m"sudo find /var/cache/pacman/pkg/ -iname "*.part" -delete"
This command deletes all partially downloaded packages from Pacman cache directory. Such packages can potentially prevent package updates.

\e[36m"sudo pacman-mirrors -f 0 && sudo pacman -Syyuu" \e[0m(for Manjaro)
This command generates a new mirrorlist of all available Manjaro repository mirrors/servers and sorts it by ping of up-to-date mirrors/servers. Additionally, the latest package database is downloaded from the chosen Manjaro repository mirror and the system is updated. If you want to speed up this command, it is recommended to only test your connection quality to Manjaro mirrors/servers near you. Example: You have noticed the pings to German and French mirrors are always best for you. Then, you can run: "sudo pacman-mirrors -f 0 -c Germany,France". In order to prevent a partially updated system after the change to another repository mirror/server, all packagaes are updated/downgraded to the repository version using "sudo pacman -Suu".

\e[36m"sudo reflector --verbose --protocol https,ftps --age 5 --sort rate --save /etc/pacman.d/mirrorlist && sudo pacman -Syyuu" \e[0m(for Arch and other Arch-based distros)
This command generates a new mirrorslist of secure and fast repository mirrors/servers. Then it resyncs the database to match the mirrors and updates the system.

\e[36m"flatpak uninstall --unused --delete-data -y" \e[0m(only if flatpak is installed)
This command cleans up unused flatpak packages, which are typically left over after flatpak updates.

\e[36m"sudo pacman -Rsn $(pacman -Qqdt)"
This option lists all orphaned packages on your system. Orphaned packages are old and no longer needed dependencies (packages not explicitly installed by you), which were never removed from your system.

\e[36m"sudo pacdiff"
A .pacnew file may be created during a package upgrade to avoid overwriting a file (e.g. a config file) which already exists and was previously modified by the user. A .pacsave file may be created during a package removal, or by a package installation (the package must be removed first). These files require manual intervention from the user and it is good practice to handle them regularly - ideally everytime a .pacnew/.pacsave file has been created.
This command offers you a choice, whether you want to keep the original file (and delete the .pacnew/.pacsave file) or overwrite the original file with the .pacnew/.pacsave file (the original file is backed up automatically with an added dash "-" to the end of its file name).
It is strongly recommended to view and compare both files by choosing "v" before making a decision.
If you keep the original config file, the new program version could not recognize the old syntax in the original config file anymore. In the worst case, your program could break or stop working. If you remove the original file and use the new file without any changes, all your configuration settings might be reset to the default values. This can result in changed system behavior, including missing passwords or even sudo capability.
In most cases, the syntax does not change and you can simply remove the .pacnew file. However, if you notice a syntax change, it is highly recommended to solve this conflict in another way (e.g. by manually editing one of those files and deleting the other).
\e[1mAttention\e[0m: This command requires a default file difference viewer by setting the environment variable DIFFPROG. for example by adding "DIFFPROG=meld" to your /etc/environment file. If this variable is not set, a minimal default is provided by PacUI based on "diff".
\e[1mAttention\e[0m: In severe cases, removing your old config file (and using the new .pacnew config file) OR keeping your old config file (and deleting the .pacnew config file) can result in a broken system. PLEASE BE CAUTIOUS WHEN USING THIS COMMAND!

\e[36m"systemctl list-units --state=failed"
This command checks for systemd units in a failed state. It is possible the systemd service will no longer be failed after a reboot. But if a systemd service still fails after a reboot, you should manually fix the problem. Start by using the command "systemctl status <SYSTEMD UNIT NAME>".

\e[36m"sudo find -xtype l" \e[0m(only if there are broken symlinks)
This command displays a list of broken symbolic links on your system. These links are not deleted by default. You have to decide yourself what to do with them. When you have doubt about deleting them, leave them on your system. They can sometimes cause problems, but they use almost no hard drive space.
Symbolic links can be removed manually or "sudo find -xtype l -delete" can be used to remove all broken symbolic links.

\e[36m"pacman -Dk"
This command checks your local package repository for consistency and shows missing packages, dependencies, or other errors. Please refer to "man pacman" for a more detailed explanation.

\e[36m"comm -23 <(pacman -Qqm | sort) <(curl https://aur.archlinux.org/packages.gz | gzip -cd | sort)"
This command compares 2 lists: The first list contains packages, which were not installed from your system repository. The second list contains all AUR package names. By comparing these 2 lists, it is possible to find EOL packages, which will never receive any updates.
These EOL packages were either installed manually by the user or from the AUR (and have been removed from there in the meantime).
Unless you know exactly what you are doing, it is recommended to remove these EOL packages.

\e[36m"comm -23 <(pacman -Qqm | sort) <(pacman -Qqem | sort)"
This command compares 2 lists: The first list contains packages, which were not installed from your system repository. The second list contains explicitly installed packages, which were not installed from your system repository. Packages unique to the first list are output.
Sometimes, packages from the system repository are no longer maintained. Typically, they get put into the AUR instead of deleting them. Such packages get filtered by this command.
These packages can cause really long update times and are generally a security risk. Unless important packages depend on them, it is recommended to remove these packages manually. You can check, which packages depend on them by using REVERSE DEPENDENCY TREE.

\e[36m"sudo journalctl --vacuum-size=100M --vacuum-time=30days"
This command limits all log files in journalctl to a combined size of 250 megabytes and a maximum age of 30 days. This leaves plenty of log files behind to analyze systematic and reoccurring errors while preventing excessive amounts of log files.

\e[36m"paccache -ruvk1"
\e[36m"paccache -rvk3"
By default Pacman uses this cache directory for downloading packages: /var/cache/pacman/pkg/ . No cached packages get deleted automatically. The package cache of an old and actively used installation can become quite large. Clean it to regain space on your root partition.
The first command removes all old packages from cache, which are not installed (anymore) on your system (except the latest version of that package).
The second command removes all old packages from cache except the 3 latest versions: The version you have currently installed on your system and 2 previous versions. Old package versions are kept to enable you to use ROLL BACK SYSTEM (or to manually downgrade packages) even without a working internet connection.

\e[36m"comm -13 <(echo "$available_kernels") <(echo "$installed_kernels")" \e[0m(for Manjaro)
This long "comm" command compares the output of 2 lists: The first list of <KERNEL NAME> contains (still) available kernels in your repository (which are also installed on your system) and the second list of <KERNEL NAME> contains installed kernels.
By comparing both lists, it is possible to extract <KERNEL NAME> of so called end-of-live kernels. These installed kernels are no longer supported and do not receive updates anymore. Kernel modules are likely to break. It is highly recommended to remove these kernels.
Kernels from the AUR are also listed by the "comm" command and trigger a warning. Please decide for yourself, whether you want to keep them or not.

\e[36m"fwupdmgr refresh --force && fwupdmgr get-updates"
\e[36m"fwupdmgr update"
fwupd can manage the firmware on (supported) devices in your system. Such devices can be e.g. hard drives, SSDs, network cards, bluetooth cards, (parts of) UEFI, etc.
If fwupd is installed, the first command downloads the latest metadata from LVFS and displays any available update(s) for any fwupd-supported devices.
If any update(s) are available, the second command installs them.


\e[1m3 - INSTALL PACKAGES
\e[36m"yay -S <PACKAGE NAME>"
This option downloads and installs <PACKAGE NAME> on your system. The list of packages shows packages from your system repository with their description while package groups or packages from the AUR are only shown with their name.
\e[1mAttention\e[0m: Experienced users can install packages from the AUR without the need to answer questions all the time by using the command "yay -S <PACKAGE NAME> --noconfirm". The "--noconfirm" flag is great for quick and dirty installations of AUR packages on non-secure systems. Please keep always in mind that the AUR can contain any sort of packages - including malicious and destructive (parts of) packages. Therefore, it is recommended to always check the PKGBUILD and .INSTALL file manually before installing a package from the AUR.


\e[1m4 - REMOVE PACKAGES AND DEPS
\e[36m"sudo pacman -Rsn <PACKAGE NAME>"
This command removes <PACKAGE NAME> from your system including all dependencies, which are no longer needed by other packages. A copy of <PACKAGE NAME> will be kept in your package cache: Run MAINTAIN SYSTEM to remove it.
Please note that folders in your home (~) directory and created by the program <PACKAGE NAME> will not get removed from your system. Look for such folders in these places and remove them manually:
~/
~/.config/
~/.local/share/
\e[1mAttention\e[0m: If you want to display a list of all your installed packages (including their version number and description) use this PacUI option. Simply do not select <PACKAGE NAME> to be removed, but quit the list view with ESC or CTRL+C.
If package removal fails, the user is offered the choice to try again, remove packages using \e[36m"pacman -Rdd <PACKAGE NAME>"\e[0m, or remove packages using \e[36m"pacman -Rsnc <PACKAGE NAME>"\e[0m.
\e[1mAttention\e[0m: \e[36m"pacman -Rdd <PACKAGE NAME>"\e[0m does not check for dependencies before removing packages. In severe cases, this can leave your system without essential packages and thus unbootable!
\e[1mAttention\e[0m: \e[36m"pacman -Rsnc <PACKAGE NAME>"\e[0m removes additional packages, which depend on <PACKAGE NAME>. Please check the list of packages, to be removed again before proceeding.


\e[1m5 - DEPENDENCY TREE
\e[36m"pactree <PACKAGE NAME>"
\e[36m"pactree -s <PACKAGE NAME>"\e[0m(only for packages not installed on your system)
This command will display a complete tree of all dependencies of <PACKAGE NAME>. <PACKAGE NAME> can be an installed package or a package from your system repositories. Dependencies are packages required by <PACKAGE NAME> in order to function. When you install <PACKAGE NAME>, all its dependencies get installed, too.
Please note that all selected lines (toggle selection with your TAB key) will get added to file /tmp/pacui-t.


\e[1m6 - REVERSE DEPENDENCY TREE
\e[36m"pactree -r <PACKAGE NAME>"
\e[36m"pactree -r -s <PACKAGE NAME>"\e[0m(only for packages not installed on your system)
This command will display a tree of installed packages, which depend on <PACKAGE NAME>. In other words: All displayed packages require <PACKAGE NAME> in order to function (properly).
Use this command when you want to know why you cannot remove <PACKAGE NAME> from your system.
Please note that all selected lines (toggle selection with your TAB key) will get added to file /tmp/pacui-rt.


\e[1m7 - LIST PACKAGE FILES
\e[36m"pacman -Ql <PACKAGE NAME>"
\e[36m"sudo pacman -Fyl <PACKAGE NAME>" \e[0m(only for packages not installed on your system)
These commands list all files contained in <PACKAGE NAME> including their path. The second command syncs the file database with your system repositories and then searches the file database for files, which get installed by <PACKAGE NAME>.
As a result the complete path to the files get displayed.
Have you ever installed a program and did not know with which command it can be started/executed? Just look for files (and their names) in your /usr/bin/ directory using LIST PACKAGE FILES.
By default, the results are filtered for files located in usr/bin/, but you can enter any filter term you want to. Delete the default filter term with BACKSPACE to see a complete list of files of <PACKAGE NAME>. Please note that all selected lines (toggle selection with your TAB key) will get added to file /tmp/pacui-l.
\e[1mAttention\e[0m: On some systems, the file database has not been downloaded which results in an error message instead of search results from your system repositories. You can fix it by running "sudo pacman -Fyy" and restarting LIST PACKAGE FILES.


\e[1m8 - SEARCH PACKAGE FILES
\e[36m"pacman -Ql | grep <FILE NAME>"
\e[36m"sudo pacman -Fyx <FILE NAME>" \e[0m(only for packages not installed on your system)
In some situations, Pacman (e.g. during UPDATE SYSTEM) cannot find a file, for example a shared library. An error message is shown about <FILE NAME>. Use SEARCH PACKAGE FILES to find out, which package has installed <FILE NAME>. In most cases, you can fix the Pacman error by using one of the following options on that package: UPDATE SYSTEM, ROLL BACK SYSTEM, REMOVE PACKAGES, and INSTALL PACKAGES, or FORCE UPDATE AUR.
SEARCH PACKAGE FILES is in many ways a reverse LIST PACKAGE FILES. You can use it to find out which package you have to install in order to use the <FILE NAME> command in your terminal.
The first command searches for <FILE NAME> in all your installed packages. <FILE NAME> can be a part of an actual file name or contain regular expressions.
The second command syncs the file database with your system repositories and then searches the file database for <FILE NAME>.
As a result, <REPOSITORY>/<PACKAGE NAME> and the complete path to <FILE NAME> gets displayed using fzf. <PACKAGE NAME> is always printed in a bold font. <REPOSITORY> only gets displayed for packages, which are not installed on your system. Please note that all selected lines (toggle selection with your TAB key) will get added to file /tmp/pacui-s.
\e[1mAttention\e[0m: On some systems, the file database has not been downloaded which results in an error message instead of search results from your system repositories. You can fix it by running "sudo pacman -Fyy" and restarting SEARCH PACKAGE FILES.


\e[1m9 - ROLL BACK SYSTEM
\e[36m"sudo pacman -R <PACKAGE NAME> --noconfirm" \e[0m(only for rolling back package installations)
\e[36m"sudo pacman -U <PACKAGE NAME IN PACKAGE CACHE> --noconfirm" \e[0m(only for rolling back package removals, upgrades, or downgrades.)
Manjaro and Arch Linux use a rolling release development model. This means ALL packages on your system continuously get updated to the latest version. Sometimes, things go wrong during UPDATE SYSTEM and you should roll back the last update. In case the latest version of a single package is broken, rolling back (a.k.a. downgrading) that package can work.
This command shows you a list of all recent Pacman actions sorted by date (using parts of this command: "tail -8000 /var/log/pacman.log"). Please select all Pacman actions you want to roll back. Installed packages will be removed from your system. Removed packages will be reinstalled as the latest version available in your Pacman/Pacaur cache. Upgraded packages will be downgraded to the previous version (if this version is available in your local Pacman/Pacaur cache). Downgraded packages will be Upgraded to a later version. If you select multiple upgrades/downgrades of the same package, the package gets downgraded/upgraded multiple times (if this version is available in your local Pacman/Pacaur cache).
\e[1mAttention\e[0m: It is strongly recommended to always roll back <PACKAGE NAME> including ALL its dependencies. Otherwise, your system could be left in a broken state. If you are in doubt about that, rolling back all changes made on your system in a short time intervall should be sufficient.
\e[1mAttention\e[0m: After downgrading a broken package to a working version, it is recommended to add the package name to your Ignore List ( "IgnorePkg" option in /etc/pacman.conf ). This will prevent Pacman from showing any available updates for this package. The package needs to be removed manually from your Ignore List in order to receive automatic updates again. Alternatively, you can run future updates with the command "sudo pacman -Syu --ignore <PACKAGE NAME>" until a fixed version of that package gets released.


\e[31;1m10 - FIX PACMAN ERRORS
Multiple commands attempt to fix the most common issues Manjaro users have with Pacman.
Please make sure that your root partition is not full. If you have doubts about this, run MAINTAIN SYSTEM before FIX PACMAN ERRORS.

\e[36m"sudo rm -r /tmp/pacui*"
This command deletes all PacUI files in /tmp directory. PacUI uses this temporary directory to cache package lists and fzf selections. By deleting the /tmp directory, PacUI behaves exactly as after a reboot: Its first usage probably feels slower but any strange bugs and incompatibilities, e.g. originating from PacUI updates, should be gone.

\e[36m"sudo unlink /var/lib/pacman/db.lck"
This command removes Pacmans database lock. The database lock prevents multiple Pacman instances from running at the same time and interfering with each other.
\e[1mAttention\e[0m: Only run this command when no other Pacman instance (e.g. Pacman, Pamac, Octopi, PacmanXG4, Yay, Pikaur, Aurman, Pakku, Trizen, Paru, Pacaur, Pamac-cli ...) is running.

\e[36m"sudo pacman-mirrors -f 0 && sudo pacman -Syy" \e[0m(for Manjaro)
This command generates a new mirrorslist of all available Manjaro repository mirrors/servers and sorts it by ping of up-to-date mirrors/servers. Additionally, the latest package database is downloaded from the chosen Manjaro repository mirror. If you want to speed up this command, it is recommended to only test your connection quality to Manjaro mirrors/servers near you. Example: You have noticed the pings to German and French mirrors are always best for you. Then, you can run: "sudo pacman-mirrors -c Germany,France".
Here, the risk of a (temporarily) partially updated system has to be considered against the effort to fix all systems, including systems on which it is no longer possible to install any packages. The system can be put in a partially updated state during the course of FIX PACMAN ERRORS, but at the end of FIX PACMAN ERRORS the complete system is updated.

\e[36m"sudo reflector --verbose --protocol https,ftps --age 5 --sort rate --save /etc/pacman.d/mirrorlist && sudo pacman -Syy" \e[0m(For Arch and other Arch-based distributions)
This command generates a new mirrorlist of secure and fast repository mirrors/servers. Then it resynchronizes the database to match the mirrors.

\e[36m"sudo dirmngr </dev/null"
Sometimes during key management the package "dirmngr" outputs error messages, which interrupt key management processes (such as the following commands). This command prevents any output from "dirmngr".

\e[36m"sudo pacman -Sc"
After an unseccessful attempt to update your system (which quits with a key error), you might have already downloaded unsigned (or wrongly signed) packages to your Pacman cache. These packages cannot be installed anymore.
This command removes all packages from your Pacman cache, which are not installed on your system. Afterwards, you need to download all previously downloaded but not installed packages again.
\e[1mAttention\e[0m: This command makes it impossible to ROLL BACK SYSTEM on systems without an internet connection.

\e[36m"echo 'keyring /etc/pacman.d/gnupg/pubring.gpg' >> $HOME/.gnupg/gpg.conf"
There are 2 different places in Arch Linux and Manjaro to store keys: One place is used by Pacman and the other gets used by GPG.
This command imports all keys for Pacman into GPG. This essentially means that the user trusts all Arch Linux Trusted Users and your distribution's developers. After that, you will be able to install AUR packages from Arch Linux Trusted Users and your distribution's developers without the need to import those keys (again) manually.

\e[36m"sudo pacman -Syuu --noconfirm"
This command forces a redownload of the latest package database from the best repository mirror. Then, all your installed packages are checked against this latest package database. If a different package is available from your system repositories, it will get downloaded and installed on your system. This behavior ensures your packages are always in sync with your system repositories.

\e[36m"sudo cp --preserve=all -f /etc/pacman.conf /etc/pacman.conf.backup && sudo sed -i 's/SigLevel[ ]*=[A-Za-z ]*/SigLevel = Never/' '/etc/pacman.conf' "
The following commands delete and reinstall some essential packages. If your keyring is broken, no packages could be installed because of a key mismatch. Therefore, it is important to disable Pacman's key check before continuing.
This command disables the signature key check of packages in Pacman.

\e[36m"sudo systemctl stop ntpd.service"
This command stops (temporarily) the Network Time Protocol daemon service NTPD (if it is installed and running). In case NTPD is not installed, the output is ignored.
This is the first command of a series of commands, which try to set the system and hardware clock on your computer (ignoring time zone and daylight saving time). An (almost) correct system time is needed for checking and importing keys or fingerprints later on in the fixing process!

\e[36m"sudo pacman -Syu ntp"
This command (re-)installs the "ntp" package.
Because the keyring is not checked, in certain situations your system could be left in a partially updated state. However, if you follow PacUI's instructions, this does not happen.

\e[36m"sudo ntpd -qg && sleep 10 && sudo hwclock -w"
The first command starts the just (re-)installed Network Time Protocol daemon (ntpd.service). Next, your system clock is set. Finally, the ntpd.service is quit.
The second command makes your system wait for 60 seconds. This is done as precaution to ensure your system has enough time to connect to an internet or network server and set the system clock.
The third command is only run when the first and second command have been successfully finished. It writes the time from your system clock to your hardware clock.
\e[1mAttention\e[0m: The last command is needed in order to prevent other services on your system to set your system clock according to your hardware clock in regular intervals. This may result in a hardware clock, which is not set to UTC anymore and/or a system clock, which shows the wrong time. If you encounter this problem read the Arch Linux Wiki article about time: "https://wiki.archlinux.org/index.php/Time"

\e[36m"sudo pacman -Syu"
This command makes abolutely sure all packages get updated. No keyring check is performed here.
If manual intervention is necessary, the user can do it here. Please follow Pacman and/or PacUI instructions, which appear during this update. It is important that this step completes without any errors in order to continue FIX PACMAN ERRORS.

The following steps are only run, when the previous update attempt was successful. They reinitialize the key database:

\e[36m"sudo rm -r /etc/pacman.d/gnupg"
This command deletes your key database. It does not output an error in case the package "gnupg" is not installed on your system.
\e[1mAttention\e[0m: This command will remove all keys from your system, including manually installed keys (with "sudo pacman-key --lsign-key <KEY>"). Please remember to reinstall those keys again after FIX PACMAN ERRORS has completed!

\e[36m"sudo pacman -Syu gnupg $(pacman -Qsq '(-keyring)' | grep -v -i -E '(gnome|python|debian)' | paste -sd " " )" --noconfirm
This command (re-)installs the gnupg and keyring packages.

\e[36m"sudo cp --preserve=all -f /etc/pacman.conf.backup /etc/pacman.conf && sudo rm /etc/pacman.conf.backup "
This command enables the signature check of packages in Pacman again.

\e[36m"sudo pacman-key --init && sudo pacman-key --populate $(pacman -Qsq '(-keyring)' | grep -v -i -E '(gnome|python|debian)' | sed 's/-keyring//' | paste -sd " " )"
These two commands create a fresh key for you and import and (re-)install all keyrings. This will solve problems with your local key database and your distribution's and Arch's key database. Such problems can occur when new Arch Linux or your distribution packagers get added, for example.
\e[1mAttention\e[0m: This command might take a long time to complete. If your system appears to stop or hang, it searches for entropy in order to generate a new key for you. In this case, it might help to do file operations with a lot of reads and/or writes per minute (such as searching for files, copying large directories, etc.). Alternatively, you can open a browser and do some heavy surfing (with a lot of mouse movements, mouse clicks, and keyboard key presses): This can help to generate entropy much faster.

\e[36m"sudo pacman -Fyy"
This command forces a sync of the file database of your system repository with your used repository mirror server. The file database is separate from the package database. The file database enables SEARCH PACKAGE FILES and LIST PACKAGE FILES of packages, which are not installed on your system but only available on your system repository.


\e[1m11 - EDIT CONFIG FILES
\e[36m"$EDITOR <FILE NAME>"
This command opens <FILE NAME> in your default text editor. You can choose between multiple important system configuration files. Files in the root directory are opened with root privileges. The "sudoers" file is edited with \e[36m"sudo visudo"\e[0m (which uses the $SUDO_EDITOR environment variable by default). For some configuration files, additional commands are executed after the text editor is closed in order to avoid system breakage.
By default the text editor Nano gets used, except custom $EDITOR and $SUDO_EDITOR environment variables have been set. In the text editor Nano, Press CTRL+O to save your changes, ENTER to choose a directory, and CTRL+X to quit Nano.
\e[1mAttention\e[0m: Changing system configuration files can harm or even destroy your system. In some cases, this can happen with a single mistake. Be extremely careful and always double check your changes before saving and rebooting - especially when editing the files marked in red! It is recommended to search the Arch Wiki for the configuration file you want to edit and read about available and recommended settings.


\e[1m12 - LIST PACKAGES BY SIZE
\e[36m"expac -Q '%m - %n %v' | sort -n -r "
This command lists packages on your system sorted by their installation size. Both explicitly installed packages and dependencies are displayed. Please note that all selected lines (toggle selection with your TAB key) will get added to file /tmp/pacui-ls.

EOF
        # only write the following paragraph to file, if an AUR helper is installed
        if [[ -n "$AUR_Helper" ]]
        then
            cat >> /tmp/pacui-help <<- "EOF"
\e[1m13 - FORCE UPDATE AUR
\e[36m"yay -Syu --devel --needed"
The Arch User Repository (AUR) is a repository of (mostly) PKGBUILD files. Everybody can create such a PKGBUILD file and upload it to the AUR. A PKGBUILD file contains simple and human readable instructions like where to download the source code from, what dependencies are needed, where to copy files for installation, etc. Your AUR helper can interpret PKGBUILD files and download the source code, install dependencies, build files on your system, and copy these files to the right location (a.k.a. installing a program).
By checking a PKGBUILD file (and .INSTALL file) you can make sure the source code is loaded from an official download server, no harmful dependencies get installed, and the installation instructions do not contain harmful code.
A lot of PKGBUILD files contain variables (e.g. program version) in download addresses; this makes them download always the latest source code (e.g. from Github) during installation. Some PKGBUILD files contain no variables: These PKGBUILD files need to be changed manually every time a new program version is released.
This command updates both packages from your system repository and AUR packages. Because of the "--devel" flag, development versions (i.e. all git, svn, and cvs-packages) from the AUR are updated as well.
\e[1mAttention\e[0m: This might take a long time! Some AUR helpers pause by default after every 15min and ask again for your password.

EOF
        fi

        cat >> /tmp/pacui-help <<- "EOF"
\e[1m14 - LIST INSTALLED FROM AUR
\e[36m"pacman -Qm"
This command lists all installed packages, which are from the AUR or which were manually installed. Packages, which are installed on your local system, but are no longer available in remote system repositories are listed here, too. They are orphaned and can get removed with MAINTAIN SYSTEM. Please note that all selected lines (toggle selection with your TAB key) will get added to file /tmp/pacui-la.
If you want a list of all installed packages use REMOVE PACKAGES AND DEPS as described in this Help Page.

EOF
        # only write the following paragraph to file, if "downgrade" is installed
        if [[ -f /usr/bin/downgrade ]]
        then
            cat >> /tmp/pacui-help <<- "EOF"
\e[1mDOWNGRADE PACKAGES
\e[36m"downgrade <PACKAGE NAME>"
Manjaro and Arch Linux use a rolling release development model. This means ALL packages on your system continuously get updated to the latest version. If the latest version of a packages does not work on your system, you can downgrade that package to an earlier, working version.
This command downgrades <PACKAGE NAME> and offers you a list of old <PACKAGE NAME> versions to choose from. This list includes all old <PACKAGE NAME> versions from your local package cache and online sources (if you have a working internet connection).
After a successful downgrade, you can add <PACKAGE NAME> to your Ignore List ( "IgnorePkg" option in /etc/pacman.conf ). This will prevent Pacman from showing any available updates for <PACKAGE NAME>. <PACKAGE NAME> needs to be removed manually from your Ignore List in order to receive automatic updates of <PACKAGE NAME> again.
Alternatively, you can run future updates with the command "sudo pacman -Syu --ignore <PACKAGE NAME>" until a fixed version of <PACKAGE NAME> gets released.
\e[1mAttention\e[0m: Be careful when using Manjaro and downgrading to <PACKAGE NAME> from online sources, because these are old versions from the Arch Linux repositories only: In the worst case, this can brake your system! Therefore, it is recommended to limit downgrading to (old versions of) local packages, if possible.
\e[1mAttention\e[0m: Downgrading to a working version of <PACKAGE NAME> can break your system in in rare cases like the following: The latest system update has replaced a dependency of <PACKAGE NAME> with a different package and <PACKAGE NAME> is an important system package. Downgrading <PACKAGE NAME> will NOT reinstall the dependency of <PACKAGE NAME>, because it conflicts with the already installed different package. This can result in a broken system. Please keep these kind of conflicts in mind when using DOWNGRADE PACKAGES.
\e[1mAttention\e[0m: DOWNGRADE PACKAGES will show you a selection of packages you can downgrade. If you are using Pacaur to install AUR packages, you will not be able to downgrade AUR packages using DOWNGRADE PACKAGES! instead, the ROLL BACK SYSTEM option is recommended.

EOF
        fi

        # only write the following paragraph to file, if an AUR helper is installed
        if [[ -n "$AUR_Helper" ]]
        then
            cat >> /tmp/pacui-help <<- "EOF"
\e[1mSEARCH (AND INSTALL) FROM AUR
\e[36m"yay <PACKAGE NAME>"
This command searches for <PACKAGE NAME> in all system repositories and the Arch User Repository (AUR). It searches for package names and package descriptions. Some AUR helpers offer an easy way to select and install a subset of these search results, too.
Example: You can search for "web browser" and you will find Firefox and other web browsers. One or multiple search results can be installed on your system.
If you want to exit this mode without installing any packages, simply press CTRL+C or ENTER.

EOF
        fi

        cat >> /tmp/pacui-help <<- "EOF"

Press "q" to quit this Help Page.

EOF

        # display /tmp/pacui-help file in "less" and interpret all ANSI escape sequences in it (which only works with "echo -e ..."):
        echo -e "$( cat '/tmp/pacui-help' )" | less -RMi
}


# Help
# this function provides short Help.
function func_h
{
        echo -e "  pacui      - \e[1mPac\e[0mUI with \e[1mU\e[0mser \e[1mI\e[0mnterface"
        echo
        echo -e "  pacui 1    - \e[1mU\e[0mpdate System"
        echo -e "  pacui 2    - \e[1mM\e[0maintain System"
        echo -e "  pacui 3    - \e[1mI\e[0mnstall Packages"
        echo -e "  pacui 4    - \e[1mR\e[0memove Packages and Deps"
        echo -e "  pacui 5    - Dependency \e[1mT\e[0mree"
        echo -e "  pacui 6    - R\e[1me\e[0mverse Dependency Tree"
        echo -e "  pacui 7    - \e[1mL\e[0mist Package Files"
        echo -e "  pacui 8    - \e[1mS\e[0mearch Package Files"
        echo
        echo -e "  pacui 9    - Roll \e[1mB\e[0mack System"
        echo -e " \e[31m pacui z    - \e[1mF\e[0;31mix Pacman Errors\e[0m"
        echo -e "  pacui y    - Edit \e[1mC\e[0monfig Files"
        echo -e "  pacui x    - List \e[1mP\e[0mackages by Size"
        echo
        [[ -n "$AUR_Helper" ]]      && echo -e "  pacui w    - F\e[1mo\e[0mrce Update AUR"
        echo -e "  pacui v    - List I\e[1mn\e[0mstalled from AUR"
        [[ -n "$AUR_Helper" ]]      && echo
        [[ -f /usr/bin/downgrade ]] && echo -e "  pacui d    - \e[1mD\e[0mowngrade Packages"
        [[ -n "$AUR_Helper" ]]      && echo -e "  pacui a    - Search (and Install) from \e[1mA\e[0mUR"
        echo
        echo -e "  pacui h    - This short \e[1mH\e[0melp."
        echo -e "  pacui help - Full \e[1mHelp\e[0m page. 'q' key quits."
}



# all functions of pacui end here.

# =======================

# section for general bug fixes


# bug #2:
# when used with tmux and pacaur and $EDITOR variable is not set and vi is not installed ("vi" is the default editor used by pacaur):
# pacaur sometimes does not find an editor to use and the --preview window in fzf does not show any package information.
# instead, it shows "::editor variable unset".

#set +u                                                                             # temporarily disable strict mode for environment variables

# check, whether pacaur is installed, user config file exists, $EDITOR variable is empty, "vi" is not installed:
if [[ "$AUR_Helper" == "pacaur" ]] && [[ ! -f $HOME/.config/pacaur/config ]] && [[ -z $EDITOR ]] && [[ ! -f /usr/bin/vi ]]
then
    # export "editor='${EDITOR:-nano}'" to config file. '${EDITOR:-nano}'" outputs "nano", if there is no $EDITOR variable set.
    mkdir -p "$HOME/.config/pacaur/"
    echo "editor='${EDITOR:-nano}'" >> "$HOME/.config/pacaur/config"
fi

#set -u


# bug #4 :
# when database of system repositories has not been saved, it is impossible to use pacman (or expac) in any meaningful way.
# therefore, the existence of the "core" database is tested here. if it does not exist, a repository server is chosen and the repository database synced to the user's system

dbpath="$( awk -F '=' '/^DBPath/ {gsub(" ","",$2); print $2}' '/etc/pacman.conf' )" # extract path of database file from pacman.conf
if [[ -z "$dbpath" ]]                                                               # if "dbpath" variable is empty (exact: if output of $dbpath is zero)
then
    dbpath="/var/lib/pacman/"                                                       # default database path
fi

if ! [[ -f "$dbpath"sync/core.db ]]                                                 # check, whether repository database file "core.db" exists
then

    # check for "pacman-mirrors" or "reflector" packages. one of those is needed!
    if [[ -f /usr/bin/pacman-mirrors ]] || [[ -f /usr/bin/reflector ]]
    then

        echo " choosing fastest mirror (which can take a while) and updating system ..."
        if [[ -f /usr/bin/pacman-mirrors ]]                                         # checks, whether file "pacman-mirrors" exists
        then
            sudo pacman-mirrors -f 0 && sudo pacman -Syyu                           # choose mirrors server (with up-to-date packages) with lowest ping from all available mirrors and sync database.

        elif [[ -f /usr/bin/reflector ]]                                            # checks, whether file "reflector" exists
        then
            sudo reflector --verbose --protocol https,ftps --age 5 --sort rate --save /etc/pacman.d/mirrorlist && sleep 10 && sudo pacman -Syyu          # If it does exists, then the mirror will sort by it

        fi
    fi

fi
unset dbpath


# =======================

# the following section of code is executed when pacui gets called directly from a terminal/tty without using the UI


# the 'pacui' command gets called (mostly) with arguments. in the following while-loop, all arguments are assigned to their designated variables:

# save number of arguments in a variable for later usage, because the following while-loop destroys all original arguments and therefore, the number of arguments is always 0 after it:
argument_number="${#:-}"                                                            # we have to use "${#:-}" instead of "$#", because of strict bash mode!        # '$#' is the number of arguments with which 'pacui' got called

# save the argument, which contains a function name to this variable:
function_call=""
function_call_previous=""                                                           # this variable is not really necessary, but its usage saves many lines of code

# save all unknown input in this variable:
argument_input=""

# variable for 'flag' input, which gets directly passed to the AUR-helper or pacman
argument_flag=""


while (( ${#:-} > 0 ))
do

    key="${1:-}"                                                                    # we have to use "${1:-}" instead of "$1", because of strict bash mode!       # '$1' is the first argument with which 'pacui' got called
    # comment: when entering regex as parameter for pacui, it has to be put in brackets. otherwise, "${1:-}" will somehow interpret it and output strange stuff.

    # remove leading white spaces from $key:
    key="$( echo "$key" | sed 's/^ *//g' )"

    # remove trailing white spaces:
    key="$( echo "$key" | sed 's/ *$//g' )"

    # remove leading dash(es):
    key="$( echo "$key" |  sed 's/^-*//g' )"

    # convert content of "key" variable to lowercase
    key="$( echo "$key" | tr '[:upper:]' '[:lower:]' )"


    # test, whether 'key' fits any of the following strings listed inside this 'case' command:
    case "$key" in

        1|u|update|update-system)                                                   # the following commands will get executed if $key is "1" or "u" or "update" until a code line containing only ";;" is encountered
            function_call="u"
            shift                                                                   # shift to next argument (which is currently known as '$2'), and make it first argument ( i.e. referred to as '$1'). this command throws away the current argument, because we have done everything with it we wanted to do and it is no longer needed.
            ;;
        2|m|maintain|maintain-system )
            function_call="m"
            shift
            ;;
        3|i|install|install-packages )
            function_call="i"
            shift
            ;;
        4|r|remove|remove-packages-and-deps )
            function_call="r"
            shift
            ;;
        5|t|tree|dependency-tree )
            function_call="t"
            shift
            ;;
        6|e|rt|reversetree|reverse-dependency-tree )
            function_call="rt"
            shift
            ;;
        7|l|list|list-package-files )
            function_call="l"
            shift
            ;;
        8|s|search|search-package-files )
            function_call="s"
            shift
            ;;
        9|b|back|roll-back-system )
            function_call="b"
            shift
            ;;
        10|z|f|fix|fix-pacman-errors )
            function_call="f"
            shift
            ;;
        11|y|c|conf|config|edit-config-files )
            function_call="c"
            shift
            ;;
        12|x|p|ls|listsize|list-packages-by-size )
            function_call="ls"
            shift
            ;;
        13|w|o|ua|fua|forceupdateaur|updateaur|force-update-aur )
            function_call="ua"
            shift
            ;;
        14|v|n|la|listaur|list-installed-from-aur )
            function_call="la"
            shift
            ;;
        d|down|downgrade|downgrade-packages )
            function_call="d"
            shift
            ;;
        a|aur|search-and-install-from-aur )
            function_call="a"
            shift
            ;;
        h )
            function_call="h"                                                       # call short help
            shift
            ;;
        99|help|man )
            function_call="help"                                                    # call full help page
            shift
            ;;

        # next, all other possible arguments pacui can be called with are listed:

        diff )
            function_call="diff"                                                    # call "diff" helper function
            shift
            ;;
        flag=* )                                                                    # this means 'flag=' string and every following string (no matter how long it is or what characters (except for " ") it contains)
            argument_flag="${key#*=}"                                               # replace '*=' (i.e. everything in front of = sign and = sign itself) in 'key' variable with nothing. save result in $argument_flag.
            shift
            ;;
        flag )
            # assign next argument (which follows directly the 'flag' argument) to $argument_flag variable
            argument_flag="${2:-}"                                                  # please note that only '$1' has been trimmed, dash(es) removed, and switched to lowercase. but nothing is done yet to '$2'.         # we have to use "${2:-}" instead of "$2", because of strict bash mode!
            shift                                                                   # shift over 'flag' argument
            shift                                                                   # shift over argument, which follows 'flag' argument, i.e. the string which got just saved to $argument_flag
            ;;
        * )                                                                         # do this, if $key variable contains anything else not listed above. this is (hopefully) all stuff, which is supposed to be passed on to fzf.
            argument_input+="$key"
            argument_input+=" "                                                     # all 'key' arguments should be space separated. problem: there will be a space at the end of $argument_input variable.
            shift
            ;;

    esac


    # print error message when more than 1 argument is recognized as an argument calling a pacui function
    if [[ -n "$function_call_previous" && "$function_call_previous" != "$function_call" ]]
    then

        echo -e " \e[41m Only one PacUI option can be called at the same time. Please try again. \e[0m"
        exit 1

    fi
    # save $function_call in $function_call_previous variable, because $function_call can get overwritten when the loop runs the next time.
    function_call_previous="$function_call"


done

# add trailing space to content of $argument_flag variable, because pacman and AUR helpers react in a strange way when an extra space is added.
if [[ -n  "$argument_flag" ]]                                                       # check, whether output of "$argument_flag" is not-zero, i.e. $argument_flag contains something
then
    argument_flag+=" "
fi

# remove trailing white spaces from $argument_input variable. this is needed e.g. for 'func_s' to not search for "<SEARCH TERM><SPACE>" but "<SEARCH TERM>"
argument_input="$( echo "$argument_input" | sed 's/ *$//g' )"


# the following code checks, whether a prefix (func_) + variable "function_call" is a valid function defined above.
if [[ "$( type -t "func_$function_call")" == "function" ]]
then

    "func_$function_call"                                                           # call pacui function

    # unset global variables:
    unset function_call
    unset function_call_previous
    unset argument_input
    unset argument_flag

    exit "$?"                                                                       # exit pacui here and return error code if present. this "exit" command is needed to prevent the UI from loading!

elif (( argument_number > 0 ))                                                      # if "func_$function_call" is no valid function AND if any arguments are given. this condition is needed to exclude the "pacui" command (note, there are NO arguments. "pacui" is supposed to start the UI) from running this section.
then

    unset function_call
    unset function_call_previous
    unset argument_input
    unset argument_flag

    # display error, if $function_call does not refer to a valid function. the UI will be started by default.
    echo -e " \e[41m Bad console command. Press ENTER to start PacUI or CTRL+C to abort. \e[0m"
    read -r
    # now, continue this script without exiting, i.e. load pacui's UI.

fi

unset argument_number                                                               # this global variable is no longer needed



# logic code is above
# =======================
# =======================
# =======================
# UI code is below



# bug #1:
# "pacui --pacui_clean" helper function. this function is only called from within pacui's UI.
function pacui_clean
{
        # the traditional "clear" command does not work as expected on all systems. problem: the terminal history of all previous commands is deleted when the "clear" command is used. solution: do everything i expect from "clear" manually. this keeps the terminal history:

        local lines
        # number of lines of the user's terminal.
        lines="$( tput lines )"
        for (( i=1; i<lines; i++ ))
        do
                # insert "lines" number of empty lines:
                echo
        done

        # move cursor to the top left of the terminal
        tput cup 0 0
}



# Run infinite loop for UI / menu, till the user quits using the "quit" option or CTRL+C.
while true
do

    pacui_clean                                                                     # clear the terminal screen

    # draw UI / menu. please note the use of ANSI Escape sequences mentioned at the top. The text/code can be hard to read and should be changed carefully: spaces are important here!
    echo
    echo -e "                        \e[7m \e[1mPac\e[0m\e[7mkage manager \e[1mUI \e[0m                      "
    echo -e " \e[1m+----------------------------------------------------------------+\e[0m"
    echo -e " \e[1m|\e[0m    \e[7m 1 \e[0m \e[1mU\e[0mpdate System           \e[7m 2 \e[0m \e[1mM\e[0maintain System             \e[1m|\e[0m"
    echo -e " \e[1m|\e[0m    \e[7m 3 \e[0m \e[1mI\e[0mnstall Packages        \e[7m 4 \e[0m \e[1mR\e[0memove Packages and Deps    \e[1m|\e[0m"
    echo -e " \e[1m|\e[0m----------------------------------------------------------------\e[1m|\e[0m"
    echo -e " \e[1m|\e[0m    \e[7m 5 \e[0m Dependency \e[1mT\e[0mree         \e[7m 6 \e[0m R\e[1me\e[0mverse Dependency Tree     \e[1m|\e[0m"
    echo -e " \e[1m|\e[0m    \e[7m 7 \e[0m \e[1mL\e[0mist Package Files      \e[7m 8 \e[0m \e[1mS\e[0mearch Package Files        \e[1m|\e[0m"
    echo -e " \e[1m+----------------------------------------------------------------+\e[0m"
    echo -e "      \e[7m 9 \e[0m Roll \e[1mB\e[0mack System        \e[31m\e[7m Z \e[0m \e[31m\e[1mF\e[0;31mix Pacman Errors\e[0m "
    echo -e "      \e[7m Y \e[0m Edit \e[1mC\e[0monfig Files       \e[7m X \e[0m List \e[1mP\e[0mackages by Size "
    echo -e " \e[1m+----------------------------------------------------------------+\e[0m"
    [[ -n "$AUR_Helper" ]] && echo -e " \e[1m|\e[0m    \e[7m W \e[0m F\e[1mo\e[0mrce Update AUR        \e[7m V \e[0m List I\e[1mn\e[0mstalled from AUR     \e[1m|\e[0m"
    [[ -z "$AUR_Helper" ]] && echo -e " \e[1m|\e[0m                                \e[7m V \e[0m List I\e[1mn\e[0mstalled from AUR     \e[1m|\e[0m"
    echo -e " \e[1m+----------------------------------------------------------------+\e[0m"
    echo
    echo -e "  Press number or marked letter            \e[7m H \e[0m \e[1mH\e[0melp       \e[7m 0 \e[0m \e[1mQ\e[0muit "


    # save entered numbers/letters in variable "choice"
    read -r -n 1 -e choice                                                          # this "read" command only accepts 1 letter as answer. this feels faster and is enough in this situation.

    # test, whether "choice" fits any of the following numbers, letters, or words
    case "$choice" in

        1|u|U )                                                                     # the following commands will get executed if $choice is "1" or "u" or "update" until a code line containing only ";;" is encountered
            func_u                                                                  # call function "func_u"
            echo
            echo -e " \e[41m System updated. To return to PacUI press ENTER \e[0m"
            # wait for input, e.g. by pressing ENTER:
            read -r
            ;;
        2|m|M )
            func_m
            echo
            echo -e " \e[41m System maintenance finished. To return to PacUI press ENTER \e[0m"
            read -r
            ;;
        3|i|I )
            func_i
            echo
            echo -e " \e[41m Package installation finished. To return to PacUI press ENTER \e[0m"
            read -r
            ;;
        4|r|R )
            func_r
            echo
            echo -e " \e[41m Operation finished. To return to PacUI press ENTER \e[0m"
            read -r
            ;;
        5|t|T )
            func_t
            echo
            ;;
        6|e|E )
            func_rt
            echo
            ;;
        7|l|L )
            func_l
            echo
            ;;
        8|s|S )
            func_s
            echo
            ;;


        9|b|B )
            func_b
            echo
            echo -e " \e[41m System roll back finished. To return to PacUI press ENTER \e[0m"
            read -r
            ;;
        z|Z|f|F )
            func_f
            echo
            echo -e " \e[41m Operation finished. To return to PacUI press ENTER \e[0m"
            read -r
            ;;
        y|Y|c|C )
            func_c
            echo
            echo -e " \e[41m Configuration files edited. To return to PacUI press ENTER \e[0m"
            read -r
            ;;
        x|X|p|P )
            func_ls
            echo
            ;;


        w|W|o|O )
            func_ua
            echo
            echo -e " \e[41m All AUR packages updated and reinstalled. To return to PacUI press ENTER \e[0m"
            read -r
            ;;
        v|V|n|N )
            func_la
            echo
            ;;


        d|D )
            func_d
            echo
            echo -e " \e[41m Downgrade finished. To return to PacUI press ENTER \e[0m"
            read -r
            ;;
        a|A )
            func_a
            echo
            echo -e " \e[41m Search (and installation) from AUR finished. To return to PacUI press ENTER \e[0m"
            read -r
            ;;


        h|H )
            func_help                                                               # call full help page
            echo
            ;;
        0|q|Q )
            pacui_clean && exit 0                                                   # clear terminal screen first (alternatively, "reset" works as well, but then the terminal history is lost). the "exit" command quits pacui.
            ;;


        * )                                                                         # do this, if $choice variable contains anything else not offered above
            echo -e " \e[41m Wrong option \e[0m"
            echo -e "  Please try again...  "
            sleep 2
            ;;

    esac                                                                            # close case-loop

# now, the infinite while-loop will start again from its top by clearing the terminal screen and redrawing the UI

done                                                                                # close while-loop
