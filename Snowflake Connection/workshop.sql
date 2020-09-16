USE ROLE SYSADMIN;

CREATE or REPLACE WAREHOUSE LOAD_WH
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 30
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'This is my DATA LOADING warehouse';
    
USE WAREHOUSE LOAD_WH;

CREATE or REPLACE DATABASE RETAIL_DEMO;

CREATE or REPLACE SCHEMA STAGING;

CREATE or REPLACE STAGE RETAIL_DEMO.STAGING.RETAIL_DEMO_STAGE
    URL = 's3://snowflake-thoughtspot-vhol/data/'
;

CREATE or REPLACE SCHEMA PROD;

create or replace TABLE ORDERS (
INVOICENO VARCHAR(16777216),
STOCKCODE VARCHAR(16777216),
DESCRIPTION VARCHAR(16777216),
QUANTITY NUMBER(38,0),
INVOICEDATE DATE,
UNITPRICE NUMBER(38,0),
CUSTOMERID NUMBER(38,0),
COUNTRY VARCHAR(16777216)
);

COPY INTO ORDERS
FROM @RETAIL_DEMO.STAGING.RETAIL_DEMO_STAGE/orders
FILE_FORMAT = (DATE_FORMAT = "MM/DD/YYYY HH24:MI");

create or replace TABLE WEBLOGS (
CUSTID INT,
PAGE VARCHAR(16777216),
PRODUCTID VARCHAR(16777216),
VISITDATE DATE,
VISITS NUMBER(38,0),
PAGEVIEWS NUMBER(38,0),
IP_ADDRESS VARCHAR(16777216),
PROMOID VARCHAR(16777216),
ONLINEPURCHASE VARCHAR(3)
);

copy into WEBLOGS
  from (select t.$1::INT,
               t.$2,
               t.$3,
               t.$4,
               t.$5,
               t.$6,
               t.$7,
               t.$8,
               t.$9
  from @RETAIL_DEMO.STAGING.RETAIL_DEMO_STAGE/weblogs t
  );
  
CREATE OR REPLACE TABLE DATE_DIM AS
SELECT DISTINCT INVOICEDATE AS DATE FROM ORDERS;
ALTER TABLE DATE_DIM ADD PRIMARY KEY (DATE);


CREATE OR REPLACE TABLE CUSTOMER_DIM AS
SELECT DISTINCT CUSTOMERID FROM ORDERS;
ALTER TABLE CUSTOMER_DIM ADD PRIMARY KEY (CUSTOMERID);

ALTER TABLE ORDERS ADD CONSTRAINT C_ORDERS_DATE FOREIGN KEY (INVOICEDATE) REFERENCES DATE_DIM (DATE);
ALTER TABLE ORDERS ADD CONSTRAINT C_ORDERS_CUST FOREIGN KEY (CUSTOMERID) REFERENCES CUSTOMER_DIM (CUSTOMERID);
ALTER TABLE WEBLOGS ADD CONSTRAINT C_WEBLOGS_DATE FOREIGN KEY (VISITDATE) REFERENCES DATE_DIM (DATE);
ALTER TABLE WEBLOGS ADD CONSTRAINT C_WEBLOGS_CUST FOREIGN KEY (CUSTID) REFERENCES CUSTOMER_DIM (CUSTOMERID);

CREATE or REPLACE WAREHOUSE MARKETING_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 600
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'This is my MARKETING warehouse';
  
USE ROLE ACCOUNTADMIN;
create role if not exists ANALYSTS comment='Read-only access';
CREATE USER tsuser password = 'embrace123' must_change_password = FALSE default_role = ANALYSTS;
GRANT ROLE ANALYSTS to USER tsuser;
GRANT usage, monitor on database RETAIL_DEMO to role ANALYSTS;
GRANT usage, monitor on all schemas in database RETAIL_DEMO to role ANALYSTS;
GRANT select on all tables in database RETAIL_DEMO to role ANALYSTS;
GRANT monitor,operate,usage on warehouse MARKETING_WH to role ANALYSTS;