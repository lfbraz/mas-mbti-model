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
                           BUYER_NAME TEXT,
                           SCORE_DISTANCE FLOAT,
                           SCORE_DENSITY FLOAT,
                           SCORE REAL                             
                             );
  
CREATE TABLE TB_TARGET (ID INTEGER PRIMARY KEY AUTOINCREMENT,
                        TYPE TEXT,
                        INTERACTION INT,
                        SELLER_NAME TEXT,
                        MBTI_SELLER TEXT,
                        BUYER_TARGET TEXT,
                        SCORE
)


CREATE TABLE TB_SELLER_PRODUCTIVITY(ID SERIAL PRIMARY KEY,
                                    INTERACTION INTEGER,
                                    SELLER_NAME VARCHAR(100),
                                    SELLER_ORIGINAL_MBTI VARCHAR(100),
                                    SELLER_REAL_MBTI VARCHAR(100),
                                    BUYER_TARGET VARCHAR(1000),
                                    LOCATION_TARGET VARCHAR(1000),
                                    IS_EXTROVERTED INT,
                                    IS_SENSING INT,
                                    IS_THINKING INT,
                                    IS_JUDGING INT,
                                    NUMBER_OF_VISITED_BUYERS INT,
                                    EXPERIMENT_NAME VARCHAR(50),
                                    SEED FLOAT
                                    );

SELECT user, pid, client_addr, query, query_start, NOW() - query_start AS elapsed
FROM pg_stat_activity
WHERE query != '<IDLE>'
-- AND EXTRACT(EPOCH FROM (NOW() - query_start)) > 1
ORDER BY elapsed DESC;

SELECT COUNT(*) FROM TB_SELLER_PRODUCTIVITY;
TRUNCATE TABLE TB_SELLER_PRODUCTIVITY;