SELECT current_database();
CREATE TABLE banking_customers(
customer_id VARCHAR(20) PRIMARY KEY,
customer_name VARCHAR(50),
gender VARCHAR(20),
age INT,
city VARCHAR(50),
occupation VARCHAR(100),
customer_segment VARCHAR(50),
joining_date DATE
);

SELECT COUNT(*) AS total_customers
FROM banking_customers;

CREATE TABLE banking_accounts(
account_id VARCHAR(20) PRIMARY KEY,
customer_id VARCHAR(20),
account_type VARCHAR(30),
branch VARCHAR(100),
account_open_date DATE,
balance NUMERIC(15,2),
currency VARCHAR(10),
account_status VARCHAR(20)
);

SELECT COUNT(*) AS total_accounts
FROM banking_accounts;

SELECT *
FROM banking_accounts
LIMIT 5;

CREATE TABLE banking_transactins (
transaction_id VARCHAR(20) PRIMARY KEY,
account_id VARCHAR(20),
customer_id VARCHAR(20),
transaction_date DATE,
transaction_type VARCHAR(30),
amount NUMERIC(15,2),
payment_mode VARCHAR(30),
transaction_status VARCHAR(30)
);
ALTER TABLE banking_transactins
RENAME TO banking_transactions;
---------------------------------------------------------------------------------------------------------------
--TRANSACTION ID CHECK
SELECT COUNT(*) total_records,
COUNT(transaction_id) AS non_null_transaction_ids,
COUNT(DISTINCT transaction_id) AS unique_transaction_ids
FROM banking_transactions;

----------------------------------------------------------------------------------------------------------------
--Validate Account IDS
--Purpose: Check whether every transactions is linked to a valid account in the Accounts table
--Expected result 0 
SELECT COUNT(*) AS invalid_account_ids
FROM banking_transactions t
LEFT JOIN banking_accounts a
ON t.account_id = a.account_id
WHERE a.account_id IS NULL; 

------------------------------------------------------------------------------------------------------------------
-- Validate Customer IDS
--Purpose : Check whether every tarnactions is linked to a valid customer in the customer table.
-- Expected result: 0
SELECT COUNT(*) AS invalid_customer_ids
FROM banking_transactions t
LEFT JOIN banking_customers c
ON t.customer_id= c.customer_id
WHERE c.customer_id IS NULL;
-------------------------------------------------------------------------------------------------------------------
--Validate Transactions Dates
--Purpose check for missing transaction dates. transaction date is required for time based analysis
--Expected result: 0 missing dates
SELECT COUNT(*) AS missing_transaction_dates
FROM banking_transactions
WHERE transaction_date IS NULL;

--------------------------------------------------------------------------------------------------------------------
--Validate transaction amounts 
--check for null, zero , or negative transactions amounts
SELECT 
      COUNT(*) AS total_transactions,
	  COUNT(amount) AS non_null_amounts,
	  COUNT(*) - COUNT(amount) AS null_amounts,
	  COUNT(*) FILTER (WHERE amount = 0) AS  zero_amounts,
	  COUNT(*) FILTER (WHERE amount < 0) AS negative_amounts
FROM banking_transactions;

-------------------------------------------------------------------------------------------------------------------------
--Analyze transactions amount range
--check minimum , maximum and average transaction amount
SELECT 
      MIN(amount) AS minimum_amount,
	  MAX(amount) AS maximum_amount,
	  ROUND(AVG(amount),2) AS avg_amount
FROM banking_transactions;

---------------------------------------------------------------------------------------------------------------
--Validate decimal precision of transaction amounts 
--check whether amounts contain more then 2 decimal palces 
SELECT 
      COUNT(*) AS transactions_with_extra_decimals
	  FROM banking_transactions
	  WHERE amount<>ROUND(amount,2);

-----------------------------------------------------------------------------------------------------------------
--Verify the data type thr transaction amount column 
--Amount should be stored as numeric/ decimal type for financial data 

SELECT 
      column_name,
	  data_type,
	  numeric_precision,
	  numeric_scale
FROM information_schema.columns
WHERE table_name='banking_transactions'
      AND column_name='amount';

--------------------------------------------------------------------------------------------------------------------------
--Final validation summary for banking transactions
--confirms record count,key uniqueness and missing values 
SELECT 
      COUNT(*) AS total_transactions,
	  COUNT(DISTINCT transaction_id) AS unique_transaction_ids,
	  COUNT(DISTINCT account_id) AS unique_accounts,
	  COUNT(DISTINCT customer_id) AS unique_customers,
	  COUNT(transaction_date) AS non_null_transaction_dates,
	  COUNT(amount) AS non_null_amounts
FROM banking_transactions;

----------------------------------------------------------------------------------------------------------------------------
-- Create Loans table for Banking Data analyst Project
-- Stores loan details linked to customers 
CREATE TABLE banking_loans(
loan_id VARCHAR(20) PRIMARY KEY,
customer_id VARCHAR(20),
loan_type VARCHAR(20),
loan_amount NUMERIC(15,2),
interest_rate NUMERIC(5,2),
loan_tenure_years INTEGER,
loan_status VARCHAR(20),
loan_start_date DATE
);

