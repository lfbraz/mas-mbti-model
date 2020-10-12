CREATE TABLE TB_AGENT_SCORE (ID INTEGER PRIMARY KEY AUTOINCREMENT,
                             INTERACTION INT,
                             SELLER_NAME TEXT,
                             MBTI_SELLER TEXT,
                             DISTANCE_TO_BUYER REAL,
                             NUMBER_OF_PEOPLE_AT_BUYER INT,
                             BUYER_NAME TEXT,
                             SCORE_TYPE TEXT,
                             SCORE REAL                             
                             );
