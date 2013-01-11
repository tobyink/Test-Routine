package Test::Routine::Test::Role;
# ABSTRACT: role providing test attributes
use Moo::Role;
use MooX::late;

has package_name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has description => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  default => sub { $_[0]->name },
);

has _origin => (
  is  => 'ro',
  isa => 'HashRef',
  required => 1,
);

sub body {
	my $self = shift;
	$self->package_name->can($self->name);
}

sub compare {
	no warnings;
	my ($A, $B) = @_;
	   $A->_origin->{file} cmp $A->_origin->{file}
	or $A->_origin->{nth}  <=> $B->_origin->{nth};
}

1;
