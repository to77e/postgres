# Задание 1

1. Развернуть ВМ (Linux) с PostgreSQL.  
   ```
   Развернул PostgreSQL 16.4 локально в Docker, docker-compose.yml в корне репозитория.
   ```
2. Залить Тайские [перевозки](https://github.com/aeuge/postgres16book/tree/main/database).  
   ```
   Залил данные в базу данных Тайские перевозки. Выбрал версию: Объем порядка 6 млн.строк (600МБ).
   ```
3. Посчитать количество поездок - select count(*) from book.tickets; 
   ```
   count
   -------
   5185505
   (1 row)
   ```