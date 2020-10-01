# Git Tutorial Mosh Hamedani
# Git Kraken - Good Gui!




# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------


# Username
git config --global username "Matt Grove"

# Email
git config --global email "matthewgrove95@gmail.com"

# Set the core editor for Git
git config --global core.editor "atom --wait"

# On mac set to input - on pc set to true - deals with new lines \n \c
git config --global core.autocrlf input

# Set the default Diff tool - doesn't work for atom!
git config --global diff.tool atom

git config --global difftool.atom.cmd "atom --wait --diff $LOCAL $REMOTE"

# Open config file in the default editor
git config --global -e

# Get help
git config --help

# Shorter summary of help file
git config -h



# Add custom aliases
git config --global alias.unstage "log --pretty=format:'%h %Cgreen%an'"

# Unstage - add an alias to type
git config --global alias.unstage "restore --staged ."

# --help - all the different values are in the middle of the sheet
# %h = hash
# %an = author name
# %s = description
# %Cgreen = change color to green
# %Creset = reset color






# ------------------------------------------------------------------------------
# Basics - Managing Commits
# ------------------------------------------------------------------------------

# Commit 5 - 10 a day on average



# Initialise repo
git init

git add *

# singe file
git add file1.txt

# a type of file
git add *.js


# Commit to repo
git commit -m ""

# If need more info on this then do it by adding a small file
git commit


# Commit without staging first
git commit -am ""
git commit -a -m ""

# List the files in the staging
git ls-files


# Remove from both Git and File system
git rm file2.txt


# Rename or remove files
git mv

# Git Ignore file
.gitignore
logs/ # Folder
main.log # File
*.log # Pattern on Extensions


# Remove only from staging area!
git rm -cached app.bin

# Recursively remove
git rm -cached -r bin/app.bin


# left column is staging column, right is the working directory
# M - Modified
# ? - Created
# A - Added
# D - Deleted

# MM - Modified in stage and also in the working directory, needs to be staged








# ------------------------------------------------------------------------------
# Changes - Logs, History & Alterations
# ------------------------------------------------------------------------------



# Find what has been changed prior to staging
git diff

# Find what has been changed at the staging level
git diff --staged

# Take a look at history
git log

# Take a look at history - single line
git log --oneline

# Take a look at history - single line - reversed
git log --oneline --reverse

# Log of single commit - see what happened
git show xxxx

# Log of previous commit - steps backwards! head minus 1
git show HEAD~1

# Show the latest version of files on this commit
git show HEAD~1:.gitignore


# Show the exact contents of the files
git ls-tree

# commits
# blob = files
# tree = folder
# tags

# each file has a unique identifier
# it means you can look at the content of the files / directories etc


# Show what files have been changed in commmit
git log --stat

# Show what edits have
git log --oneline --patch

# Last 3 commits
git log -3

# Show what files have been changed in commmit on file
git log --stat file1.txt

# Show the actual edits of the file
git log --oneline --patch file1.txt


# Filter by Author
git log --author="Matt"


# Filter by date
git log --before="2020-08-17"
git log --after=""
git log --after="yesterday"

# Find commits that contain - Case Sensitive!
git log --grep="GUI"

# Contain function, anything
git log -S"onClick()"

# Get only the commits between
git log 555b62e..fb0d184

# Get only the files that touch a particular file (file1)
git log -- file1.txt


# Get only the changes that happened  ona particular file (file1)
git log --patch -- file1.txt

# Show commit 2 steps back - all details
git show HEAD~2

# Show only the names of the files that have been added, modified or deleted
git show HEAD~2 --name-only

# Show only the names of the files a m or d, and their status
git show HEAD~2 --name-status





# ------------------------------------------------------------------------------
# Unstaging
# ------------------------------------------------------------------------------


# Move back to previously staged state
git restore --staged file1.js


# Discard local changes
git restore file1.js


# Discard all stages - you can't get this back! All directories also -d
git clean -fd


git restore --source=HEAD~1 file1.js






# ------------------------------------------------------------------------------
# Check differences between two commits
# ------------------------------------------------------------------------------

# See the changes between two files
git diff HEAD~2 HEAD

# See the changes between two files on particular file
git diff HEAD~2 HEAD file1.txt

# See the names of files that have been changed between two commits
git diff HEAD~2 HEAD --name-only

# See the names of files and their status that have been changed between two c's
git diff HEAD~2 HEAD --name-status



# ------------------------------------------------------------------------------
# Restore to eariler commit - only for viewing! - do not commit to it..
# ------------------------------------------------------------------------------


# This will jump back to previous commit in history - detached head
# (head has been detactched from master (latest), gone back in time so is detached)
git checkout ID_GOES_HERE

# show only the commits up to the HEAD
# git log --oneline


# Shows all commits up to master
git log --oneline --all

# Go back to the latest version (master)
git checkout master






# ------------------------------------------------------------------------------
# Find a bug - bisect
# ------------------------------------------------------------------------------


# Initialise Bisect
git bisect start

# tell it the latest commit is bad
git bisect bad

# tell it where we had a commit with no bug
git bisect good ID_GOES_HERE


# then go through - is the bug there?
# it splits the commits in half between the step (if good)
git bisect good

# If we find the bug
git bisect bad


# on zero revisions, git bisect bad again - it will tell you
# what the first bad commit is

# this will take back to the master branch
git bisect reset




# ------------------------------------------------------------------------------
# Find all users
# ------------------------------------------------------------------------------


# Find all users and what they have
git shortlog

# numbered, suppress summary, show email address
git shortlog -nse

# before / after dates
git shortlog --before="" --after=""





# ------------------------------------------------------------------------------
# Get back deleted file
# ------------------------------------------------------------------------------

# check the previous commits for where this file existed
git log --oneline -- file1.txt


# The latest file won't contain it as it was deleted! need the one before
git checkout ID_GOES_HERE file1.txt

# This brings it back into the master branch !
# This is ideal for real world scenario - just delete files going forwards!





# ------------------------------------------------------------------------------
# Blame - 
# ------------------------------------------------------------------------------