--Verify total loan record after CSV import
SELECT COUNT(*) AS total_loans
FROM banking_loans;

---------------------------------------------------------------------------------------------------------------
--Validate loan IDs
--Each loan should have a unique and non-null loan_id
SELECT 
      COUNT(*) AS total_loans,
	  COUNT(loan_id) AS non_null_loan_ids,
	  COUNT(DISTINCT loan_id) AS unique_loan_ids
FROM banking_loans;

--------------------------------------------------------------------------------------------------------------
--Valiadte customer references in loans table 
--Every loan should be linked to a valid customer 
SELECT 
      COUNT(*) AS total_loans,
	  COUNT(customer_id) AS non_null_customer_ids,
	  COUNT(*) - COUNT(customer_id) AS null_customer_ids
FROM banking_loans;

--------------------------------------------------------------------------------------------------------------------
-- Validate customer references against customer table 
-- Identify loans linked to non- existing  customers 
SELECT 
      COUNT(*) AS invalid_customer_references
	  FROM banking_loans l
	  LEFT JOIN banking_customers c
	  ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

----------------------------------------------------------------------------------------------------------------------
--Validate loan amounts
-- Loan amounts should be present and greater than zero 
SELECT 
      COUNT(*) AS total_loans,
	  COUNT(loan_amount) AS non_null_loan_amounts,
	  COUNT(*) - COUNT(loan_amount) AS null_loan_amounts,
	  COUNT(*) FILTER(WHERE loan_amount=0) AS zero_loan_amounts,
	  COUNT(*) FILTER(WHERE loan_amount<0) AS negative_loan_amounts
	  FROM banking_loans;

---------------------------------------------------------------------------------------------------------------------
-- Validate loan interest rates 
-- Interest rates should be present and non-negative
SELECT 
      COUNT(*) AS total_loans,
	  COUNT(interest_rate) AS non_null_interest_rates,
	  COUNT(*) - COUNT(interest_rate) AS null_interest_rates,
	  COUNT(*) FILTER(WHERE interest_rate=0) AS zero_interest_rates,
	  COUNT(*) FILTER(WHERE interest_rate<0) AS negative_interest_rates
FROM banking_loans;

---------------------------------------------------------------------------------------------------------------------------
--Validate loan tenure
SELECT
COUNT (*) AS total_records,
COUNT(loan_tenure_years) AS non_null_tenure,
COUNT(*) - COUNT(loan_tenure_years) AS null_tenure,
MIN(loan_tenure_years) AS minimum_tenure,
MAX(loan_tenure_years) AS maximum_tenure
FROM banking_loans;

----------------------------------------------------------------------------------------------------------------------
-- Validate invalid loan tenure values
SELECT 
      COUNT(*) AS invalid_tenure_records
FROM banking_loans
WHERE loan_tenure_years <=0;

-----------------------------------------------------------------------------------------------------------------------
-- Validate loan status values to identify missing or unexpected categories in the loan data.
SELECT 
      loan_status,
	  COUNT(*) AS record_count
FROM banking_loans
GROUP BY loan_status
ORDER BY loan_status;

----------------------------------------------------------------------------------------------------------------------
-- Check for missing loan status values
SELECT 
      COUNT(*) AS null_loan_status
FROM banking_loans
WHERE loan_status IS NULL;

--------------------------------------------------------------------------------------------------------------------------
-- check for missing loan start dates 
SELECT 
      COUNT(*) AS null_loan_start_date
FROM banking_loans
WHERE loan_start_date IS NULL;

--------------------------------------------------------------------------------------------------------------------------------
--Check for invalid future loan start dates 
SELECT 
      COUNT(*) AS future_start_dates
FROM banking_loans
WHERE loan_start_date > CURRENT_DATE;

--------------------------------------------------------------------------------------------------------------------------------
--Check for duplicate loan IDs
--Each loan_id uniquely identify one loan record
SELECT 
      loan_id,
	  COUNT(*) AS duplicate_count
	  FROM banking_loans
	  GROUP BY loan_id
	  HAVING COUNT(*)>1;

----------------------------------------------------------------------------------------------------------------------------------
--Check for missing customers IDs
-- Every loan should be linked to a customer
SELECT COUNT(*) AS missing_customer_id
FROM banking_loans
WHERE customer_id IS NULL;

----------------------------------------------------------------------------------------------------------------------------------
-- Check for missing loan type 
-- Every loan record should have a defined loan type 
SELECT COUNT(*) AS missing_loan_type
FROM banking_loans
WHERE loan_type IS NULL;

---------------------------------------------------------------------------------------------------------------------------------
-- Check the distinct loan_type available 
-- This helps verify that loan_type constains valid categories
SELECT loan_type, COUNT(*) AS loan_count
FROM banking_loans
GROUP BY loan_type 
ORDER BY loan_type;

---------------------------------------------------------------------------------------------------------------------------------
-- Check the loan status categories 
-- This helps verify that loan_status contains valid values
SELECT loan_status, COUNT(*) AS loan_count
FROM banking_loans
GROUP BY loan_status
ORDER BY loan_status;

---------------------------------------------------------------------------------------------------------------------------------
-- Check for missing start date
-- Every loan should have start date for tracking its timeline
SELECT COUNT(*) AS missing_loan_start_date
FROM banking_loans
WHERE loan_start_date IS NULL;

