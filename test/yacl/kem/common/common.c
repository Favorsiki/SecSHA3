
    unsigned long long get_cpu_cycle()
    {
        unsigned long long reth1;
        unsigned long long retl0;
        __asm__ __volatile__(
        "rdtsc" :
        "=d" (reth1),
        "=a" (retl0)
        );
        return ((reth1 << 32)|(retl0));
    }