* When TinyCI is executed against a commit without a configuration file, it exports the whole directory, finds the config file to be missing, then deletes the export. As such, when TinyCI installed against an existing project with many commits, this process will happen for every commit, wasting a lot of time and churning the disk.  
Instead, it would be preferable to check for the config file before doing the export, with a call to `git-cat-file`. An additional way to handle this would be to prevent the processing of commits created prior to the installation of TinyCI, perhaps by marking them with git-notes at install time, or by checking the creation date of the hook file.
 
* Presently, if a user kills their local git process while TinyCI is running, it will continue to execute on the server. If they then push another commit, the original TinyCI process will go on to test the second commit as well, as expected. However, the output from the second git push will simply consist of an error message describing the behavior.  
Instead, this second TinyCI execution should begin tailing the output of the first process, perhaps gaining direct access to it's stdout stream.

* It would be desirable to add a command to the TinyCI binary to SSH into the remote server and tail the the log output of a currently running TinyCI process, enabling functionality similar to that described in above, but without making a new commit.

* More configuration options should be added, eg. specification of the export path.

* In general, more local functionality for the TinyCI binary would be desirable, some way to retrieve the results of tests and query them from the local clone for example, or some way to show them in `git log` output.
