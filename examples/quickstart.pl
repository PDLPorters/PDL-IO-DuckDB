# Copyright 2026 Google LLC
#
# Licensed under the the same terms as Perl itself (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;
use PDL;
use PDL::IO::DuckDB qw(duckdb_connect duckdb_version);

# 1. Connect to an in-memory DuckDB instance
print 'DuckDB version: ', duckdb_version(), "\n";
my $db = duckdb_connect(':memory:');

# 2. Create a table and insert sample sales records
$db->exec('CREATE TABLE sales (region VARCHAR, qty INTEGER, price DOUBLE)');
$db->exec(
    q{INSERT INTO sales VALUES
      ('north', 10, 12.50),
      ('north', 5,  15.00),
      ('south', 8,  20.00),
      ('west',  12, 10.00)}
);

# 3. Run vectorized SQL aggregation and return numeric columns as PDL ndarrays
my $cols = $db->query_pdl(
    'SELECT region,
            CAST(SUM(qty) AS BIGINT) AS total_qty,
            SUM(qty * price)         AS revenue,
            AVG(price)               AS avg_price
     FROM sales
     GROUP BY region
     ORDER BY region'
);

# 4. Perform downstream vectorized PDL math
my $rev   = $cols->{revenue};
my $share = 100.0 * $rev / $rev->sum;

for my $i (0 .. $#{ $cols->{region} }) {
    printf "%-6s qty=%-3d avg_price=%5.2f revenue=%6.2f (%.1f%%)\n",
        $cols->{region}[$i],
        $cols->{total_qty}->at($i),
        $cols->{avg_price}->at($i),
        $rev->at($i),
        $share->at($i);
}
