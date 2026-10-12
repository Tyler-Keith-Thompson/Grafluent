#ifndef CLIBFUZZER_H
#define CLIBFUZZER_H

#include <stddef.h>
#include <stdint.h>

/// libFuzzer's driver, for a program that has its own `main`: LLVM's documented entry point
/// ("Using LibFuzzer as a library", llvm.org/docs/LibFuzzer.html), defined by the fuzzer runtime
/// that `-sanitize=fuzzer` links. It parses the command line in `argc`/`argv` as libFuzzer's own
/// `main` would and calls `callback` with each input; it returns the process's exit status.
int LLVMFuzzerRunDriver(int *argc, char ***argv, int (*callback)(const uint8_t *data, size_t size));

#endif
