# Задание 2

1. открыть консоль и зайти по ssh на ВМ
2. открыть вторую консоль и также зайти по ssh на ту же ВМ (можно в докере 2 сеанса)
3. запустить везде psql из под пользователя postgres 
   ```
   в нашем случае в обоих консолях это будет команда:
   make psql
   ```
4. сделать в первой сессии новую таблицу и наполнить ее данными
   ```
   create table users (
       id serial primary key, 
       name text,
       email text unique,
       created_at timestamp default now()
   );
   
   insert into users (id, name, email, created_at)
   select
       generate_series(1, 10000) as id,
       md5(random()::text) as name,
       md5(random()::text) as email,
       now() - (random() * interval '2 year') as created_at;
   ```
5. посмотреть текущий уровень изоляции
   ```
   show transaction isolation level;
   transaction_isolation 
   -----------------------
   read committed
   (1 row)
   ```
6. начать новую транзакцию в обеих сессиях с дефолтным (не меняя) уровнем
   изоляции
   ```
      Начать транзакцию можно командой:
      begin;
   ```
7. в первой сессии добавить новую запись
   ```
   insert into users (id, name, email) values (10001, 'john doe', 'john@doe.com');
   ```
8. сделать запрос на выбор всех записей во второй сессии
   ```
   select * from users order by id desc;
   ```
9. видите ли вы новую запись и если да то почему?
   ```
    Нет, не вижу. Потому что уровень изоляции по умолчанию - read commited.
   ```
10. завершить транзакцию в первом окне
    ```
    commit;
    ```
11. сделать запрос на выбор всех записей второй сессии
    ```
    select * from users order by id desc;
    ```
12. видите ли вы новую запись и если да то почему?
    ```
    Да, вижу. Потому что транзакция второй сессии видит закоммиченные изменения первой сессии.
    ```
13. завершите транзакцию во второй сессии
    ```
    commit;
    ```
14. начать новые транзакции, но уже на уровне repeatable read в ОБЕИХ сессиях
    ```
    \set AUTOCOMMIT OFF
    set transaction isolation level repeatable read;
    ```
15. в первой сессии добавить новую запись
    ```
    insert into users (id, name, email) values (10002, 'jane doe', 'jane@doe.com');
    ```
16. сделать запрос на выбор всех записей во второй сессии
    ```
    select * from users order by id desc;
    ```
17. видите ли вы новую запись и если да то почему?
    ```
    Нет, не вижу. Потому что уровень изоляции repeatable read.
    ```
18. завершить транзакцию в первом окне
    ```
    commit;
    ```
19. сделать запрос во выбор всех записей второй сессии
    ```
    select * from users order by id desc;
    ```
20. видите ли вы новую запись и если да то почему?
    ```
    Нет, не вижу. Потому что уровень изоляции repeatable read. 
    Изменения видны только после завершения транзакции во второй сессии.
    ```