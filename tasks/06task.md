# Задание 6

1. Развернуть ВМ (Linux) с PostgreSQL
    Выполняем команду:
    ```bash
    docker-compose -f docker-compose.yaml up -d
    ```
2. Залить Тайские перевозки https://github.com/aeuge/postgres16book/tree/main/database  
    При развертывании контейнера базы данных, скрипты заливки базы thai выполняются автоматически.
3. Проверить скорость выполнения сложного запроса (приложен в конце файла скриптов)
   ```
   10 rows retrieved starting from 1 in 6 s 868 ms (execution: 6 s 840 ms, fetching: 28 ms)
   ```
4. Навесить индексы на внешние ключ
    ```sql
    create index concurrently idx_seat_fkbus ON book.seat(fkbus);
    create index concurrently idx_tickets_fkride ON book.tickets(fkride);
    create index concurrently idx_ride_fkschedule on book.ride(fkschedule);
    create index concurrently idx_ride_fkbus on book.ride(fkbus);
    create index concurrently idx_schedule_fkroute on book.schedule(fkroute);
    create index concurrently idx_busroute_fkbusstationfrom on book.busroute(fkbusstationfrom);
    ```

5. Проверить, помогли ли индексы на внешние ключи ускориться
    ```
    10 rows retrieved starting from 1 in 5 s 141 ms (execution: 5 s 100 ms, fetching: 41 ms)
    ```
    Индексы на внешние ключи незначительно ускорили запрос. По плану запроса представленного ниже видно, что основное время выполнения запроса тратится на агрегацию и сканирование таблицы `tickets`. Partial HashAggregate и Finalize GroupAggregate: операции агрегации занимают основную часть времени выполнения запроса. Поэтому индексы на внешние ключи не сильно ускорили запрос.

    План запроса:
    ```
| QUERY PLAN |
| :--- |
| Limit  \(cost=324834.86..324834.88 rows=10 width=56\) \(actual time=6393.442..6393.524 rows=10 loops=1\) |
|   -&gt;  Sort  \(cost=324834.86..325167.20 rows=132938 width=56\) \(actual time=6350.524..6350.605 rows=10 loops=1\) |
|         Sort Key: r.startdate |
|         Sort Method: top-N heapsort  Memory: 25kB |
|         -&gt;  Group  \(cost=319635.70..321962.12 rows=132938 width=56\) \(actual time=6272.407..6330.645 rows=144000 loops=1\) |
|               Group Key: r.id, \(\(\(bs.city \|\| ', '::text\) \|\| bs.name\)\), \(count\(t.id\)\), \(count\(s\_1.id\)\) |
|               -&gt;  Sort  \(cost=319635.70..319968.05 rows=132938 width=56\) \(actual time=6272.376..6295.579 rows=144000 loops=1\) |
|                     Sort Key: r.id, \(\(\(bs.city \|\| ', '::text\) \|\| bs.name\)\), \(count\(t.id\)\), \(count\(s\_1.id\)\) |
|                     Sort Method: external merge  Disk: 7872kB |
|                     -&gt;  Hash Join  \(cost=260403.06..303775.92 rows=132938 width=56\) \(actual time=5623.894..6081.295 rows=144000 loops=1\) |
|                           Hash Cond: \(r.fkbus = s\_1.fkbus\) |
|                           -&gt;  Hash Join  \(cost=260397.94..302461.36 rows=132938 width=36\) \(actual time=5623.754..6011.450 rows=144000 loops=1\) |
|                                 Hash Cond: \(r.fkschedule = s.id\) |
|                                 -&gt;  Merge Join  \(cost=260341.54..300577.06 rows=132938 width=24\) \(actual time=5620.889..5961.614 rows=144000 loops=1\) |
|                                       Merge Cond: \(r.id = t.fkride\) |
|                                       -&gt;  Index Scan using ride\_pkey on ride r  \(cost=0.42..4534.42 rows=144000 width=16\) \(actual time=0.023..30.354 rows=144000 loops=1\) |
|                                       -&gt;  Finalize GroupAggregate  \(cost=260341.12..294020.91 rows=132938 width=12\) \(actual time=5620.852..5871.351 rows=144000 loops=1\) |
|                                             Group Key: t.fkride |
|                                             -&gt;  Gather Merge  \(cost=260341.12..291362.15 rows=265876 width=12\) \(actual time=5620.812..5795.378 rows=432000 loops=1\) |
|                                                   Workers Planned: 2 |
|                                                   Workers Launched: 2 |
|                                                   -&gt;  Sort  \(cost=259341.10..259673.44 rows=132938 width=12\) \(actual time=5467.415..5491.751 rows=144000 loops=3\) |
|                                                         Sort Key: t.fkride |
|                                                         Sort Method: external merge  Disk: 3672kB |
|                                                         Worker 0:  Sort Method: external merge  Disk: 3672kB |
|                                                         Worker 1:  Sort Method: external merge  Disk: 3672kB |
|                                                         -&gt;  Partial HashAggregate  \(cost=222939.69..245752.81 rows=132938 width=12\) \(actual time=4301.692..5225.039 rows=144000 loops=3\) |
|                                                               Group Key: t.fkride |
|                                                               Planned Partitions: 4  Batches: 5  Memory Usage: 8241kB  Disk Usage: 26424kB |
|                                                               Worker 0:  Batches: 5  Memory Usage: 8241kB  Disk Usage: 27400kB |
|                                                               Worker 1:  Batches: 5  Memory Usage: 8241kB  Disk Usage: 27416kB |
|                                                               -&gt;  Parallel Seq Scan on tickets t  \(cost=0.00..82006.35 rows=2199935 width=12\) \(actual time=22.988..1371.117 rows=1759948 loops=3\) |
|                                 -&gt;  Hash  \(cost=38.40..38.40 rows=1440 width=20\) \(actual time=2.844..2.849 rows=1440 loops=1\) |
|                                       Buckets: 2048  Batches: 1  Memory Usage: 91kB |
|                                       -&gt;  Hash Join  \(cost=3.58..38.40 rows=1440 width=20\) \(actual time=1.790..2.520 rows=1440 loops=1\) |
|                                             Hash Cond: \(br.fkbusstationfrom = bs.id\) |
|                                             -&gt;  Hash Join  \(cost=2.35..31.80 rows=1440 width=8\) \(actual time=0.843..1.299 rows=1440 loops=1\) |
|                                                   Hash Cond: \(s.fkroute = br.id\) |
|                                                   -&gt;  Seq Scan on schedule s  \(cost=0.00..25.40 rows=1440 width=8\) \(actual time=0.754..0.870 rows=1440 loops=1\) |
|                                                   -&gt;  Hash  \(cost=1.60..1.60 rows=60 width=8\) \(actual time=0.057..0.058 rows=60 loops=1\) |
|                                                         Buckets: 1024  Batches: 1  Memory Usage: 11kB |
|                                                         -&gt;  Seq Scan on busroute br  \(cost=0.00..1.60 rows=60 width=8\) \(actual time=0.016..0.021 rows=60 loops=1\) |
|                                             -&gt;  Hash  \(cost=1.10..1.10 rows=10 width=20\) \(actual time=0.037..0.037 rows=10 loops=1\) |
|                                                   Buckets: 1024  Batches: 1  Memory Usage: 9kB |
|                                                   -&gt;  Seq Scan on busstation bs  \(cost=0.00..1.10 rows=10 width=20\) \(actual time=0.020..0.022 rows=10 loops=1\) |
|                           -&gt;  Hash  \(cost=5.05..5.05 rows=5 width=12\) \(actual time=0.103..0.104 rows=5 loops=1\) |
|                                 Buckets: 1024  Batches: 1  Memory Usage: 9kB |
|                                 -&gt;  HashAggregate  \(cost=5.00..5.05 rows=5 width=12\) \(actual time=0.089..0.091 rows=5 loops=1\) |
|                                       Group Key: s\_1.fkbus |
|                                       Batches: 1  Memory Usage: 24kB |
|                                       -&gt;  Seq Scan on seat s\_1  \(cost=0.00..4.00 rows=200 width=8\) \(actual time=0.014..0.035 rows=200 loops=1\) |
| Planning Time: 2.910 ms |
| JIT: |
|   Functions: 83 |
|   Options: Inlining false, Optimization false, Expressions true, Deforming true |
|   Timing: Generation 20.082 ms, Inlining 0.000 ms, Optimization 8.809 ms, Emission 161.081 ms, Total 189.972 ms |
| Execution Time: 6417.865 ms |
    ```
