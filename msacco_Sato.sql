---Project Database File
alter table entitys add entry_amount real not null default 0;
alter table entitys add  exit_amount real not null default 0;
alter table entitys add entry_date date not null default current_date;
alter table entitys add exit_date date check (entry_date > exit_date);
alter table entitys add national_id_no varchar (89) not null default 11111;
alter table entitys add secondary_telephone varchar (89) ;

CREATE TABLE periods (
	period_id				serial primary key,
	org_id					integer references orgs,
	period_name        			varchar(50),
	period_start_date			date not null,
	period_end_date				date not null,
	period_closed				boolean default false not null,
	period_details				text
);

CREATE TABLE contribution_types(
	contribution_type_id			serial primary key,
	contribution_type_name			varchar(20),
	details					text
);

INSERT INTO contribution_types(contribution_type_id, contribution_type_name) VALUES
(1, 'Daily'),
(2, 'Weekly'),
(3, 'fortnight'),
(4, 'Monthly');

CREATE TABLE contributions (
	contribution_id				serial primary key,
	org_id					integer references orgs,
	entity_id				integer references entitys,
	contribution_type_id			integer references contribution_types,
	period_id				integer references periods,
	deposit_date				date,
	entry_date                  		timestamp default CURRENT_TIMESTAMP,
	expenses       				real default 0,
	narrative				varchar(255),
	UNIQUE (entity_id, period_id,org_id)
);

CREATE TABLE loan_types (
	loan_type_id				serial primary key,
	org_id						integer references orgs,
	loan_type_name				varchar(50),
	loan_type_default_interest	real,
	details						text
);

CREATE TABLE loans (
	loan_id 					serial primary key,
	loan_type_id				integer references loan_types,
	entity_id					integer references entitys,
	org_id						integer references orgs,
	loan_date					date not null default current_date,
	loan_principle				real not null default 0,
	loan_interest				real not null default 0,
	loans_weekly_repayment		real not null default 0,
	loan_monthly_repayment		real not null default 0,
	expenses     				real not null default 0,
	period_id					integer references periods,
	repayment_period			integer not null default 0,
	loan_approved				boolean not null default false,
	interest_amount				real default 0,
	details						text
);
--new inclusion
create TABLE loan_repayment(
	loan_repayment_id       serial primary key,
	loan_id					integer references loans,
	org_id					integer references orgs,
	repayment_amount		real not null default 0,
	repayment_interest		real not null default 0,
	repayment_narrative		text
);

CREATE TABLE payment_type( 
	payment_type_id			serial primary key,		
	payment_type_name			varchar (50),
	payment_narrative 			text
);
INSERT INTO payment_type(payment_type_id, payment_type_name) VALUES
(1, 'Bank'),
(2, 'Mpesa'),
(3, 'Cash'),
(4, 'Airtel Money');

alter table loans add payment_type_id integer references payment_type;
alter table loans add loan_repayment_id integer references loan_repayment;
alter table loans add loan_balance real not null default 0;
--end inclusion 1

CREATE TABLE gurrantors (
	gurrantor_id				serial primary key,
	entity_id					integer references entitys,
	loan_id						integer references loans,
	org_id						integer references orgs,
	amount						real not null default 0,
	details						text
);

CREATE TABLE fine_types(
	fine_type_id          		serial primary key,
	org_id						integer references orgs,
	fine_type_name				varchar(50),
	details						text
	
);
 
create table fines (
	fine_id                   	serial primary key,
	fine_type_id				integer references fine_types,
	fine_name					varchar (70),
	table_name					varchar(50),
	table_id					integer not null,
	org_id						integer references orgs,
	amount						real not null default 0,
	expenses					real default 0,
	details						text
);
--inclusion 2
CREATE OR REPLACE FUNCTION insInterest() RETURNS TRIGGER AS $$
DECLARE
    v_loan_default_interest     real;
BEGIN
        SELECT loan_type_default_interest INTO v_loan_default_interest FROM loan_types WHERE loan_type_id = NEW.loan_type_id;
        NEW.loan_interest := v_loan_default_interest;
        
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insInterest BEFORE INSERT ON loans
    FOR EACH ROW EXECUTE PROCEDURE insInterest();


--end inclusion 2
--trigger 1
CREATE OR REPLACE FUNCTION insInterest() RETURNS TRIGGER AS $$
DECLARE
    v_loan_default_interest     real;
BEGIN
        SELECT loan_type_default_interest INTO v_loan_default_interest FROM loan_types WHERE loan_type_id = NEW.loan_type_id;
        NEW.loan_interest := v_loan_default_interest;
        
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insInterest BEFORE INSERT ON loans
    FOR EACH ROW EXECUTE PROCEDURE insInterest();

--trigger
--amount
CREATE OR REPLACE FUNCTION insPaymentsMonthly() RETURNS TRIGGER AS $$
DECLARE
    v_repayment     real;
BEGIN
        SELECT repayment_amount INTO v_payment FROM loan_payment WHERE loan_id = NEW.loan_id;
        NEW.loan_repayment_monthly  := v_payment;
        
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;
----loans
CREATE OR REPLACE FUNCTION insLoansMonthly() RETURNS TRIGGER AS $$
SELECT CASE WHEN loan_repayment(repayment_amount) is null THEN 0 ELSE loans(loans_monthly_amount) END 
	FROM loans
	WHERE (loan_id = NEW.loan_id);
$$ LANGUAGE SQL;

CREATE TRIGGER insLoansMonthly BEFORE INSERT ON loans
    FOR EACH ROW EXECUTE PROCEDURE insInterest();
----end loans1