----------------------------------------------------------------------------------------------------------------------------------
-- Check for loan start dates in the future 
-- A loan start date should not be later than today date 
SELECT COUNT(*) AS future_loan_start_dates
FROM banking_loans
WHERE loan_start_date > CURRENT_DATE;

---------------------------------------------------------------------------------------------------------------------------------
-- Create table for banking cards data 
-- This table will store card details linked to customers 
CREATE TABLE banking_cards(
card_id INT,
customer_id INT,
card_type VARCHAR(50),
card_network VARCHAR(50),
credit_limit NUMERIC(15,2),
card_issue_date DATE,
card_status VARCHAR(30)
);
-- change card_id text because card IDs contain values in text
ALTER TABLE banking_cards
ALTER COLUMN card_id TYPE VARCHAR(20);
-- cahnge customer id to text 
ALTER TABLE banking_cards 
ALTER COLUMN customer_id TYPE VARCHAR(20);

-----------------------------------------------------------------------------------------------------------------------------
-- Verify the total number of cards record after import
SELECT COUNT(*) AS total_cards 
FROM banking_cards;

------------------------------------------------------------------------------------------------------------------------------
-- Check for dublicate card IDs 
-- Each card id should uniquely identify one card 
SELECT 
      card_id,
	  COUNT(*) AS duplicate_count
	  FROM banking_cards
	  GROUP BY card_id
	  HAVING COUNT(*) > 1;

-------------------------------------------------------------------------------------------------------------------------------
-- Check for missing customers IDs 
-- Every card should be linked to a customer
SELECT COUNT(*) AS missing_customer_id
FROM banking_cards
WHERE customer_id IS NULL;

--------------------------------------------------------------------------------------------------------------------------------
-- Valiadte customer referance in the cards table 
-- Every customer id in banking cards should exist in banking customers 
SELECT COUNT(*) AS invalid_customer_id
FROM banking_cards c
LEFT JOIN banking_customers cu 
ON c.customer_id = cu.customer_id
WHERE cu.customer_id IS NULL;

---------------------------------------------------------------------------------------------------------------------------------
-- Check for missing credit limits 
-- Every card should have a defined credit limit
SELECT COUNT(*) AS missing_credit_limit
FROM banking_cards 
WHERE credit_limit IS NULL;

---------------------------------------------------------------------------------------------------------------------------------
-- Check for invalid credit limits 
-- A cards credit limit should be greater than 0
SELECT COUNT(*) AS invalid_credit_limit
FROM banking_cards 
WHERE credit_limit <=0;

--------------------------------------------------------------------------------------------------------------------------------
-- Check for missing card issue dates 
-- every card should have an issue date 
SELECT COUNT (*) AS missing_card_issue_date
FROM banking_cards 
WHERE card_issue_date IS NULL;

---------------------------------------------------------------------------------------------------------------------------------
-- Check for card issue dates in the future 
-- A card should not have an issue date later than today
SELECT COUNT(*) AS future_card_issue_dates
FROM banking_cards
WHERE card_issue_date > CURRENT_DATE;

--------------------------------------------------------------------------------------------------------------------------------
-- Check the card status categories
-- This helps verify that card_status conatains valid values
SELECT 
      card_status,
	  COUNT(*) AS card_count
	  FROM banking_cards
	  GROUP BY card_status
	  ORDER BY card_status;

---------------------------------------------------------------------------------------------------------------------------------
-- Check minimum and maximum card issue dates
-- This helps verify the overall date range of card issuance
SELECT 
      MIN(card_issue_date) AS earliest_issue_date,
	  MAX(card_issue_date) AS latest_issue_date
FROM banking_cards;

--------------------------------------------------------------------------------------------------------------------------------
-- Check card type categories and their record counts
-- This helps verify that card type contain valid and consistent categories
SELECT 
      card_type,
	  COUNT(*) AS card_count
FROM banking_cards
GROUP BY card_type
ORDER BY card_type;

---------------------------------------------------------------------------------------------------------------------------------
-- Check card network categories and their record counts
-- This helps verify that card networks contain valid and consistent categories
SELECT 
      card_network,
	  COUNT(*) AS card_count
FROM banking_cards
GROUP BY card_network
ORDER BY card_network;

---------------------------------------------------------------------------------------------------------------------------------
-- Check for missing card types
-- This ensure every card has a card type assigned 
SELECT COUNT(*) AS missing_card_type 
FROM banking_cards
WHERE card_type IS NULL;

---------------------------------------------------------------------------------------------------------------------------------
-- Check missing card network 
-- This ensures every card has a card network assigend 
SELECT COUNT(*) AS missing_card_netwrok
FROM banking_cards
WHERE card_network IS NULL;
---------------------------------------------------------------------------------------------------------------------------------
-- Check invalid card type 
-- This ensure card type contains only expected categories
SELECT COUNT(*) AS invalid_card_type
FROM banking_cards
WHERE card_type NOT IN ('Credit','Debit');

-----------------------------------------------------------------------------------------------------------------------------
-- Check for invalid card networks
-- This ensure card network contains only expected categories
SELECT COUNT(*) AS invalid_card_network
FROM banking_cards
WHERE card_network NOT IN ('Visa','Mastercard','RuPay');

