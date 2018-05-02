     _____ _               _____  _____
    /__   (_)_ __  _   _  / ___/ /_  _/
       | || | '_ \| | | |/ /     / /
       | || | | | | |_| / /___/\/ /_  
       |_||_|_| |_|\__, \____/\____/
                   |___/

TinyCI
======

A minimal Continuous Integration system, written in ruby, powered by git. MIT licensed.

RDoc documentation is available at [rubydoc.org](https://www.rubydoc.info/gems/tinyci)

### Motivation

Existing CI solutions like [Travis](https://travis-ci.org) and [Jenkins](https://jenkins.io) run as daemons requiring large amounts of RAM, typically in their own virtual machines. In particular Travis and systems like it are designed as SaaS products, and it's not really feasible to self-host them.

A more lightweight system was desired, for use with small scale personal projects.

### Architecture

#### Requirements

TinyCI is written in ruby 2. It is not known exactly how recent a version of git is required, however development and testing was carried out against 2.7.4, the version packaged for ubuntu 16.04.

It does not have a heavy dependency on ruby 2, mainly making use of convenient syntactic features. Porting to ruby 1.9 would be very simple.

#### Stages

TinyCI is executed via git `post-update` hooks. When a new commit is pushed, the following steps are executed:

1. Clean  
    The [export path](#Export_Path) is removed
2. Export  
    A clean copy of the commit is placed at the [export path](#Export_Path). Clean in this context means without any .git directory or similar.
3. Build  
    The project's build command is executed
4. Test  
    The project's test command is executed

Finally the result is stored in git using the [git-notes](https://git-scm.com/docs/git-notes) feature. This is how TinyCI determines which commits to run against.

#### Eligible Commits

When TinyCI is executed, it runs against all eligible commits, from oldest to newest. At the present time, all commits without any `tinyci-result` git-notes object attached are eligible. This means that the first time TinyCI executes, it will run against every commit in the repository's history. 

While this is obviously suboptimal, note that if no configuration file is found, the exported copy of the commit is deleted and TinyCI moves on to the next commit, so this will not create a huge number of extraneous exports. It would be desirable to check for the presence of the config file before exporting the entire commit with a call to `git-cat-file`, see the [TODO section](#Limitations_TODO) below.

#### Executor Classes

Building and Testing are done by subclasses of {TinyCI::Executor}. An instance of each is created for every commit TinyCI runs against. This enables "pluggable backends" for TinyCI. At present there is only the `ScriptBuilder` and `ScriptTester`, which just run a command specified in the config file.

#### Export Path

The export path is the location where exported copies of commits are placed. Currently it is hardcoded as a directory called `builds` under the repo root, or under the the `.git` directory in the case of a non-bare repository.

#### Configuration

TinyCI is configured with a YAML file named `.tinyci.yml` in the root directory of the repo. There are two sections, one for the builder and one for the tester. Each has a `class` key which specifies the {TinyCI::Executor} subclass to be used, and a `config` key which contains specific configuration for that executor. This `config` object can contain anything, it is passed wholesale to the executor object. For an example, see below, or see the example project.

#### Execution Model

TinyCI uses a pidfile to guarantee only a single executing process at a time. This ensures that multiple team members committing to a repository concurrently, or rapid commits in succession by a single user do not result in multiple concurrent executions of the test suite.

Because TinyCI checks anew for eligible git objects to run against after each iteration of its main loop, and runs until no more are found, in the event of multiple commits being pushed concurrently, or further commits being pushed while an initial commit is still being built and tested, the first TinyCI instance will eventually execute against all commits.

It is of course possible that commits might be pushed consistently faster than they can be tested, resulting in a never-to-be-cleared backlog; if this is the case the a more substantial CI solution is probably advisable for your project.

If you look in the source code you will also find `RktBuilder` and `RktTester`, these were experimental attempts to integrate the Rkt container runtime. They are not recommended for use but are left for users to examine.

#### Logging/Output

TinyCI is executed in a `post-update` git hook. As such, the output is shown to the user as part of the local call to `git push`. Once the TinyCI hook is running, the local git process can be freely killed if the user does not wish to watch the output - this will not affect the remote execution of TinyCI.

As well as logging to stdout, the TinyCI process writes a `tinyci.log` file in each exported directory.

#### Limitations/TODO

* TinyCI currently has no support for running a script on success or failure of the test script. This feature would allow for notifications to be sent, eg. slack bots, email, etc. It would also enable TinyCI to act as part of an automated deployment system.

* As mentioned above, when TinyCI is executed against a commit without a configuration file, it exports the whole directory, finds the config file to be missing, then deletes the export. As such, when TinyCI installed against an existing project with many commits, this process will happen for every commit, wasting a lot of time and churning the disk.  
Instead, it would be preferable to check for the config file before doing the export, with a call to `git-cat-file`. An additional way to handle this would be to prevent the processing of commits created prior to the installation of TinyCI, perhaps by marking them with git-notes at install time, or by checking the creation date of the hook file.
 
* Presently, if a user kills their local git process while TinyCI is running, it will continue to execute on the server. If they then push another commit, the original TinyCI process will go on to test the second commit as well, as expected. However, the output from the second git push will simply consist of an error message describing the behavior.  
Instead, this second TinyCI execution should begin tailing the output of the first process, perhaps gaining direct access to it's stdout stream.

* It would be desirable to add a command to the TinyCI binary to SSH into the remote server and tail the the log output of a currently running TinyCI process, enabling functionality similar to that described in above, but without making a new commit.

* The exported copies of each build are left on the disk forever. This will obviously eat disk space. One could handle deleting/compressing them with a cronjob, however it would be desirable to integrate this functionality into TinyCI and to automate it.

* More configuration options should be added, eg. specification of the export path.

* In general, more local functionality for the TinyCI binary would be desirable, some way to retrieve the results of tests and query them from the local clone for example, or some way to show them in `git log` output.

### Usage

#### Instructions

First, add a configuration file to your project:

    cat <<EOF > .tinyci.yml
    builder:
      class: ScriptBuilder
      config:
        command: build.sh
    tester:
      class: ScriptTester
      config:
        command: test.sh
    EOF

This config assumes you have files called `build.sh` and `test.sh` in the root of your project that execute the appropriate commands.

TinyCI is distributed as a ruby gem. Install it like so:

    gem install tinyci
    
The gem should be installed on the remote server where you want the tests to execute. On that server, install TinyCI into your repository with the install command:

    tinyci install
    
Now, commit the configuration file and push it to your remote repository. As discussed above, this will currently result in a large amount of output as every previous commit is exported, found to be missing a config file and then the export deleted. Eventually you will see your build and test scripts executed.

#### Example Project

Here we will demonstrate cloning the [tinyci-example](https://github.com/JonnieCache/tinyci-example) project, creating a bare clone of it to simulate our server where the tests will run, and pushing a commit to see TinyCI in action.

The example project has very simple build and test scripts written in bash.

First, create a directory to store both clones:

    $ mkdir tinyci-test
    $ cd tinyci-test

Clone the example project from github:

    $ git clone https://github.com/JonnieCache/tinyci-example.git
    
    Cloning into 'tinyci-example'...
    remote: Counting objects: 8, done.
    remote: Compressing objects: 100% (6/6), done.
    remote: Total 8 (delta 0), reused 8 (delta 0), pack-reused 0
    Unpacking objects: 100% (8/8), done.
    
Clone it again into a bare repository:

    $ git clone --bare tinyci-example tinyci-example-bare
    
    Cloning into bare repository 'tinyci-example-bare'...
    done.
    
Install tinyci:

    $ gem install tinyci
    
Install the tinyci hook into our bare clone:

    $ cd tinyci-example-bare
    $ tinyci install
    
    [09:48:42] tinyci post-update hook installed sucessfully
    
Go into our initial clone and make a change:

    $ cd ../tinyci-example
    $ echo "foo" > bar
    $ git add bar
    $ git commit -m 'foobar'
    
    [master cebb4ec] foobar
     1 file changed, 1 insertion(+)
     create mode 100644 bar
    
Add our bare repo as a remote:

    $ git remote add test ../tinyci-example-bare
    
Push the commit and watch tinyci in action:

    $ git push test master
    
    Counting objects: 3, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (2/2), done.
    Writing objects: 100% (3/3), 268 bytes | 0 bytes/s, done.
    Total 3 (delta 1), reused 0 (delta 0)
    remote: [09:49:53] Commit: 22c36d0c1213361d06b385d2b55648985347e1f4
    remote: [09:49:53] Cleaning...
    remote: [09:49:53] Exporting...
    remote: [09:49:53] Building...
    remote: [09:49:53] Testing...
    remote: [09:49:53] foo bar
    remote: [09:49:53] Finished 22c36d0c1213361d06b385d2b55648985347e1f4
    remote: [09:49:53] Commit: cebb4ec18b89f093c7cdeb909c2c340708052575
    remote: [09:49:53] Cleaning...
    remote: [09:49:53] Exporting...
    remote: [09:49:53] Building...
    remote: [09:49:53] Testing...
    remote: [09:49:53] foo bar
    remote: [09:49:53] Finished cebb4ec18b89f093c7cdeb909c2c340708052575
    To ../tinyci-example-bare
       22c36d0..cebb4ec  master -> master
    
Here we are seeing TinyCI testing both the initial commit that is present in the github repo, an then the new commit that we just made. Breaking the test to see the failure output is left as an exercise for the reader.
    
### Contributing

Make an issue, send a pull request, you know the drill. Have a look at the [TODO section](#Limitations_TODO) for some ideas.

TinyCI has a suite of RSpec tests, please use them.

### Copyright

Copyright (c) 2018 Jonathan Davies. See [LICENSE](LICENSE) for details.
