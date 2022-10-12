/* Taken from https://eater.net/6502
 * Compile with:
 * arduino-cli compile 6502Debug.ino --fqbn "arduino:avr:mega"
 * arduino-cli upload 6502Debug.ino --fqbn "arduino:avr:mega" --port /dev/ttyACM0
 */

const char ADDR[] = {28, 41, 31, 42, 34, 35, 33, 32,
                     43, 44, 45, 46, 47, 48, 49, 50};
const char DATA[] = {36, 37, 38, 39, 40, 53, 52, 51};

#define CLOCK 21
#define READ_WRITE 29

void setup() {
    for (int n = 0; n < 16; n += 1) {
        pinMode(ADDR[n], INPUT);
    }
    for (int n = 0; n < 8; n += 1) {
        pinMode(DATA[n], INPUT);
    }
    pinMode(CLOCK, INPUT);
    pinMode(READ_WRITE, INPUT);

    attachInterrupt(digitalPinToInterrupt(CLOCK), onClock, RISING);
    Serial.begin(57600);
}

void onClock() {
    char output[15];

    unsigned int address = 0;
    for (int n = 0; n < 16; n += 1) {
        int bit = digitalRead(ADDR[n]) ? 1 : 0;
        Serial.print(bit);
        address = (address << 1) + bit;
    }

    Serial.print("   ");

    unsigned int data = 0;
    for (int n = 0; n < 8; n += 1) {
        int bit = digitalRead(DATA[n]) ? 1 : 0;
        Serial.print(bit);
        data = (data << 1) + bit;
    }

    sprintf(output, "   %04x  %c %02x", address, digitalRead(READ_WRITE) ? 'r' : 'w', data);
    Serial.println(output);
}

void loop() {
}

