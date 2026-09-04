int main() {
    // Simple test: write 42 to RAM[0]
    volatile int* ram = (int*)0x10000000;
    ram[0] = 42;
    return 0;
}
