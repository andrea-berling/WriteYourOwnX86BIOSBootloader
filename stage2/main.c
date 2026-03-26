// -----------------------------------------------------------------------------
// kernel.c - A minimal 32-bit Protected Mode kernel
// -----------------------------------------------------------------------------

#define VGA_ADDRESS 0xb8000
#define WHITE_ON_BLACK 0x0f

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
    for (int i = 0; i < 80 * 25; i++) {
        video_memory[i * 2] = ' ';
        video_memory[i * 2 + 1] = WHITE_ON_BLACK;
    }
}

// Entry point
void __attribute__((section(".text.entry"))) main() {
    clear_screen();
    print_string("Hello from Stage 2!", 0);

    // Hang indefinitely
    while (1) {}
}
