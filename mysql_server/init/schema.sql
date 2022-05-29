-- MySQL dump 10.13  Distrib 8.0.25, for Win64 (x86_64)
--
-- Host: localhost    Database: rpgdb
-- ------------------------------------------------------
-- Server version	8.0.25

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `rpgdb`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `rpgdb` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `rpgdb`;

--
-- Table structure for table `igrac`
--

DROP TABLE IF EXISTS `igrac`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `igrac` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `pos_x` float DEFAULT NULL,
  `pos_y` float DEFAULT NULL,
  `pos_z` float DEFAULT NULL,
  `rot_x` float DEFAULT NULL,
  `rot_y` float DEFAULT NULL,
  `rot_z` float DEFAULT NULL,
  `novac` int NOT NULL DEFAULT '0',
  `model_id` smallint NOT NULL DEFAULT '0',
  `nalog_id` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_nalog_id` (`nalog_id`),
  CONSTRAINT `fk_nalog_id` FOREIGN KEY (`nalog_id`) REFERENCES `nalog` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nalog`
--

DROP TABLE IF EXISTS `nalog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nalog` (
  `korisnicko_ime` varchar(32) NOT NULL,
  `lozinka` char(60) NOT NULL,
  `email` varchar(45) DEFAULT NULL,
  `vreme_registracije` datetime DEFAULT CURRENT_TIMESTAMP,
  `poslednji_login` datetime DEFAULT NULL,
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vozilo`
--

DROP TABLE IF EXISTS `vozilo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vozilo` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `model_id` smallint unsigned NOT NULL,
  `registarska_tablica` varchar(8) DEFAULT NULL,
  `color_1` char(6) NOT NULL,
  `color_2` char(6) NOT NULL,
  `color_3` char(6) NOT NULL,
  `color_headlight` char(6) NOT NULL,
  `vlasnik_id` int unsigned NOT NULL,
  `gorivo` tinyint unsigned DEFAULT '0',
  `pos_x` float NOT NULL,
  `pos_y` float NOT NULL,
  `pos_z` float NOT NULL,
  `rot_x` float NOT NULL,
  `rot_y` float NOT NULL,
  `rot_z` float NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `registarska_tablica` (`registarska_tablica`),
  KEY `fk_vlasnik_id` (`vlasnik_id`),
  CONSTRAINT `fk_vlasnik_id` FOREIGN KEY (`vlasnik_id`) REFERENCES `igrac` (`id`) ON DELETE CASCADE,
  CONSTRAINT `vozilo_ibfk_1` FOREIGN KEY (`vlasnik_id`) REFERENCES `igrac` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'rpgdb'
--
/*!50003 DROP FUNCTION IF EXISTS `RegistarskaOznaka` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`mta_server`@`%` FUNCTION `RegistarskaOznaka`(duzina VARCHAR(20)) RETURNS varchar(100) CHARSET utf8mb4
begin SET @oznaka = ''; SET @slova = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; SET @brojevi = '1234567890'; SET @i = 0; WHILE (@i < duzina) DO IF @i < (duzina-2) THEN SET @oznaka = CONCAT(@oznaka, substring(@slova, FLOOR(RAND() * LENGTH(@slova) + 1), 1)); ELSE SET @oznaka = CONCAT(@oznaka, substring(@brojevi, FLOOR(RAND() * LENGTH(@brojevi) + 1), 1)); END IF; SET @i = @i + 1; END WHILE; RETURN @oznaka; END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `RegistrujVozilo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`mta_server`@`%` FUNCTION `RegistrujVozilo`(id_vozila INT, duzina TINYINT) RETURNS varchar(20) CHARSET utf8mb4
    MODIFIES SQL DATA
BEGIN SET @oznaka = REGISTARSKAOZNAKA(duzina); WHILE ( (SELECT count(*) FROM vozilo WHERE registarska_tablica = @oznaka) > 0 ) DO SET @oznaka = REGISTARSKAOZNAKA(duzina); END WHILE; UPDATE vozilo SET registarska_tablica = @oznaka WHERE id = id_vozila; RETURN @oznaka; END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2022-05-29 14:52:41
