#!/bin/ksh
help() {
        echo '\n'
        echo "auto_help (2017 Sept)"
        echo '\n'
        echo "usage: auto_help -f [input file] [-o | -s] [arguments]"
        echo '\n'
        echo "Parameters:"
        echo "  -h  or  --help  Prompt this help message."
        echo "  --------------------"
		echo "  -e  or  --export  Export specific jobs to a JIL file. This parameter doesn't take any arguments."
        echo "  --------------------"
        echo "  -f  or  --file  JIL file you want to use as an input."
        echo "  --------------------"
        echo "  -o  or  --owner Set the owner"
        echo "  auto_help --file input.jil --owner <OWNER>"
        echo "  This will create input.jil.updated with the owner change to <OWNER>."
        echo "  --------------------"
        echo "  -s  or  --status        Set a jobs list to a specified status. List can be a JIL file or a auto_help exported list."
        echo "  auto_help --file input.jil --status OH"
        echo "  This will set the jobs from the list to the ON HOLD status."
        echo "  The following list contains the status options."
        echo '\n'
        echo '  +-----------------+'
        echo '  | AC - ACTIVATED  |'
        echo '  | FA - FAILURE    |'
        echo '  | IN - INACTIVE   |'
        echo '  | OH - ON_HOLD    |'
        echo '  | OI - ON_ICE     |'
        echo '  | QU - QUE_WAIT   |'
        echo '  | RE - RESTART    |'
        echo '  | RU - RUNNING    |'
        echo '  | ST - STARTING   |'
        echo '  | SU - SUCCESS    |'
        echo '  | TE - TERMINATED |'
        echo '  +-----------------+'
        echo '\n'
        exit
}

format() {
        if [ "x$format" = "x" ]; then
                echo "Which format you want to export this data?"
        echo "  1) JIL file format"
        echo "  2) Human Readable Format"
                        while true; do
                                        case $format in
                                        1|2)
                                                        break ;;
                                        *)
                                                        printf "Enter [1|2] : "
                                                        read -r format ;;
                                        esac
                        done
                printf "Export file name : "
                read -r exportfile
        elif [ $format -eq 1 ] && [ $outputformat = "hr" ]; then
                # convert to JIL format
                echo "Converting to JIL format..."
				while IFS=\| read -r line; do
					autorep -j $line -q >> "$exportfile.jil"
                done < "$exportfile"
				rm $exportfile
				exportfile="$exportfile.jil"
        elif [ $format -eq 2 ] && [ $outputformat = "jil" ]; then
                # convert to hr 
                echo "Converting to Human Readable format..."
				
				# do stuff
        fi
		if [ -e $exportfile ]; then
			echo "$exportfile has been generated"
		fi
}

exportation() {
        echo "Which jobs do you want to export ?"
        echo "  1) From specific box"
        echo "  2) From specific machine"
        echo "  3) From specific status"
        echo "  4) From specific owner"
        while true; do
                case $opt in
                1)
                        printf "Targeted Box : "
                        read -r target
                        format
						echo "Processing..."
                        autorep -J $target -q > "$exportfile"
						outputformat="jil"
                        format
                        break;;
                2)
				        printf "Targeted Machine : "
                        read -r machine
                        format
						echo "Step 1) Exporting all jobs..."
						autorep -j ALL -q > "/tmp/all-autosys-jobs.$exportfile"
                        mkdir /tmp/autosystemp
						i=0
						echo "Step 2) Sorting jobs out..."
						while IFS=\| read -r "line"; do
								if [ `echo $line | grep '/* ------' | wc -l` -eq 1 ]; then
										i=$((i+1))
								fi
								echo "$line" >> "/tmp/autosystemp/file-temp-$i"
						done < "/tmp/all-autosys-jobs.$exportfile"
						echo "Step 3) Getting jobs from $machine..."
						for file in /tmp/autosystemp/*; do
								while read line; do
										if [ `echo $line | grep "machine: $machine" | wc -l` -eq 1 ]; then
												cat $file >> "$exportfile"
										fi
								done < $file
						done
						rm -rf /tmp/autosystemp/
						rm "/tmp/all-autosys-jobs.$exportfile"
						outputformat="jil"
                        format
                        break;;
                3)
                        while true; do
                                case $statusToExport in
                                "AC"|"FA"|"IN"|"OH"|"OI"|"QU"|"RE"|"RU"|"ST"|"SU"|"TE")
                                        break ;;
                                *)
                                        printf "Collect jobs from which status [AC|FA|IN|OH|OI|QU|RE|RU|ST|SU|TE] : "
                                        read -r statusToExport ;;
                                 esac
                        done
						format
                        echo "Processing..."
                        autorep -wj ALL | grep $statusToExport | sed 's/^ *//' | tr -s " " | cut -d " " -f -1 >> "$exportfile"
						outputformat="hr"
                        format
                        break;;

                4)
                        format
                        # select jobs from specific owner
                        format
                        break ;;
                *)
                        printf "Enter [1|2|3|4] : "
                        read -r opt ;;
                esac
        done


}

