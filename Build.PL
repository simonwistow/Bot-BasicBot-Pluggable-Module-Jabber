#!/usr/bin/perl
use warnings;
use strict;

use Module::Build;

Module::Build->new(
    module_name => 'Bot::BasicBot::Pluggable::Module:::WebService',
    license => 'perl',
    requires => {
      'POE::Component::Server::HTTP' => '0',
      'Bot::BasicBot::Pluggable' => '0',
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
)->create_build_script;

