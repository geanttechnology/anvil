package AN::Tools::Get;
# 
# This module contains methods used to handle access to frequently used data.
# 

use strict;
use warnings;
use Data::Dumper;

our $VERSION  = "3.0.0";
my $THIS_FILE = "Get.pm";

### Methods;
# date_and_time
# host_uuid
# local_db_id
# network_details
# switches

=pod

=encoding utf8

=head1 NAME

AN::Tools::Get

Provides all methods related to getting access to frequently used data.

=head1 SYNOPSIS

 use AN::Tools;

 # Get a common object handle on all AN::Tools modules.
 my $an = AN::Tools->new();
 
 # Access to methods using '$an->Get->X'. 
 # 
 # Example using 'date_and_time()';
 my $foo_path = $an->Get->date_and_time({...});

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {
		HOST	=>	{
			UUID	=>	"",
		},
	};
	
	bless $self, $class;
	
	return ($self);
}

# Get a handle on the AN::Tools object. I know that technically that is a sibling module, but it makes more 
# sense in this case to think of it as a parent.
sub parent
{
	my $self   = shift;
	my $parent = shift;
	
	$self->{HANDLE}{TOOLS} = $parent if $parent;
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 date_and_time

This method returns the date and/or time using either the current time, or a specified unix time.

NOTE: This only returns times in 24-hour notation.

=head2 Parameters;

=head3 date_only (optional)

If set, only the date will be returned (in C<< yyyy/mm/dd >> format).

=head3 file_name (optional)

When set, the date and/or time returned in a string more useful in file names. Specifically, it will replace spaces with 'C<< _ >>' and 'C<< : >>' and 'C<< / >>' for 'C<< - >>'. This will result in a string in the format like 'C<< yyyy-mm-dd_hh-mm-ss >>'.

=head3 offset (optional)

If set to a signed number, it will add or subtract the number of seconds from the 'C<< use_time >>' before processing.

=head3 use_time (optional)

This can be set to a unix timestamp. If it is not set, the current time is used.

=head3 time_only (optional)

If set, only the time will be returned (in C<< hh:mm:ss >> format).

=cut
sub date_and_time
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $offset    = defined $parameter->{offset}    ? $parameter->{offset}    : 0;
	my $use_time  = defined $parameter->{use_time}  ? $parameter->{use_time}  : time;
	my $file_name = defined $parameter->{file_name} ? $parameter->{file_name} : 0;
	my $time_only = defined $parameter->{time_only} ? $parameter->{time_only} : 0;
	my $date_only = defined $parameter->{date_only} ? $parameter->{date_only} : 0;
	
	# Are things sane?
	if ($use_time =~ /D/)
	{
		die "Get->date_and_time() was called with 'use_time' set to: [$use_time]. Only a unix timestamp is allowed.\n";
	}
	if ($offset =~ /D/)
	{
		die "Get->date_and_time() was called with 'offset' set to: [$offset]. Only real number is allowed.\n";
	}
	
	# Do my initial calculation.
	my $return_string = "";
	my $time          = {};
	my $adjusted_time = $use_time + $offset;
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - adjusted_time: [$adjusted_time]\n";
	
	# Get the date and time pieces
	($time->{sec}, $time->{min}, $time->{hour}, $time->{mday}, $time->{mon}, $time->{year}, $time->{wday}, $time->{yday}, $time->{isdst}) = localtime($adjusted_time);
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - time->{sec}: [".$time->{sec}."], time->{min}: [".$time->{min}."], time->{hour}: [".$time->{hour}."], time->{mday}: [".$time->{mday}."], time->{mon}: [".$time->{mon}."], time->{year}: [".$time->{year}."], time->{wday}: [".$time->{wday}."], time->{yday}: [".$time->{yday}."], time->{isdst}: [".$time->{isdst}."]\n";
	
	# Process the raw data
	$time->{pad_hour} = sprintf("%02d", $time->{hour});
	$time->{mon}++;
	$time->{pad_min}  = sprintf("%02d", $time->{min});
	$time->{pad_sec}  = sprintf("%02d", $time->{sec});
	$time->{year}     = ($time->{year} + 1900);
	$time->{pad_mon}  = sprintf("%02d", $time->{mon});
	$time->{pad_mday} = sprintf("%02d", $time->{mday});
	#print $THIS_FILE." ".__LINE__."; [ Debug ] - time->{pad_hour}: [".$time->{pad_hour}."], time->{pad_min}: [".$time->{pad_min}."], time->{pad_sec}: [".$time->{pad_sec}."], time->{year}: [".$time->{year}."], time->{pad_mon}: [".$time->{pad_mon}."], time->{pad_mday}: [".$time->{pad_mday}."], time->{mon}: [".$time->{mon}."]\n";
	
	# Now, the date and time separator depends on if 'file_name' is set.
	my $date_separator  = $file_name ? "-" : "/";
	my $time_separator  = $file_name ? "-" : ":";
	my $space_separator = $file_name ? "_" : " ";
	if ($time_only)
	{
		$return_string = $time->{pad_hour}.$time_separator.$time->{pad_min}.$time_separator.$time->{pad_sec};
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - return_string: [$return_string]\n";
	}
	elsif ($date_only)
	{
		$return_string = $time->{year}.$date_separator.$time->{pad_mon}.$date_separator.$time->{pad_mday};
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - return_string: [$return_string]\n";
	}
	else
	{
		$return_string = $time->{year}.$date_separator.$time->{pad_mon}.$date_separator.$time->{pad_mday}.$space_separator.$time->{pad_hour}.$time_separator.$time->{pad_min}.$time_separator.$time->{pad_sec};
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - return_string: [$return_string]\n";
	}
	
	return($return_string);
}

