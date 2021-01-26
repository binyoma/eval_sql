
-- 1) Requêtes d'intérrogation sur la base NorthWind


/*1 - Liste des contacts français*/
SELECT CompanyName as "société",
contactName as "contact",
ContactTitle as "Fonction",
Phone as "Téléphone"
FROM customers
WHERE Country="France";

/* 2 - Produits vendus par le fournisseur « Exotic Liquids »*/
SELECT ProductName as "Produit",
UnitPrice as "Prix"
FROM products
WHERE SupplierID=1;

/*3 - Nombre de produits vendus par les fournisseurs Français dans l’ordre décroissant*/
SELECT CompanyName as "Fournisseur",
count(products.SupplierID) as "Nbre produits"
FROM suppliers INNER JOIN products on suppliers.SupplierID=products.SupplierID
WHERE suppliers.Country="France"
group by products.SupplierID
order by count(products.SupplierID) Desc  ;

/*4 Liste des clients Français ayant plus de 10 commandes*/
SELECT CompanyName as "client",
COUNT(orders.CustomerID) as "Nbre commandes"
FROM orders inner join customers on orders.CustomerID=customers.CustomerID
WHERE ShipCountry ="France"
group by orders.CustomerID
Having COUNT(orders.CustomerID) >10 ;

/*5 - Liste des clients ayant un chiffre d’affaires > 30.00*/
SELECT ShipName as "client",
SUM(orderdetails.UnitPrice*orderdetails.Quantity) as "CA",
ShipCountry as Pays
FROM  orders INNER JOIN orderdetails ON orders.OrderID=orderdetails.OrderID
GROUP BY CLIENT
HAVING CA>30000
ORDER BY CA DESC ;

/*6 – Liste des pays dont les clients ont passé commande de produits fournis par « Exotic
Liquids »*/
SELECT Distinct customers.Country as Pays
FROM customers inner join orders on customers.CustomerID=orders.CustomerID
    INNER JOIN orderdetails on  orders.OrderID=orderdetails.OrderID 
    INNER JOIN products  on   orderdetails.productID=products.productID
    INNER JOIN suppliers on products.SupplierID=suppliers.supplierID
Where suppliers.CompanyName="Exotic Liquids"
ORDER BY customers.Country Asc;

/*7 – Montant des ventes de 1997 */
SELECT SUM(orderdetails.UnitPrice*orderdetails.Quantity) as "Montant ventes 97"
FROM orders inner JOIN orderdetails on orders.OrderID=orderdetails.OrderID
WHERE YEAR(OrderDate)=1997

/*8 – Montant des ventes de 1997 mois par mois */
SELECT SUM(orderdetails.UnitPrice*orderdetails.Quantity) as "Montant ventes 97"
FROM orders inner JOIN orderdetails on orders.OrderID=orderdetails.OrderID
WHERE YEAR(OrderDate)= 1997
GROUP BY MONTH(orderDate);

/*9 – Depuis quelle date le client « Du monde entier » n’a plus commandé ?*/
SELECT MAX(OrderDate) as "Date de dernière commande"
FROM orders inner JOIN customers on orders.CustomerID=customers.CustomerID
WHERE customers.CompanyName="Du monde entier";

/*10 – Quel est le délai moyen de livraison en jours ?*/
SELECT ROUND(AVG(DATEDIFF(ShippedDate,OrderDate))) AS "Délai moyen de livraison"
FROM orders;


-- 2) Procédures stockées
 /*Depuis quelle date le client « x » n’a plus commandé ?*/

DELIMITER |

CREATE PROCEDURE dernière_commande(
    IN client VARCHAR(50)
)
BEGIN
    SELECT MAX(OrderDate) as "Date de dernière commande"
    FROM orders inner JOIN customers on orders.CustomerID=customers.CustomerID
    WHERE customers.CompanyName=client;
END |

DELIMITER ;

/*10 – Quel est le délai moyen de livraison en jours ?*/
DELIMITER |

CREATE PROCEDURE delaiMoyen_livraison()
BEGIN
    SELECT ROUND(AVG(DATEDIFF(ShippedDate,OrderDate))) AS "Délai moyen de livraison"
    FROM orders;
END |

DELIMITER ;

-- 3)Mise en place d'une règle de gestion
/*  j'ai proposé d'augmenter le prix de fret de 5%*/

CREATE TRIGGER `transport` AFTER INSERT ON `orderdetails` FOR EACH ROW BEGIN 
  DECLARE customerCountry VARCHAR(15);
  DECLARE supplierCountry VARCHAR(15);
  SET customerCountry = ( SELECT Country FROM customers INNER JOIN orders on customers.CustomerID = orders.CustomerID INNER JOIN orderdetails on orders.OrderID= orderdetails.OrderID WHERE orderdetails.OrderID =NEW.OrderID LIMIT 1); 
  SET supplierCountry = ( SELECT Country FROM suppliers INNER JOIN products on suppliers.SupplierID = products.SupplierID INNER JOIN orderdetails on products.ProductID= orderdetails.ProductID WHERE orderdetails.ProductID =new.ProductID LIMIT 1); 
  IF customerCountry != supplierCountry 
   THEN 
    UPDATE orders
    SET Freight= Freight*1.05
    WHERE OrderID=NEW.OrderID;
   END IF; 
END