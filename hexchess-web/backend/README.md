# Backend Notes

The backend is intentionally split into web-facing services and AI strategy:

- `controller`: REST endpoints.
- `service`: match workflow and board rules.
- `model`: JPA entities for MySQL.
- `ai`: AI adapter boundary.

`HeuristicAiEngine` uses alpha-beta search, beam-limited candidates, and shortest connection distance. Replace the bean with a real `LegacyAiEngine` implementation after extracting the previous algorithm from the old Swing `HexUI` dependency.

The board values sent to Vue are:

- `0`: empty
- `1`: red human piece
- `2`: blue piece

The owner of a color depends on match setup:

- `humanColor=RED`: human first, AI blue.
- `humanColor=BLUE`: AI red first, human second.
