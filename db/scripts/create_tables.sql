DROP TABLE TB_SCORE_E_I;
DROP TABLE TB_SCORE_S_N;

CREATE TABLE TB_SCORE_E_I (ID INTEGER PRIMARY KEY AUTOINCREMENT,
                           INTERACTION INT,
                           SELLER_NAME TEXT,
                           MBTI_SELLER TEXT,
                           DISTANCE_TO_BUYER REAL,
                           NUMBER_OF_PEOPLE_AT_BUYER INT,
                           BUYER_NAME TEXT,
                           SCORE_DISTANCE FLOAT,
                           SCORE_QTY_BUYERS FLOAT,
                           SCORE REAL                             
                             );

CREATE TABLE TB_SCORE_S_N (ID INTEGER PRIMARY KEY AUTOINCREMENT,
                           INTERACTION INT,
                           SELLER_NAME TEXT,
                           MBTI_SELLER TEXT,
                           CLUSTER_DENSITY INT,
                           DISTANCE_TO_BUYER REAL,
                           CLUSTER TEXT,
                           BUYER_NAME TEXT,
                           SCORE_DISTANCE FLOAT,
                           SCORE_DENSITY FLOAT,
                           SCORE REAL                             
                             );
  
CREATE TABLE TB_TARGET (ID INTEGER PRIMARY KEY AUTOINCREMENT,
                        INTERACTION INT,
                        SELLER_NAME TEXT,
                        MBTI_SELLER TEXT,
                        BUYER_TARGET TEXT,
                        SCORE REAL
                        );