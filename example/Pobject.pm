package Pobject;

use Brain;

sub subscribe {
   my $object=shift;
   my %opt=@_;
   Brain::postback('subscribe', OBJECT=>$object,
                    %opt);
}

sub unsubscribe {
   my $object=shift;
   my %opt=@_;
   Brain::postback('unsubscribe', OBJECT=>$object,
                    %opt);
}

sub request_data {
   my $object=shift;
   my %opt=@_;
   Brain::postback('request_data', OBJECT=>$object,
                    %opt);
}

sub register_object {
   my $object=shift;
   print STDERR "going to try to register object $object\n";
   Brain::postback('register_object', $object);
}

sub unregister_object {
   my $object=shift;
   print STDERR "going to try to unregister object $object\n";
   Brain::callback('unregister_object', $object);
}

sub get_poe_id {
   my $self=shift;
   return $self->{_poe_id};
}

sub set_poe_id {
   # stores poe_id in object, assuming it's a hashref.
   # this could conceiveably be stored elsewhere, e.g.
   # in a global hash which mapped an object's scalar value
   # to a poe_id.
   my $self=shift;
   my ($poe_id)=@_;
   $self->{_poe_id}=$poe_id;
}



1;