process() {
        if [ ! -n "$file" ] && [[ -n "$owner" || -n "$status" ]]; then
                echo "You need to specify an input file! Use auto_help --help."
                exit
        else
                if [ -n "$status" ]; then
                        case $status in
                                "AC" )
                                        status="ACTIVATED";;
                                "FA" )
                                        status="FAILURE";;
                                "IN" )
                                        status="INACTIVE";;
                                "OH" )
                                        status="JOB_ON_HOLD";;
                                "OI" )
                                        status="JOB_ON_ICE";;
                                "QU" )
                                        status="QUE_WAIT";;
                                "RE" )
                                        status="RESTART";;
                                "RU" )
                                        status="RUNNING";;
                                "ST" )
                                        status="STARTING";;
                                "SU" )
                                        status="SUCCESS";;
                                "TE" )
                                        status="TERMINATED";;
                                *   )
                                 echo "Status incorrect, use auto_help --help"
                                esac
                                while IFS=\| read -r line; do
                                        if [ `echo $line | grep "insert_job:" | wc -l` -eq 1 ]; then
                                                filetype=JIL
                                                break
                                        fi
                                done <"$file"
                                if [ $filetype = "JIL" ]; then
                                        while IFS=\| read -r line; do
                                                if [ `echo $line | grep "insert_job:" | wc -l` -eq 1 ]; then
                                                        if [ $status = "JOB_ON_HOLD" ] || [ $status = "JOB_ON_ICE" ]; then
                                                                sendevent -E $status -J `echo $line | cut -d " " -f 2`
                                                        else
                                                                sendevent -E CHANGE_STATUS -s $status -J `echo $line | cut -d " " -f 2`
                                                        fi
                                                fi
                                        done <"$file"
                                else
                                        while  IFS=\| read -r line; do
                                                if [ $status = "JOB_ON_HOLD" ] || [ $status = "JOB_ON_ICE" ]; then
                                                        sendevent -E $status -J `echo $line`
                                                else
                                                        sendevent -E CHANGE_STATUS -s $status -J `echo $line`
                                                fi
                                        done <"$file"
                                fi
        else
                        while IFS=\| read -r line; do
                                if [ `echo $line | grep "insert_job:" | wc -l` -eq 1 ]; then
                                        jobname=`echo $line | cut -d " " -f 2`
                                        jobtype=`echo $line | cut -d " " -f 4`
                                        echo " update_job: $jobname job_type: $jobtype" >> "$file.updated"
                                elif [ `echo $line | grep "owner:" | wc -l` -eq 1 ]; then
                                        if [ -n "$owner" ]; then
                                                echo " owner: $owner" >> "$file.updated"
                                        else
                                                echo "$line" >> "$file.updated"
                                        fi
                                else
                                        echo "$line" >> "$file.updated"
                                fi
                        done <"$file"
                        echo "$file.updated has been generated with your updated values."

                fi
        fi
}

main() {
        if [ `whoami` != "autosys" ]; then
        	echo "Script needs to be run as autosys user, please use following the command : su - autosys"
		exit
        fi
        if [ $# -eq 0 ]; then
                help
		elif [ $# -gt 1 ]; then
			for args in $*; do
				if [ $args = "-e" ] || [ $args = "--export" ]; then
					echo "--export can't be used with other parameters, please type auto_help --help"
					exit
				fi
			done
		fi
        while [ $# -ne 0 ];do
                if [ "$1" = "--owner" ] || [ "$1" = "-o" ]; then
                        if [ "$2" = "-f" ] || [ "$2" = "--file" ] || [ "$2" = "-s" ] || [ "$2" = "--status" ] || [ ! -n "$2" ]; then
                                echo "--owner needs a valid argument! Try auto_help --owner <owner>"
                                exit
                        fi
                        owner=$2
                        shift
                elif [ "$1" = "--status" ] || [ "$1" = "-s" ]; then
                        if [ "$2" = "-f" ] || [ "$2" = "--file" ] || [ "$2" = "-o" ] || [ "$2" = "--owner" ] || [ ! -n "$2" ]; then
                                echo "--status needs a valid argument! Try auto_help --status <AC|FA|IN|OH|OI|QU|RE|RU|ST|SU|TE>"
                                echo '\n'
                                echo '  +-----------------+'
                                echo '  | AC - ACTIVATED  |'
                                echo '  | FA - FAILURE    |'
                                echo '  | IN - INACTIVE   |'
                                echo '  | OH - ON_HOLD    |'
                                echo '  | OI - ON_ICE     |'
                                echo '  | QU - QUE_WAIT   |'
                                echo '  | RE - RESTART    |'
                                echo '  | RU - RUNNING    |'
                                echo '  | ST - STARTING   |'
                                echo '  | SU - SUCCESS    |'
                                echo '  | TE - TERMINATED |'
                                echo '  +-----------------+'
                                echo '\n'
                                exit
                        fi
                        status=$2
                        shift
                elif [ "$1" = "--file" ] || [ "$1" = "-f" ];then
                        if [ "$2" = "-o" ] || [ "$2" = "--owner" ] || [ "$2" = "-s" ] || [ "$2" = "--status" ] || [ ! -n "$2" ]; then
                                echo "--file needs a valid argument! Try auto_help --file <file.jil>"
                                exit
                        fi
                        file=$2
                        shift
				elif [ "$1" = "--export" ] || [ "$1" = "-e" ]; then
					exportation
					exit
                elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
                        help
                else
                        help
                fi
                shift
        done
        process
}

main $*
