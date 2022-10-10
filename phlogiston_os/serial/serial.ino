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
//#define BCLK_HPERIOD 1000

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
    Serial.setTimeout(WINT_MAX);
    Serial.begin(57600);
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

void pingPong() {
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

int waitForData() {
    while (true) {
        pulseClockRecv();
        if (digitalRead(DATA_OUT) == LOW) {
            return recieveData();
        }
    }
}

// 6502 must send 0x42 as a poke byte to initialize transfer
void sendMessage(char *message) {
    while (waitForData() != 0x42);
    for (char *it = message; *it != '\0'; it++) {
        // Serial.print("Sending: ");
        // Serial.println(*it);
        sendData(*it);
    }
    // Serial.println("End message.");
    sendData(0);
}

// Sends garbage data, up to n bytes
void sendBytes(int n) {
    if (n > 0x3ffe) {
        Serial.println("Max sendBytes is 0x3ffe");
        return;
    }
    while (waitForData() != 0x42);
    for (int i = 0; i < n; i++) {
        sendData('0' + (i % 10));
    }
    sendData(0);
}

void loop() {
    sendBytes(0x3ffe);
    //sendMessage("The quick brown fox jumps over the lazy dog.");
    //pingPong();
}
