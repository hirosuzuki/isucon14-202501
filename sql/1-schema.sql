SET CHARACTER_SET_CLIENT = utf8mb4;
SET CHARACTER_SET_CONNECTION = utf8mb4;

USE isuride;

DROP TABLE IF EXISTS settings;
CREATE TABLE settings
(
  name  VARCHAR(30) NOT NULL COMMENT '設定名',
  value TEXT        NOT NULL COMMENT '設定値',
  PRIMARY KEY (name)
)
  COMMENT = 'システム設定テーブル';

DROP TABLE IF EXISTS chair_models;
CREATE TABLE chair_models
(
  name  VARCHAR(50) NOT NULL COMMENT '椅子モデル名',
  speed INTEGER     NOT NULL COMMENT '移動速度',
  PRIMARY KEY (name)
)
  COMMENT = '椅子モデルテーブル';

DROP TABLE IF EXISTS chairs;
CREATE TABLE chairs
(
  id           VARCHAR(26)  NOT NULL COMMENT '椅子ID',
  owner_id     VARCHAR(26)  NOT NULL COMMENT 'オーナーID',
  name         VARCHAR(30)  NOT NULL COMMENT '椅子の名前',
  model        TEXT         NOT NULL COMMENT '椅子のモデル',
  is_active    TINYINT(1)   NOT NULL COMMENT '配椅子受付中かどうか',
  access_token VARCHAR(255) NOT NULL COMMENT 'アクセストークン',
  created_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '登録日時',
  updated_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新日時',
  INDEX (access_token),
  PRIMARY KEY (id)
)
  COMMENT = '椅子情報テーブル';

DROP TABLE IF EXISTS chair_locations;
CREATE TABLE chair_locations
(
  id         VARCHAR(26) NOT NULL,
  chair_id   VARCHAR(26) NOT NULL COMMENT '椅子ID',
  latitude   INTEGER     NOT NULL COMMENT '経度',
  longitude  INTEGER     NOT NULL COMMENT '緯度',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '登録日時',
  PRIMARY KEY (id)
)
  COMMENT = '椅子の現在位置情報テーブル';

DROP TABLE IF EXISTS users;
CREATE TABLE users
(
  id              VARCHAR(26)  NOT NULL COMMENT 'ユーザーID',
  username        VARCHAR(30)  NOT NULL COMMENT 'ユーザー名',
  firstname       VARCHAR(30)  NOT NULL COMMENT '本名(名前)',
  lastname        VARCHAR(30)  NOT NULL COMMENT '本名(名字)',
  date_of_birth   VARCHAR(30)  NOT NULL COMMENT '生年月日',
  access_token    VARCHAR(255) NOT NULL COMMENT 'アクセストークン',
  invitation_code VARCHAR(30)  NOT NULL COMMENT '招待トークン',
  created_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '登録日時',
  updated_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新日時',
  PRIMARY KEY (id),
  UNIQUE (username),
  UNIQUE (access_token),
  UNIQUE (invitation_code)
)
  COMMENT = '利用者情報テーブル';

DROP TABLE IF EXISTS payment_tokens;
CREATE TABLE payment_tokens
(
  user_id    VARCHAR(26)  NOT NULL COMMENT 'ユーザーID',
  token      VARCHAR(255) NOT NULL COMMENT '決済トークン',
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '登録日時',
  PRIMARY KEY (user_id)
)
  COMMENT = '決済トークンテーブル';

DROP TABLE IF EXISTS rides;
CREATE TABLE rides
(
  id                    VARCHAR(26) NOT NULL COMMENT 'ライドID',
  user_id               VARCHAR(26) NOT NULL COMMENT 'ユーザーID',
  chair_id              VARCHAR(26) NULL     COMMENT '割り当てられた椅子ID',
  pickup_latitude       INTEGER     NOT NULL COMMENT '配車位置(経度)',
  pickup_longitude      INTEGER     NOT NULL COMMENT '配車位置(緯度)',
  destination_latitude  INTEGER     NOT NULL COMMENT '目的地(経度)',
  destination_longitude INTEGER     NOT NULL COMMENT '目的地(緯度)',
  evaluation            INTEGER     NULL     COMMENT '評価',
  created_at            DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '要求日時',
  updated_at            DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '状態更新日時',
  INDEX (chair_id, updated_at DESC),
  PRIMARY KEY (id)
)
  COMMENT = 'ライド情報テーブル';

