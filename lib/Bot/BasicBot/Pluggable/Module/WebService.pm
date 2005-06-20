package Bot::BasicBot::Pluggable::Module::WebService;
use base qw( Bot::BasicBot::Pluggable::Module );

use warnings;
use strict;

use POE::Component::Server::HTTP;

sub init {
  my $self = shift;

  my $server = POE::Component::Server::HTTP->new(
    Port => 1813,
    ContentHandler => { '/' => sub { $self->http_handler(@_) } },
  )->{httpd};

  $self->{server_alias} = $server;

  warn "init called, got server $server\n";
}

sub stop {
  my $self = shift;
  warn "stopping server";
  POE::Kernel->call($self->{server_alias}, "shutdown");
}

sub http_handler {
  my $self = shift;
  my ($request, $response) = @_;
  warn "request for ".$request->uri;

  $self->{reply_catcher} = [];

  # this is the canonical Thing You Do Not Do. Don't do it.
  my $q = $request->uri->equery;
  $q =~ s/%(\d\d)/chr(hex($1))/eg;
  my %hash = split(/[\&\=]/, $q);
  
  use Data::Dumper;
  
  my $mess = {
    who => $hash{who} || "jerakeen",
    body => $hash{body} || $hash{'q'},
    channel => 'msg',
    address => 'msg',
    reply_hook => sub { $self->catch_reply(@_) },
  };
  
  my $reply = $self->bot->said($mess);
  
  warn Dumper($mess, $reply, $self->{reply_catcher});
  
  
  $response->code(RC_OK);
  $response->content(join("\n", @{ $self->{reply_catcher} }, $reply ) );

  return RC_OK;
}

sub catch_reply {
  my $self = shift;
  warn "CAUGHT @_\n";
  my $mess = shift;
  push @{ $self->{reply_catcher} }, @_;
  return 1;
}

1;
