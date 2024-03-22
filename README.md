# Smart Parking Management System

## Table of Contents
- [Introduction](#introduction)
- [Database Setup Steps](#database-setup-steps)
- [Conclusion](#conclusion)

## Introduction

Welcome to the Smart Parking Management System (SPMS) database setup guide. This project aims to address urban parking challenges by providing a comprehensive database-driven solution. Follow the comprehensive setup steps below to initialize the SPMS database with the required configurations and sample data.

## Database Setup Steps

### Step 1: Login as Oracle Database Admin
Ensure you have Oracle Database Admin credentials. Login to your Oracle database to start setting up the SPMS database.

### Step 2: Create Database Users
- **PLADMIN Creation Script** (`1_SPMS_PARKINGLOT_ADMIN_creation.sql`): Creates the PLADMIN user with administrative permissions.
- **PL_USER1 Creation Script** (`2_SPMS_USER1_creation.sql`): Creates PL_USER1 with user-level permissions.
- **PL_MANAGER1 Creation Script** (`3_SPMS_MANAGER_1_creation.sql`): Establishes PL_MANAGER1 with manager-level permissions.

### Step 3: Connect as PLADMIN from SQL Developer
Utilize SQL Developer to connect to the database using the PLADMIN credentials.

### Step 4: Execute DDL Statements
- **DDL Creation Script** (`4_SPMS_DDL_creation.sql`): Execute DDL statements to create tables, ensuring to drop existing tables if necessary and to maintain the parent-child table hierarchy. Also, manage sequences accordingly.

### Step 5: Insert Sample Records
- **DML Statements Script** (`5_SPMS_DML_Stmt.sql`): Insert sample records into the database using the PLADMIN user.

### Step 6: Create Views
- **View Creation Script** (`6_SPMS_View_Creation.sql`): Define views for reporting and data access purposes, executing this script as PLADMIN.

### Step 7: Grant Access to Users
- **Grant Permissions Script** (`7_Grant_Statements.sql`): Assign appropriate access rights to PL_USER1 and PL_MANAGER1 for the tables and views.

### Step 8 & 9: User and Manager Access
- **PL_USER1 Steps** (`8_USER_STEPS.sql`): Directions for PL_USER1 to access and interact with the system.
- **PL_MANAGER1 Steps** (`9_MANAGER_STEPS.sql`): Instructions for PL_MANAGER1 on managing and overseeing parking operations.

## Conclusion

Following these steps will set up a comprehensive database system for the Smart Parking Management System, addressing urban parking inefficiencies. This setup serves as a crucial foundation for integrating with application layers, enhancing parking space management, user interaction, and administrative functions. Ensure to secure user credentials and adhere to database management best practices throughout the process.
