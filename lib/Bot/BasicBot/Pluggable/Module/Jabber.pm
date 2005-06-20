package Bot::BasicBot::Pluggable::Module::Jabber;
use base qw( Bot::BasicBot::Pluggable::Module );

use warnings;
use strict;
use Data::Dumper;

use Jabber::Connection;
use Jabber::NodeFactory;


# TODO
# integrate roster stuff and allow people to query it

=head1 NAME

Bot::BasicBot::Pluggable::Module::Jabber - allow a Bot::BasicBot::Pluggable bot to communicate via Jabber

=head1 VARS

=over 4

=item nick

Defaults to existing bot nick; Our username on the Jabber server 

=item password

Password on a jabber srever. Must be set.

=item server

Defaults to jabber.org; A list of public servers is available at http://www.jabber.org/network/

Most will require you to create a new account using a traditional Jabber client.

=item port

Defaults to 5222;

=item resource

Defaults to Bot::basicBot::Pluggable; The client identifier string.

=cut


sub init {
    my $self = shift;

    
    my $server = $self->get("user_server") || 'jabber.org';
    my $port   = $self->get("user_port")   || '5222';

    $self->set("user_server", $server);
    $self->set("user_port", $port);

    unless ($self->get("user_nick")) {
	warn "Setting Jabber nick to bot nick - ".$self->bot->nick."\n";
	$self->set("user_nick",$self->bot->nick);
    }

    $self->set("user_resource","Bot::BasicBot:Pluggable") unless $self->get("user_resource");

    my $connection = Jabber::Connection->new(server => $server.':'.$port, log => 0);


    
    return unless defined $connection;
    warn "init called, logging into $server:$port\n";

    $self->{_connection} = $connection;
    $self->run;


}

sub stop {
    my $self = shift;
    warn "stopping jabber connection";
    $self->{_connection}->disconnect()
}

sub run {
    my $self = shift;
    my $c = $self->{_connection};

    unless ($self->get("user_password")) {
	warn "You must set a jabber password for the nick ".$self->get("user_nick")."\n";
	return;
    }

    unless ($c->connect) {
        warn "oops: ".$c->lastError;
        return;
    }


    $c->register_handler('message',sub { return $self->message(@_) });

    $c->auth($self->get("user_nick"),$self->get("user_password"),$self->get("user_resource"));
    $c->send('<presence/>');
    $c->start;
}



sub message {
    my ($self,$in) = @_;

    my $body = $in->getTag('body')->data || "";
    my $who  = $in->attr('from');
          

    $who =~ s!@.*$!!; # get rid of pesky server stuff

 
    my $mess = {
            who => $who,
            body => $body,
            channel => 'msg',
            address => 'msg',
            reply_hook => sub { $self->catch_reply(@_) },
     };
  
     my $reply = $self->bot->said($mess);
      

     warn Dumper($mess, $reply, $self->{reply_catcher});
     my $response = join("\n", @{ $self->{reply_catcher} } );
     warn "Replying with $body\n";
     @{ $self->{reply_catcher} } = ();
     $self->jabber_say( $in->attr('from'), $response ); 
}

sub jabber_say {
    my ($self, $to, $message, $type) = @_;

    $type ||= 'chat';

    # do we need to quote the message?
    my $out = $self->nf->newNodeFromStr("<message><body>$message</body></message>");
    $out->attr('to',$to);
    $out->attr('type',$type);
    $self->{_connection}->send($out);

}

sub catch_reply {
    my $self = shift;
    # warn "CAUGHT @_\n";
    my $mess = shift;
    push @{ $self->{reply_catcher} }, @_;
    return 1;
}

sub nf {
    my $self = shift;
    return $self->{_nf} if $self->{_nf};
    $self->{_nf} = Jabber::NodeFactory->new(fromstr => 1);
}

=head1 REQUIREMENTS

L<Jabber::Connection>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Bot::JabberBot> by Jo Walsh

A lot of this code is based on hers.

=cut


1;
