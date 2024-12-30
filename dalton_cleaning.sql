CREATE TABLE IF NOT EXISTS `dalton_cleaning` (
  `identifier` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `level` int(11) NOT NULL DEFAULT 1,
  `exp` int(11) NOT NULL DEFAULT 0,
  `cleaning_total` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
);