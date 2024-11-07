# Задание 5

1. Развернуть асинхронную реплику (можно использовать 1 ВМ, просто рядом кластер развернуть и подключиться через localhost).  
    В `docker-compose.yaml` файле добавил настройку баз мастера и реплики.
    ## Основная база данных (postgres_primary):
    `primary/init.sh` - скрипт инициализации для создания пользователя replicator и физического слота репликации:
    ```bash
    cat >> $PGDATA/pg_hba.conf << EOL
    host replication replicator 0.0.0.0/0 scram-sha-256
    EOL
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" <<-EOSQL
      CREATE USER $POSTGRES_REPLICA_USER WITH REPLICATION ENCRYPTED PASSWORD '$POSTGRES_REPLICA_PASSWORD';
      SELECT pg_create_physical_replication_slot('test');
    EOSQL
    ```
    `primary/postgresql.conf` - конфигурационный файл для настройки репликации:
    ```conf
    listen_addresses = '*'
    wal_level = replica
    ```
    ## Реплика (postgres_replica):
    `replica/init.sh` - для настройки .pgpass и очистки данных перед подключением.
    Разварачиваем мастер и реплику:
    ```bash
    docker-compose -f docker-compose.yaml up -d
    ```
    Подключаемся к реплике:
    ```bash
    docker exec -it postgres_replica bash
    ```
    Копируем текущее состояние основной базы и начинаем репликацию с нее, используя заданный слот:
    ```bash
    rm -rf $PGDATA/*
    pg_basebackup -h "$POSTGRES_PRIMARY_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_REPLICA_USER" -D "$PGDATA" -R -S test --verbose --progress
    ```
    
2. Тестируем производительность по сравнению с сингл инстансом.
   ## Подключаемся к мастеру:
    ```bash
    docker exec -it postgres_primary bash
    ```
   ### нагрузка на запись
   ```bash
   cat > workload2.sql << EOF
   INSERT INTO book.tickets (fkRide, fio, contact, fkSeat)
   VALUES (
   ceil(random()*100)
   , (array(SELECT fam FROM book.fam))[ceil(random()*110)]::text || ' ' ||
   (array(SELECT nam FROM book.nam))[ceil(random()*110)]::text
   ,('{"phone":"+7' || (1000000000::bigint + floor(random()*9000000000)::bigint)::text || '"}')::jsonb
   , ceil(random()*100));
   ```
   ```bash
   pgbench -f workload2.sql -c 8 -j 1 -T 10 -n -U postgres -p 5432 thai
   ```
   Результаты:
   ```
   pgbench (16.4)
   transaction type: workload2.sql
   scaling factor: 1
   query mode: simple
   number of clients: 8
   number of threads: 1
   maximum number of tries: 1
   duration: 10 s
   number of transactions actually processed: 19777
   number of failed transactions: 0 (0.000%)
   latency average = 4.038 ms
   initial connection time = 31.520 ms
   tps = 1981.413764 (without initial connection time)
   ```
   ### нагрузка на чтение
   ```bash
   cat > workload.sql << EOF
   \set r random(1, 5000000)
   SELECT id, fkRide, fio, contact, fkSeat FROM book.tickets WHERE id = :r;
   ```
   ```bash
    pgbench -f workload.sql -c 8 -j 1 -T 10 -n -U postgres thai
   ```
   Результаты:
   ```
   pgbench (16.4)
   transaction type: workload.sql
   scaling factor: 1
   query mode: simple
   number of clients: 8
   number of threads: 1
   maximum number of tries: 1
   duration: 10 s
   number of transactions actually processed: 51609
   number of failed transactions: 0 (0.000%)
   latency average = 1.547 ms
   initial connection time = 30.029 ms
   tps = 5169.763560 (without initial connection time)
   ```
   ## Тестируем с репликой
   Запускаем реплику:
   ```bash
   docker-compose -f docker-compose.yaml up -d postgres_replica
   ```
   ### нагрузка на запись
   Проверяем на мастере:
   ```bash
   pgbench -f workload2.sql -c 8 -j 1 -T 10 -n -U postgres -p 5432 thai
   ```
   Результаты:
   ```
   pgbench (16.4)
   transaction type: workload2.sql
   scaling factor: 1
   query mode: simple
   number of clients: 8
   number of threads: 1
   maximum number of tries: 1
   duration: 10 s
   number of transactions actually processed: 17118
   number of failed transactions: 0 (0.000%)
   latency average = 4.665 ms
   initial connection time = 29.131 ms
   tps = 1715.075107 (without initial connection time)
   ```
   ### нагрузка на чтение
   Проверяем на мастере:
   ```bash
   pgbench -f workload.sql -c 8 -j 1 -T 10 -n -U postgres thai
   ```
   Результаты:
   ```
   pgbench (16.4)
   transaction type: workload.sql
   scaling factor: 1
   query mode: simple
   number of clients: 8
   number of threads: 1
   maximum number of tries: 1
   duration: 10 s
   number of transactions actually processed: 49573
   number of failed transactions: 0 (0.000%)
   latency average = 1.610 ms
   initial connection time = 32.860 ms
   tps = 4968.861547 (without initial connection time)
   ```
   Проверяем на реплике
   ```bash
   cat > workload.sql << EOF
   \set r random(1, 5000000)
   SELECT id, fkRide, fio, contact, fkSeat FROM book.tickets WHERE id = :r;
   ```
   ```bash
   pgbench -f workload.sql -c 8 -j 1 -T 10 -n -U postgres thai
   ```
   Результаты:
   ```
   pgbench (16.4)
   transaction type: workload.sql
   scaling factor: 1
   query mode: simple
   number of clients: 8
   number of threads: 1
   maximum number of tries: 1
   duration: 10 s
   number of transactions actually processed: 52800
   number of failed transactions: 0 (0.000%)
   latency average = 1.510 ms
   initial connection time = 42.067 ms
   tps = 5298.610309 (without initial connection time)
   ```

## Вывод
При включении асинхронной репликации производительность записи на мастере незначительно снизилась с 1981 до 1715 tps. Это связано с дополнительной нагрузкой на мастер из-за репликации данных. Производительность чтения на мастере также немного уменьшилась с 5169 до 4968 tps. Однако на реплике производительность чтения составила 5298 tps, что даже превышает показатели мастера без репликации. Это объясняется тем, что реплика не обрабатывает запросы на запись, и, следовательно, имеет больше ресурсов для обработки запросов на чтение.

Таким образом, использование асинхронной репликации позволяет распределить нагрузку, улучшив общую производительность системы при запросах на чтение. 
