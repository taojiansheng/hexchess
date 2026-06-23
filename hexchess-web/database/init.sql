CREATE DATABASE IF NOT EXISTS hexchess
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE hexchess;

CREATE TABLE IF NOT EXISTS hex_matches (
  id BIGINT NOT NULL AUTO_INCREMENT,
  board_size INT NOT NULL,
  board_json LONGTEXT NOT NULL,
  current_turn VARCHAR(16) NOT NULL,
  human_color VARCHAR(16) NULL,
  ai_color VARCHAR(16) NULL,
  status VARCHAR(24) NOT NULL,
  winner VARCHAR(16) NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS hex_moves (
  id BIGINT NOT NULL AUTO_INCREMENT,
  match_id BIGINT NOT NULL,
  row_index INT NOT NULL,
  col_index INT NOT NULL,
  player VARCHAR(16) NOT NULL,
  move_number INT NOT NULL,
  ai_move BIT NOT NULL,
  created_at DATETIME NOT NULL,
  PRIMARY KEY (id),
  INDEX idx_hex_moves_match_id (match_id),
  CONSTRAINT fk_hex_moves_match
    FOREIGN KEY (match_id)
    REFERENCES hex_matches (id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
