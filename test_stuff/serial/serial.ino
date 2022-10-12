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

// Smol blinking program to test out uploading programs to RAM
// Conveniently, it doesn't have any null bytes!
const char blink[19] = {
    0xa9,
    0xf0,
    0x8d,
    0x03,
    0x80,
    0xa9,
    0x20, // initial output register byte
    0x8d,
    0x01,
    0x80,
    //0x6a, // ror
    0xea, // nop
    0x8d,
    0x01,
    0x80,
    0x4c,
    0x0a,
    0x40,
    0x00, // Null terminate, a bit odd I know
};

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

void echo() {
    if (Serial.available() > 0) {
        byte incoming = Serial.read();
        Serial.write(incoming);
    }
}

void loop() {
    //sendBytes(0x3ffe);
    //sendMessage("The quick brown fox jumps over the lazy dog.");
    //sendMessage(blink);
    //pingPong();
    //infiniteStream();
    relay();
    // Wait for poke byte from 6502
}

// To test that the bootloader buffering code works
void infiniteStream() {
    while (waitForData() != 0x42);
    byte i = 0;
    while (true) {
        sendData(i);
        i = (i + 1) & 0xf;
    }
}

void relay() {
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

    #define BUF_LEN 255
    byte buf[BUF_LEN];
    for (int i = 0; i < progSize;) {
        byte readNum = Serial.readBytes(buf, BUF_LEN);

        for (int j = 0; j < readNum; j++) {
            sendData(buf[j]);
        }
        // Send upload ack byte to PC
        Serial.write(readNum);
        i += readNum;
    }
}
