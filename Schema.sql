-- Food Table
CREATE TABLE food (
    f_id CHAR(11) PRIMARY KEY,
    item VARCHAR(250) NOT NULL,
    veg_or_non_veg VARCHAR(10) CHECK (veg_or_non_veg IN ('Veg', 'Non-Veg')) NOT NULL
);

--Restaurant Table
CREATE TABLE restaurant (
    r_id SERIAL PRIMARY KEY,
    r_name VARCHAR(100) ,
    city VARCHAR(50) ,
    rating Numeric(10, 2),
    rating_count VARCHAR(50),
    costs NUMERIC(10, 2),
    cuisine VARCHAR(100) 
);

--Users Table 
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    u_name VARCHAR(100),
    email VARCHAR(100) UNIQUE ,
    u_password VARCHAR(255),
    age SMALLINT CHECK (age > 0),
    gender VARCHAR(6) CHECK (gender IN ('Male', 'Female', 'Other')),
    marital_status VARCHAR(50),
    occupation VARCHAR(30),
    monthly_income varchar(50),
    educational_qualifications VARCHAR(30),
    family_size SMALLINT
);

--Orders Table
CREATE TABLE orders (
    order_date DATE NOT NULL,
    sales_qty INT CHECK (sales_qty >= 0),
    sales_amount NUMERIC(10, 2) CHECK (sales_amount >= 0),
    currency VARCHAR(10) NOT NULL,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    r_id INT REFERENCES restaurant(r_id) ON DELETE CASCADE ON UPDATE CASCADE
);

--Menu Table
CREATE TABLE menu (
    menu_id CHAR(11),
    r_id INT REFERENCES restaurant(r_id) ON DELETE CASCADE ON UPDATE CASCADE,
    f_id CHAR(11) REFERENCES food(f_id) ON DELETE CASCADE ON UPDATE CASCADE,
    cuisine VARCHAR(100),
    price VARCHAR(100),
	PRIMARY KEY(menu_id, f_id)
);
