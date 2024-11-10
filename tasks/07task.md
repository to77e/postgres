# Задание 7

1. Создать таблицу с продажами:
    ```sql
    create table sales (
        id serial primary key,
        product_id int not null,
        customer_id int not null,
        amount numeric(10, 2) default 0,
        sale_date timestamp default now()
    );
    ```
    Заполнить таблицу данными:
    ```sql
    insert into sales (product_id, customer_id, amount, sale_date)
    select
        ceil(random() * 1000)::int as product_id,
        ceil(random() * 10000)::int as customer_id,
        ceil(random() * 100000) as amount,
        timestamp '2023-01-01' + random() * interval '1 year' AS sale_date
        from generate_series(1, 100000);
    ```
2. Реализовать функцию выбор трети года (1-4 месяц - первая треть, 5-8 - вторая и тд):
   а. через case:
   ```sql
   create or replace function get_third_of_year(date) returns int as $$
   begin
      return case
           when extract(month from $1) <= 4 then 1
           when extract(month from $1) <= 8 then 2
           else 3
      end;
   end;
   $$ language plpgsql;
   ```
   Проверим работу функции:
   ```sql
   select get_third_of_year('2023-01-01'::date);
   select get_third_of_year('2023-05-01'::date);
   select get_third_of_year('2023-10-01'::date);
   ```
   b. * (бонуса в виде зачета дз не будет) используя математическую операцию:
   ```sql
   create or replace function get_third_of_year_v2(date) returns int as $$
   begin
     return ceil(extract(month from $1) / 4);
   end;
   $$ language plpgsql;
   ```
   Проверим работу функции:
   ```sql
   select get_third_of_year_v2('2023-01-01'::date);
   select get_third_of_year_v2('2023-05-01'::date);
   select get_third_of_year_v2('2023-10-01'::date);
   ```
   ```sql
   create or replace function get_third_of_year_v3(date) returns int as $$
   begin
     return ceil(extract(month from $1) * 0.25);
   end;
   $$ language plpgsql;
   ```
   Проверим работу функции:
   ```sql
   select get_third_of_year_v3('2023-01-01'::date);
   select get_third_of_year_v3('2023-05-01'::date);
   select get_third_of_year_v3('2023-10-01'::date);
   ```
   Проверим скорость выполнения сложного запроса вариант 1:
   ```sql
   select get_third_of_year(sale_date::date), count(*) from sales group by 1;
   ```
   ```
   3 rows retrieved starting from 1 in 314 ms (execution: 293 ms, fetching: 21 ms)
   ```
   Проверим скорость выполнения сложного запроса вариант 2:
   ```sql
   select get_third_of_year_v2(sale_date::date), count(*) from sales group by 1;
   ```
   ```
   3 rows retrieved starting from 1 in 349 ms (execution: 336 ms, fetching: 13 ms)
   ```
    Проверим скорость выполнения сложного запроса вариант 3:
    ```sql
    select get_third_of_year_v3(sale_date::date), count(*) from sales group by 1;
    ```
    ```
    3 rows retrieved starting from 1 in 431 ms (execution: 418 ms, fetching: 13 ms)
    ```
   Вариант с case работает быстрее, чем остальные варианты, поэтому далее будет использовать вариант с case.  
   с. предусмотреть NULL на входе:
   ```sql
   create or replace function get_third_of_year(date) returns int as $$
   begin
      if $1 is null then
        return null;
      end if;
      return case
         when extract(month from $1) <= 4 then 1
         when extract(month from $1) <= 8 then 2
         else 3
      end;
   end;
   $$ language plpgsql;
   ```
3. Вызвать эту функцию в SELECT из таблицы с продажами, уведиться, что всё отработало:
    ```sql
    select sale_date, get_third_of_year(sale_date::date) from sales limit 10;
    ```
   ```
   2023-06-05 17:07:34.340499,2
   2023-06-12 07:58:31.349086,2
   2023-12-12 21:08:03.608309,3
   2023-11-03 22:41:02.685690,3
   2023-07-01 05:43:49.187101,2
   2023-11-13 08:15:59.550943,3
   2023-11-15 01:18:39.227297,3
   2023-01-13 01:18:58.745236,1
   2023-07-31 09:15:43.276506,2
   2023-11-21 13:18:50.363769,3
   ``` 
   