-------------------------------------------------------------------------------------------------------------------------------
-- Verify the final record count of the cards 
-- This ensure all imported card record are still present 
SELECT COUNT(*) AS total_cards
FROM banking_cards;

-----------------------------------------------------------------------------------------------------------------------------
-- Calculate total number of customers 
SELECT COUNT(*) AS total_customers
FROM banking_customers;
-----------------------------------------------------------------------------------------------------------------------------------
-- Calculate total numbers of bank accounts 
SELECT COUNT(*) AS total_accounts
FROM banking_accounts;
--------------------------------------------------------------------------------------------------------------------------------
-- Calculate the total number of transactions 
-- This gives an overview of the bank transaction activity
SELECT COUNT(*) AS total_transactions
FROM banking_transactions;
--------------------------------------------------------------------------------------------------------------------------
-- Calculate total number of loan records 
SELECT COUNT(*) AS total_loans
FROM banking_loans;
-------------------------------------------------------------------------------------------------------------------------
--Calculate the total number of cards
SELECT COUNT(*) AS total_cards
FROM banking_cards;
-----------------------------------------------------------------------------------------------------------------------------------
-- Calculate total transaction amount
-- This show the overall monetary value of all recorded transaction
SELECT SUM(amount) AS total_transaction_amount
FROM banking_transactions;

--------------------------------------------------------------------------------------------------------------------------------
--Calculate the avarage transaction amount across all transactions.
-- AVG() returns the mean value of the transaction amount coumn 
SELECT 
      AVG(amount) AS average_transaction_amount
FROM banking_transactions;

---------------------------------------------------------------------------------------------------------------------------------
--Business Objective:
--Identify the number of transaction for each transaction type.
--This helps analyze customer transaction patterns.
SELECT 
      transaction_type,
	  COUNT(*) AS total_transactions
FROM banking_transactions
GROUP BY transaction_type
ORDER BY total_transactions DESC;

-------------------------------------------------------------------------------------------------------------------------------
--Business Obejctive:
--Calculate the total transction amount for tarnsaction type 
-- This helps compare the monetory value of different banking activities
SELECT 
      transaction_type,
	  SUM(amount) AS total_transaction_amount
FROM banking_transactions
GROUP BY transaction_type
ORDER BY total_transaction_amount DESC;

--------------------------------------------------------------------------------------------------------------------------------
--Business Objective:
-- Count transactions by status to understand transaction outcomes.
-- This analysis helps identify sucessful and unsuccessful tarnsactions.
SELECT
      transaction_status,
	  COUNT(*) AS total_transactions
FROM banking_transactions
GROUP BY transaction_status
ORDER BY total_transactions DESC;

---------------------------------------------------------------------------------------------------------------------------------
--Business Objective
--Analyze transaction statuses across different transaction types.
-- This helps identify which transaction types have more failures or pending transactions
SELECT 
      transaction_type,
	  transaction_status,
	  COUNT(*) AS total_transactions
FROM banking_transactions
GROUP BY 
	    transaction_type,
		transaction_status
ORDER BY
	    transaction_type,
		total_transactions DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Business Objective:
-- Calculate the failure rate for each transaction type.
--This helps identify transaction categories with a higher proportions of failed transactions.
SELECT
      transaction_type,
	  COUNT(*) AS total_transactions,
	  SUM(
           CASE 
		       WHEN transaction_status='Failed' THEN 1
			   ELSE 0
		   END
		  ) AS failed_transactions,
		  ROUND(
                100.0 * SUM(
                    CASE 
					    WHEN transaction_status='Failed' THEN 1
						ELSE 0
					END  
				) / COUNT(*),
				2
		  ) AS failure_rate_percentage
FROM banking_transactions
GROUP BY transaction_type
ORDER BY failure_rate_percentage DESC;

-----------------------------------------------------------------------------------------------------------------------------
--Business Obejctive
--Calculate the avearage tarnsactions amount for each transaction type.
-- This helps compare the typical transaction value across categories.
SELECT transaction_type,
COUNT(*) AS total_transactions,
ROUND(AVG(amount),2) AS average_transaction_amount
FROM banking_transactions
GROUP BY transaction_type
ORDER BY average_transaction_amount DESC;

-------------------------------------------------------------------------------------------------------------------------------
--Business Objective:
--Calculate the total transaction amount for total transaction status
--This helps asses the monetory value associated with completed 
--pending and failed transaction.
SELECT transaction_status,
COUNT(*) AS total_transactions,
ROUND(SUM(amount),2) AS total_transaction_amount
FROM banking_transactions
GROUP BY transaction_status
ORDER BY total_transaction_amount DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Business Objective 
-- Verify the overall transactions amount in the banking dataset 
-- This helps ensure the total amount is consistent with the transaction status ananlysis.
SELECT COUNT(*) AS total_transaction,
ROUND(SUM(amount),2) AS total_transaction_amount
FROM banking_transactions;

----------------------------------------------------------------------------------------------------------------------------------
--Business Objective
-- Calculate the average transactions amount for each transactions status.
-- this helps compare the average value of completed ,pending,failed transactions.
SELECT 
      transaction_status,
	  COUNT(*) AS total_transactions,
	  ROUND(AVG(amount),2) AS average_transaction_amount
