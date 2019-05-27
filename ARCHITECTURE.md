TinyCI Architecture
===================

This document contains details about TinyCI's implementation.

### Architecture

#### Requirements

TinyCI is written in ruby 2. It is tested against git 2.7.4, the version packaged for ubuntu 16.04.

It does not have a heavy dependency on ruby 2, mainly making use of convenient syntactic features. Porting to ruby 1.9 would be very simple.

#### Eligible Commits

When TinyCI is executed, it runs against all eligible commits, from oldest to newest. At the present time, all commits without any `tinyci-result` git-notes object attached are eligible. This means that the first time TinyCI executes, it will run against every commit in the repository's history. 

While this is obviously suboptimal, note that if no configuration file is found, the exported copy of the commit is deleted and TinyCI moves on to the next commit, so this will not create a huge number of extraneous exports. It would be desirable to check for the presence of the config file before exporting the entire commit with a call to `git-cat-file`, see [TODO.md](TODO.md)

#### Executor Classes

Building and Testing are done by subclasses of {TinyCI::Executor}. An instance of each is created for every commit TinyCI runs against. This enables "pluggable backends" for TinyCI. At present there is only the `ScriptBuilder` and `ScriptTester`, which just run a command specified in the config file.

#### Export Path

The export path is where exported copies of commits are placed. Currently it is hardcoded: a directory called `builds` is created under the repo root, or under the the `.git` directory in the case of a non-bare repository. Within this, for each commit a directory named after the datetime along with the commit hash is created, and inside there you will find an `export` directory which contains the tree exported from that commit.

#### Configuration

TinyCI is configured with a YAML file named `.tinyci.yml` in the root directory of the repo. There are two sections, one for the builder and one for the tester. Each has a `class` key which specifies the {TinyCI::Executor} subclass to be used, and a `config` key which contains specific configuration for that executor. This `config` object can contain anything, it is passed wholesale to the executor object. For an example, see below, or see the example project.

#### Execution Model

TinyCI uses a pidfile to guarantee only a single executing process at a time. This ensures that multiple team members committing to a repository concurrently, or rapid commits in succession by a single user do not result in multiple concurrent executions of the test suite.

Because TinyCI checks anew for eligible git objects to run against after each iteration of its main loop, and runs until no more are found, in the event of multiple commits being pushed concurrently, or further commits being pushed while an initial commit is still being built and tested, the first TinyCI instance will eventually execute against all commits.

It is of course possible that commits might be pushed consistently faster than they can be tested, resulting in a never-to-be-cleared backlog; if this is the case the a more substantial CI solution is probably advisable for your project.
