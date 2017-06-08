# Sync Redmine ticket to Trello card

## Setup

1. Clone this plugin **outside from your Redmine installation path** in case of you may overwrite some files with the same names.
1. Copy `./plugins/redmine_trello_card_sync` to `./plugins/` of your Redmine installation (e.g: `cp -Rp ./plugins/redmine_trello_card_sync YOUR_REDMINE_HOME/plugins/`)
1. Change directory to your Redmine installation. (`cd YOUR_REDMINE_HOME`)
1. Run `bundle install --without development test` to install essential gems.
1. Run `bundle exec rake db:migrate_plugins RAILS_ENV=production` to setup plugin-related database tables. (In older version of Redmine, you may need to run `RAILS_ENV=production bundle exec rake redmine:plugins:migrate` instead)
1. Go to `http(s)://YOUR_REDMINE_HOST/settings/plugin/redmine_trello_card_sync`, enter the essential settings to enable this plugin.
    * Get your API key (32 characters long) & member token (64 characters long) from [here](https://trello.com/app-key), note they are *different*, one is the value of "Key", another is what will you get from the "Token" link.

## Configuration

You can configure each project to toggle sync on or off, give its own Trello board ID and status-list mapping in projects' settings page.

Your board ID is such a 'board_random_id' value like `abXYzWtB` which you can get it at your board's URL like `https://trello.com/b/`*board_random_id*`/board_title`

When configure status-list mapping, enter an one-by-one pair between two textareas, like:
  * Redmine statuses for mapping:
    * New
    * InProgress
    * Resolved
    * Closed
  * Trello lists for mapping:
    * Task backlogs
    * In progress
    * Done
    * `//close` **(this is a magic word in order to notify this plugin to close the Trello card)**
