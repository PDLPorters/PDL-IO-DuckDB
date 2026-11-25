use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

my $brew_prefix = '';
if ($^O eq 'darwin') {
    chomp($brew_prefix = `brew --prefix 2>/dev/null` || '');
}
my @inc_dirs = ('/usr/include', '/usr/local/include');
push @inc_dirs, "$brew_prefix/include" if $brew_prefix;
my $duck_inc;
for my $dir (@inc_dirs) {
    if (-f "$dir/duckdb.h") {
        $duck_inc = $dir;
        last;
    }
}
if (!$duck_inc) {
    die "libduckdb-dev (duckdb.h) is required to build PDL::IO::DuckDB.\n";
}
my $lib_flag = ($brew_prefix && $duck_inc && $duck_inc =~ m{^\$brew_prefix}) ? "-L$brew_prefix/lib " : '';

my $pdl_inc = PDL::Core::Dev::PDL_INCLUDE();

WriteMakefile(
    NAME               => 'PDL::IO::DuckDB',
    AUTHOR             => q{C.J. Collier <cjac@google.com>},
    VERSION_FROM       => 'lib/PDL/IO/DuckDB.pm',
    ABSTRACT_FROM      => 'lib/PDL/IO/DuckDB.pm',
    LICENSE            => 'perl_5',
    MIN_PERL_VERSION   => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'PDL'                 => '2.080',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'PDL' => '2.080',
    },
    INC     => '-I. ' . $pdl_inc . ' -I' . $duck_inc,
    XSMULTI => 1,
    LIBS    => [ $lib_flag . '-lduckdb' ],
    ($brew_prefix ? (dynamic_lib => { OTHERLDFLAGS => "-L$brew_prefix/lib -Wl,-rpath,$brew_prefix/lib -lduckdb" }) : ()),
    clean   => { FILES => 'PDL-IO-DuckDB-* *.o DuckDB.bs DuckDB.c' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/PDLPorters/PDL-IO-DuckDB.git',
                web  => 'https://github.com/PDLPorters/PDL-IO-DuckDB',
            },
            bugtracker => {
                web => 'https://github.com/PDLPorters/PDL-IO-DuckDB/issues',
            },
        },
    },
);