FROM banking_transactions
GROUP BY transaction_status
ORDER BY average_transaction_amount DESC;

--------------------------------------------------------------------------------------------------------------------------------
--Business Objective:
-- Calculate the total transactions amount for each combination of transaction type and transaction status.
-- This helps compare the monetary value of completed, pending,and failed transactions across transactions types.
SELECT transaction_type,transaction_status,
COUNT(*) AS total_transactions,
ROUND(SUM(amount),2) AS total_transaction_amount
FROM banking_transactions
GROUP BY transaction_type,transaction_status
ORDER BY transaction_type,total_transaction_amount DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Analysis:- Transaction and transaction amount by payment mode 
-- Objective:- Compare transaction volumn and total amount across different payment modes .
SELECT payment_mode,
COUNT(*) AS total_transactions,
ROUND(SUM(amount),2) AS total_transaction_amount
FROM banking_transactions
GROUP BY payment_mode 
ORDER BY total_transaction_amount DESC;

---------------------------------------------------------------------------------------------------------------------------------
--Analysis:- Monthly Transaction Trend
-- Business Objective: Analyze monthly transaction valume and total amount to understand transaction activity over time
SELECT
DATE_TRUNC('month', transaction_date)::DATE AS month,
COUNT(transaction_id) AS total_transactions,
ROUND(SUM(amount),2) AS total_transaction_amount
FROM banking_transactions
GROUP BY DATE_TRUNC('month',transaction_date)
ORDER BY month;

----------------------------------------------------------------------------------------------------------------------------------
--Analysis:- Monthly Transaction Status Analysis
--Business Objective:- Analyze monthly transaction counts by status to understand changes in transaction reliability
SELECT 
      DATE_TRUNC('month',transaction_date)::DATE AS transaction_month,
	  transaction_status,
	  COUNT(transaction_id) AS total_transactions
FROM banking_transactions
GROUP BY 
        DATE_TRUNC('month',transaction_date)::DATE,
		transaction_status
ORDER BY 
        transaction_month,
		total_transactions DESC;

---------------------------------------------------------------------------------------------------------------------------------
-- Analysis:- Overall Transaction Performance Summary
--Business Objective:- Summarize transaction counts and status percentage to evaluate overall transaction perfromance
SELECT
COUNT(*) AS total_transaction,
COUNT(*) FILTER(
WHERE transaction_status='Completed'
) AS completed_transaction,
COUNT(*) FILTER(
WHERE transaction_status='Failed'
) AS failed_transaction,
COUNT(*) FILTER(
WHERE transaction_status='Panding'
) AS pending_transaction,
ROUND(
100.0 * COUNT(*) FILTER(
WHERE transaction_status='Completed'
)/NULLIF(COUNT(*),0),2
) AS completed_percentage,
ROUND(
100.0 * COUNT(*) FILTER(
WHERE transaction_status='Failed'
)/NULLIF(COUNT(*),0),2
) AS failed_percentage,
ROUND(
100.0 * COUNT(*) FILTER(
WHERE transaction_status='Pending'
)/NULLIF(COUNT(*),0),
2
)AS pending_percentage
FROM banking_transactions;
-------------------------------------------------------------------------------------------------------------------------------
--Customer Analysis
--------------------------------------------------------------------------------------------------------------------------------
--Customer Data overview
--Business Obejctive:- Inspect customer records and available column before performing business analysis
SELECT *
FROM banking_customers
LIMIT 5;
-------------------------------------------------------------------------------------------------------------------------------
--Customer Analysis:- Customer Distribution by city
--Business Objective:- Identify cities with the highest number of cutomers to understand the bank geographic customer base.
SELECT city,
COUNT(customer_id) AS total_customers
FROM banking_customers
GROUP BY city
ORDER BY total_customers DESC;
-------------------------------------------------------------------------------------------------------------------------------
--Customer Analysis:- Customer distribution by Occupation
--Business Obejctive:- Understand the occupatinal profile of the customer base to support customer segmentation and product planning
SELECT 
occupation,
COUNT(customer_id) AS total_customers
FROM banking_customers
GROUP BY occupation
ORDER BY total_customers DESC;

-----------------------------------------------------------------------------------------------------------------------------------
--Customers Analysis :- Customer Age group Analysis
--Business Objective:-Understand the age distribution of customers to identify the largest customer age group
SELECT 
      CASE 
	      WHEN age < 25 THEN 'Below 25'
		  WHEN age BETWEEN 25 AND 35 THEN '25-35'
		  WHEN age BETWEEN 36 AND 45 THEN '36-45'
		  WHEN age BETWEEN 46 AND 60 THEN '46-60'
		  ELSE 'Above 60'
	  END AS age_group,
	  COUNT(customer_id) AS total_customers
FROM banking_customers
GROUP BY
      CASE
	      WHEN age < 25 THEN 'Below 25'
		  WHEN age BETWEEN 25 AND 35 THEN '25-35'
		  WHEN age BETWEEN 36 AND 45 THEN '36-45'
		  WHEN age BETWEEN 46 AND 60 THEN '46-60'
		  ELSE 'Above 60'
	  END 
