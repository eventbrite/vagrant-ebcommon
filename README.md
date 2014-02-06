# vagrant-ebcommon

A [Vagrant](http://www.vagrantup.com/) plugin to handle various Eventbrite workflows.

Using this plugin we can:

    - take actions before we bring up the virtualenv
    - take actions before we provision the virtualenv
    - add custom commands like "start-selenium" to distribute commands to our
      dev team that run on the host machine

## Installation

``` bash
vagrant plugin install vagrant-ebcommon
```

## Usage

This plugin exposes the following additional vagrant commands:

* clear-requirements-cache: will remove the pip_requirements_cache file within the VM
* start-selenium: will ensure selenium is started on the host machine
* stop-selenium: will stop selenium on the host machine

## Development

``` bash
$ bundle
$ bundle exec vagrant <any vagrant option or command defined by the plugin>
```

## Contributing

1. Create your feature branch (`git checkout -b my-new-feature`)
2. Commit your changes (`git commit -am 'Add some feature'`)
3. Push to the branch (`git push origin my-new-feature`)
4. Create new Pull Request
