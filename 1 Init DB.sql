CREATE DATABASE "HarvexDB"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; --расширение для uuid

--**************************************************	
/*
	DROP SCHEMA IF EXISTS public CASCADE;
	CREATE SCHEMA public AUTHORIZATION postgres;
*/
--**************************************************