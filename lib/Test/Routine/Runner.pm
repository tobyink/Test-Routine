package Test::Routine::Runner;
use Moo;
use MooX::late;
# ABSTRACT: tools for running Test::Routine tests

=head1 OVERVIEW

A Test::Routine::Runner takes a callback for building test instances, then uses
it to build instances and run the tests on it.  The Test::Routine::Runner
interface is still undergoing work, but the Test::Routine::Util exports for
running tests, descibed in L<Test::Routine|Test::Routine/Running Tests>, are
more stable.  Please use those instead, unless you are willing to deal with
interface breakage.

=cut

use Carp qw(confess);
use Scalar::Util qw(reftype);
use Sub::Quote qw(quote_sub);
use Test::More ();

use namespace::clean;

# XXX: THIS CODE BELOW WILL BE REMOVED VERY SOON -- rjbs, 2010-10-18
use Sub::Exporter -setup => {
  exports => [
    run_tests => \'_curry_tester',
    run_me    => \'_curry_tester',
  ],
  groups  => [ default   => [ qw(run_me run_tests) ] ],
};

sub _curry_tester {
  my ($class, $name) = @_;
  use Test::Routine::Util;
  my $sub = Test::Routine::Util->_curry_tester($name);

  return sub {
    warn "you got $name from Test::Routine::Runner; use Test::Routine::Util instead; Test::Routine::Runner's exports will be removed soon\n";
    goto &$sub;
  }
}
# XXX: THIS CODE ABOVE WILL BE REMOVED VERY SOON -- rjbs, 2010-10-18

# type constraints and coercions
use constant {
  _TC_INSTANCE => quote_sub(q{ my ($x) = @_; die unless Scalar::Util::blessed($x) && $x->does('Test::Routine::Common') }),
  _IS_INSTANCE => quote_sub(q{ my ($x) = @_; !!         Scalar::Util::blessed($x) && $x->does('Test::Routine::Common') }),
  _TC_BUILDER  => quote_sub(q{ my ($x) = @_; die unless Scalar::Util::reftype($x) eq 'CODE' }),
  _IS_BUILDER  => quote_sub(q{ my ($x) = @_;            Scalar::Util::reftype($x) eq 'CODE' }),
};
sub _COERCE_BUILDER {
  my $x = shift;
  return sub { $x } if _IS_INSTANCE->($x);
  return $x;
}

has test_instance => (
  is   => 'lazy',
  isa  => _TC_INSTANCE,
  init_arg   => undef,
);

has _instance_builder => (
  is  => 'ro',
  isa => _TC_BUILDER,
  coerce   => \&_COERCE_BUILDER,
  traits   => [ 'Code' ],
  init_arg => 'instance_from',
  required => 1,
);

sub _build_test_instance {
  my $self = shift;
  $self->_instance_builder->(@_);
}

has description => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has fresh_instance => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub run {
  my ($self) = @_;

  my $thing = $self->test_instance;

  my @ordered_tests = $thing->test_routines;

  Test::More::subtest($self->description, sub {
    for my $test (@ordered_tests) {
      $self->test_instance->run_test( $test );
      $self->clear_test_instance if $self->fresh_instance;
    }
  });
}

1;
