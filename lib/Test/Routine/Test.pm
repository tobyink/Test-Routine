package Test::Routine::Test;
use Moo;
# ABSTRACT: a test method in a Test::Routine role

with 'Test::Routine::Test::Role';

=head1 OVERVIEW

Test::Routine::Test is a very simple class, used
primarily to identify which methods in a class are tests.  It also has
attributes used for labeling and ordering test runs.

=cut

1;
