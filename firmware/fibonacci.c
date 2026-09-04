int main() {
  volatile int *ram = (int *)0x10000000; // pointer to the start of Data Memory

  int count = 20; // limit of fibonacci numbers

  ram[0] = 0; // first number
  ram[1] = 1; // second number

  // Start the loop at index 2, and fill the array sequentially
  for (int k = 2; k < count; k++) {
    ram[k] = ram[k - 1] + ram[k - 2];
  }

  return 0;
}