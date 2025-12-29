USE [Swiggy Database]
SELECT * FROM Swiggy_data


--- Data Validation & Cleaning
--- Null check
SELECT
     SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
     SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
     SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
     SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
     SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
     SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
     SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dish,
     SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
     SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
     SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM swiggy_data;



---Blank or Empty Strings
SELECT*
FROM swiggy_data
WHERE
State = '' OR city = '' OR Restaurant_Name = '' OR Location = '' OR Category = '' OR Dish_Name = ''

---Duplicate Detection
SELECT
State, City, order_date, restaurant_name,location, category, dish_name, price_INR, rating, rating_count, count(*) as CNT
FROM swiggy_data
GROUP BY
State, City, order_date, restaurant_name,location, category, dish_name, price_INR, rating, rating_count
Having count(*) > 1

---Delete Duplication
WITH CTE AS (
SELECT *, ROW_NUMBER() Over(
   PARTITION BY State, City, order_date, restaurant_name,location, category, dish_name, price_INR, rating, rating_count
ORDER BY (SELECT NULL)
) AS rn
FROM swiggy_data
)
DELETE FROM CTE WHERE rn>1

---CREATING SCHEMA
--DIMENSION TABLES
--DATE TABLE
CREATE TABLE dim_date (
  date_id INT IDENTITY(1,1) PRIMARY KEY,
  FULL_DATE DATE,
  YEAR INT, 
  MONTH INT,
  Month_Name varchar(20),
  Quarter INT,
  Day INT,
  Week INT
  )

  SELECT * FROM dim_data

  ---dim_location
  CREATE TABLE dim_location (
  location_id INT IDENTITY(1,1) PRIMARY KEY,
  State VARCHAR(100),
  City VARCHAR(100),
  Location VARCHAR(200)
  );

  --dim restaurant
CREATE TABLE dim_restaurant (
  restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
  Restaurant_Name VARCHAR(200)
  );


--dim-category
CREATE TABLE dim_category (
 category_id INT IDENTITY(1,1) PRIMARY KEY,
 category VARCHAR(200)
  );

  --dim-dish
CREATE TABLE dim_dish(
 dish_id INT IDENTITY(1,1) PRIMARY KEY,
 dish_Name VARCHAR(200)
  );

SELECT * FROM swiggy_data

---FACT TABLE
CREATE TABLE fact_swiggy_orders (
  order_id INT IDENTITY(1,1) PRIMARY KEY,

  date_id INT,
  Price_INR DECIMAL(10,2),
  Rating DECIMAL(4,2),
  Rating_Count INT,

  location_id INT,
  restaurant_id INT,
  category_id INT,
  dish_id INT,

  FOREIGN KEY (date_id) REFERENCES dim_data(date_id),
  FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
  FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
  FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
  FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
  );

  
SELECT * FROM fact_swiggy_orders

