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

A more lightweight system was desired, for use with small-scale personal projects.

### Usage

TinyCI works by installing a `post-update` hook into your remote repository. When a commit containing a TinyCI config file is pushed, the commit is exported and commands are executed as defined in the config.

#### Instructions

First, add a configuration file to your project with the name `.tinyci.yml`:

    cat <<EOF > .tinyci.yml
    build: ./build.sh
    test: ./test.sh
    EOF

This config assumes you have files called `build.sh` and `test.sh` in the root of your project that execute the appropriate commands.

TinyCI is distributed as a ruby gem. Install it like so:

    gem install tinyci
    
The gem should be installed on the remote server where you want the tests to execute. On that server, install TinyCI into your repository with the install command:

    tinyci install
    
Now, commit the configuration file and push it to your remote repository. After some initial extraneous output (depending on the size of your repo's history,) you will see your build and test commands executed.

#### Example Project

There is an example project available at https://github.com/JonnieCache/tinyci-example
    
See that repo for a walkthrough demonstrating various TinyCI features.

#### Stages
Here is a brief overview of the operations TinyCI goes through when processing a commit:

```
  * clean
  * export

  before_build
  
  * build
  
  after_build_success
  after_build_failure
  after_build
  
  before_test
  
  * test
  
  after_test_success
  after_test_failure
  after_test
  
  after_all
```
`*` indicates an actual phase of TinyCI's execution, the rest are callbacks.

1. **Clean**  
    The [export path](ARCHITECTURE.md#Export_Path) is removed.
2. **Export**  
    A clean copy of the commit is placed at the [export path](ARCHITECTURE.md#Export_Path). Clean in this context means without any `.git` directory or similar.
3. `before_build`  
    The `before_build` hook is executed, and processing halts if the hook fails.
4. **Build**  
    The project's build command is executed.
5. `after_build_success`  
    If the build completed successfully, the `after_build_success` hook is executed.
6. `after_build_failure`  
    If the build failed, the `after_build_failure` hook is executed.
7. `before_test`  
    The `before_test` hook is executed, and processing halts if the hook fails.
8. **Test**  
    The project's test command is executed.
9. `after_test_success`  
    If the test completed successfully, the `after_test_success` hook is executed.
10. `after_test_failure`  
    If the test failed, the `after_test_failure` hook is executed.
11. `after_all`  
    The `after_all` hook is always exectued as the final stage of processing.

Finally the result is stored in git using the [git-notes](https://git-scm.com/docs/git-notes) feature. This is how TinyCI determines which commits to run against.

Note that the `before_build` and `before_test` hooks will halt the processing of the commit completely if they fail (ie. return a status > 0)

The `after_all` hook runs at the end of a commit's processing, whether or not the build/test stages have succeeded or failed.

To setup hooks, define a section like this in your config file:

```
hooks:
  after_build: ./after_build.sh
```

#### Interpolation

It is possible to interpolate values into the scripts defined in the TinyCI configuration file, using the [ERB](https://ruby-doc.org/stdlib/libdoc/erb/rdoc/ERB.html) syntax. Here is an example:

    build: docker build -t app:<%= commit %> .
    test: docker run app:<%= commit %> bundle exec rspec
    hooks:
      after_all: rm -rf <%= export %>
      
Here we are using the commit sha to tag our docker image, and then in our `after_all` hook we are removing the exported build directory, as in the docker use-case our build artifacts live in the local docker index.

The following variables are available for interpolation:

* `commit` the sha hash of the commit being processed
* `export` the absolute path to the commits exported tree

#### Compactor

With continued use, the [`builds`](ARCHITECTURE.md#Export_Path) directory will grow ever larger. TinyCI provides the `compact` command to deal with this. It compresses old builds into `.tar.gz` files.

"Old" in this context is defined using two options to the `tinyci compact` command:

* `--num-builds-to-leave` - How many build directories to leave in place, starting from the newest. Defaults to `1`.
* `--builds-to-leave` - A comma-separated list of specific build directories to leave in place.

The latter option is intended for use in an automated deployment system, to allow the script to run without removing builds that are being used somewhere else in the system. For a demonstration of this, see the [example project](#Example_Project).

To use it, simply run `tinyci compact` from the root of the repo you wish to compact.

#### Logging/Output

TinyCI is executed in a `post-update` git hook. As such, the output is shown to the user as part of the local call to `git push`. Once the TinyCI hook is running, the local git process can be freely killed if the user does not wish to watch the output - this will not affect the remote execution of TinyCI.

As well as logging to stdout, the TinyCI process writes a `tinyci.log` file in each exported directory.

### Architecture

Implementation details are described in a separate document, [ARCHITECTURE.md](ARCHITECTURE.md)

### Limitations/TODO

See [TODO.md](TODO.md)
    
### Contributing

Make an issue, send a pull request, you know the drill. Have a look at the [TODO section](#Limitations_TODO) for some ideas.

TinyCI has a suite of RSpec tests, please use them.

### Copyright

Copyright (c) 2019 Jonathan Davies. See [LICENSE.md](LICENSE.md) for details.
