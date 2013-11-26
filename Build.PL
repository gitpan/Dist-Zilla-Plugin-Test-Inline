
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Create test files for inline tests in POD sections",
  "dist_author" => [
    "Jens Berthold <jens.berthold\@jebecs.de>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-Test-Inline",
  "dist_version" => "0.011001",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::Test::Inline",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dist::Zilla::Role::FileGatherer" => "5.006",
    "File::Find::Rule" => "0.33",
    "Moose" => "2.1005",
    "Test::Inline" => "2.213",
    "parent" => "0.228",
    "perl" => "v5.8.8"
  },
  "script_files" => [],
  "test_requires" => {}
);


my %fallback_build_requires = (
  "Module::Build" => "0.3601"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
