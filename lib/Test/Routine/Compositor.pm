use strict;
use warnings;
package Test::Routine::Compositor;
# ABSTRACT: the tool for turning test routines into runnable classes

use Carp qw(confess);
use Class::Load qw(load_class);
use Moo::Role ();
use Params::Util qw(_CLASS);
use Scalar::Util qw(blessed);

use namespace::clean;

sub _invocant_for {
  my ($self, $thing, $arg) = @_;

  confess "can't supply preconstructed object for running tests"
    if $arg and blessed $thing;

  return $thing if blessed $thing;

  $arg ||= {};
  my $new_class = $self->_class_for($thing);
  $new_class->name->new($arg);
}

sub _class_for {
  my ($class, $inv) = @_;

  confess "can't supply preconstructed object for test class construction"
    if blessed $inv;

  $inv = [ $inv ] if _CLASS($inv);

  my @bases;
  my @roles;

  for my $item (@$inv) {
    load_class($item);
    my $target = $class->_is_class($item) ? \@bases
               : $class->_is_role($item)  ? \@roles
               : confess "can't run tests for this weird thing: $item";

    push @$target, $item;
  }

  confess "can't build a test class from multiple base classes" if @bases > 1;
  @bases = 'Moo::Object' unless @bases;

  my $new_class = $class->_create_anon_class(
    superclasses => \@bases,
    cache        => 1,
    (@roles ? (roles => \@roles) : ()),
  );

  return $new_class;
}

sub _is_class {
  my $item = $_[1];
  return 1 if $item->can('new');
  return 1 if $INC{'Class/MOP.pm'} && Class::MOP::class_of($item)->isa('Class::MOP::Class');
  return;
}

sub _is_role {
  my $item = $_[1];
  return 1 if ref $Role::Tiny::INFO{$item};
  return 1 if $INC{'Class/MOP.pm'} && Class::MOP::class_of($item)->isa('Moose::Meta::Role');
  return;
}

{
  my ($anon, %cache);
  sub _create_anon_class {
    my ($me, %args) = @_;
    
    my @isa  = @{ $args{superclasses} || [] };
    my @does = @{ $args{roles} || [] };
    my $key  = sprintf('%s + %s', join(',', @isa), join('|', @does));
    
    $cache{$key} ||= do {
      my $pkg  = sprintf('%s::__ANON__::%04d', $me, ++$anon);
      { no strict 'refs'; *{"$pkg\::ISA"} = \@isa };
      Moo::Role::->apply_roles_to_package($pkg, @does);
      $pkg;
    };
  }
}

sub instance_builder {
  my ($class, $inv, $arg) = @_;

  confess "can't supply preconstructed object and constructor arguments"
    if $arg and blessed $inv;

  return sub { $inv } if blessed $inv;

  my $new_class = $class->_class_for($inv);
  $arg ||= {};

  return sub { $new_class->new($arg); };
}

1;
