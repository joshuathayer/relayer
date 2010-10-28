#!/usr/bin/perl

use lib ('../lib');

use strict;
use Audio::PortAudio;
use Data::Dumper;
use Relayer::Buffer;
use IO::Select;

system "stty -echo -icanon";
select(STDIN); $| = 1;

my $s = IO::Select->new();
$s->add(\*STDIN);

my $api = Audio::PortAudio::default_host_api();
my @apis = Audio::PortAudio::host_apis();
my $device = $api->default_input_device;
my $odevice = $api->default_output_device;

warn("input device " . $device->name . ", output device " . $odevice->name);

my $number_of_frames = 1024;
my $number_of_channels = 2;
my $sample_rate = 22050;
my $frames_per_buffer = 1024;
my $stream_flags = 0;

my $stream = $device->open_read_stream(
	{
		device => $device,
		channel_count => $number_of_channels,
		sample_format => 'int32',
	},

	$sample_rate,
	$frames_per_buffer,	# frames per buffer
	$stream_flags
);

my $ostream = $odevice->open_write_stream(
	{
		device => $odevice,
		#channel_count => $number_of_channels,
		channel_count => 2,
		sample_format => 'int32',
	},

	$sample_rate,
	$frames_per_buffer,	# frames per buffer
	$stream_flags
);

my $firstbuffer;
my $lastbuffer;

my $bufcount = 100;
my $buffered = 0;

while(1) {
	my $buffer = Relayer::Buffer->new;

	$stream->read($buffer->{raw}, $number_of_frames);

	my @in = $s->can_read(0);
	if (scalar(@in)) {
		my $keys;
		sysread(STDIN, $keys, 1);
		if ($keys eq 'a') {
			$bufcount += 10;
		}
		if ($keys eq 'z') {
			$bufcount -= 10;
		}
		if ($bufcount < 10) { $bufcount = 10; }
	}

	if ($firstbuffer) {
		# all cases except 1st time through
		$lastbuffer->{next} = $buffer;
		$lastbuffer = $buffer;
	} else {
		# first time through
		$firstbuffer = $buffer;
		$lastbuffer = $buffer;
		$lastbuffer->{next} = undef;
	}

	$buffered += 1;

	$ostream->write($firstbuffer->{raw});

	if ($buffered > $bufcount) {
		# too much data, we skip some
		$firstbuffer = $firstbuffer->{next}->{next};
		$buffered -= 2;
		warn("delay $buffered");
	} elsif ($buffered < $bufcount) { 
		# no enough data. we reply the buffer we're on
		warn("delay $buffered");
	} else {
		# normal state. advance to next buffer
		$firstbuffer = $firstbuffer->{next};
		$buffered -= 1;
	}

}

#my @samples = unpack("l".($number_of_frames * $number_of_channels), $buffer);
#print Dumper \@samples;
