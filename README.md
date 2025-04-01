# Elastic Homebrew Tap

This tap is for products in the Elastic stack.

## How do I install these formulae?

Install the tap via:

    brew tap digitalspacestdio/elastic

Then you can install individual products via:

    brew install digitalspacestdio/elastic/elasticsearch-full

The following products are supported:

* Elasticsearch `brew install digitalspacestdio/elastic/elasticsearch-full`
* Logstash `brew install digitalspacestdio/elastic/logstash-full`
* Kibana `brew install digitalspacestdio/elastic/kibana-full`
* Beats
  * Auditbeat `brew install digitalspacestdio/elastic/auditbeat-full`
  * Filebeat `brew install digitalspacestdio/elastic/filebeat-full`
  * Heartbeat `brew install digitalspacestdio/elastic/heartbeat-full`
  * Metricbeat `brew install digitalspacestdio/elastic/metricbeat-full`
  * Packetbeat `brew install digitalspacestdio/elastic/packetbeat-full`

## How do I ensure my configuration is still up to date after the branch renaming?

Run the following command to update your configuration:

    brew untap digitalspacestdio/elastic --force
    brew tap digitalspacestdio/elastic

Verify your configuration is based on the `main` branch with:

    git -C $(brew --prefix)/Library/Taps/elastic/homebrew-tap status

You should have the following output:

    On branch main
    Your branch is up to date with 'origin/main'.

## Documentation
`brew help`, `man brew` or check [Homebrew's documentation](https://github.com/Homebrew/brew/blob/master/docs/README.md).

## Troubleshooting
### Calling bottle :unneeded is deprecated!

When I execute `brew update`, the following warning appears

    Warning: Calling bottle :unneeded is deprecated! There is no replacement.

This is related to your configuration not being up-to-date. Your are still using the legacy `master` branch which is not updated anymore. Please [follow the instructions to update](#how-do-i-ensure-my-configuration-is-up-to-date) your local configuration to use the `main` branch.