ORDER BY MIN(age);
----------------------------------------------------------------------------------------------------------------------------------
--Customer analysis:- Customer Distribution by Gender
--Business Objective:- Analyze the gender distribution of the customer base to understand customer demographics 
SELECT 
      gender,
	  COUNT(customer_id) AS total_customers,
	  ROUND(
            COUNT(customer_id) * 100.0 /
			SUM(COUNT(customer_id)) OVER(),
			2
	  ) AS customer_percentage
FROM banking_customers
GROUP BY gender
ORDER BY total_customers DESC;

---------------------------------------------------------------------------------------------------------------------------------
--Customer Analysis:- Customer segment Analysis
--Business Objective:- Analyze the distribution of customer across segments to undersatnd the banks customer portfolio.
SELECT
      customer_segment,
	  COUNT(customer_id) AS total_customers,
	  ROUND(
            COUNT(customer_id) * 100.0/
			SUM(COUNT(customer_id)) OVER(),
			2
	  ) AS customer_percentage
FROM banking_customers
GROUP BY customer_segment
ORDER BY total_customers DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Accounts Analysis:-
----------------------------------------------------------------------------------------------------------------------------------
--Account type Distribution
--Business Objective:- Analyze the number and percentage of accounts by account type to understand the account portfolio.
SELECT
      account_type,
	  COUNT(account_id) AS total_accounts,
	  ROUND(
            COUNT(account_id) * 100.0/
			SUM(COUNT(account_id)) OVER(),
			2
	  ) AS account_percentage
FROM banking_accounts
GROUP BY account_type
ORDER BY total_accounts DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Account Anlysis:- Account Status Analysis
--Business Objective:- Analyze the number and percentage of accounts by status to understand account activity levels.
SELECT 
      account_status,
	  COUNT(account_id) AS total_accounts,
	  ROUND(
            COUNT(account_id) * 100.0/
			SUM(COUNT(account_id)) OVER(),
			2
	  ) AS account_percentage
FROM banking_accounts
GROUP BY account_status
ORDER BY total_accounts DESC;

---------------------------------------------------------------------------------------------------------------------------------
--Accounts Analysis:- Balance Analysis by Account type
--Business Objective:- Compare total and average account balances across account types to understand balance distribution.
SELECT
      account_type,
	  COUNT(account_id) AS total_accounts,
	  ROUND(SUM(balance),2) AS total_balance,
	  ROUND(AVG(balance),2) AS average_balance
FROM banking_accounts
GROUP BY account_type
ORDER BY total_balance DESC;

--------------------------------------------------------------------------------------------------------------------------------
--Account Analysis:- Branch wise Account balance Analysis
--Business Objective:- Compare account balance across branches.
SELECT
      branch,
	  COUNT(account_id) AS total_accounts,
	  ROUND(SUM(balance),2) AS total_balance,
	  ROUND(AVG(balance),2) AS average_balance
FROM banking_accounts
GROUP BY branch
ORDER BY total_balance DESC;

------------------------------------------------------------------------------------------------------------------------------
--Accounts Analysis:- Yearly Account opening Trends
--Business Objective:- Track yearly growth in account openings.
SELECT 
      EXTRACT(YEAR FROM account_open_date) AS opening_year,
	  COUNT(account_id) AS total_accounts_opened
FROM banking_accounts
GROUP BY EXTRACT(YEAR FROM account_open_date)
ORDER BY opening_year;
--------------------------------------------------------------------------------------------------------------------------------
--Loan Analysis
---------------------------------------------------------------------------------------------------------------------------------
--Loan Analysis:-Loan Status Distribution
--Business Objective:- Analyze loan counts and accounts by status.
SELECT
      loan_status,
	  COUNT(loan_id) AS total_loans,
	  ROUND(SUM(loan_amount),2) AS total_loan_amount,
	  ROUND(AVG(loan_amount),2) AS average_loan_amount
FROM banking_loans
GROUP BY loan_status
ORDER BY total_loans DESC;

--------------------------------------------------------------------------------------------------------------------------------
--Loan Analysis :- Average Interest Rate by Loan Status
-- Business Objective:- Compare borrwing costs across loan statuses.
SELECT
      loan_status,
	  COUNT(loan_id) AS total_loans,
	  ROUND(AVG(interest_rate),2) AS average_interest_rate
FROM banking_loans
GROUP BY loan_status
ORDER BY average_interest_rate DESC;

-------------------------------------------------------------------------------------------------------------------------------
--Loan Analysis:- Average Loan Tenure by Loan Status
--Business Objective:- Compare the average loan duration across diffrent loan statuses.
SELECT
      loan_status,
	  COUNT(loan_id) AS total_loans,
	  ROUND(AVG(loan_tenure_years),2) AS average_loan_tenure
FROM banking_loans
GROUP BY loan_status
ORDER BY average_loan_tenure DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Loan Analysis:- Loan type analysis
-- Business Obejctive:- Compare loan volumn and loan amounts across loan type.
SELECT
      loan_type,
	  COUNT(loan_id) AS total_loans,
	  ROUND(SUM(loan_amount),2) AS total_loan_amount,
	  ROUND(AVG(loan_amount),2) AS average_loan_amount
