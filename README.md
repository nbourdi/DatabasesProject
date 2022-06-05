# Databases Poject: ELIDEK
This is a project for the ECE NTUA Databases course, spring semester 2021-2022.
## Project Group 3

- [Konstantinos Xidias](https://github.com/xidias)
- [Natalia Bourdi](https://github.com/nbourdi)


# How to set up the database and web app

## Dependencies

- [MySQL](https://www.mysql.com/)
- [Apache](https://httpd.apache.org/)
- [PHP](https://www.php.net/)

The above can be installed and configured either individually or as a stack. 

## Recommended installation steps

1. Install the approporiate [XAMPP](https://www.apachefriends.org/download.html) distribution for your system.

2. Run the XAMPP Control Panel with administrative priviledges and start the Apache and MySQL services.

3. Click on the "Explorer" button and navigate to `\xampp\mysql\bin`. Copy [quick-set-up.sql](https://github.com/nbourdi/DatabasesProject/blob/main/quick-set-up.sql) to the directory.

4. Set up the database with all initial mock data inserted.

    Click the "Shell" button on the Control Panel and execute quick-set-up.sql.
    
    
  ```
 cd mysql\bin
 mysql -u <user> -p
 CREATE DATABASE elidek;
 exit
 mysql -u <user> -p elidek < quick-set-up.sql
 ```
  
5. Clone the repository to `\xampp\htdocs`.
 ```
 git clone https://github.com/nbourdi/DatabasesProject
 ```

6. Edit /ui-db-3/connection.ini to match your credentials.

7. Open a web browser and go to localhost/DatabasesProject.
    

  
## E-R Diagram
We based our database on the provided Entity-Relationship diagram.

![ER-1](https://user-images.githubusercontent.com/62358292/167364488-d679b6a8-589a-40bd-bbab-b67a8d6aa3df.png)

## Relational Diagram

![relational-diagram](https://user-images.githubusercontent.com/62358292/171855701-8056b0ec-985a-40ca-83a4-62c9870b2f24.png)

# Preview

![image](https://user-images.githubusercontent.com/62358292/172061751-e8e3fac4-6765-40e2-a041-dd5cab751e8c.png)
![image](https://user-images.githubusercontent.com/62358292/172061768-0ad16df7-2fad-4051-b5e6-f5d972cd7a1a.png)



