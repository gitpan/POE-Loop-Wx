package DemoApp;

use base qw(Wx::App);
use strict;
use Viewer;
use Brain;
use Wx::Event qw(EVT_CLOSE);

sub OnInit {
   my( $self ) = shift;

   Wx::InitAllImageHandlers();
   
   my $firstframe=Viewer->new();
   $firstframe->SetTitle("Main Frame: Close Me To Quit App");
   my $closeapp = sub {
      print STDERR "in close subroutine.  Trying to stop.\n";
      Brain::stop();
      $firstframe->Destroy();
   };
   EVT_CLOSE($firstframe, $closeapp);
   
   $self->SetTopWindow($firstframe);
   $firstframe->Show(1);

	return 1;
}
# end of class FirstFrameApp




1;
