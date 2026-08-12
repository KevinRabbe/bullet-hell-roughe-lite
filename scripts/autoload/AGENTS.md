# Autoload Services
- Owns global services such as `DataRegistry` and `RunRng`.
- Gameplay-affecting randomness should come from named RNG streams exposed here.
- Keep registry validation useful and low-noise; warn once when possible.
- `DataRegistry.load_failures` is strict validation input: unreadable resources and malformed or skipped JSON entries must be recorded instead of silently shrinking a content registry.
