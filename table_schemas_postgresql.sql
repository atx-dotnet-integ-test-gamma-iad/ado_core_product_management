-- PostgreSQL Table Schemas for Equivalency Validation
-- These schemas represent the converted PostgreSQL database structure
-- Schema: productmanagement_dbo (as converted by DMS tool)

-- Products Table (PostgreSQL)
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    categoryid INTEGER,
    supplierid INTEGER,
    sku VARCHAR(50),
    weight NUMERIC(10, 2),
    dimensions VARCHAR(50),
    isdiscontinued BOOLEAN NOT NULL DEFAULT false,
    reorderlevel INTEGER NOT NULL DEFAULT 10,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

-- ProductHistory Table (PostgreSQL)
CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice NUMERIC(18, 2),
    newprice NUMERIC(18, 2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedby VARCHAR(100)
);

-- ProductStats Table (PostgreSQL)
CREATE TABLE productmanagement_dbo.productstats (
    statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
