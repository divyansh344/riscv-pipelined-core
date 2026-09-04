#define NUM_ELEMENTS 50

int main() {
    volatile int* ram = (int*)0x10000000;
    
    int n = NUM_ELEMENTS;
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - i - 1; j++) {
            if (ram[j] > ram[j + 1]) {
                // Swap
                int temp = ram[j];
                ram[j] = ram[j + 1];
                ram[j + 1] = temp;
            }
        }
    }
    
    return 0;
}
