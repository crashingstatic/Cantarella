# Cantarella
#### Poison your hash to defend your kingdom.

This is a very simple script that poisons /etc/shadow hashes. It will avoid poisoning the hashes of users that currently exist to allow for transparent operation (no one will care that it's there).
  
It is currently tooled for use with sha512crypt hashes. If your system uses a different hash type, replace the `PASSWORD` value at the top of the script with your own. Use the `mkpasswd` utility to generate hashes and don't forget to escape the $'s.
  
Requires root password to run. Disables root account login after running.
  
I wrote in some nice features:
  
  *  Checks to ensure sudoers is properly configured with at least one member of the `sudo` group 
  *  Creates dummy accounts (default: 26 accounts) that mimic a sudo member account in terms of group membership, home directory folders, and login shell. To an unprivileged user, it should be difficult to tell the difference between a real account (that you can log into) and a fake one.
  *  Does your organization use a template for user names? (i.e. first initial + last name + number)
     *  Cantarella accepts custom user lists as a `$1` command line argument for added stealth.
  *  Shuffles wordlists before account creation
  *  Random number generator for UID and GID  
     *  Normal user creation in Linux/UNIX system use the next available sequential number for GID and UID  
     *  Cantarella takes the number of fake accounts and uses twice that number as an upper limit for randomly-generated UID and GID  
     *  Accounts created normally after Cantarella is run have UIDs that fit in between the fake accounts, making Cantarella more stealthy over time (use `pwck -s` and `grpck -s` to sort /etc/passwd and /etc/group to take advantage of this feature)
  
##### Cantarella is a force multiplying defense against any attacks on PAM-authenticated protocols.
