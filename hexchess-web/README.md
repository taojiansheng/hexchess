# Hexchess Web

This folder is a new full-stack web version under the original Java Hexchess project.

## Structure

- `backend`: Spring Boot 2 backend, REST API, MySQL persistence.
- `frontend`: Vue2 battle screen.
- `database`: MySQL bootstrap script.

## Current Scope

- No login or registration yet.
- The first screen is the battle interface.
- The board is an 11x11 hex grid.
- Red connects top to bottom, blue connects left to right.
- The player can choose red first move or blue second move.
- After a human move, the backend immediately applies one AI move.
- The old Java AI algorithm is isolated behind `AiEngine`; the current web AI uses depth-limited search with connection-distance evaluation.

## Run MySQL

Create the database first:

```sql
CREATE DATABASE IF NOT EXISTS hexchess
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

The default backend config is:

- database: `hexchess`
- username: `root`
- password: `770329`
- port: `3307`

Change these in `backend/src/main/resources/application.yml` if your local MySQL uses another account.

## Run Backend

```bash
cd backend
mvn spring-boot:run
```

Main APIs:

- `POST /api/matches`: create a match. Body example: `{"humanColor":"RED"}` or `{"humanColor":"BLUE"}`.
- `GET /api/matches/{id}`: load a match.
- `POST /api/matches/{id}/moves`: play a human move with body `{"row":0,"col":0}`.
- `GET /api/matches/{id}/ai/suggestion`: preview the AI suggestion.

## Run Frontend

```bash
cd frontend
npm install
npm run serve
```

Open `http://localhost:8081`.

## Old AI Integration

The previous project currently exposes compiled classes such as:

- `com.withing.project.AI.AIObject`
- `com.withing.project.action.GameAction`
- `com.withing.project.UI.HexUI`

`AIObject` depends on the old Swing `HexUI`, so the web project does not call it directly from REST yet. The backend uses the `AiEngine` interface:

```java
public interface AiEngine {
    AiMove chooseMove(int[][] board, PlayerColor aiColor);
}
```

When the old Java source is available, move the AI calculation out of the Swing UI dependency and implement it in `LegacyAiEngine`. The frontend and REST API do not need to change.
