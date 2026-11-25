# PDL::IO::DuckDB

Vectorized SQL/DataFrame engine (**DuckDB**) bindings for [PDL](https://pdl.perl.org/), built on DuckDB's C API (`duckdb.h`) via C99 XS. Execute SQL joins, group-bys, window functions, and native Parquet/CSV queries and receive numeric result columns directly as PDL ndarrays.

## Quickstart

```perl
use strict;
use warnings;
use PDL;
use PDL::IO::DuckDB qw(duckdb_connect duckdb_version);

my $db = duckdb_connect(':memory:');
$db->exec('CREATE TABLE sales (region VARCHAR, qty INTEGER, price DOUBLE)');
$db->exec(q{INSERT INTO sales VALUES ('north', 10, 12.50), ('south', 8, 20.00)});

my $cols = $db->query_pdl(
    'SELECT region, CAST(SUM(qty) AS BIGINT) AS total_qty, SUM(qty * price) AS revenue
     FROM sales GROUP BY region ORDER BY region'
);

# $cols->{total_qty} and $cols->{revenue} are 1-D PDL ndarrays
# $cols->{region} is ['north', 'south']
print 'Total revenue: ', $cols->{revenue}->sum, "\n";
```

See [examples/quickstart.pl](examples/quickstart.pl) for a complete runnable tutorial, and run `perldoc PDL::IO::DuckDB` for the full API reference and tutorial.

## Prerequisites

- DuckDB C library (`libduckdb` and `duckdb.h`)
- Perl: `PDL >= 2.080`

## Installation

```bash
perl Makefile.PL
make
make test
make install
```

## License

the same terms as Perl itself.
