package Message::Passing::Output::ELSA;
use Moose;
with 'Message::Passing::Role::Output';
use Data::Dumper;
use namespace::autoclean;
use Config::JSON;
use JSON;
use Try::Tiny qw/ try catch /;
use MRO::Compat;
use Moose::Util::TypeConstraints;
use Module::Load;

our $Log_parse_errors = 0;

has 'conf' => ( is => 'ro', isa => 'Config::JSON', required => 1);
class_type 'Reader'; # Best to be explicit as they're not loaded yet
class_type 'Writer';
has 'reader' => (
    is => 'ro',
    isa => 'Reader',
    lazy => 1,
    default => sub {
        my $self = shift;
        Reader->new(conf => $self->conf);
    },
);
has 'reader' => (
    is => 'ro',
    isa => 'Writer',
    lazy => 1,
    default => sub {
        my $self = shift;
        Writer->new(conf => $self->conf);
    },
);

sub BUILDARGS {
	my $class = shift;
	my %params = %{ $class->next::method(@_) };

	if ($params{config_file}){
		my $config_file = $params{config_file} ? $params{config_file} : '/etc/elsa_node.conf';
		$params{conf} = Config::JSON->new($config_file);
	}

	try {
		if ($params{inc}){
			push @INC, $params{inc};
		}
		require Reader;
		require Writer;
	}
    catch {
		die('Unable to find ELSA libraries in given dir ' . $params{inc} . ': ' . $_);
	};

	return \%params;
}

sub BUILD {
    my $self = shift;
    $self->reader;
    $self->writer;
}

sub consume {
    my $self = shift;
    no warnings qw(uninitialized); # these will happen a lot, legitimately
    my $line;
    try {
    	$line = $self->reader->parse_hash(from_json(shift()));
    }
    catch {
    	$self->reader->log->error('Parse error: ' . $_ . ', ' . Dumper($line)) if $Log_parse_errors;
    };

    return unless $line;

	$self->writer->write($line);

    if (scalar keys %{ $self->reader->to_add }){
		$self->writer->add_programs($self->reader->to_add);
		$self->reader->to_add({});
	}
}

__PACKAGE__->meta->make_immutable;
1;

