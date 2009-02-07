#!/usr/bin/perl
use Data::Dumper;
use POSIX qw(locale_h);
use locale;
use Encode;
use CGI qw/:standard/;

#use encoding "utf-8", STDOUT=>"koi8-r";

#setlocale("LC_ALL", "ru_RU.UTF-8");

my $lines = [];
my $current_matching = [];
my $replace = {};

open(my $f, "lines.txt");
for (<$f>) {
  chomp;
  if (/\S/) {
    push @$current_matching, $_;
  } elsif (scalar @$current_matching) {
    push @$lines, $current_matching;
    $current_matching = [];
  }
}
close $f;

open($f, "replace.txt");
for (<$f>) {
  s/#.*$//g;
  my @words = grep {$_} /"(.*?)"|(\S+)/g;

  next unless $#words;
  $replace->{$words[0]} = \@words;
}
close $f;

for $current_matching(@$lines) {
  for my $line(@$current_matching) {
    for (keys %$replace) {
      $line =~ s%$_(?!$)%#{$&}%g;
    }
  }
}

sub generate_pair
{
  my $matching = $lines->[rand(scalar @$lines)];
  my $num_lines = scalar @$matching;
  my @indexes = (int(rand($num_lines)), int(rand($num_lines)));
  if ($indexes[0] == $indexes[1]) {
    $indexes[1] = ($indexes[1]+1) % $num_lines;
  }

  @result = ($matching->[$indexes[0]], $matching->[$indexes[1]]);
  return @result;
}

sub random_replace
{
  my $r = shift;
  my $reps = $replace->{$r};
  return $reps->[rand(scalar @$reps)];
}

sub replace_tokens
{
  shift;
  s/#{(.*?)}/&random_replace($1)/gem;
  return $_;
}

sub generate_4
{
  my @lines = (generate_pair(), generate_pair());
  if (rand()>.5) {
    @lines = ($lines[0], $lines[2], $lines[1], $lines[3]);
  }

  for (@lines) {
    $_ = replace_tokens($_);
    $_ = decode('utf-8', $_);
    s/^(.)/uc($1)/e;
    $_ = encode('utf-8', $_);
  }
  return @lines;
}

sub show_page
{
  my $f;
  open($f, 'template.html');
  local $/;
  my $content = <$f>;
  close($f);

  my $count_4s = int(rand(3))+2;
  my $poetry = '';

  my $i;
  for ($i=0; $i<$count_4s; $i++) {
    $poetry .= join "<br/>", generate_4();
    $poetry .= "<br/><br/>" if ($i!=$count_4s-1);
  }

  $content =~ s/!POETRY/$poetry/;

  print header(-charset=>'utf-8');
  print $content;
}

#print Dumper generate_4();

#my @result = generate_4();
#print join "\n", @result;

show_page();

#print Dumper $lines;
#print Dumper $replace;
