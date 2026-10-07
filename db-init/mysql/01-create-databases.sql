-- Runs once, when the mysql-data volume is first initialised.
-- Services also use createDatabaseIfNotExist=true, so this is a safety net
-- for a local (non-docker) MySQL as well: run it manually with
--   mysql -uroot -proot1234 < db-init/mysql/01-create-databases.sql
CREATE DATABASE IF NOT EXISTS Fooddb;
CREATE DATABASE IF NOT EXISTS jb2404;
CREATE DATABASE IF NOT EXISTS cartdb;
CREATE DATABASE IF NOT EXISTS paymentdb;