=head2 host_uuid

This returns the local host's system UUID (as reported by 'dmidecode'). 

 print "This host's UUID: [".$an->Get->host_uuid."]\n";

It is possible to override the local UUID, though it is not recommended.

 $an->Get->host_uuid({set => "720a0509-533d-406b-8fc1-03aca3e75fa7"})

=cut
sub host_uuid
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $set = defined $parameter->{set} ? $parameter->{set} : "";
	
	if ($set)
	{
		$an->data->{HOST}{UUID} = $set;
	}
	elsif (not $an->data->{HOST}{UUID})
	{
		# Read dmidecode
		my $uuid       = "";
		my $shell_call = $an->data->{path}{exe}{dmidecode}." --string system-uuid";
		#print $THIS_FILE." ".__LINE__."; [ Debug ] - shell_call: [$shell_call]\n";
		open(my $file_handle, $shell_call." 2>&1 |") or warn $THIS_FILE." ".__LINE__."; [ Warning ] - Failed to call: [".$shell_call."], the error was: $!\n";
		while(<$file_handle>)
		{
			# This should never be hit...
			chomp;
			$uuid = lc($_);
		}
		close $file_handle;
		
		if ($uuid)
		{
			$an->data->{HOST}{UUID} = $uuid;
		}
	}
	
	return($an->data->{HOST}{UUID});
}

=head2 network_details

This method returns the local hostname and IP addresses.

It returns a hash reference containing data in the following keys:

C<< hostname >> = <name>
C<< interface::<interface>::ip >> = <ip_address>
C<< interface::<interface>::netmask >> = <dotted_decimal_subnet>

