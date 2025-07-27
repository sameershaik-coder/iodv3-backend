-- Create databases for microservices
CREATE DATABASE iodv3_accounts;
CREATE DATABASE iodv3_blog;

-- Create users and grant permissions
CREATE USER accounts_user WITH PASSWORD 'accounts_password';
CREATE USER blog_user WITH PASSWORD 'blog_password';

GRANT ALL PRIVILEGES ON DATABASE iodv3_accounts TO accounts_user;
GRANT ALL PRIVILEGES ON DATABASE iodv3_blog TO blog_user;