--INSERT DATA IN TABLES
--dim_date
INSERT INTO dim_date (Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
  Order_Date,
  YEAR(Order_Date),
  MONTH(Order_Date),
  DATENAME(MONTH,Order_Date),
  DATEPART(QUARTER, Order_Date),
  DAY(Order_Date),
  DATEPART(WEEK, Order_Date)
  FROM swiggy_data
  WHERE Order_Date IS NOT NULL;

  SELECT * FROM dim_data

  ---dim_location
  INSERT INTO dim_location (State, City, Location)
  SELECT DISTINCT
  State,
  City,
  Location
  FROM swiggy_data;


  ---dim_restaurant
  INSERT INTO dim_restaurant (Restaurant_Name)
  SELECT DISTINCT
  Restaurant_Name
  FROM swiggy_data;

  ---dim_category
  INSERT INTO dim_category (category)
 SELECT DISTINCT
  Category
  FROM swiggy_data;

  ---dim_dish
  INSERT INTO dim_dish (Dish_Name)
  SELECT DISTINCT
  Dish_Name
  FROM swiggy_data

  --fact _table
  INSERT INTO fact_swiggy_orders
  (

    date_id,
    Price_INR,
    Rating,
    Rating_Count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
    )

    SELECT
      dd.date.id,
      s.Price_INR,
      s.Rating,
      s.Rating_Count,

      dl.location.id,
      dr.restaurant_id,
      dc.category_id,
      dsh.dish_id
      FROM swiggy_data s

      JOIN dim_data dd
      ON dd.Full_Date = s.Order_Date

     JOIN dim_location dl
      ON dl.State = s.State
      AND dl.City= s.City
      AND dl.location = s.Location

      JOIN dim_restaurant dr
      ON dr.Restaurant_Name = s.Restaurant_Name
      
      JOIN dim_category dc
      ON dc.Category = s.Category

      JOIN dim_dish dsh
      ON dsh.Dish_Name = s.Dish_Name;

      USE [Swiggy Database]
SELECT * FROM Swiggy_data

SELECT * FROM fact_swiggy_orders

      SELECT * FROM fact_swiggy_orders f
      JOIN dim_date d  ON f.date_id = d.date_id
      JOIN dim_location l ON f .location_id = l.location_id
      JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
      JOIN dim_category c ON f.category_id = c.category_id
      JOIN dim_dish di ON f.dish_id = di.dish_id;


---KPI'S
---TOTAL ORDERS

SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders

--TOTAL REVENUE (INR MILLION)
  SELECT
     FORMAT (SUM(CONVERT(FLOAT, price_INR))/1000000, 'N2') + 'INR Million'
    AS Total_Revenue
FROM fact_swiggy_orders

---Average Dish Price
SELECT 
FORMAT (AVG(CONVERT(FLOAT, price_INR))/1000000, 'N2') + 'INR'
AS Total_Revenue
FROM fact_swiggy_orders

---Average Rating
SELECT 
AVG(Rating) AS Avg_Rating
FROM fact_swiggy_orders

---Deep Dive business Analysis

--Monthly Order Trends
SELECT
d.year,
d.month,
d.month_name
count() AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d ON  f.date_id = d.date_id
GROUP BY d.year,
d.month,
d.month_name
ORDER BY count(*) DESC


--Quaterly Trend
SELECT
d.year,
d.quarter,
count(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d
ON  f.date_id = d.date_id
GROUP BY d.year,
d.quarter
d.month_name
ORDER BY count(*) DESC

--Yearly Trend
SELECT
d.year,
count(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d
ON  f.date_id = d.date_id
GROUP BY d.year
ORDER BY count(*) DESC

Orders by Day of Week (mon -sun)

SELECT
  DATENAME(WEEKDAY, d.full_date) AS day_name,
  COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date ON f.date_id = d.date_id
GROUP BY DATENAME(WEEKDAY, d.full_date), DATEPART(WEEKDAY, d.full_date)
ORDER BY DATEPART(WEEKDAY, d.full_date);

--TOP 10 CITIES BY ORDER VOLUME

SELECT TOP 10
l.city,
COUNT(*) AS Total Orders FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.city
ORDER BY COUNT(*) DESC


1. city,
SUM(f.price_INR)
AS TotaL_Revenue
FROM fact_swiggy_orders f
JOIN dim_location 1
ON 1.location_id = f.location_id
GROUP BY 1. city
ORDER BY SUM(f.price_INR) DESC

--REVENUE CONTRIBUTION BY STATES

SELECT
1.state,
SUM(f.price_INR) AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.state
ORDER BY SUM(f.price_INR) DESC

---TOP 10 restaurants by orders 

SELECT TOP 10
r.restaurant_name,
SUM(f.price_INR) AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_restaurant r
ON r.restaurant_id = f.restaurant_id
GROUP BY r.restaurant_name
ORDER BY SUM(f.price_INR) DESC

---Top Categories by Order Volume

SELECT
  c.category,
  COUNT(*) AS total_orders
  FROM fact_swiggy_orders f
  JOIN dim_category c ON f.category_id = c.category_id
  GROUP BY c.category
  ORDER BY total_orders DESC;

  ---MOST ORDERED DISHES

  SELECT 
   d.dish_name,
   COUNT(*) AS order_count
   FROM fact_swiggy_orders f
   JOIN dim_dish d ON f.dish_id = d.dish_id
  GROUP BY d.dish_name
  ORDER BY order_count DESC;

  ---CUISINE PERFORMANCE (ORDERS + AVG RATING)
SELECT 
  c.category,
  COUNT(*) AS total_orders,
  AVG(CONVERT(FLOAT, f.rating)) AS avg_rating
  FROM fact_swiggy_orders f
  JOIN dim_category c ON f.category_id = c.category_id
  GROUP BY c.category
  ORDER BY total_orders DESC;


 ---Total orders by price range
    SELECT
      CASE
        WHEN CONVERT(FLOAT,price_inr) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT,price_inr) BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN CONVERT(FLOAT,price_inr) BETWEEN 200 AND 299  THEN '200 - 299'
        WHEN CONVERT(FLOAT,price_inr) BETWEEN 300 AND 499 THEN '300 - 499'
 ELSE '500+'
 END AS price_range,
 COUNT(*) AS total_orders
 FROM fact_swiggy_orders
 GROUP BY
  CASE
  WHEN CONVERT(FLOAT, price_inr)<100 THEN 'Under 100'
  WHEN CONVERT(FLOAT,price_inr) BETWEEN 100 AND 199 THEN '100 - 199'
         WHEN CONVERT(FLOAT,price_inr) BETWEEN 200 AND 299  THEN '200 - 299'
         WHEN CONVERT(FLOAT,price_inr) BETWEEN 300 AND 499 THEN '300 - 499'
 ELSE '500+'
 END
 ORDER BY total_orders DESC;

 ---Rating count distribution (1-5)
 SELECT
   rating,
   COUNT(*) AS rating_count
   FROM fact_swiggy_orders
   GROUP BY rating
   ORDER BY COUNT(*) DESC;





