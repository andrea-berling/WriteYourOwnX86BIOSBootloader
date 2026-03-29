// -----------------------------------------------------------------------------
// main.c - A minimal 32-bit Protected Mode Stage2 bootloader
// -----------------------------------------------------------------------------

#define VGA_ADDRESS 0xb8000
#define WHITE_ON_BLACK 0x0f
#define ROW_WIDTH 80
#define COL_WIDTH 25
#include <stdint.h>

// Access video memory directly
volatile char* video_memory = (volatile char*)VGA_ADDRESS;

void print_string(const char* string, int offset) {
    int i = 0;
    while (string[i] != 0) {
        // Character
        video_memory[offset * 2] = string[i];
        // Attribute
        video_memory[offset * 2 + 1] = WHITE_ON_BLACK;
        i++;
        offset++;
    }
}

void clear_screen() {
    for (int i = 0; i < ROW_WIDTH * COL_WIDTH; i++) {
        video_memory[i * 2] = ' ';
        video_memory[i * 2 + 1] = WHITE_ON_BLACK;
    }
}

// Entry point
void __attribute__((section(".text.entry"))) entrypoint(uint32_t cursor_position) {
    // clear_screen();
    int row_number = (cursor_position >> 8) & 0xff;
    int col_number = cursor_position & 0xff;
    print_string("Hello from Stage 2!", ROW_WIDTH*row_number + col_number);

    // Hang indefinitely
    while (1) {}
}
