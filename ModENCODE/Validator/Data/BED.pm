package ModENCODE::Validator::Data::BED;
=pod

=head1 NAME

ModENCODE::Validator::Data::BED - Class for validating and updating BIR-TAB
L<Data|ModENCODE::Chado::Data> objects containing BED files (or rather, paths to
BED files) to include L<ModENCODE::Chado::Wiggle_Data> objects. This class is a
subclass of the abstract class L<ModENCODE::Validator::Data::Data>.

=head1 SYNOPSIS

This class is meant to be used to parse BED files into
L<ModENCODE::Chado::Wiggle_Data> objects when given L<ModENCODE::Chado::Data>
objects with values that are paths to BED files. L<Data|ModENCODE::Chado::Data>
are passed in using L<add_datum($datum,
$applied_protocol)|ModENCODE::Validator::Data::Data/add_datum($datum,
$applied_protocol)>, and then the paths in the data's values are validated and
parsed as BED files and loaded in L<Wiggle_Data|ModENCODE::Chado::Wiggle_Data>
objects. L<Wiggle_Data|ModENCODE::Chado::Wiggle_Data> objects are the type used
to store continuous data for the BIR-TAB Chado extension, and are used for
Wiggle format, BED format, and others.

=head1 USAGE

A BIR-TAB data column should be run through this validator if it contains the
path to a BED file. This is implemented in practice by typing the column as a
BED column, which leads the L<ModENCODE::Validator::Data> delegator to add the
L<ModENCODE::Chado::Data> objects from that column to this validator.

The file at that given path is then parsed, converted to a
L<ModENCODE::Chado::Wiggle_Data> object, and added to the datum that was passed
in.

  my $datum = new ModENCODE::Chado::Data({
    'value' => 'relative/path/to/file.bed'
  });
  my $applied_protocol = new ModENCODE::Chado::AppliedProtocol({
    'input_data' => [ $datum ],
  });
  my $validator = new ModENCODE::Validator::Data::BED();
  $validator->add_datum($datum, $applied_protocol);
  if ($validator->validate()) {
    my $new_datum = $validator->merge($datum);
    print $new_datum->get_wiggle_datas()->[0]->get_data();
  }

Note that this class is not meant to be used directly, rather it is mean to be
used within L<ModENCODE::Validator::Data>.

=head1 FUNCTIONS

=over

=item validate()

Makes sure that all of the data added using L<add_datum($datum,
$applied_protocol)|ModENCODE::Validator::Data::Data/add_datum($datum,
$applied_protocol)> have values that point to existing files that can be parsed
as valid BED files.

=item merge($datum, $applied_protocol)

Given an original L<datum|ModENCODE::Chado::Data> C<$datum>,
returns a copy of that datum with a newly attached
L<ModENCODE::Chado::Wiggle_Data>.

=back

=head1 SEE ALSO

L<ModENCODE::Chado::Data>, L<ModENCODE::Validator::Data>,
L<ModENCODE::Validator::Data::Data>, L<ModENCODE::Chado::Wiggle_Data>,
L<ModENCODE::Chado::CVTerm>, L<ModENCODE::Validator::Data::GFF3>,
L<ModENCODE::Validator::Data::Result_File>,
L<ModENCODE::Validator::Data::SO_transcript>,
L<ModENCODE::Validator::Data::WIG>, L<ModENCODE::Validator::Data::dbEST_acc>,
L<ModENCODE::Validator::Data::dbEST_acc_list>,

=head1 AUTHOR

E.O. Stinson L<mailto:yostinso@berkeleybop.org>, ModENCODE DCC
L<http://www.modencode.org>.

=cut
use strict;
use base qw( ModENCODE::Validator::Data::Data );
use Class::Std;
use Carp qw(croak carp);
use ModENCODE::Chado::Wiggle_Data;
use ModENCODE::ErrorHandler qw(log_error);

my %cached_wig_files            :ATTR( :default<{}> );
my %seen_data           :ATTR( :default<{}> );       


sub validate {
  my ($self) = @_;
  my $success = 1;
  
  log_error "Validating attached BED file(s).", "notice", ">";

  while (my $ap_datum = $self->next_datum) {
    my ($applied_protocol, $direction, $datum) = @$ap_datum;
    next if $seen_data{$datum->get_id}++; # Don't re-update the same datum

    my $datum_obj = $datum->get_object;

    if (!length($datum_obj->get_value())) {
      log_error "No BED file for " . $datum_obj->get_heading(), 'warning';
      next;
    } elsif (!-r $datum_obj->get_value()) {
      log_error "Cannot find BED file " . $datum_obj->get_value() . " for column " . $datum_obj->get_heading() . " [" . $datum_obj->get_name . "].", "error";
      $success = 0;
      next;
    } elsif ($cached_wig_files{ident $self}->{$datum_obj->get_value()}++) {
      log_error "Referring to the same BED file (" . $datum_obj->get_value . ") in two different data columns!", "error";
      $success = 0;
      next;
    }

    # Read the file
    open FH, '<', $datum_obj->get_value() or croak "Couldn't open file " . $datum_obj->get_value . " for reading; fatal error";
    my $linenum = 0;
    # Build Wiggle object
    my ($filename) = ($datum_obj->get_value() =~ m/([^\/]+)$/);
    my $wiggle = new ModENCODE::Chado::Wiggle_Data({
        'name' => $filename,
        'datum' => $datum,
      });
    $datum->get_object->add_wiggle_data($wiggle);

    log_error "Validating BED file: $filename", 'notice' ;
    my $wiggle_data = "";

    while (defined(my $line = <FH>)) {
      $linenum++;
      next if $line =~ m/^\s*#/; # Skip comments
      next if $line =~ m/^\s*$/; # Skip blank lines
      my ($chr, $start, $end) = ($line =~ m/^\s*(\S+)\s+(\d+)\s+(\d+)\s*$/);
      if (!(length($chr) && length($start) && length($end))) {
        log_error "BED file " . $datum_obj->get_value() . " does not seem valid beginning at line $linenum:\n      $line";
        $success = 0;
        next;
      } elsif ($start == 0) {
        log_error "BED file " . $datum_obj->get_value() . " does not seem valid beginning at line $linenum:\n\>      $line.  You have a start coordinate of zero, which may indicate your data are zero-based.  BED files must be 1-based.\nOnly the first instance is reported.";
        $success = 0;
        next;
      } else {
        $wiggle_data .= "$chr $start $end\n";
      }
    }

    close FH;
    $wiggle->get_object->set_data($wiggle_data);
  }

  log_error "Done.", "notice", "<";
  return $success;
}

1;
