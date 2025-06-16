const text = @import("textout.zig");
const multiboot = @cImport({
    @cInclude("multiboot.h");
});

const FLAGS = multiboot.MULTIBOOT_PAGE_ALIGN | multiboot.MULTIBOOT_MEMORY_INFO;
export var multibootHeader: multiboot.multiboot_header align(4) linksection(".multiboot") = .{
    .magic = multiboot.MULTIBOOT_HEADER_MAGIC,
    .flags = FLAGS,
    .checksum = @bitCast(-(multiboot.MULTIBOOT_HEADER_MAGIC + FLAGS)),
};

var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

// We specify that this function is "naked" to let the compiler know
// not to generate a standard function prologue and epilogue, since
// we don't have a stack yet.
export fn _start() callconv(.Naked) noreturn {
    // We use inline assembly to set up the stack before jumping to
    // our kernel main.
    asm volatile (
        \\ movl %[stack_top], %%esp
        \\ movl %%esp, %%ebp
        \\ movl %%eax, %%edi  // save multiboot magic to EDI
        \\ movl %%ebx, %%esi  // save multiboot info pointer to ESI
        \\ push %%esi         // 2nd arg
        \\ push %%edi         // 1st arg
        \\ call %[kmain:P]
        :
        // The stack grows downwards on x86, so we need to point ESP
        // to one element past the end of `stack_bytes`.
        //
        // Unfortunately, we can't just compute `&stack_bytes[stack_bytes.len]`,
        // as the Zig compiler will notice the out-of-bounds access
        // at compile-time and throw an error.
        //
        // We can instead take the start address of `stack_bytes` and
        // add the size of the array to get the one-past-the-end
        // pointer. However, Zig disallows pointer arithmetic on all
        // pointer types except "multi-pointers" `[*]`, so we must cast
        // to that type first.
        //
        // Finally, we pass the whole expression as an input operand
        // with the "immediate" constraint to force the compiler to
        // encode this as an absolute address. This prevents the
        // compiler from doing unnecessary extra steps to compute
        // the address at runtime (especially in Debug mode), which
        // could possibly clobber registers that are specified by
        // multiboot to hold special values (e.g. EAX).
        : [stack_top] "i" (@as([*]align(16) u8, @ptrCast(&stack_bytes)) + @sizeOf(@TypeOf(stack_bytes))),
          // We let the compiler handle the reference to kmain by passing it as an input operand as well.
          [kmain] "X" (&kmain),
    );
}

fn kmain(multibootMagic: u32, multibootInfo: *multiboot.multiboot_info) callconv(.C) void {
    if (multibootMagic != 0x2BADB002) return;
    text.setColor(.{ .bg = .BLACK, .fg = .RED });
    text.puts("newline test\n");
    text.puts("newline test\n");
    text.printf("printf test {}", .{multibootInfo});
    asm volatile ("hlt");
}
