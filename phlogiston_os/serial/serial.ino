/* Compile with:
 * arduino-cli compile serial.ino --fqbn "arduino:avr:uno"
 * arduino-cli upload serial.ino --fqbn "arduino:avr:uno" --port /dev/ttyACM0
 */

// https://systemembedded.eu/download/file.php?id=172&sid=0ad25e106c4c5b0b8739cf29a67e8601&mode=view
// http://krap.pl/mirrorz/atari/homepage.ntlworld.com/kryten_droid/Atari/800XL/atari_hw/pokey.htm#Serial%20Port
#define CLK_OUT  3 // ACLK
#define CLK_IN   2 // BCLK
#define DATA_OUT 7 // SOD
#define DATA_IN  4 // SID

#define BCLK_HPERIOD 1 // half period of biclock

// Ribbon cabble mapping:
// 4 (yellow) -> SID  (from Arduino)
// 2 (orange) -> BCLK (from Arduino), bidirectional clock
// 3 (red)    -> ACLK (into Arduino)
// 7 (brown)  -> SOD  (into Arduino)

void setup() {
    pinMode(CLK_IN, OUTPUT);
    pinMode(DATA_IN, OUTPUT);
    pinMode(CLK_OUT, INPUT);
    pinMode(DATA_OUT, INPUT);
    digitalWrite(DATA_IN, HIGH);
    Serial.begin(57600);
}

void pulseClockRecv() {
    digitalWrite(CLK_IN, LOW);
    delay(BCLK_HPERIOD);
    digitalWrite(CLK_IN, HIGH);
    delay(BCLK_HPERIOD);
}

void pulseClockSend() {
    digitalWrite(CLK_IN, HIGH);
    delay(BCLK_HPERIOD);
    digitalWrite(CLK_IN, LOW);
    delay(BCLK_HPERIOD);
}

int recieveData() {
    int num = 0;
    for (int i = 0; i < 8; i++) {
        pulseClockRecv();
        num = (num >> 1) + (digitalRead(DATA_OUT) ? 0x80 : 0);
    }
    return num;
}

void sendData(int data) {
    digitalWrite(DATA_IN, LOW); // Transmission start bit
    pulseClockSend();
    for (int i = 0; i < 8; i++) {
        int toSend = data & 1;
        data >>= 1;
        digitalWrite(DATA_IN, toSend ? HIGH : LOW);
        pulseClockSend();
    }
    digitalWrite(DATA_IN, HIGH); // Transmission stop bit
    pulseClockSend();
}

void loop() {
    char output[15];

    pulseClockRecv();
    if (digitalRead(DATA_OUT) == LOW) {
        int dat = recieveData();
        sprintf(output, "recv: %02x", dat);
        Serial.println(output);

        sprintf(output, "send: %02x", dat + 1);
        Serial.println(output);
        sendData(dat + 1);
    }
}
