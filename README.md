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
!!!!DRAFT!!!!
1. Install the approporiate [XAMPP](https://www.apachefriends.org/download.html) distribution for your system.

2. Run the XAMPP Control Panel with administrative priviledges and start the Apache and MySQL services.

3. Click on the "Explorer" button and navigate to `\xampp\mysql\bin`. Copy [quick-set-up.sql](https://github.com/evitapp/db-3/blob/main/quick-set-up.sql) to the directory.

4. Set up the database with all initial mock data inserted.

  Click the "Shell" button on the Control Panel. Type the following:
  ```
      cd mysql\bin
  ```
  Then,
  ```
      mysql -u root -p elidek < quick-set-up.sql 
  ```
  You will be asked to enter your password. If you have not set it, simply press Enter.

5. Navigate to `\xampp\htdocs`, create a new directory "elidek" and place the contents of the [ui](https://github.com/evitapp/db-3/tree/main/ui) folder in it.

6. Open a web browser and go to localhost/elidek.      (should we ask that they also edit index.php to route to /elidek?)
    
#### Note: 
If you get this warning message:
Warning: mysqli::__construct(): (HY000/1045): Access denied for user 'root'@'localhost' (using password: YES) in C:\xampp\htdocs\elidek\config.php on line 19

Edit lines 14 and/or 15 of `\xampp\htdocs\elidek\config.php` to match your credentials.
```
  $username = "root";
  $password = "";
  ```
  
## E-R Diagram
We based our database on the provided Entity-Relationship diagram.

![ER-1](https://user-images.githubusercontent.com/62358292/167364488-d679b6a8-589a-40bd-bbab-b67a8d6aa3df.png)

## Relational Diagram

![relational-diagram](https://user-images.githubusercontent.com/62358292/171855701-8056b0ec-985a-40ca-83a4-62c9870b2f24.png)

## Preview
![image](https://user-images.githubusercontent.com/62358292/172023949-9c32323f-ad0b-40f3-81fb-e5d90e1f4f6c.png)

