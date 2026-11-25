package PDL::IO::DuckDB;

use strict;
use warnings;
use Exporter 'import';
use XSLoader;

use PDL::Core;
use PDL::Types;
use PDL::Slices;

our $VERSION = '0.011';

our @EXPORT_OK = qw(
    duckdb_connect
    duckdb_version
);

XSLoader::load('PDL::IO::DuckDB', $VERSION);

sub duckdb_connect {
    my ($path) = @_;
    $path = ':memory:' unless defined $path && length $path;
    return PDL::IO::DuckDB::Connection::_xs_open($path);
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDL::IO::DuckDB - Vectorized SQL/DataFrame engine (DuckDB) bindings for PDL

=head1 SYNOPSIS

    use PDL;
    use PDL::IO::DuckDB qw(duckdb_connect duckdb_version);

    my $db = duckdb_connect(':memory:');
    $db->exec('CREATE TABLE t (grp VARCHAR, x DOUBLE)');
    $db->exec("INSERT INTO t VALUES ('a', 1.5), ('a', 2.5), ('b', 10.0)");

    my $cols = $db->query_pdl(
        'SELECT grp, SUM(x) AS total, AVG(x) AS mean FROM t GROUP BY grp ORDER BY grp'
    );
    # $cols->{total} and $cols->{mean} are PDL double ndarrays
    # $cols->{grp} is ['a', 'b']

=head1 DESCRIPTION

C<PDL::IO::DuckDB> binds L<PDL> ndarrays directly to DuckDB's pure-C API
(C<duckdb.h>) via C99 XS, providing a platform-agnostic, vectorized,
multithreaded SQL/DataFrame engine (joins, group-bys, window functions, and
native Parquet/CSV querying) that returns numeric columns directly as PDL
ndarrays.

=head1 FUNCTIONS

=head2 duckdb_connect

=for ref

Open a DuckDB database (default C<':memory:'>) and return a
C<PDL::IO::DuckDB::Connection>.

=for usage

    $db = duckdb_connect();
    $db = duckdb_connect('analytics.duckdb');

=head2 duckdb_version

=for ref

Return the linked DuckDB library version string.

=for usage

    $ver = duckdb_version();

=head1 TUTORIAL

This tutorial translates DuckDB's flagship SQL analytics quickstart into
idiomatic Perl and L<PDL>, executing vectorized SQL queries and receiving
numeric result columns directly as PDL ndarrays.

=head2 1. Connect to an In-Memory Database

    use strict;
    use warnings;
    use PDL;
    use PDL::IO::DuckDB qw(duckdb_connect duckdb_version);

    print 'DuckDB version: ', duckdb_version(), "\n";
    my $db = duckdb_connect(':memory:');

=head2 2. Create Tables and Load Data

Use C<< $db->exec($sql) >> for DDL and DML statements:

    $db->exec('CREATE TABLE sales (region VARCHAR, qty INTEGER, price DOUBLE)');
    $db->exec(
        q{INSERT INTO sales VALUES
          ('north', 10, 12.50),
          ('north', 5,  15.00),
          ('south', 8,  20.00),
          ('west',  12, 10.00)}
    );

=head2 3. Run SQL Analytics and Materialize PDL Ndarrays

Use C<< $db->query_pdl($sql) >> to return a hashref where every numeric column
is a 1-D L<PDL> ndarray and string columns (such as C<VARCHAR>) are Perl
arrayrefs:

    my $cols = $db->query_pdl(
        'SELECT region,
                CAST(SUM(qty) AS BIGINT) AS total_qty,
                SUM(qty * price)         AS revenue,
                AVG(price)               AS avg_price
         FROM sales
         GROUP BY region
         ORDER BY region'
    );

=head2 4. Continue with Vectorized PDL Math

Once in PDL, apply vectorized statistics and array operations directly:

    my $rev   = $cols->{revenue};
    my $share = 100.0 * $rev / $rev->sum;

    for my $i (0 .. $#{ $cols->{region} }) {
        printf "%-6s qty=%-3d revenue=%6.2f (%.1f%%)\n",
            $cols->{region}[$i],
            $cols->{total_qty}->at($i),
            $rev->at($i),
            $share->at($i);
    }

See C<examples/quickstart.pl> in the distribution for a complete runnable
script.

=head1 TYPES

Supports standard real numeric PDL types (C<byte>, C<short>, C<long>, C<longlong>, C<float>, C<double> as supported by the underlying library). Complex types (C<cfloat>, C<cdouble>) are not supported by this backend.

=head1 SEE ALSO

L<PDL>, L<PDL::IO::Arrow>, L<PDL::Torch>, L<PDL::XGBoost>

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 Google LLC

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
