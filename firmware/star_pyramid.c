int main() {
  // Treat the start of Data Memory as a character buffer
  volatile char *text_buffer = (char *)0x10000000;

  int cursor = 0;
  int height = 10; // 10 rows of stars

  for (int row = 1; row <= height; row++) {
    // 1. Print leading spaces
    for (int s = 0; s < height - row; s++) {
      text_buffer[cursor] = ' ';
      cursor++;
    }
    
    // 2. Print the stars
    for (int s = 0; s < 2 * row - 1; s++) {
      text_buffer[cursor] = '*';
      cursor++;
    }
    text_buffer[cursor] = '\n'; // Newline
    cursor++;
  }

  text_buffer[cursor] = '\0'; // Null-terminator so Python knows when to stop

  return 0;
}
