package Bot::BasicBot::Pluggable::Module::Jabber;
use base qw( Bot::BasicBot::Pluggable::Module );

use warnings;
use strict;
use Data::Dumper;

use Jabber::Connection;
use Jabber::NodeFactory;

sub init {
    my $self = shift;

    my $server = $self->{server} || 'jabber.org';
    my $port = $self->{port} || '5222';

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
    unless ($c->connect) {
        warn "oops: ".$c->lastError;
        return;
    }

    $c->register_handler('message',sub { return $self->message(@_) });

    $c->auth("dipsy","dipsy","Infobot");
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


1;
