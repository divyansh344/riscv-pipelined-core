#define NUM_ELEMENTS 50

int main() {
    volatile int* ram = (int*)0x10000000;
    
    // We use the hardware memory layout agreed upon in the plan
    int* arr = (int*)&ram[0];       // Input array (indices 0-49)
    int* out = (int*)&ram[100];     // Scratchpad array (indices 100-149)
    int* count = (int*)&ram[200];   // Count array (indices 200-455, size 256)
    
    int n = NUM_ELEMENTS;
    
    // Radix sort with base 256 (4 passes for 32-bit integers)
    // We use shifts instead of modulo to avoid hardware division!
    for (int shift = 0; shift < 32; shift += 8) {
        
        // 1. Reset count array
        for (int i = 0; i < 256; i++) {
            count[i] = 0;
        }
        
        // 2. Count frequencies of the current byte
        for (int i = 0; i < n; i++) {
            int byte = (arr[i] >> shift) & 0xFF;
            count[byte]++;
        }
        
        // 3. Compute prefix sums
        for (int i = 1; i < 256; i++) {
            count[i] += count[i - 1];
        }
        
        // 4. Build the output array (traverse backwards for stability)
        for (int i = n - 1; i >= 0; i--) {
            int byte = (arr[i] >> shift) & 0xFF;
            int idx = count[byte] - 1;
            out[idx] = arr[i];
            count[byte]--;
        }
        
        // 5. Copy back to the main array for the next pass
        for (int i = 0; i < n; i++) {
            arr[i] = out[i];
        }
    }
    
    return 0;
}
