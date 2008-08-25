# $Id: DllInject.pm 143 2008-08-25 13:26:35Z rplessl $

package Win32::Monitoring::DllInject;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Monitoring::DllInject ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
   new
   StatMailSlot
   GetMessage
   Unhook
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.04';

bootstrap Win32::Monitoring::DllInject $VERSION;

# Preloaded methods go here.

sub new {
    my $class = shift;
    my $self  =
        {
         'VERSION' => $VERSION,
        };

    bless $self, $class;

    $self->{pid} = shift;
    $self->{dll} = shift;

    ( $self->{hmailslot},
      $self->{hmodule},
      $self->{hooked} ) = init( $self->{pid}, $self->{dll} );

    return $self;
}

sub StatMailSlot {
    my $self = shift;
    return StatMailslot( $self->{hmailslot} );
}

sub GetMessage {
    my $self = shift;
    return GetMailslotMessage( $self->{hmailslot} );
}

sub Unhook {
   my $self = shift;

   ( $self->{hmodule},
     $self->{unhooked} ) = destroy($self->{pid}, $self->{dll}, $self->{hmailslot}, $self->{hmodule});

   if ($self->{unhooked} == 1) {
      $self->{hooked} = 0;
      delete $self->{unhooked};
   }
}

DESTROY {
   my $self = shift;
   ( $self->{hmodule},
     $self->{unhooked} ) = destroy($self->{pid}, $self->{dll}, $self->{hmailslot}, $self->{hmodule});

   if ($self->{unhooked} == 1) {
      $self->{hooked} = 0;
      delete $self->{unhooked};
   }
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Win32::Monitoring::DllInject - Injects Win32 programs with overloaded functions

=head1 SYNOPSIS

  use Win32::Monitoring::DllInject qw(new UnHook StatMailslot GetMessage);

  my $handle = new Win32::Monitoring::DllInject($dll_path, $process_id);

  while(1){
        sleep(1);
        my $msg_cnt = $handle->StatMailSlot();

        for (my $i = 0; $i < $msg_cnt; $i++) {
           print $handle->GetMessage(), "\n";
        }

  }
  $handle->UnHook();

=head1 DESCRIPTION

The Win32::Monitoring::DllInject module provides a perl object to automatically
handles and injects a Windows program or a DLL with some overloading (self written)
functional code.

Additional a communication infrastructure is set up using a Windows mailslot
to return information like status information or time measurements to the callee.

As a bonus there is an example framework for a DLL implementation included, such
that you can implement a nice time measuring monitoring program for any Win32
application without requiring further modules.

=over

=item $handle = new($dll_path,$process_id)

Returns an handle to the Win32::Monitoring::DllInject object to handle the
overloaded (hooked) program.

=item $handle->StatMailSlot()

Returns the amount of messages in the internal message store (mailslot).

=item $handle->GetMessage()

Returns the content of the first message in the message store.

=item $handle->Unhook()

Reverts the hooking of the program injecting.

=back

=head2 EXAMPLE

  #! perl

  use Win32::OLE;
  use Win32::Monitoring::DllInject;
  use Data::Dumper;

  my $WshShell = Win32::OLE->new("WScript.Shell");
  $WshShell->Run("notepad", 5);

  sleep(1);

  my %processes;

  for my $line (`tasklist /v /nh`) {
     chomp($line);
     if ( $line ne "" ) {
        my $pid = substr($line, 26, 8);  # extract PID
        $pid =~ s/^ *([0-9]+)$/$1/g;     # remove leading spaces

        my $proc = substr($line, 0, 24); # extract process
        $proc =~ s/\s\s\s*/ /g;          # change multiple spaces to single spaces
        $proc =~ s/\s$//g;               # remove trailing space
        $proc =~ s/ N\/A$//g;            # remove trailing N/A

        $processes{$proc} = $pid;
      }
  }

  my $P = Win32::Monitoring::DllInject->new($processes{'notepad.exe'},'Y:\\perl\\Win32-Monitoring-DllInject\\HookedFunctions.dll');

  print Dumper($P);

  while(1)
  {
       sleep(1);
       my $msg_cnt = $P->StatMailSlot();
       for (my $i = 0; $i < $msg_cnt; $i++) {
           print $P->GetMessage(), "\n";
       }
  }

=head1 SEE ALSO

Webpage: <http://oss.oetiker.ch/optools/>

=head1 COPYRIGHT

Copyright (c) 2008 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

Win32::Monitoring::DllInject is free software: you can redistribute
it and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Win32::Monitoring::DllInject is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Win32::Monitoring::WindowPing. If not, see
<http://www.gnu.org/licenses/>.


=head1 AUTHORS

Roman Plessl,
Tobi Oetiker

=cut
