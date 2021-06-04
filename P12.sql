create type return_before_after as
(
    before integer,
    after  integer
);

alter type return_before_after owner to postgres;

create table categories
(
    category     serial      not null,
    categoryname varchar(50) not null
);

alter table categories
    owner to postgres;

create table customers
(
    customerid           serial      not null
        constraint customers_pkey
            primary key,
    firstname            varchar(50) not null,
    lastname             varchar(50) not null,
    address1             varchar(50) not null,
    address2             varchar(50),
    city                 varchar(50) not null,
    state                varchar(50),
    zip                  integer,
    country              varchar(50) not null,
    region               smallint    not null,
    email                varchar(50),
    phone                varchar(50),
    creditcardtype       integer     not null,
    creditcard           varchar(50) not null,
    creditcardexpiration varchar(50) not null,
    username             varchar(50) not null,
    password             varchar(50) not null,
    age                  smallint,
    income               integer,
    gender               varchar(1)
);

alter table customers
    owner to postgres;

create table cust_hist
(
    customerid integer not null
        constraint fk_cust_hist_customerid
            references customers
            on delete cascade,
    orderid    integer not null,
    prod_id    integer not null
);

alter table cust_hist
    owner to postgres;

create index ix_cust_hist_customerid
    on cust_hist (customerid);

create unique index ix_cust_username
    on customers (username);

create table inventory
(
    prod_id       integer not null
        constraint inventory_pkey
            primary key,
    quan_in_stock integer not null,
    sales         integer not null
);

alter table inventory
    owner to postgres;

create table orders
(
    orderid     serial         not null
        constraint orders_pkey
            primary key,
    orderdate   date           not null,
    customerid  integer
        constraint fk_customerid
            references customers
            on delete set null,
    netamount   numeric(12, 2) not null,
    tax         numeric(12, 2) not null,
    totalamount numeric(12, 2) not null
);

alter table orders
    owner to postgres;

create table orderlines
(
    orderlineid integer  not null,
    orderid     integer  not null
        constraint fk_orderid
            references orders
            on delete cascade,
    prod_id     integer  not null,
    quantity    smallint not null,
    orderdate   date     not null
);

alter table orderlines
    owner to postgres;

create unique index ix_orderlines_orderid
    on orderlines (orderid, orderlineid);

create index ix_order_custid
    on orders (customerid);

create table products
(
    prod_id        serial         not null
        constraint products_pkey
            primary key,
    category       integer        not null,
    title          varchar(50)    not null,
    actor          varchar(50)    not null,
    price          numeric(12, 2) not null,
    special        smallint,
    common_prod_id integer        not null
);

alter table products
    owner to postgres;

create index ix_prod_category
    on products (category);

create index ix_prod_special
    on products (special);

create table reorder
(
    prod_id        integer not null,
    date_low       date    not null,
    quan_low       integer not null,
    date_reordered date,
    quan_reordered integer,
    date_expected  date
);

alter table reorder
    owner to postgres;

create function new_customer(firstname_in character varying, lastname_in character varying,
                             address1_in character varying, address2_in character varying, city_in character varying,
                             state_in character varying, zip_in integer, country_in character varying,
                             region_in integer, email_in character varying, phone_in character varying,
                             creditcardtype_in integer, creditcard_in character varying,
                             creditcardexpiration_in character varying, username_in character varying,
                             password_in character varying, age_in integer, income_in integer,
                             gender_in character varying, OUT customerid_out integer) returns integer
    language plpgsql
as
$$
DECLARE
    rows_returned INT;