=cut
sub network_details
{
	my $self      = shift;
	my $parameter = shift;
	my $an        = $self->parent;
	
	my $network      = {};
	my $hostname     = $an->System->call({shell_call => $an->data->{path}{exe}{hostname}});
	my $ip_addr_list = $an->System->call({shell_call => $an->data->{path}{exe}{ip}." addr list"});
	$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
		hostname     => $hostname, 
		ip_addr_list => $ip_addr_list,
	}});
	$network->{hostname} = $hostname;
	
	my $in_interface = "";
	my $ip_address   = "";
	my $subnet_mask  = "";
	foreach my $line (split/\n/, $ip_addr_list)
	{
		$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { line => $line }});
		if ($line =~ /^\d+: (.*?):/)
		{
			$in_interface = $1;
			$ip_address   = "";
			$subnet_mask  = "";
			$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { in_interface => $in_interface }});
			next if $in_interface eq "lo";
			$network->{interface}{$in_interface}{ip}      = "--";
			$network->{interface}{$in_interface}{netmask} = "--";
		}
		if ($in_interface)
		{
			next if $in_interface eq "lo";
			if ($line =~ /inet (.*?)\/(.*?) /)
			{
				$ip_address   = $1;
				$subnet_mask  = $2;
				$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { 
					ip_address  => $ip_address,
					subnet_mask => $subnet_mask, 
				}});
				
				if ((($subnet_mask =~ /^\d$/) or ($subnet_mask =~ /^\d\d$/)) && ($subnet_mask < 25))
				{
					$subnet_mask = $an->Convert->cidr({cidr => $subnet_mask});
					$an->Log->variables({source => $THIS_FILE, line => __LINE__, level => 3, list => { subnet_mask => $subnet_mask }});
				}
				$network->{interface}{$in_interface}{ip}      = $ip_address;
				$network->{interface}{$in_interface}{netmask} = $subnet_mask;
			}
		}
	}
	
	return($network);
}

=head2 switches

This reads in the command line switches used to invoke the parent program. 

It takes no arguments, and data is stored in 'C<< $an->data->{switches}{x} >>', where 'x' is the switch used.

Switches in the form 'C<< -x >>' and 'C<< --x >>' are treated the same and the corresponding 'C<< $an->data->{switches}{x} >>' will contain '#!set!#'. 

Switches in the form 'C<< -x foo >>', 'C<< --x foo >>', 'C<< -x=foo >>' and 'C<< --x=foo >>' are treated the same and the corresponding 'C<< $an->data->{switches}{x} >>' will contain 'foo'. 

The switches 'C<< -v >>', 'C<< -vv >>', 'C<< -vvv >>' and 'C<< -vvvv >>' will cause the active log level to automatically change to 1, 2, 3 or 4 respectively. Passing 'C<< -V >>' will set the log level to '0'.

Anything after 'C<< -- >>' is treated as a raw string and is not processed. 

=cut
sub switches
{
	my $self = shift;
	my $an   = $self->parent;
	
	my $last_argument = "";
	foreach my $argument (@ARGV)
	{
		if ($last_argument eq "raw")
		{
			# Don't process anything.
			$an->data->{switches}{raw} .= " $argument";
		}
		elsif ($argument =~ /^-/)
		{
			# If the argument is just '--', appeand everything after it to 'raw'.
			if ($argument eq "--")
			{
				$last_argument         = "raw";
				$an->data->{switches}{raw} = "";
			}
			else
			{
				($last_argument) = ($argument =~ /^-{1,2}(.*)/)[0];
				if ($last_argument =~ /=/)
				{
					# Break up the variable/value.
					($last_argument, my $value) = (split /=/, $last_argument, 2);
					$an->data->{switches}{$last_argument} = $value;
				}
				else
				{
					$an->data->{switches}{$last_argument} = "#!SET!#";
				}
			}
		}
		else
		{
			if ($last_argument)
			{
				$an->data->{switches}{$last_argument} = $argument;
				$last_argument                        = "";
			}
			else
			{
				# Got a value without an argument.
				$an->data->{switches}{error} = 1;
			}
		}
	}
	# Clean up the initial space added to 'raw'.
	if ($an->data->{switches}{raw})
	{
		$an->data->{switches}{raw} =~ s/^ //;
	}

	# Adjust the log level if requested.
	$an->Log->_adjust_log_level();
	
	return(0);
}


# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################