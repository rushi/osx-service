## Mac OS launchctl utility

Managing services on OSX is pretty painful. Service scripts are XML files usually present in `~/Library/LaunchAgents` and a restart usually involves something like:

```
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.elasticsearch.plist
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.elasticsearch.plist
```

which is ugly, hard to remember and `launchctl` has no way of listing all available services which can reside in multiple directories:

* /System/Library/LaunchDaemons
* /System/Library/LaunchAgent
* /Library/LaunchDaemons
* /Library/LaunchAgents
* ~/Library/LaunchAgents

I prefer the simple unix way of just doing:

```
service elasticsearch restart
```

This script allows you todo just that.

## Usage

The script supports a partial match of a service name. It will exit on error if no of more than one service is found.

* **service php**
 * searches for a plist containing `php`
* **service php load|unload|reload**
 * insert or remove a plist from `launchctl`
* **service php start|stop|restart**
 * manage a daemon, but leave it in `launchctl`  (does not work with Agents)
* **service php link**
 * If you use [Homebrew](http://brew.sh/), which you should, it will link the plist of this Formula into `~/Library/LaunchAgents`, reloading if needed.
 Very useful when upgrading.

## Installation

Copy `service.sh` into `$PATH` and symlink it to `service` or anything other command you prefer

## LICENSE

The original work was developed by [Sébastien Lavoie (@lavoiesl)](https://github.com/lavoiesl) as a gist [https://gist.github.com/lavoiesl/6160897](https://gist.github.com/lavoiesl/6160897). I have only fine tuned some of the code and released it as a Github Repo
