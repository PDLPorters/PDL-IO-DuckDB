use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

my $duck_inc;
for my $dir ('/usr/include', '/usr/local/include', '/opt/homebrew/include') {
    if (-f "$dir/duckdb.h") {
        $duck_inc = $dir;
        last;
    }
}
if (!$duck_inc) {
    die "libduckdb-dev (duckdb.h) is required to build PDL::IO::DuckDB.\n";
}
my $lib_flag = $duck_inc =~ m{^/opt/homebrew} ? '-L/opt/homebrew/lib ' : '';

my $pdl_inc = PDL::Core::Dev::PDL_INCLUDE();

WriteMakefile(
    NAME               => 'PDL::IO::DuckDB',
    AUTHOR             => q{C.J. Collier <cjac@google.com>},
    VERSION_FROM       => 'lib/PDL/IO/DuckDB.pm',
    ABSTRACT_FROM      => 'lib/PDL/IO/DuckDB.pm',
    LICENSE            => 'apache_2_0',
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
