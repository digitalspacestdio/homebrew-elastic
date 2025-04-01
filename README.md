# Elastic Homebrew Tap

This tap is for products in the Elastic stack.

## How do I install these formulae?

Install the tap via:

    brew tap digitalspace/elastic

Then you can install individual products via:

    brew install digitalspace/elastic/elasticsearch-full

The following products are supported:

* Elasticsearch `brew install digitalspace/elastic/elasticsearch-full`
* Logstash `brew install digitalspace/elastic/logstash-full`
* Kibana `brew install digitalspace/elastic/kibana-full`
* Beats
  * Auditbeat `brew install digitalspace/elastic/auditbeat-full`
  * Filebeat `brew install digitalspace/elastic/filebeat-full`
  * Heartbeat `brew install digitalspace/elastic/heartbeat-full`
  * Metricbeat `brew install digitalspace/elastic/metricbeat-full`
  * Packetbeat `brew install digitalspace/elastic/packetbeat-full`

## How do I ensure my configuration is still up to date after the branch renaming?

Run the following command to update your configuration:

    brew untap digitalspace/elastic --force
    brew tap digitalspace/elastic

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
