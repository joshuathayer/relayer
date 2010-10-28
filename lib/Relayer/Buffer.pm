package Relayer::Buffer;

use strict;

sub new {
	my $class = shift;
	my $self = {};

	$self->{raw} = '';
	$self->{next} = undef;

	bless $self, $class;
	return $self;
}	


1;