FROM banking_loans
GROUP BY loan_type
ORDER BY total_loan_amount DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Loan Analysis:- Yearly loan Disbursement trend
--Business Objective:- Track yearly loan volumn and loan amounts.
SELECT
      EXTRACT(YEAR FROM loan_start_date ) AS loan_years,
	  COUNT(loan_id) AS total_loans,
	  ROUND(SUM(loan_amount),2) AS total_loan_amount,
	  ROUND(AVG(loan_amount),2) AS average_loan_amount
FROM banking_loans
GROUP BY EXTRACT(YEAR FROM loan_start_date)
ORDER BY loan_years;
-----------------------------------------------------------------------------------------------------------------------------------
--Cards Analysis
-----------------------------------------------------------------------------------------------------------------------------------
--Cards Analysis:- Card type Distribution
--Business Objective :- Compare card counts and credit limits by card type 
SELECT
      card_type,
	  COUNT(card_id) AS total_cards,
	  ROUND(SUM(credit_limit),2) AS total_credit_limit,
	  ROUND(AVG(credit_limit),2) AS average_credit_limit
FROM banking_cards
GROUP BY card_type
ORDER BY total_cards DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Cards Analysis :- Card status distribution
--Business Objective:- Understand the distribution of cards by status.
SELECT
      card_status,
	  COUNT(card_id) AS total_cards,
	  ROUND(
            COUNT(card_id) * 100.0/ SUM(COUNT(card_id)) OVER(),
			2
	  ) AS percentage_of_cards
FROM banking_cards
GROUP BY card_status
ORDER BY total_cards DESC;

---------------------------------------------------------------------------------------------------------------------------------
--Cards Analysis:- Credit Limit by Card network
--Business Objective:- Compare card and credit limits by network
SELECT
      card_network,
	  COUNT(card_id) AS total_cards,
	  ROUND(SUM(credit_limit),2) AS total_credit_limit,
	  ROUND(AVG(credit_limit),2) AS average_credit_limit
FROM banking_cards
GROUP BY card_network
ORDER BY total_credit_limit;

---------------------------------------------------------------------------------------------------------------------------------
--Cards Analysis:- Yearly Card Issuance Trend
--Business Objective:- Analyse how card issuance changes year by year.
SELECT
      EXTRACT(YEAR FROM card_issue_date) AS issue_year,
	  COUNT(card_id) AS total_cards_issued
FROM banking_cards
GROUP BY EXTRACT(YEAR FROM card_issue_date)
ORDER BY issue_year;

---------------------------------------------------------------------------------------------------------------------------------
--Cards Analysis :- Avearge Credit limit by card status
--Business obejctive:-Compare recirded credit limits across card statuses
SELECT
      card_status,
	  COUNT(card_id) AS total_cards,
	  ROUND(AVG(credit_limit),2) AS average_credit_limit,
	  ROUND(SUM(credit_limit),2) AS total_credit_limit
FROM banking_cards
GROUP BY card_status
ORDER BY average_credit_limit DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Join Analysis:- Customer Account Overview by city
--Purpose:- Analyze customers , Accounts And account balances city-wise
SELECT
      c.city,
	  COUNT(DISTINCT c.customer_id) AS total_customers,
	  COUNT(a.account_id) AS total_accounts,
	  SUM(a.balance) AS total_account_balance
FROM banking_customers AS c
INNER JOIN banking_accounts AS a
ON c.customer_id = a.customer_id
GROUP BY c.city
ORDER BY total_account_balance DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Join Analysis:- City-Wise Transaction Performance
--Purpose:- Analyze transaction activity and value across cities.
SELECT
      c.city,
	  COUNT(t.transaction_id) AS total_transaction,
	  SUM(t.amount) AS total_transaction_amount,
	  ROUND(AVG(t.amount),2) AS average_transaction_amount
FROM banking_customers AS c
INNER JOIN banking_transactions AS t
ON c.customer_id=t.customer_id
GROUP BY c.city
ORDER BY total_transaction_amount DESC;

----------------------------------------------------------------------------------------------------------------------------------
--JOIN Analysis:- Customer-Wise Transaction summary
--Purpose:-Analyze transaction activity for each customers.
SELECT
      c.customer_id,
	  c.customer_name,
	  COUNT(t.transaction_id) AS total_transactions,
	  SUM(t.amount) AS total_transaction_amount,
	  ROUND(AVG(t.amount),2) AS average_transaction_amount
FROM banking_customers AS c
INNER JOIN banking_transactions AS t
ON c.customer_id=t.customer_id
GROUP BY c.customer_id,c.customer_name
ORDER BY total_transaction_amount DESC;

---------------------------------------------------------------------------------------------------------------------------------
--Join Analysis:- Customer Transaction Status by City
--Purpose:- Analyse Transaction status and amoount across cities
SELECT
      c.city,
	  t.transaction_status,
	  COUNT(t.transaction_id) AS total_transactions,
	  SUM(t.amount) AS total_transaction_amount
FROM banking_customers AS c
INNER JOIN banking_transactions AS t
ON c.customer_id = t.customer_id
GROUP BY c.city,t.transaction_status
ORDER BY c.city,total_transactions DESC;

