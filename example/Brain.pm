package Brain;

use Wx 0.15 qw[:allclasses];
use strict;

use POE;
use POE::Component::Client::UserAgent;
use POE::Loop::Wx;
use Wx qw(wxTheApp);

my $app;
my $counter = 0;
my %states;

our ($postback, $callback);

sub start {
   POE::Session->create(inline_states=>\%states);
   our ($postback, $callback);
   POE::Component::Client::UserAgent->new;
   POE::Kernel->loop_run();
   POE::Kernel->run();
   
}

sub stop {
   POE::Kernel->stop();
   Wx::wxTheApp->ExitMainLoop();
}

sub postback {
   &{$postback}(@_);
}

sub callback {
   &{$callback}(@_);
}

$states{subscribe}=sub{
   my ($kernel, $session, $heap)=@_[KERNEL, SESSION, HEAP];
   my %opt=(@_[ARG0..$#_]);
   my $key=$opt{KEY};
   my $poe_id=$opt{OBJECT}->get_poe_id();
   $heap->{subscriptions}{$key} = {} unless 
       defined $heap->{subscriptions}{$key};
   $heap->{subscriptions}{$key}{$poe_id}=$opt{ACTION};
};

$states{unsubscribe}=sub{
   my ($kernel, $session, $heap)=@_[KERNEL, SESSION, HEAP];
   my %opt=(@_[ARG0..$#_]);
   my $object=$opt{OBJECT};
   my $key=$opt{KEY};
   my $poe_id=$object->get_poe_id();
   $heap->{subscriptions}{$key} = {} unless 
       defined $heap->{subscriptions}{$key};
   print STDERR "trying to unsubscribe $object from $key\n";
   print STDERR "current subscription:  $heap->{subscriptions}{$key}{$poe_id}\n";
   delete $heap->{subscriptions}{$key}{$poe_id};
};

$states{invoke_state}=sub{
   my ($kernel, $args ) = 
       @_[KERNEL, ARG1];
   my @args=@$args;
   my $state=shift @args;
   print STDERR "in invoke_state state.  trying to invoke $state\n";
   $kernel->yield($state, @args)
};

$states{request_data} = sub {
   my ($kernel, $session, $heap)=@_[KERNEL, SESSION, HEAP];
   my %opt=(@_[ARG0..$#_]);
   my $object=$opt{OBJECT};
   my $param=$opt{PARAMETER};
   my $key=$opt{KEY};
   my $action=$opt{ACTION};
   print STDERR "got request for $param from object $object\n";
   my $request=HTTP::Request->new(GET=>$param);
   my $response_postback=$session->postback('response',%opt);
   $kernel->post('useragent', 'request',
                 request=> $request, 
                 response=>$response_postback);
};

# $states{publish}=sub{
#    my ($kernel, $session, $heap)=@_[KERNEL, SESSION, HEAP];
#    my %opt=(@_[ARG0..$#_]);
#    my $key=$opt{KEY};


# };


$states{response}= sub{
   my $heap=@_[HEAP];
   my %opt= @{$_[ARG0]};
   my ($request, $response, $entry) = @{$_[ARG1]};
   my $key=$opt{KEY};
   my $action=$opt{ACTION};
   print STDERR "got a response to call with key $key\n";
   if ($response->is_success) {
      print STDERR "it is a success\n";
      if ($action) {
         print STDERR "I have an action\n";
         &{$action}($response->content);
      }
      if (ref $heap->{subscriptions}{$key} eq 'HASH') {
         print STDERR "Checking subscriptions\n";
         my %subscriptions = %{$heap->{subscriptions}{$key}};
         while (my ($poe_id, $sub_action) = each %subscriptions) {
            print STDERR "Checking subscription $poe_id\n";
            next unless defined ( $heap->{objects}{$poe_id} ) and
                (ref $sub_action eq 'CODE');
            print STDERR "Found valid subscription for $poe_id\n";
            &$sub_action($response->content);
         }
      }
   } else {
      print STDERR "the request failed.";
   }
};

$states{register_object}=sub{
   my ($heap, $object) = 
       @_[HEAP, ARG0];
   $heap->{object_counter}=$heap->{object_counter}+1;
   # the session can keep track of the object by id
   $heap->{objects}{$heap->{object_counter}}=$object;
   $object->set_poe_id($heap->{object_counter});
};

$states{unregister_object}=sub{
   my ($heap, $object) = @_[HEAP, ARG0];
   delete $heap->{objects}{$object->get_poe_id}
};

$states{_start}=sub{
   print STDERR "start state\n";
   my ($kernel, $session, $heap ) = @_[KERNEL, SESSION, HEAP ];
   $kernel->alias_set('main_session');
   
   $Brain::callback=$session->callback('invoke_state');
   $Brain::postback=$session->postback('invoke_state');
   
   use DemoApp;
   $heap->{app}=DemoApp->new();
   $heap->{object_counter}=0;
   $heap->{objects}={};
   $heap->{subscriptions}={};
   
   $kernel->yield('pulse');
};

$states{pulse}=sub{
   my ($kernel, $heap ) = @_[KERNEL, HEAP ];
   print STDERR "\nThis pulse is just a demo of a recurring event,\n";
   print STDERR "to prove that POE is running.  It also gives an\n";
   print STDERR "inventory of Pobjects that main_session knows about.\n";
   my %objects=%{$heap->{objects}};
   print STDERR "I have ".scalar(keys %objects)." objects\n";
   print STDERR "they include...\n";
   while(my ($key, $val) = each %objects) {
      print STDERR "object $key is $val\n";
   }
   
   $kernel->delay_set('pulse', 10);
   print STDERR $counter++, "\n";
   
};


1;
