# Sync Redmine ticket to Trello card

## Setup

1. Clone this plugin to `./plugins/` of your Redmine installation
2. Excute `RAILS_ENV=production bundle exec rake redmine:plugins:migrate`
3. Go to `/settings/plugin/redmine_trello_card_sync`, enter the essential settings to enable this plugin. (Get your API key & member token from [here](https://trello.com/app-key))

## Configuration

* When configure status-list mapping, enter an one-by-one pair between two textareas, like:
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
* You can configure each project to toggle sync, give its own Trello board ID and status-list mapping in projects' settings page.
