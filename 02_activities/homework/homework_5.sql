-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

-- Select vendor names, product names, and total revenue per product
SELECT 
    v.vendor_name, 
    p.product_name, 
    SUM(vi.original_price * 5 * customer_count.customer_total) AS total_revenue_per_product
FROM 
    vendor_inventory vi -- Contains product price and vendor-product relationship
JOIN 
    vendor v ON vi.vendor_id = v.vendor_id -- Link vendor inventory to vendor names
JOIN 
    product p ON vi.product_id = p.product_id -- Link vendor inventory to product names
CROSS JOIN 
    (SELECT COUNT(*) AS customer_total FROM customer) AS customer_count -- Count total customers
GROUP BY 
    v.vendor_name, p.product_name; -- Group by vendor and product to calculate total revenue

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

-- Create a new table for products sold by unit, adding a timestamp
CREATE TABLE product_units AS 
SELECT 
    *, 
    CURRENT_TIMESTAMP AS snapshot_timestamp -- Adds a timestamp column to track data entry time
FROM 
    product
WHERE 
    product_qty_type = 'unit'; -- Only include products sold in 'unit' quantity

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

-- Insert a new row (Apple Pie example) into product_units with a current timestamp
INSERT INTO product_units (product_id, product_name, product_size, product_category_id, product_qty_type, snapshot_timestamp)
VALUES 
    (7, 'Apple Pie', 'Large', 1, 'unit', CURRENT_TIMESTAMP); -- Add new product with timestamp

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

-- Delete older records for the newly inserted product (Apple Pie)
DELETE FROM product_units
WHERE product_id = 7
AND snapshot_timestamp < (SELECT MAX(snapshot_timestamp) FROM product_units WHERE product_id = 7); -- Keep the most recent record

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

-- Add a new column 'current_quantity' to the product_units table
ALTER TABLE product_units
ADD current_quantity INT;

-- Update 'current_quantity' with the most recent quantity from vendor_inventory
UPDATE product_units
SET current_quantity = (
    SELECT COALESCE(vi.quantity, 0) -- Get the most recent quantity from vendor_inventory, replace NULL with 0
    FROM vendor_inventory vi
    WHERE vi.product_id = product_units.product_id -- Match product IDs
    ORDER BY vi.market_date DESC -- Sort by date to get the latest entry
    LIMIT 1 -- Only take the most recent record
)
WHERE EXISTS (
    SELECT 1 FROM vendor_inventory vi WHERE vi.product_id = product_units.product_id -- Ensure matching products exist
);

