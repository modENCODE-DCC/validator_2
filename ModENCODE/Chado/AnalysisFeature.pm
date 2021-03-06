package ModENCODE::Chado::AnalysisFeature;
=pod

=head1 NAME

ModENCODE::Chado::AnalysisFeature - A class representing a simplified Chado
I<analysisfeature> object.

=head1 SYNOPSIS

This class is an object-oriented representation of an entry in a Chado
B<analysisfeature> table. It provides accessors for the various attributes of an
analysisfeature that are stored in the analysisfeature table itself, plus
accessors for relationships to certain other Chado tables (i.e. B<feature> and
B<analysis>).

=head1 USAGE

=head2 Implications Of Class::Std

=over

As with all of the ModENCODE::Chado::* object classes, this module utilizes
L<Class::Std> to enforce object-oriented programming practices. Therefore, many
of the accessor functions are automatically generated, and are of the form
<get|set>_<attribute>, e.g. $obj->L<get_rawscore()|/get_rawscore() |
set_rawscore($rawscore)> or $obj->L<set_rawscore()|/get_rawscore() |
set_rawscore($rawscore)>.

ModENCODE::Chado::* objects can also be created with values at initialization
time by passing in a hash. For instance, 
C<my $obj = new ModENCODE::Chado::AnalysisFeature({ 'rawscore' =E<gt> 103, 'identity' =E<gt> 75.8 });>
will create a new AnalysisFeature object with a rawscore of 103 and
an identity score of 75.8. For complex types (other Chado objects), the default
L<Class::Std> setters and initializers have been replaced with subroutines that
make sure the type of the object being passed in is correct.

=back

=head2 Using ModENCODE::Chado::AnalysisFeature

=over

  my $analysisfeature = new ModENCODE::Chado::AnalysisFeature({
    # Simple attributes
    'chadoxml_id'       => 'Feature_111',
    'rawscore'          => 103,
    'normscore'         => 53,
    'significance'      => 75,
    'identity'          => 99,

    # Object relationships
    'feature'           => new ModENCODE::Chado::Feature(),
    'analysis'          => new ModENCODE::Chado::Analysis(),
  });

  $analysisfeature->set_rawscore(100);
  my $rawscore = $analysisfeature->get_rawscore();
  print $analysisfeature->to_string();

=back

=head1 ACCESSORS

=over

=item get_chadoxml_id() | set_chadoxml_id($chadoxml_id)

The I<chadoxml_id> is used by L<ModENCODE::Chado::XMLWriter> to keep track of
the ChadoXML Macro ID (used to refer to the same feature in XML multiple times).
It is also populated when using L<ModENCODE::Parser::Chado> to pull data out of
a Chado database. (Note that the XMLWriter will generate new I<chadoxml_id>s in
this case; it does so whenever the I<chadoxml_id> is purely numeric.

=item get_rawscore() | set_rawscore($rawscore)

The rawscore of this Chado analysisfeature; it corresponds to the
analysisfeature.rawscore field in a Chado database.

=item get_normscore() | set_normscore($normscore)

The normscore of this Chado analysisfeature; it corresponds to the
analysisfeature.normscore field in a Chado database.

=item get_significance() | set_significance($significance)

The significance of this Chado analysisfeature; it corresponds to the
analysisfeature.significance field in a Chado database.

=item get_identity() | set_identity($identity)

The identity of this Chado analysisfeature; it corresponds to the
analysisfeature.identity field in a Chado database.

=item get_feature() | set_feature($feature)

The feature for this Chado analysisfeature. This must be a
L<ModENCODE::Chado::Feature> or conforming subclass (via C<isa>). The feature
object corresponds to a feature in the Chado feature table, and the
analysisfeature.feature_id field is used to track the relationship.

=item get_analysis() | set_analysis($analysis)

The analysis for this Chado analysisfeature. This must be a
L<ModENCODE::Chado::Analysis> or conforming subclass (via C<isa>). The analysis
object corresponds to an analysis in the Chado analysis table, and the
analysisfeature.analysis_id field is used to track the relationship.

=back

=head1 UTILITY FUNCTIONS

=over

=item equals($obj)

Returns true if this feature and $obj are equal. Checks all simple and complex
attributes. Also requires that this object and $obj are of the exact same type.
(A parent class != a subclass, even if all attributes are the same.)

=item clone()

Returns a deep copy of this object, recursing to clone all complex type
attributes.

=item to_string()

Return a string representation of this analysisfeature. Attempts to print the
associated analysis and feature. Because the feature's to_string method follows
feature relationships, this may involve deep graph traversal and thus can take
some time.

=back

=head1 SEE ALSO

L<Class::Std>, L<ModENCODE::Chado::Analysis>, L<ModENCODE::Chado::Feature>

=head1 AUTHOR

E.O. Stinson L<mailto:yostinso@berkeleybop.org>, ModENCODE DCC
L<http://www.modencode.org>.

=cut

use strict;
use Class::Std;
use Carp qw(croak carp);
use ModENCODE::Chado::Analysis;
use ModENCODE::Chado::Feature;

# Attributes
my %analysisfeature_id  :ATTR( :name<id>,               :default<undef> );
my %rawscore            :ATTR( :name<rawscore>,         :default<undef> );
my %normscore           :ATTR( :name<normscore>,        :default<undef> );
my %significance        :ATTR( :name<significance>,     :default<undef> );
my %identity            :ATTR( :name<identity>,         :default<undef> );

# Relationships
my %analysis            :ATTR( :init_arg<analysis> );

sub get_analysis_id {
  my $self = shift;
  return $analysis{ident $self} ? $analysis{ident $self}->get_id : undef;
}

sub get_analysis {
  my $self = shift;
  my $get_cached_object = shift || 0;
  my $analysis = $analysis{ident $self};
  return undef unless defined $analysis;
  return $get_cached_object ? $analysis->get_object : $analysis;
}

sub to_string {
  my ($self) = @_;
  my $string = "analysisfeature(" . $self->get_rawscore() . ", " . $self->get_identity() . ")";
  $string .= " for " . $self->get_analysis(1)->to_string() if $self->get_analysis();
  return $string;
}

1;
