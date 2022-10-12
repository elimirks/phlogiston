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

// Half period of biclock, in microseconds.
// Any faster than 35 and we get unpredictable behavior
// This is largely constrained by the speed of the IRQ handler in the
// loader program.
#define BCLK_HPERIOD 35

// Ribbon cabble mapping:
// 4 (yellow) -> SID  (from Arduino)
// 2 (orange) -> BCLK (from Arduino), bidirectional clock
// 3 (red)    -> ACLK (into Arduino)
// 7 (brown)  -> SOD  (into Arduino)

#define SERIAL_BUF_LEN 255

void setup() {
    pinMode(CLK_IN, OUTPUT);
    pinMode(DATA_IN, OUTPUT);
    pinMode(CLK_OUT, INPUT);
    pinMode(DATA_OUT, INPUT);
    digitalWrite(DATA_IN, HIGH);
    Serial.setTimeout(100);
    Serial.begin(256000);
}

void pulseClockRecv() {
    digitalWrite(CLK_IN, LOW);
    delayMicroseconds(BCLK_HPERIOD);
    digitalWrite(CLK_IN, HIGH);
    delayMicroseconds(BCLK_HPERIOD);
}

void pulseClockSend() {
    digitalWrite(CLK_IN, HIGH);
    delayMicroseconds(BCLK_HPERIOD);
    digitalWrite(CLK_IN, LOW);
    delayMicroseconds(BCLK_HPERIOD);
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

int waitForData() {
    while (true) {
        pulseClockRecv();
        if (digitalRead(DATA_OUT) == LOW) {
            return recieveData();
        }
    }
}

void loop() {
    byte buf[SERIAL_BUF_LEN];

    // Wait for poke byte from 6502
    while (waitForData() != 0x42);
    // Send poke byte to PC
    Serial.write(0x42);
    // Wait for PC to send some data
    while (Serial.available() == 0);
    // First off, find program size. So we know how many bytes to read
    byte lsb = Serial.read();
    while (Serial.available() == 0);
    byte msb = Serial.read();
    // Send the program size to the 6520 as a header
    // sendData(progSize & 0xff);
    // sendData((progSize & 0xff00) >> 8);
    sendData(lsb);
    sendData(msb);

    int progSize = (msb << 8) + lsb;

    for (int i = 0; i < progSize;) {
        byte readNum = Serial.readBytes(buf, SERIAL_BUF_LEN);

        for (int j = 0; j < readNum; j++) {
            sendData(buf[j]);
        }
        // Send upload ack byte to PC
        Serial.write(readNum);
        i += readNum;
    }
}
