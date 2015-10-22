
ALTER TABLE entitys ADD entity_entry_amount	real not null default 0;
ALTER TABLE entitys ADD entity_start_date	date not null default current_date;
ALTER TABLE entitys ADD entity_exit_amount	real not null default 0;
ALTER TABLE entitys ADD entity_exit_date	date;

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
	contribution_type_name			varchar(20);
	details					text
);

INSERT INTO contribution_types(contribution_type_id, contribution_type_name) VALUES
(1, 'Daily'),
(2, 'Weekly'),
(3, 'Monthly');

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
	org_id					integer references orgs,
	loan_type_name				varchar(50),
	loan_type_default_interest		integer,
	details					text
);

CREATE TABLE loans (
	loan_id 				serial primary key,
	loan_type_id				integer references loan_types,
	entity_id				integer references member,
	org_id					integer references orgs
	loan_date				date not null default current_date,
	loan_principle				real not null,
	loan_interest				real not null,
	loans_weekly_repayment			real not null,
	loan_monthly_repayment			real not null,
	expenses     				real not null,
	period_id				integer references period,
	repayment_period			integer not null CHECK (repayment_period > 0),
	loan_approved				boolean not null default false,
	interest_amount				real default 0
	details					text
);

CREATE TABLE gurrantor (
	gurrantor_id				serial primary key,
	member_id					integer references member,
	loan_id						integer references loans,
	org_id						integer references orgs
	gurrantor_name				varchar (120) not null default 'self',
	gurrantor_name_1			varchar (120) not null default 'self',
	gurrantor_1_id				varchar (120) not null,
	gurrantor_2_id				varchar (120) not null,
	amount						real not null default 0,
	details						text
);
CREATE TABLE loan_weekly (
	loan_weekly_id 				serial primary key,
	loan_weekly_name			varchar (70),
	loan_id						integer references loans,
	org_id						integer references orgs
	period_id					integer references periods,
	principle_amount			real default 0,
	interest_amount				real default 0,
	balance           			real default 0,
	sum_total 					real default 0,
 repayment_period 				real default 0,
	expenses					real default 0,
	details						text
	);
create table fines (
	fine_id                   	serial primary key,
	fine_name					varchar (70),
	member_id					integer references member,
	loan_id						integer references loans,
	contribution_id				integer references contribution,
	org_id						integer references orgs
	amount						real not null default 0,
	expenses					real default 0,
	details						text
);
CREATE TABLE motorcycle(
	motorcycle_id      			serial primary key,
	motorcycle_name				varchar(80),
	motorcycle_plate_no 		varchar(80) not null,
	motor_cycle_narrative 		varchar (70),
	motorcycle_insurance_no		varchar(80) not null,
	member_id					integer references member,
	loan_id						integer references loans,
	loan_weekly_id             	integer references loans_weekly,
	org_id						integer references orgs,
	motorcycle_details			text
);
create table expenses(
	expenses_id    				serial primary key,
	org_id						integer references orgs
	loan_id						integer references loans,
	loan_weekly_id             	integer references loans_weekly,
	contribution_id				integer references contribution,
	loan_weekly_id 				integer references loan_weekly,
	fines_id 					integer references fines
);

DROP VIEW tomcat_users;
CREATE OR REPLACE VIEW tomcat_users AS
 SELECT users.user_name,
users.primary_email,
    users.user_password,
    roles.role_name
   FROM roles
     JOIN users ON roles.role_id = users.role_id
  WHERE users.is_active = true;


CREATE OR REPLACE FUNCTION first_password() RETURNS varchar(12) AS $$
DECLARE
	passchange varchar(12);
BEGIN
	passchange := upper(substr(md5(random()::text), 1, 12));

	return passchange;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_users() RETURNS trigger AS $$
BEGIN
	IF(NEW.user_password is null) THEN
		NEW.first_password := first_password();
		NEW.user_password := md5(NEW.first_password);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_users BEFORE INSERT ON users
    FOR EACH ROW EXECUTE PROCEDURE ins_users();

CREATE TRIGGER auditlogfunc AFTER INSERT ON member
	FOR EACH ROW EXECUTE PROCEDURE auditlogfunc();
CREATE OR REPLACE FUNCTION getpaymentperiod(real, real, integer, real) RETURNS real AS $$
DECLARE
	loan_balance real;
	ri real;
BEGIN
	ri := 1 + ($2/1200);

	loan_balance := $1 * (ri ^ $3) - ($4 * ((ri ^ $3)  - 1) / (ri - 1));
		
	RETURN loan_balance;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getpaymentperiod(real, real, real) RETURNS real AS $$
DECLARE
	paymentperiod real;
	q real;
BEGIN
	q := $3/1200;

	paymentperiod := (log($2) - log($2 - (q * $1))) / (log(q + 1));
		
	RETURN repayment_period;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION gettotalinterest(integer,real) RETURNS real AS $$
	SELECT CASE WHEN sum(sum_total) is null THEN 0 ELSE sum(interest_amount) END 
	FROM loan_weekly
	WHERE (loan_id = $1);
$$ LANGUAGE SQL;

 CREATE OR REPLACE FUNCTION gettotalinterest(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(loans_interest) is null THEN 0 ELSE sum(interest_amount) END 
	FROM loans INNER JOIN periods ON loans.period_id = periods.period_id
	WHERE (loan_id = $1) AND (period_start_date < $2);
$$ LANGUAGE SQL;
