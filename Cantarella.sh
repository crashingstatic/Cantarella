#!/bin/bash

#===Cantarella===
# "Cantarella was a poison allegedly used by the Borgias during the papacy of Pope Alexander VI.
# If it did exist, it left no trace."
#
# Aaron Sawyer (@CrashingStatic)
# This will create a bunch of dummy accounts that look real
# Then it will poison all of their hashes so PAM will never authenticate
# It also poisons the hash for root

#Generated with mkpasswd like so:
#mkpasswd -m sha512crypt
#PASSWORD: SomeRandomString
#For once it actually doesn't matter

PASSWORD="\$6\$INwRx61Nl/6\$sA9QCgGLGrp0nYSTp7MXY3UrS/vEmz.Hs7QFkOe0LtB9QYQEwl.lBCSub7wpWTsik9rBl3bpV3zK0ElQoVKNH/"
OLDPWD="$PWD"

#if whoami != root -> exit
USERNM=$(whoami)
if [ ! "$USERNM" == "root" ]; then
    echo "Please enter the root password to properly run this script or run this script as sudo"
    su root -c './DnD.sh'
    exit
fi

#Check that sudoers is set up properly
SUDOMKR=$(grep -E "^%sudo" /etc/sudoers)
[[ ! -z "$SUDOMKR" ]] || echo -ne "%sudo\tALL=(ALL:ALL) ALL" >> /etc/sudoers
unset SUDOMKR

#Find out what non-root users are currently on the system
REALUSRS=$(grep -vE '^root|/sbin/nologin|/bin/false|/bin/sync' /etc/passwd | cut -d":" -f1)

[[ ! -z "$REALUSRS" ]] && {

#Check to make sure at least one is a member of sudo
USERGRP=()
ALLUSER=()
for luser in $REALUSRS
do
    SUDOMKR=$(groups "$luser" | grep "sudo")
    ALLUSER+=("$luser")
    #If SUDOMKR is not empty, add the luser to USERGRP (a list of all sudo users)
    [[ ! -z "$SUDOMKR" ]] && USERGRP+=("$luser")
    unset SUDOMKR USRCOMTMP
done

len=${#USERGRP[@]}

[[ $len -eq 0 ]] && {

    echo -n "Current non-root users: "
    for luser in ${#ALLUSER[@]}
    do
        echo -n "$i "
    done

    echo
    read -p "You need a user to be a member of sudo for admin purposes. You will not be able to use root after this. Please pick an existing user to add to sudoers. DO NOT PICK AN OBVIOUS USERNAME LIKE admin: " USERNM

    } || {
        USERNM="${USERGRP[0]}"
        SUDOMKR=1
    }
} || {
    read -p "You need a non-root user for this to work. Please enter a login name and we will take care of the rest. DO NOT PICK AN OBVIOUS NAME LIKE admin: " USERNM
    export USRCOMTMP="$USERNM"
    /usr/sbin/useradd -m -s "$NEWSHELL" -p "$PASSWORD" "$USERNM"
    echo "The password for $USERNM is $PASSWORD. Change it when you login"

    cd /root
    find . -type d | while read DIRS
    do
        mkdir -p /home/"$USRCOMTMP/$DIRS"
    done
    chown -R $USERNM:$USERNM /home/$USERNM

}

[[ ! -z "$SUDOMKR" ]] || /usr/sbin/usermod -aG sudo "$USERNM"

#After adding that user to sudo, remember which groups user belongs to >>> $USERGRP
USERGRP=$(/usr/bin/groups "$USERNM" | cut -d' ' -f3- | tr ' ' ',')

#Add 20 other users, add all users to all groups that real user is a member of, honey (place "[FAKE]" in hash) everything except for real users

[[ ! -z $1 ]] && { mapfile -t PRE < "$1" ; PRE+=("root") ; } || {

# Add a buttload (384 Gallons) of dummy users
declare -a PRE=("admin"
                "alice"
                "bob"
                "charlie"
                "denise"
                "eve"
                "frank"
                "george"
                "heather"
                "ida"
                "juliet"
                "kevin"
                "louise"
                "mallory"
                "nicholas"
                "olga"
                "peter"
                "quinn"
                "roxanne"
                "samantha"
                "trevor"
                "upton"
                "victoria"
                "whitney"
                "yani"
                "zebidiah"
                "root"
    )
}
#Shuffle the array so that alphabetical ordering doesn't give us away...
POST=()
# Function to check if item already exists in array
function checkArray
{
    for item in ${POST[@]}
    do
		[[ "$item" == "$1" ]] && return 0 # Exists in dest
    done
    return 1 # Not found
}
# Main loop
while [ "${#PRE[@]}" -ne "${#POST[@]}" ]
do
	rand=$[ $RANDOM % ${#PRE[@]} ]
	checkArray "${PRE[$rand]}" || POST=(${POST[@]} "${PRE[$rand]}")
done

#Generate a random number between 1000 and 1000+MODU
roll () {

	#Find length of dummy username array, multiply by two, add 1000
	UNUM=$(( 2 * ${#POST[@]} ))
	BASE=$(grep -E "^"$USERNM":" /etc/passwd | cut -d":" -f3)
	while true
	do
		MODU=$(($BASE + RANDOM % $UNUM))
		#Then check if already in use, if so, generate new and try again
		[ $(cat /etc/passwd | cut -d":" -f3,4 | grep "$MODU") ] || break
	done
	echo "$MODU"
}

cd $(find /home -maxdepth 1 -type d -exec bash -c "echo -ne '{}\t'; ls '{}' | wc -l" \; | sort -k2 -nr | head -n1 | cut -f1)
NEWSHELL=$(grep "$USERNM" /etc/passwd | cut -d":" -f7)
unset USRCOMTMP

for i in "${POST[@]}"
do
    export TMPID=$(roll)
    export USRCOMTMP="$i"
    EXISTING=$(grep -E "^$i" /etc/passwd)
    #If the user exists...
    [[ ! -z "$EXISTING" ]] && {
        #And that user is not root...
        [[ "$i" == "root" ]] || {
            echo "User $i already exists... skipping"; unset EXISTING; continue; }
    } || {
    #But if the user does not exist...
	/usr/sbin/groupadd -g "$TMPID" "$i"
        /usr/sbin/useradd -m -s "$NEWSHELL" -p "$PASSWORD" -u "$TMPID" -g "$TMPID" "$i"

            find . -type d | while read DIRS
        do
            mkdir -p /home/"$USRCOMTMP/$DIRS"
        done

        chown -R $i:$i /home/$i
        chmod -R 770 /home/$i
    }

    awk '
    /^'$USRCOMTMP':/    { n=split ( $0, f, "$" );
        if (n>0) {
            $0=f[1]"$"f[2]"$"f[3]"$[FAKE]"f[4] ;
        }
    }
    { print $0; }
    ' /etc/shadow >shadow.new
    unset USRCOMTMP EXISTING
    chmod 600 shadow.new
    chown root:root shadow.new
    mv shadow.new /etc/shadow
    /usr/sbin/usermod -aG "$USERGRP" "$i"
done


/usr/sbin/pwck -s
/usr/sbin/grpck -s

cd "$OLDPWD"
rm -f Cantarella.sh
echo "Logout then log back in for the changes to take effect"
exit
