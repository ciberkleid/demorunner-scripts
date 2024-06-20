# demorunner-scripts


### Pre-requisites:

1. Install demorunner utility:
```shell
git clone https://github.com/cgcollab/demorunner
```

2. (Optional) Put `demorunner.sh` in your $PATH.


### Instructions:

1. Clone this repo and set DEMO_HOME to the root directory of the repo (e.g. `export DEMO_HOME=~/workspace/demorunner-scripts`)

2. Run a demo. 
Replace the demo file name below with name of the demo script you want to run.
```shell
demorunner.sh cnb-pack
```

> Note: Depending on the commands in each demo script, additional dependencies may be required.
> Most can probably be installed with a package manager such as Homebrew.

### Caveats from the author:

The scripts found in this repo incorporate some personal configurations that you may need to update.
For example:
- I have renamed `demorunner.sh` to `demorunner`
- I use `1Password` to manage passwords and some scripts use the `op` CLI to obtain passwords needed
- Some values are hardcoded, such as my GitHub org name

You may need to update corresponding entries in the scripts to accommodate your own preferences.