---------------------------------------------------------------------------------------------------------------------------------
--Join Analysis:- Customer Transaction Activity
--Purpose:- Categories Customers based On transaction frequency.
SELECT
      c.customer_id,
	  c.customer_name,
	  COUNT(t.transaction_id) AS total_transactions,
	  SUM(t.amount) AS total_transaction_amount,
	  CASE
	      WHEN COUNT(t.transaction_id)>=5 THEN 'High Activity'
		  WHEN COUNT(t.transaction_id)>=3 THEN 'Medium Activity'
		  ELSE 'Low Activity'
	  END AS customer_activity
FROM banking_customers AS c
INNER JOIN banking_transactions AS t
ON c.customer_id=t.customer_id
GROUP BY c.customer_id,c.customer_name
ORDER BY total_transactions DESC,
         total_transaction_amount DESC;

---------------------------------------------------------------------------------------------------------------------------------
--Validation:- Customer Transaction Frequenty Distribution
--Purpose:- check how many customer have diffrent transaction counts.
SELECT
      transaction_count,
	  COUNT(*) AS total_customers
FROM(
     SELECT
	       customer_id,
		   COUNT(transaction_id) AS transaction_count
		   FROM banking_transactions
		   GROUP BY customer_id
) AS customer_activity
GROUP BY transaction_count
ORDER BY transaction_count;

-------------------------------------------------------------------------------------------------------------------------------
--Validation :- check total and unique customer_id in transactions
SELECT
      COUNT(*) AS total_transactions,
	  COUNT(DISTINCT customer_id) AS unique_customers,
	  COUNT(*) - COUNT(DISTINCT customer_id) AS repeated_customer_records
FROM banking_transactions;

-------------------------------------------------------------------------------------------------------------------------------
--Join Analysis:- Customers Loan overview by city
--Purpose:- Analyse loan distribution and loan amount across cities.
SELECT
      c.city,
	  COUNT(DISTINCT c.customer_id) AS total_customers,
	  COUNT(l.loan_id) AS total_loan_records,
	  SUM(l.loan_amount) AS total_loan_amount
FROM banking_customers AS c
INNER JOIN banking_loans AS l
ON c.customer_id = l.customer_id
GROUP BY c.city
ORDER BY total_loan_amount DESC;

---------------------------------------------------------------------------------------------------------------------------------
--Join Analysis:- Loan Status analysis by city
--Purpose:- Analyse loan status distribution across cities
SELECT
      c.city,
	  l.loan_status,
	  COUNT(l.loan_id) AS total_loans,
	  SUM(l.loan_amount) AS total_loan_amount
FROM banking_customers AS c
INNER JOIN banking_loans AS l
ON c.customer_id = l.customer_id
GROUP BY c.city,l.loan_status
ORDER BY c.city,total_loans DESC;

---------------------------------------------------------------------------------------------------------------------------------
--Join Analysis:- Loan default Exposure by city
--Purpose :- Identify default loan counts and amounts across cities.
SELECT
      c.city,
	  COUNT(l.loan_id) AS total_default_loans,
	  SUM(l.loan_amount) AS total_default_loan_amount,
	  ROUND(AVG(l.loan_amount),2) AS average_default_loan_amount
FROM banking_customers AS c
INNER JOIN banking_loans AS l
ON c.customer_id = l.customer_id
WHERE l.loan_status='Default'
GROUP BY c.city
ORDER BY total_default_loan_amount DESC;

--------------------------------------------------------------------------------------------------------------------------------
--Join Analysis:- customer Loan Summary
--Purpose:- Analyse total loan exposure for individual customers.
SELECT
      c.customer_id,
	  c.customer_name,
	  COUNT(l.loan_id) AS total_loans,
	  SUM(l.loan_amount) AS total_loan_amount
FROM banking_customers AS c
INNER JOIN banking_loans AS l
ON c.customer_id = l.customer_id
GROUP BY c.customer_id,c.customer_name
ORDER BY total_loan_amount DESC;

----------------------------------------------------------------------------------------------------------------------------------
--Join Analysis:- Customer credit card Overview by city
--Purpose:- Analyse card distribution and credit limits across cities
SELECT
      c.city,
	  COUNT(DISTINCT c.customer_id) AS total_customers,
	  COUNT(cd.card_id) AS total_cards,
	  SUM(cd.credit_limit) AS total_credit_limit,
	  ROUND(AVG(cd.credit_limit),2) AS average_credit_limit
FROM banking_customers AS c
INNER JOIN banking_cards AS cd
ON c.customer_id = cd.customer_id
GROUP BY c.city
ORDER BY total_credit_limit DESC;

--------------------------------------------------------------------------------------------------------------------------------
--Join Analysis:- Customers Account and Transaction Summary
--Purpose:- Amalyse banking activity across cities.
SELECT 
      c.city,
	  COUNT(DISTINCT c.customer_id) AS total_customers,
	  COUNT(DISTINCT a.account_id) AS total_accounts,
	  COUNT(t.transaction_id) AS total_transactions,
	  SUM(t.amount) AS total_transaction_amount
FROM banking_customers AS c
INNER JOIN banking_accounts AS a
ON c.customer_id=a.customer_id
INNER JOIN banking_transactions AS t
ON a.account_id = t.account_id
GROUP BY c.city
ORDER BY total_transaction_amount DESC;






	  






	  






