BEGIN
    SELECT COUNT(*) INTO rows_returned FROM CUSTOMERS WHERE USERNAME = username_in;
    IF rows_returned = 0 THEN
        INSERT INTO CUSTOMERS
        (FIRSTNAME,
         LASTNAME,
         EMAIL,
         PHONE,
         USERNAME,
         PASSWORD,
         ADDRESS1,
         ADDRESS2,
         CITY,
         STATE,
         ZIP,
         COUNTRY,
         REGION,
         CREDITCARDTYPE,
         CREDITCARD,
         CREDITCARDEXPIRATION,
         AGE,
         INCOME,
         GENDER)
        VALUES ((
                 firstname_in,
                 lastname_in,
                 email_in,
                 phone_in,
                 username_in,
                 password_in,
                 address1_in,
                 address2_in,
                 city_in,
                 state_in,
                 zip_in,
                 country_in,
                 region_in,
                 creditcardtype_in,
                 creditcard_in,
                 creditcardexpiration_in,
                 age_in,
                 income_in,
                 gender_in
            );
        select currval(pg_get_serial_sequence('customers', 'customerid')) into customerid_out;
    ELSE
        customerid_out := 0;
    END IF;
END
$$;

alter function new_customer(varchar, varchar, varchar, varchar, varchar, varchar, integer, varchar, integer, varchar, varchar, integer, varchar, varchar, varchar, varchar, integer, integer, varchar, out integer) owner to postgres;

create function del_under18() returns SETOF integer
    language sql
as
$$
delete
from dell.public.customers
where age < 18
returning customerid
$$;

alter function del_under18() owner to postgres;

create function show_name_sql(id integer, OUT first character varying, OUT last character varying) returns record
    language sql
as
$$
SELECT firstname, lastname
FROM customers
WHERE customerid = id;
$$;

alter function show_name_sql(integer, out varchar, out varchar) owner to postgres;

create function show_name_plpgsql(id integer, OUT first character varying, OUT last character varying) returns record
    language plpgsql
as
$$
BEGIN
    SELECT firstname, lastname
    INTO first, last
    FROM customers
    WHERE customerid = id;
END;
$$;

alter function show_name_plpgsql(integer, out varchar, out varchar) owner to postgres;

create function insert_category1_sql(pcategory integer, pname character varying) returns void
    language sql
as
$$
INSERT INTO categories
VALUES (pcategory, pname);
$$;

alter function insert_category1_sql(integer, varchar) owner to postgres;

create function insert_category2_sql(integer, character varying) returns void
    language sql
as
$$
INSERT INTO categories
VALUES ($1, $2);
$$;

alter function insert_category2_sql(integer, varchar) owner to postgres;

create function del_under18_2() returns return_before_after
    language plpgsql
as
$$
DECLARE
    before integer;
    after  integer;
BEGIN
    SELECT count(*) INTO before FROM customers;
    DELETE FROM customers WHERE age < 18;
    SELECT count(*) INTO after FROM customers;
    RETURN (before, after);
END;
$$;

alter function del_under18_2() owner to postgres;

create function show_cust_sql(id integer) returns customers
    language sql
as
$$
SELECT *
FROM customers
WHERE customerid = id;
$$;

alter function show_cust_sql(integer) owner to postgres;

create function show_cust_plpgsql(id integer) returns customers
    language plpgsql
as
$$
DECLARE
    cust customers;
BEGIN
    SELECT * INTO cust FROM customers WHERE customerid = id;
    RETURN cust;
END;
$$;

alter function show_cust_plpgsql(integer) owner to postgres;

create function show_prod_cat_sql(catid integer) returns SETOF products
    language sql
as
$$
SELECT *
FROM products
WHERE category = catid;
$$;

alter function show_prod_cat_sql(integer) owner to postgres;

create function insert_category3_sql(category integer, categoryname character varying) returns void
    language sql
as
$$
INSERT INTO categories
VALUES (insert_category3_sql.category,
        insert_category3_sql.categoryname);
$$;

alter function insert_category3_sql(integer, varchar) owner to postgres;

create function insert_category4_sql(pcategory categories) returns void
    language sql
as
$$
INSERT INTO categories
VALUES (pcategory.category,
        pcategory.categoryname);
$$;

alter function insert_category4_sql(categories) owner to postgres;

create function increase_price_sql(prod products) returns numeric
    language sql
as
$$
UPDATE products
SET price = price + 0.05 * price
WHERE prod.prod_id = prod_id
RETURNING price;
$$;

alter function increase_price_sql(products) owner to postgres;

create function increase_price_plpgsql(prod products) returns numeric
    language plpgsql
as
$$
BEGIN
    UPDATE products
    SET price = price + 0.05 * price
    WHERE prod.prod_id = prod_id;
    RETURN (SELECT price
            FROM products
            WHERE prod.prod_id = prod_id);
END;
$$;

alter function increase_price_plpgsql(products) owner to postgres;

create function show_prod_cat_plpgsql(catid integer) returns SETOF products
    language plpgsql
as
$$
BEGIN
    RETURN QUERY
        SELECT * FROM products WHERE category = catid;
END;
$$;

alter function show_prod_cat_plpgsql(integer) owner to postgres;

create function show_prod_sql(INOUT prod_id integer, OUT title character varying, OUT price numeric) returns record
    language plpgsql
as
$$
BEGIN
    SELECT products.title
    INTO title
    FROM products
    WHERE products.prod_id = $1;
    SELECT products.price
    INTO price
    FROM products
    WHERE products.prod_id = $1;
END;
$$;

alter function show_prod_sql(inout integer, out varchar, out numeric) owner to postgres;

create function avg_price_sql() returns numeric
    language sql
as
$$
SELECT AVG(price)
FROM products;
$$;

alter function avg_price_sql() owner to postgres;

create function avg_price_plpgsql() returns numeric
    language plpgsql
as
$$
BEGIN
    RETURN (SELECT AVG(price)
            FROM products);
END;
$$;

alter function avg_price_plpgsql() owner to postgres;

create function avg_price_noavg() returns numeric
    language plpgsql
as
$$
DECLARE
    aveg products.price%type;
BEGIN
    SELECT SUM(price) / COUNT(*)
    INTO aveg
    FROM products;
    RETURN aveg;
END;
$$;

alter function avg_price_noavg() owner to postgres;

create function show_prod_cat2_plpgsql(catid integer)
    returns TABLE
            (
                prod_id        integer,
                category       integer,
                title          character varying,
                actor          character varying,
                price          numeric,
                special        smallint,
                common_prod_id integer
            )
    language plpgsql
as
$$
BEGIN
    RETURN QUERY (SELECT *
                  FROM products
                  WHERE products.category = $1);
END;
$$;

alter function show_prod_cat2_plpgsql(integer) owner to postgres;


