MAX_PAT_COLS = 80
PATTERN_FIRST_TILENO = 256 - MAX_PAT_COLS / 2

assembled_pattern = $0100
OAM = $0200

.global crc16_update
.globalzp CRCLO, CRCHI
.global rotate_pattern, center_pattern, get_pattern_x
.globalzp NUM_PATTERNS