DROP TABLE IF EXISTS ride_statuses;
CREATE TABLE ride_statuses
(
  id              VARCHAR(26)                                                                NOT NULL,
  ride_id VARCHAR(26)                                                                        NOT NULL COMMENT 'ライドID',
  status          ENUM ('MATCHING', 'ENROUTE', 'PICKUP', 'CARRYING', 'ARRIVED', 'COMPLETED') NOT NULL COMMENT '状態',
  created_at      DATETIME(6)                                                                NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '状態変更日時',
  app_sent_at     DATETIME(6)                                                                NULL COMMENT 'ユーザーへの状態通知日時',
  chair_sent_at   DATETIME(6)                                                                NULL COMMENT '椅子への状態通知日時',
  INDEX (ride_id, id),
  PRIMARY KEY (id)
)
  COMMENT = 'ライドステータスの変更履歴テーブル';

DROP TABLE IF EXISTS owners;
CREATE TABLE owners
(
  id                   VARCHAR(26)  NOT NULL COMMENT 'オーナーID',
  name                 VARCHAR(30)  NOT NULL COMMENT 'オーナー名',
  access_token         VARCHAR(255) NOT NULL COMMENT 'アクセストークン',
  chair_register_token VARCHAR(255) NOT NULL COMMENT '椅子登録トークン',
  created_at           DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '登録日時',
  updated_at           DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新日時',
  PRIMARY KEY (id),
  UNIQUE (name),
  UNIQUE (access_token),
  UNIQUE (chair_register_token)
)
  COMMENT = '椅子のオーナー情報テーブル';

DROP TABLE IF EXISTS coupons;
CREATE TABLE coupons
(
  user_id    VARCHAR(26)  NOT NULL COMMENT '所有しているユーザーのID',
  code       VARCHAR(255) NOT NULL COMMENT 'クーポンコード',
  discount   INTEGER      NOT NULL COMMENT '割引額',
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '付与日時',
  used_by    VARCHAR(26)  NULL COMMENT 'クーポンが適用されたライドのID',
  INDEX (used_by),
  PRIMARY KEY (user_id, code)
)
  COMMENT 'クーポンテーブル';

-- 拡張テーブル

DROP TABLE IF EXISTS chairs_ex;
CREATE TABLE chairs_ex
(
  id                           VARCHAR(26)  NOT NULL COMMENT '椅子ID',
  latitude                     INTEGER      NOT NULL COMMENT '経度',
  longitude                    INTEGER      NOT NULL COMMENT '緯度',
  location_count               INTEGER      NOT NULL,
  total_distance_updated_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '更新日時',
  total_distance               INTEGER      NOT NULL COMMENT '緯度',
  PRIMARY KEY (id)
)
  COMMENT = '椅子情報テーブルの追加情報';

DROP TABLE IF EXISTS rides_ex;
CREATE TABLE rides_ex
(
  id                   VARCHAR(26) NOT NULL COMMENT 'ライドID',
  status               ENUM ('MATCHING', 'ENROUTE', 'PICKUP', 'CARRYING', 'ARRIVED', 'COMPLETED') NOT NULL COMMENT '状態',
  status_count         INTEGER  NOT NULL,
  status_updated_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '更新日時',
  PRIMARY KEY (id)
)
  COMMENT = 'ライド情報テーブルの追加情報';

DELIMITER //

CREATE TRIGGER after_chair_location_insert
AFTER INSERT ON chair_locations
FOR EACH ROW
BEGIN
  INSERT INTO chairs_ex (id, latitude, longitude, location_count, total_distance_updated_at, total_distance)
  VALUES (NEW.chair_id, NEW.latitude, NEW.longitude, 1, NEW.created_at, 0)
  ON DUPLICATE KEY UPDATE
    total_distance = total_distance + ABS(NEW.latitude - latitude) + ABS(NEW.longitude - longitude),
    latitude = NEW.latitude,
    longitude = NEW.longitude,
    location_count = location_count + 1,
    total_distance_updated_at = NEW.created_at;
END;

CREATE TRIGGER after_ride_statuses_insert
AFTER INSERT ON ride_statuses
FOR EACH ROW
BEGIN
  INSERT INTO rides_ex (id, status, status_count, status_updated_at)
  VALUES (NEW.ride_id, NEW.status, 1, NEW.created_at)
  ON DUPLICATE KEY UPDATE
    status = NEW.status,
    status_count = status_count + 1,
    status_updated_at = NEW.created_at;
END;

//

DELIMITER ;

--

DROP VIEW IF EXISTS rides_with_status;
CREATE VIEW rides_with_status AS SELECT rides.*, rides_ex.status, rides_ex.status_updated_at FROM rides LEFT JOIN rides_ex ON rides.id = rides_ex.id;

DROP VIEW IF EXISTS chairs_with_location;
CREATE VIEW chairs_with_location AS
SELECT chairs.*, chairs_ex.latitude, chairs_ex.longitude, chairs_ex.location_count, chairs_ex.total_distance
FROM chairs LEFT JOIN chairs_ex ON chairs.id = chairs_ex.id;
