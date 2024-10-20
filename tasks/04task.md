# Задание 4

1. Создать таблицу accounts(id integer, amount numeric).
    ```sql
    create table accounts (
        id serial primary key,
        amount numeric
    );
    ```
2. Добавить несколько записей.
    ```sql
    insert into accounts (amount) values (100), (200), (300), (400), (500), (600), (700), (800), (900), (1000);
    ```
3. Подключившись через 2 терминала добиться ситуации взаимоблокировки (deadlock).
    ```sql
    -- Terminal 1
    begin;
    update accounts set amount = amount - 100 where id = 1;
    -- Terminal 2
    begin;
    update accounts set amount = amount - 100 where id = 2;
    -- Terminal 1
    update accounts set amount = amount + 100 where id = 2;
    -- Terminal 2
    update accounts set amount = amount + 100 where id = 1;
    ```
   Результат: 
   ```
   ERROR:  deadlock detected
   DETAIL:  Process 7484 waits for ShareLock on transaction 788; blocked by process 7470.
   Process 7470 waits for ShareLock on transaction 789; blocked by process 7484.
   HINT:  See server log for query details.
   CONTEXT:  while updating tuple (0,1) in relation "accounts"
   ```
4. Посмотреть логи и убедиться, что информация о дедлоке туда попала.
   ```bash
   docker-compose -f docker-compose.yaml logs -f | grep deadlock -A 10
   ```
   Результат:
   ```
   postgres  | 2024-10-19 20:37:02.129 UTC [7484] ERROR:  deadlock detected
   postgres  | 2024-10-19 20:37:02.129 UTC [7484] DETAIL:  Process 7484 waits for ShareLock on transaction 788; blocked by process 7470.
   postgres  |     Process 7470 waits for ShareLock on transaction 789; blocked by process 7484.
   postgres  |     Process 7484: update accounts set amount = amount + 100 where id = 1;
   postgres  |     Process 7470: update accounts set amount = amount + 100 where id = 2;
   postgres  | 2024-10-19 20:37:02.129 UTC [7484] HINT:  See server log for query details.
   postgres  | 2024-10-19 20:37:02.129 UTC [7484] CONTEXT:  while updating tuple (0,1) in relation "accounts"
   postgres  | 2024-10-19 20:37:02.129 UTC [7484] STATEMENT:  update accounts set amount = amount + 100 where id = 1;
   ```