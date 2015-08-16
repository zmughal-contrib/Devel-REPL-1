use strict;
use warnings;
package Devel::REPL::Plugin::CompletionDriver::LexEnv;
# ABSTRACT: Complete variable names in the REPL's lexical environment

our $VERSION = '1.003027';

use Devel::REPL::Plugin;
use Devel::REPL::Plugin::Completion;    # die early if cannot load
use namespace::autoclean;

sub BEFORE_PLUGIN {
    my $self = shift;
    $self->load_plugin('Completion');
}

around complete => sub {
  my $orig = shift;
  my ($self, $text, $document) = @_;

  my $last = $self->last_ppi_element($document);

  return $orig->(@_)
    unless $last->isa('PPI::Token::Symbol');

  my ($sigil, $name) = split(//, $last, 2);
  my $re = qr/^\Q$name/;

  return $orig->(@_),
         # ReadLine is weirdly inconsistent
         map  { $sigil eq '%' ? '%' . $_ : $_ }
         grep { /$re/ }
         map  { substr($_, 1) } # drop lexical's sigil
         '$_REPL', keys %{$self->lexical_environment->get_context('_')};
};

1;

__END__

=pod

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail dot com> >>

=cut
