package Test::Routine::Common;
use Moo::Role;
# ABSTRACT: a role composed by all Test::Routine roles

=head1 OVERVIEW

Test::Routine::Common provides the C<run_test> method described in L<the docs
on writing tests in Test::Routine|Test::Routine/Writing Tests>.

=cut

use Test::More ();
use Sub::Identify qw(get_code_info);
use Moo::_Utils qw(_getstash);
require Test::Routine;

use namespace::clean;

sub run_test {
  my ($self, $test) = @_;

  my $name = $test->name;
  Test::More::subtest($test->description, sub { $self->$name });
}

sub test_routines {
	my $self  = shift;
	my $class = Scalar::Util::blessed($self) or die;
	
	my %tests;
	
	for my $isa (reverse @{$class->mro::get_linear_isa}) {
		my $stash = _getstash($isa);
		for my $k (keys %$stash) {
			my $code = *{$stash->{$k}}{CODE} or next;
			my ($package, $name) = get_code_info($code);
			$tests{$name} ||= $Test::Routine::TESTS{$package}{$name};
		}
	}
	
	return sort { $a->compare($b) } grep defined, values %tests;
}

1;
