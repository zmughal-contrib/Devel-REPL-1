package Devel::REPL::Plugin::CompletionDriver::Methods;
use Devel::REPL::Plugin;
use namespace::clean -except => [ 'meta' ];

with 'Devel::REPL::Plugin::FindVariable';

around complete => sub {
  my $orig = shift;
  my ($self, $text, $document) = @_;

  my $last = $self->last_ppi_element($document);
  my $incomplete = '';

  # handle an incomplete method name, and back up to the ->
  if ($last->isa('PPI::Token::Word')) {
      my $previous = $last->sprevious_sibling
        or return $orig->(@_);
      $previous->isa('PPI::Token::Operator') && $previous->content eq '->'
        or return $orig->(@_);
      $incomplete = $last->content;
      $last = $previous;
  }

  # require a -> here
  return $orig->(@_)
    unless $last->isa('PPI::Token::Operator')
        && $last->content eq '->';

  # ..which is preceded by a word (class name)
  my $previous = $last->sprevious_sibling
    or return $orig->(@_);
  $previous->isa('PPI::Token::Word') || $previous->isa('PPI::Token::Symbol')
    or return $orig->(@_);
  my $class;

  # we have a variable, need to look up its class
  if ($previous->isa('PPI::Token::Symbol')) {
    my $object_ref = $self->find_variable($previous->content)
      or return $orig->(@_);
    $class = blessed($$object_ref)
      or return $orig->(@_);
  }
  else  {
    $class = $previous->content;
  }

  # now we have $class->$incomplete

  my $metaclass = Class::MOP::Class->initialize($class);

  my $re = qr/^\Q$incomplete/;

  return $orig->(@_),
         grep { $_ =~ $re }
         map  { $_->{name} }
         $metaclass->compute_all_applicable_methods;
};

1;

