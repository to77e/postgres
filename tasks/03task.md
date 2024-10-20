# Задание 3

1. Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1 млн строк.
    ```sql
    create table comments (
        id serial primary key,
        user_id int references users(id),
        comment text,
        created_at timestamp default now()
    );
    
    insert into comments (user_id, comment)
    select
        (1+(random() * 9999))::int as user_id,
        md5(random()::text) as comment
    from generate_series(1, 1000000);
    ```

2. Посмотреть размер файла с таблицей
    Найдем имя файла таблицы:
    ```sql
   select oid from pg_database where datname = current_database();
   select relfilenode from pg_class where relname = 'comments';
   ```
    Посмотрим размер файла:
    ```bash
    ls -lh /var/lib/postgresql/data/base/5/16403
   ```
    Результат:
    ```bash
    -rw-------    1 postgres postgres   80.5M Oct 19 16:48 /var/lib/postgresql/data/base/5/16403
    ```
3. 5 раз обновить все строчки и добавить к каждой строчке любой символ.
    ```sql
    update comments set comment = comment || 'a';
    update comments set comment = comment || 'b';
    update comments set comment = comment || 'c';
    update comments set comment = comment || 'd';
    update comments set comment = comment || 'e';
    ```
4. Посмотреть количество мертвых строчек в таблице и когда последний раз приходил
   автовакуум.
    ```sql
    select n_dead_tup, last_autovacuum from pg_stat_user_tables where relname = 'comments';
    ```
    Результат:
    ```
    n_dead_tup | last_autovacuum
    -----------+---------------------
    1001866    | <null>
    ```
5. Подождать некоторое время, проверяя, пришел ли автовакуум.
    ```sql
    select n_dead_tup, last_autovacuum from pg_stat_user_tables where relname = 'comments';
    ```
    Результат:
    ```
    n_dead_tup | last_autovacuum
    -----------+-----------------------------------
    0          | 2024-10-19 18:42:07.581276 +00:00
    ```
6. 5 раз обновить все строчки и добавить к каждой строчке любой символ.
    ```sql
    update comments set comment = comment || 'f';
    update comments set comment = comment || 'g';
    update comments set comment = comment || 'h';
    update comments set comment = comment || 'i';
    update comments set comment = comment || 'j';
    ```
7. Посмотреть размер файла с таблицей.
    ```bash
    ls -lh /var/lib/postgresql/data/base/5/16403
    ```
    Результат:
    ```bash
    -rw-------    1 postgres postgres  483.2M Oct 19 19:02 /var/lib/postgresql/data/base/5/16403
    ```
8. Отключить Автовакуум на конкретной таблице.
    ```sql
    alter table comments set (autovacuum_enabled = false);
    ```
9. 10 раз обновить все строчки и добавить к каждой строчке любой символ. Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице. Не забыть вывести номер шага цикла.
    ```sql
    do $$
    declare
        i int;
        random_char char;
        table_name text := 'comments';
    begin
        for i in 1..10 loop
            random_char := chr(97 + floor(random() * 26)::int); 
            execute format('update %I set comment = comment || %L', table_name, random_char);
            raise notice 'step %', i;
        end loop;
    end $$;
    ```
10. Посмотреть размер файла с таблицей.
    ```bash
    ls -lh /var/lib/postgresql/data/base/5/16403
    ```
    Результат:
    ```bash
    -rw-------    1 postgres postgres 1014.7M Oct 19 19:08 /var/lib/postgresql/data/base/5/16403
    ```
11. Объясните полученный результат.
    Размер файла с таблицей увеличивается из-за того, что при обновлении строки, PostgreSQL не удаляет старую строку, а добавляет новую. При этом, старая строка помечается как мертвая и не удаляется из файла. При этом, автовакуум удаляет мертвые строки. Если автовакуум отключен, то мертвые строки не удаляются и файл с таблицей увеличивается.

12. Не забудьте включить автовакуум.
    ```sql
    alter table comments set (autovacuum_enabled = true);
    ```
